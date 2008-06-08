#!/usr/bin/env ruby

module Convert
  extend self
  
  def start(start_file)
    Thread.new do
      system(%Q{/Library/Application\\ Support/Techspansion/vh131ffmpeg -y -i #{start_file} -threads 4 -s 800x480 -aspect 800/480 -r 23.98 -vcodec h264 -g 200 -qmin 8 -b 230k -bf 1 -level 41 -loop 1 -sc_threshold 40 -partp4x4 1 -rc_eq "blurCplx^(1-qComp)" -refs 3 -qmax 51 -async 50 -acodec libfaac -ar 48000 -ac 2 -ab 128k #{start_file}.mp4 2>> #{file}; echo done >> #{done_file}})
    end
  end
  
  def file
    @file ||= "/tmp/progress-#{self.object_id}"
  end
  
  def done_file
    @done_file ||= "/tmp/finished-#{self.object_id}"
  end
  
  def done?
    File.exists?(done_file) && open(done_file).read =~ /done/
  end
end

module Status
  extend self

  attr_accessor :file
  
  WIDTH = `tput cols`.to_i - 2
  # FILE = ARGV[0]
  
  def contents
  	@contents ||= open(file).read
  end

  def frames
  	@frames ||= begin
  		frame_rate = contents[/0.0,,,,,Video,.*q=.*,([\d\.]+)$/,1].to_f
  		duration = contents[/Duration-(\d+)/,1].to_f
  		(frame_rate * duration).to_i
  	end
  end

  def current_frame
    return 0 unless File.exists?(file)
    
    matches = open(file).read.scan(/frame=\s*(\d+)/)
    (matches.last && matches.last[0]).to_i || 0
  end

  def percent_done
  	("%0.4f" % (current_frame.to_f / frames)).to_f
  end

  def done_chars
  	(percent_done * WIDTH).to_i
  end

  def progress
  	out = ""
  	out << "["
  	out << "=" * (done_chars)
  	out << ">"
  	out << "-" * ((WIDTH - done_chars) - 1)
  	out << "]"
  end

  def status
  	"#{current_frame}/#{frames} (#{percent_done * 100}%)"
  end

  def output
  	s = status
  	#print "\033[2A#{" " * WIDTH}"
  	#print "\033[1B#{" " * WIDTH}"
  	#print "\033[#{WIDTH}D"
  	#print "\033[2A#{s}"
  	#print "\033[1B\033[#{s.length}D#{progress}"
  	puts "\033[2J"
  	puts s
  	puts progress
  	print "\033[2B"
  end
end

Convert.start(ARGV[0])
Status.file = Convert.file

puts
print "starting"

while(Status.current_frame == 0)
  print "."
  sleep(0.5)
end

while(!Convert.done?)
  Status.output
  sleep(1)
end

puts "Done..."

File.unlink(Convert.file)
File.unlink(Convert.done_file)
