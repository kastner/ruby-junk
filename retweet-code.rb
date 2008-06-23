#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'json'
require 'net/http'

TWITTER_USER = ""
TWITTER_PASS = ""
RETWEET_CODE = "" # This code is given out to trusted people allowed to retweet

LAST_TWEET_FILE = ".last_tweet_code"

def last_tweet
  @last_tweet ||= open(LAST_TWEET_FILE).read rescue 0
end

def url
  "http://twitter.com/direct_messages.json?since_id=#{last_tweet}"
end

def dm_from_twitter
  open(url, :http_basic_authentication => [TWITTER_USER, TWITTER_PASS]).read
end

def direct_messages
  @direct_messages ||= JSON.parse(dm_from_twitter)
end

def update_last_tweet(tweet_id)
  File.open(LAST_TWEET_FILE, "w") do |f|
    f.puts tweet_id
  end
end

def send_update(tweet)
  Net::HTTP.post_form(URI.parse("http://#{TWITTER_USER}:#{TWITTER_PASS}@twitter.com/statuses/update.json"),
    {'status' => tweet}
  )
end

def valid?(tweet)
  !tweet.match(/\b#{RETWEET_CODE}\b/).nil?
end

def strip(tweet)
  tweet.gsub(/\b#{RETWEET_CODE}\b\s*/, '')
end

direct_messages.reverse.each do |dm|
  next if dm["id"] == last_tweet
  tweet = "from @#{dm["sender_screen_name"]}: #{strip(dm["text"])}" if valid?(dm["text"])
  send_update(tweet)
end

update_last_tweet(direct_messages.first["id"]) if direct_messages.first
