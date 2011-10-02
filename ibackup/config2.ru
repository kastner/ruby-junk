require "rubygems"
require "bundler/setup"

require "rack_dav"

run RackDAV::Handler.new(:root => "/tmp")
