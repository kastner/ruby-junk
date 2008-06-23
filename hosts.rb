#!/usr/bin/env ruby

hosts = []
hosts << open("#{ENV["HOME"]}/.ssh/config").read.scan(/host\s(.+?)\n/i).uniq

hosts << open("#{ENV["HOME"]}/.ssh/known_hosts").read.scan(/^(.*) ssh/).map do |h| 
  host = h[0].gsub(/,.*/,'')
  host = "'#{$1} -p #{$2}'" if host.match(/\[(.*)\]:(.*)/)
  host
end

puts hosts.join(" ")