#!/usr/bin/env ruby

%w|rubygems active_record irb|.each {|lib| require lib}

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :fruits, :force => true do |t|
    t.string :name
  end
end

class Fruit < ActiveRecord::Base
  validates_presence_of :name
end

Fruit.create(:name => "apple")

IRB.start if __FILE__ == $0