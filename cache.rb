require 'yaml'

class Cache

  attr_reader :items

  def initialize(cache_file)
    @cache_file = cache_file
    @items = {}
  end

  def load
    if File.exist? @cache_file
      @items = YAML.load(IO.read(@cache_file))
      @items = {} unless @items
    else
      @items = {}
    end
  end

  def add(hash)
    now = Time.now
    @items[hash['name']] = hash
    @items[hash['name']]['update_time'] = now
  end

  def save
    File.open(@cache_file,'w') do |file|
      file.write YAML.dump(@items)
    end
  end

end



