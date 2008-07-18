#!/usr/bin/env ruby

require 'open-uri'
require 'osx/cocoa'
include OSX

def read_char
  system "stty raw -echo"
  STDIN.getc
ensure
  system "stty -raw echo"
end

puts "Fetching MP3s..."
mp3s = []
open('http://www.freesound.org/packsViewSingle.php?id=1454').read.scan(/http:\/\/[^"]+?\.mp3/).each_with_index do |mp3, i|
  break if i > 9
  puts "Loading #{mp3}"
  mp3s << NSSound.alloc.initWithContentsOfURL_byReference(NSURL.alloc.initWithString(mp3), 1)
end

puts "Done. Now hit number 0-9 to play sounds. (ctrl-c or ESC to end)"

OSX.ruby_thread_switcher_start(0.001, 0.1)
Thread.start { NSRunLoop.currentRunLoop.run }

while(1)
  c = read_char
  break if c == 27 || c == 3
  c = c.chr.to_i
  if c && mp3s[c]
    Thread.start do
      mp3s[c].play
    end.join
  end
end
