#!/usr/bin/env ruby

module Progress
  extend self

  attr_accessor :file, :total, :current
  
  WIDTH = `tput cols`.to_i - 2
  
  def height
    `tput lines`.to_i
  end
  
  def percent_done
  	("%0.4f" % (current.call.to_f / total.call)).to_f
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
  	"#{current.call}/#{total.call} (#{percent_done * 100}%)"
  end

  def output
    s = status

    unless @cleared
      puts "\n\n"
      @cleared = true
    end
    
    print "\033[2A" # up 2 lines
    puts s
    puts progress
  end
end

