#!/usr/bin/env ruby
%w|rubygems active_record irb|.each {|lib| require lib}
ActiveSupport::Inflector.inflections.singular("toyota", "toyota")

class Car < ActiveRecord::Base
end

class CarWheelMap < ActiveRecord::Base
end

%w|ford buick toyota|.each do |car_type|
  eval <<-CLASS
    class #{car_type.classify}Wheels < ActiveRecord::Base
      set_table_name "wheels_for_#{car_type.pluralize}"
  CLASS
end

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
  
  %w|ford buick toyta|.each do |car_type|
    create_table "wheels_for_#{car_type.pluralize}" do
      t.integer :car_id
      t.string :color
    end
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