#!/usr/bin/env ruby
%w|rubygems active_record irb|.each {|lib| require lib}

class Number < ActiveRecord::Base
  belongs_to :group
end

class Group < ActiveRecord::Base
  has_many :numbers
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :numbers do |t|
    t.integer :number
    t.belongs_to :group
  end
  
  create_table :groups do |t|
    t.string :name
  end  
end

10.times do |i|
  start = i * 10 + 1
  group = Group.create(:name => "#{start} to #{start+9}")
  10.times do |i|
    group.numbers << Number.create(:number => i + start)
  end
end

IRB.start if __FILE__ == $0