#!/usr/bin/env ruby
require 'socket'
require 'time'

class Graphite
  PORT=2003
  SERVER="localhost"

  def self.write_to_graphite(key, value, timestamp = nil)
    timestamp = Time.now.to_i unless timestamp
    connection.puts("#{key} #{value} #{timestamp}")
  end

  def self.connection
    @connection ||= TCPSocket.new(SERVER, PORT)
  end
end

open('/tmp/timings.csv').each_line do |line|
  (timestamp, env, stack, time) = line.split("|")
  next if env.nil?
  epoch_seconds = Time.parse(timestamp + " UTC").to_i
  Graphite.write_to_graphite("deploy.#{env}", time.to_f, epoch_seconds)
end

# Good resolution is important:
# [deploy]
# priority = 100
# pattern = ^deploy.*
# retentions = 60:1440000,900:350400
