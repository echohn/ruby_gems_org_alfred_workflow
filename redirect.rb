
query = ARGV[0]

def open_uri(query)
  %x{osascript <<__APPLESCRIPT__
    open location "#{query}"
__APPLESCRIPT__}
end

def install_gem(query)
  %x{osascript <<__APPLESCRIPT__
    tell application "Terminal"
      activate
      set currentTab to do script "gem install #{query} -N"
    end tell
__APPLESCRIPT__}
end

def install_gem_to_gemset(query,gemset)
  %x{osascript <<__APPLESCRIPT__
    tell application "Terminal"
      activate
      set currentTab to do script "rvm use #{gemset} && gem install #{query} -N"
    end tell
__APPLESCRIPT__}
end

case query
when /http[s]*:\/\/.*/
  open_uri query
when /^[\w\-]+$/
  install_gem query
when /^([\w\-]+)\s+([\w\-\.@]+)$/
  install_gem_to_gemset($1,$2)
end

