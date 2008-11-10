#!/usr/bin/env ruby

%w|rubygems active_record irb|.each {|lib| require lib}

class Building < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
end

class Person < ActiveRecord::Base
  has_many :buildings, :as => :owner
end

class Company < ActiveRecord::Base
  has_many :buildings, :as => :owner
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :buildings do |t|
    t.string :address
    t.references :owner, :polymorphic => true
  end
  
  create_table :people do |t|
    t.string :name
    t.integer :age
  end
  
  create_table :companies do |t|
    t.string :name
    t.string :tax_id
  end
end

apple = Company.create(:name => "Apple", :tax_id => "123-abc")
steve = Person.create(:name => "Steve Jobs", :age => 100)

b1 = Building.create(:address => "1 Infinate Loop")
b2 = Building.create(:address => "123 Fake st.")

b1.owner = apple
b1.save

b2.owner = steve
b2.save

IRB.start if __FILE__ == $0