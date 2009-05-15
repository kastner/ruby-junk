#!/usr/bin/env ruby
%w|rubygems active_record irb|.each {|lib| require lib}
ActiveSupport::Inflector.inflections.singular("toyota", "toyota")
CAR_TYPES = %w|ford buick toyota|

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define do
  create_table :cars do |t|
    t.string :name
  end

  create_table :car_to_wheel_table_map, :id => false do |t|
    t.integer :car_id
    t.string :wheel_table
  end
  
  CAR_TYPES.each do |car_type|
    create_table "wheels_for_#{car_type.pluralize}" do |t|
      t.integer :car_id
      t.string :color
    end
  end
end

CAR_TYPES.each do |car_type|
  eval <<-END
    class #{car_type.classify}Wheel < ActiveRecord::Base
      set_table_name "wheels_for_#{car_type.pluralize}"
      belongs_to :car
    end
  END
end

class Car < ActiveRecord::Base
  has_one :car_wheel_map
  
  CAR_TYPES.each do |car_type|
    has_many "#{car_type}_wheels"
  end
  
  delegate :wheel_table, :to => :car_wheel_map
  
  def wheels
    send("#{wheel_table}_wheels")
  end
end

class CarWheelMap < ActiveRecord::Base
  set_table_name "car_to_wheel_table_map"
  belongs_to :car
end


rav4 = Car.create(:name => "Rav4")
rav4.create_car_wheel_map(:wheel_table => "toyota")
rav4.wheels.create(:color => "red")

fiesta = Car.create(:name => "Fiesta")
fiesta.create_car_wheel_map(:wheel_table => "ford")
fiesta.wheels.create(:color => "green")

IRB.start if __FILE__ == $0
