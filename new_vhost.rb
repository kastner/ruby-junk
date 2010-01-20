#!/usr/bin/env ruby

require 'rubygems'
require 'mustache'

VHOST_PREFIX = "/etc/apache2/sites-available/"

server = ARGV[0]

raise "usage #{$0} <host>" unless server
server = "#{server}.metaatem.net" unless server[/\./]

path   = ARGV[1] || "/var/www/#{server}"

vhost_file = VHOST_PREFIX + server
raise "#{server} is already defined" if File.exists?(vhost_file)

vhost_entry = Mustache.render(<<-VHOST, :server => server, :path => path)
<VirtualHost *>
	ServerName {{server}}
	DocumentRoot {{path}}/public
</VirtualHost>
VHOST

File.open(vhost_file, "w") do |f|
  f.puts vhost_entry
end


%x|sudo a2ensite #{server}|
%x|sudo apache2ctl graceful|
