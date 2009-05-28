require 'rubygems'
require 'open-uri'
require 'json'

base = "http://search.twitter.com/search.json?q=%s&rpp=100&page=%s"
mentions = Hash.new(0)

15.times do |page|
p = JSON.parse(open(base % ["etsy", page+1]).read)
  p["results"].each do |tweet|
    t = Time.parse(tweet["created_at"])
    hours_ago = ((Time.now - t) / 60 / 60).to_i
    mentions[hours_ago] += 1
  end
end

results = mentions.sort.reverse
%x{open "http://chart.apis.google.com/chart?cht=lc&chs=300x125&chd=t:#{results.collect{|a| a[1]}.join(",")}"}