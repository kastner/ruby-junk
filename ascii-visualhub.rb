#!/usr/bin/env ruby

require 'progress'
require 'convert'

Convert.start(ARGV[0])

Progress.total = Proc.new do
  Convert.frames
end

Progress.current = Proc.new do
  Convert.current_frame
end

puts
print "starting"

while(!Convert.done?)
  Progress.output
  sleep(1)
end

puts "Done..."

Convert.cleanup