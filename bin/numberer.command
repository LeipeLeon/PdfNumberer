#!/usr/bin/env ruby 

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

if ARGV.include?('-h')
  puts <<-RUBY
Usage #{$0}:
  #{$0} <config file>       Load alternative config file (Default ~/pdf_numberer)
  ENV=DEBUG #{$0}           debugging mode
  #{$0} -h                  this screen
RUBY
  exit
end

require 'pdf_numberer'

# first check if there is a process running
# FIXME This is very HACKish
if `ps waux | grep numberer | grep fsevent_sleep`.split("\n").length > 1
  raise "[41;37;1m\n#{"\t" * 8}\n#{"\t" * 8}\n\tLijkt er op dat er al een process draait!\t\t\n#{"\t" * 8}\n#{"\t" * 8}\n\n[0m"
end

numberer = PdfNumberer.new
puts "[41;37;1m\nCurrent Config:\n\n"
puts numberer.prefs.to_yaml
puts "\n\n[0m"

while true
  numberer.watch
end

