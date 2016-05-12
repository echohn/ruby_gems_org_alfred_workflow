Encoding::default_external = Encoding::UTF_8 if defined? Encoding

$LOAD_PATH.unshift File.dirname(__FILE__)

require "alfred_feedback"

begin
  require 'json'
  require 'plist'

rescue LoadError
  feedback = Feedback.new
  feedback.add_item({
  :uid      => 'Missing Required Gems',
  :title    => 'Missing Required Gems',
  :subtitle => "Not found gem: json or plist, press enter to install them.",
  :arg      => "json plist"
})
  puts feedback.to_xml
end

require "alfred"
require "cache"
require 'open-uri'


query = ARGV[0]



Alfred = AlfredInit.new(query)

class RubyGemOrg

  def initialize(query)
    @feedback = Feedback.new
    @separator = '=>'
    @separator_gemset = '->'

    temp_file = File.join(Alfred.temp_storage_path, 'gems.yml')
    @cache = Cache.new(temp_file)

    if query.match @separator
      info query.split.first
    elsif query.match @separator_gemset
      choose_gemset query.split.first
    else
      search query
    end
  end

  private

  def search(query)
    api = "https://rubygems.org/api/v1/search.json?query=#{query}"

    response = nil

    open(api) do |http|
      response = http.read
    end

    response = JSON.parse(response)

    if response.empty?
      search_empty
    else
      search_feedback response
    end


    puts @feedback.to_xml

    @cache.save
  end

  def search_feedback(response)
    response.each do |result|
      @feedback.add_item({
        :uid      => result['name'],
        :title    => result['name'],
        :subtitle => "Downloads: #{result['downloads']} ; Info: #{result['info']}",
        :arg      => result['name'],
        :autocomplete => result['name'] + '  ' + @separator,
        :valid    => 'no'
      })
      @cache.add result
    end
  end

  def search_empty
    @feedback.add_item({
      :uid      => 'empty',
      :title    => 'Couldn\'t find any gems like that.',
      :subtitle => "Is spelling wrong ?"
    })
  end

  def choose_gemset(query)
    gemsets =`rvm list gemsets`.lines.map {|x| $2 if x.chomp.match /(=>)*\s+(.*)\s+\[.*\]/}.compact
    feedback = Feedback.new

    gemsets.each do |gemset|
      feedback.add_item({
          :title    => gemset,
          :subtitle => "#{query} will install to #{gemset}",
          :arg      => "#{query} #{gemset}"
      })
    end

    puts feedback.to_xml
  end


  def info(gem_name)
    @cache.load
    @gem_info = @cache.items[gem_name]

    @feedback = Feedback.new
    feedback_add_install_gem
    feedback_add_choose_gemset
    feedback_add_project_uri
    feedback_add_gem_uri
    feedback_add_homepage_uri
    feedback_add_wiki_uri
    feedback_add_documentation_uri
    feedback_add_mailling_list_uri
    feedback_add_source_code_uri
    feedback_add_bug_tracker_uri
    puts @feedback.to_xml
  end

  def feedback_add_install_gem
    @feedback.add_item({
      :title => "Install this gem ...",
      :subtitle => "Version: #{@gem_info["version"]} ; Version downloads: #{@gem_info['version_downloads']}",
      :arg => @gem_info['name']
    })
  end

  def feedback_add_choose_gemset
    @feedback.add_item({
      :title => "Install this gem to specified gemset ...",
      :subtitle => "Version: #{@gem_info["version"]} ; Version downloads: #{@gem_info['version_downloads']}",
      :arg => @gem_info['name'],
      :autocomplete => @gem_info['name'] + '  ' + @separator_gemset,
      :valid    => 'no'
    })
  end
  def method_missing(method_id, &block)
    if method_id.to_s =~ /feedback_add_(.*)_uri/
      uri_name = $1
      unless @gem_info["#{uri_name}_uri"].nil? or @gem_info["#{uri_name}_uri"].empty?
        self.class.send :define_method,method_id do
          @feedback.add_item({
            :title => "Open #{uri_name.split(/_/).map(&:capitalize).join(' ')} Uri ...",
            :subtitle => @gem_info["#{uri_name}_uri"],
            :arg => @gem_info["#{uri_name}_uri"]
          })
        end
        self.send(method_id)
      end
    end
  end

end


gem = RubyGemOrg.new(query)
