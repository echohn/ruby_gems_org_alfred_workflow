#!/usr/bin/env ruby

require 'yaml'

class Caches

  TempFile = File.join( Alfred.temp_storage_path, 'gems.yml')

  attr_reader :items

  def initialize
    if File.exist? TempFile
      @items = YAML.load(IO.read(TempFile))
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
    File.open(Caches::TempFile,'w') do |file|
      file.write YAML.dump(@items)
    end
  end

end

#caches = Caches.new
#caches.add({'name' => 'hi','version' => '2.0.0'})
#caches.add({'name' => 'hia','version' => '2.0.0'})
#caches.save



