#!/usr/bin/env ruby
%w|rubygems active_record irb|.each {|lib| require lib}

class Fruit < ActiveRecord::Base
  validates_uniqueness_of :name
  
  belongs_to :stand
  
  named_scope :red_fruits, :conditions => "color = 'red'"
  
  named_scope :recent, lambda { { :conditions => ['created_at > ?', 10.seconds.ago] }}
  
  def self.by_color(color)
    with_scope :conditions => {:color => color} do
      find(:all)
    end
  end
  
  def self.red
    find(:all, :conditions => "color = 'red'")
  end
end

class Stand < ActiveRecord::Base
  has_many :fruits do
    def newest(color = nil)
      if color
        find(:all, :conditions => ["created_at > ? AND color = ?", 10.seconds.ago, color])
      else
        find(:all, :conditions => ["created_at > ?", 10.seconds.ago])
      end
    end
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :stands do |t|
    t.string :name
    t.string :address
  end
  
  create_table :fruits do |t|
    t.string :name
    t.string :color
    t.belongs_to :stand
    t.timestamps
  end  
end

stand = Stand.create(:name => "Joe's Fruit Market", :address => "Around the corner")
Fruit.create(:stand => stand, :name => "apple", :color => "red")
Fruit.create(:stand => stand, :name => "pear", :color => "brown")
Fruit.create(:stand => stand, :name => "red grape", :color => "red")
Fruit.create(:stand => stand, :name => "orange", :color => "orange")

IRB.start if __FILE__ == $0