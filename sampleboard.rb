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

url = ARGV[0] || 'http://www.freesound.org/packsViewSingle.php?id=1454'

puts "Fetching MP3s..."
mp3s = []
@total_samples = 0
open(url).read.scan(/http:\/\/[^"]+?\.mp3/).each_with_index do |mp3, i|
  break if i > 9
  puts "Loading #{mp3}"
  mp3s << NSSound.alloc.initWithContentsOfURL_byReference(NSURL.alloc.initWithString(mp3), 1)
  @total_samples = i
end

puts "Done. Now hit number 0-#{@total_samples} to play sounds. (ctrl-c or ESC to end)"

while(1)
  c = read_char
  break if c == 27 || c == 3
  c = c.chr.to_i
  if c && mp3s[c]
    Thread.new { mp3s[c].stop; mp3s[c].play }
  end
end
