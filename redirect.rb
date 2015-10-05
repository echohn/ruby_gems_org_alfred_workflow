
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
      do script "gem install #{query} --no-document"
    end tell
  __APPLESCRIPT__}
end

case query
when /http[s]*:\/\/.*/
  open_uri query
when /[a-z0-9_\-]+/
  install_gem query
end

