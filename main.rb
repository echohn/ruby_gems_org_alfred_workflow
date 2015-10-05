# coding: utf-8
require 'open-uri'
require 'json'

load 'alfred_feedback.rb'
load 'caches.rb'
query = Alfred.query

class RubyGemOrg

  def initialize(query)
    @feedback = Feedback.new
    @caches   = Caches.new

    if query.match ':'
      info query.split.first
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

    @caches.save
  end

  def search_feedback(response)
    response.each do |result|
      @feedback.add_item({
        :uid      => result['name'],
        :title    => result['name'],
        :subtitle => "Downloads: #{result['downloads']} ; Info: #{result['info']}",
        :arg      => result['name'],
        :autocomplete => result['name'] + ' : ',
        :valid    => 'no'
      })
      @caches.add result
    end
  end

  def search_empty
    @feedback.add_item({
      :uid      => 'empty',
      :title    => 'Couldn\'t find any gems like that.',
      :subtitle => "Is spelling wrong ?"
    })
  end


  def info(gem_name)

    @gem_info = @caches.items[gem_name]

    @feedback = Feedback.new
    feedback_add_install_gem
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
