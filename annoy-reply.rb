#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'json'
require 'net/http'

TWITTER_USER = ""
TWITTER_PASS = ""

LAST_TWEET_FILE = ".last_tweet"

def last_tweet
  @last_tweet ||= open(LAST_TWEET_FILE).read rescue 0
end

def url
  "http://search.twitter.com/search.json?q=%s&since_id=#{last_tweet}"
end

def tweets_for_word(word)
  json = JSON.parse(open(url % word).read) 
  json["results"]
end

def send_update(tweet)
  Net::HTTP.post_form(URI.parse("http://#{TWITTER_USER}:#{TWITTER_PASS}@twitter.com/statuses/update.json"),
    {'status' => tweet}
  )
end

def update_last_tweet(tweet_id)
  File.open(LAST_TWEET_FILE, "w") do |f|
    f.puts tweet_id
  end
end

co_working_tweets = tweets_for_word("co-working")
co_working_tweets.reverse.each do |tweet|
  next if tweet["id"] == last_tweet
  my_tweet = "@#{tweet["from_user"]} it's coworking"
  puts "Sending #{my_tweet}"
  # send_update(tweet)
end

# update_last_tweet(co_working_tweets.first["id"]) if co_working_tweets.first
