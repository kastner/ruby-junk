#!/usr/bin/env ruby
%w|rubygems active_record irb|.each {|lib| require lib}

class Restaurant < ActiveRecord::Base
end

class Item < ActiveRecord::Base
  has_many :toppings
  belongs_to :restaurant
  
  def final_price
    price + toppings.inject(0) {|a, t| a += t.additional_price}
  end
end

class Topping < ActiveRecord::Base
  belongs_to :item
  belongs_to :sub_item, :class_name => "Item"
end

class LineItem < ActiveRecord::Base
  has_one :item
  has_many :additions
  has_many :toppings, :through => :additions
  
  def price
    item.price + toppings.inject(0) {|a, t| a += t.additional_price}
  end
end

class Addition < ActiveRecord::Base
  belongs_to :topping
  belongs_to :line_item
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :restaurants do |t|
    t.string :name
    t.string :phone
    t.string :address
  end
  
  create_table :items do |t|
    t.string :name
    t.integer :price
  end
  
  create_table :toppings do |t|
    t.integer :item_id
    t.integer :sub_item_id
    t.integer :additional_price
  end
end

zorba = Restaurant.create(:name => "Zorba's!", :phone => "1234")
small_pizza = Item.create(:name => "small pizza", :price => 9, :restaurant => zorba)
green_pepper = Item.create(:name => "green peppers", :price => 1)
pineapple = Item.create(:name => "pineapple", :price => 1)

peppers_on_pizza = Topping.create({
  :item => small_pizza, :sub_item => green_pepper, :additional_price => 2
})

pineapple_on_pizza = Topping.create({
  :item => small_pizza, :sub_item => pineapple, :additional_price => 10
})


raise small_pizza.final_price.to_s
