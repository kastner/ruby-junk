require 'rubygems'
require 'mysql'

my = Mysql.new("localhost", "root", "", "advancing")

my.query(<<SQL)
  CREATE TABLE IF NOT EXISTS instructors(name VARCHAR(255))
SQL

my.query(%Q{INSERT INTO instructors (name) VALUES ("David")})
my.query(%Q{INSERT INTO instructors (name) VALUES ("Erik")})

my.query("SELECT * FROM instructors").each_hash do |h|
  puts h.inspect
end
