#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'open-uri'
require 'json'
require 'cgi'

# the first part of a term must have no spaces
# the second part is the actual search on search.twitter.com you want counted
TERMS = {
  "etsy"    => "etsy"
}

class Twitter
  def self.base 
    "http://search.twitter.com/search.json?q=%s&rpp=100&page=%s"
  end
  
  def self.mentions(term)
    mentions = 0
    
    1.upto(15) do |page|
      p = JSON.parse(open(base % [CGI.escape(term), page]).read)
      p["results"].each do |tweet|
        t = Time.parse(tweet["created_at"])
        minutes_ago = ((Time.now - t) / 60).to_i
        return mentions if minutes_ago > 5
        mentions += 1
      end
    end
    
    return mentions
  end
end

if ARGV[0] == "config"
  puts "graph_title Twitter Mentions"
  puts "graph_vlabel mentions"
  TERMS.each do |term, title|
    puts "#{term}.label #{title}"
  end
  exit
end

TERMS.each do |term, title|
  puts "#{term}.value #{Twitter.mentions(title)}"
end