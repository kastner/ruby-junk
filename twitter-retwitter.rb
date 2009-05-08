#!/usr/bin/env ruby

# */15 * * * * cd /path/to/script_dir/ && ruby twitter-retwitter.rb > /dev/null 2>&1

require 'net/http'
require 'rss'
require 'open-uri'

TWITTER_USER = "bedtime" # your twitter username
TWITTER_PASS = "SECRET" # twitter password
DONE_FILE = "#{ENV["HOME"]}/.retweet_list"
SEPERATOR = "\n--==--==--*--==--==--\n"

seen_replies = []
begin
  seen_replies = open(DONE_FILE).read.split(SEPERATOR)
rescue Errno::ENOENT
end

get_more = true
page = 1

while get_more do
  rss = RSS::Parser.parse(open("http://twitter.com/statuses/replies.rss?page=#{page}", :http_basic_authentication => [TWITTER_USER, TWITTER_PASS]).read)

  # if this page is empty, we're done
  get_more = false if rss.items.empty?

  # loop over each reply
  rss.items.each do |item|
    reply = item.link + "|" + item.description.chomp

    # if we haven't seen it before
    unless seen_replies.include?(reply) or seen_replies.include?(reply + "\n")
      
      # put it in teh seen list
      seen_replies << reply
      
      # fix the tweet to give credit to the author
      tweet = item.description.gsub(/^([^:].+): @#{TWITTER_USER}/, 'from @\1:')
      
      # post to twitter
      puts "Posting #{tweet}"
      Net::HTTP.post_form(URI.parse("http://#{TWITTER_USER}:#{TWITTER_PASS}@twitter.com/statuses/update.json"),
        {'status' => tweet}
      )
    else
      get_more = false
    end
  end
  
  page += 1
end

# write out the file
File.open(DONE_FILE, "w") do |f|
  f.puts seen_replies.join(SEPERATOR)
end
