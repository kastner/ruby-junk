#!/usr/bin/env ruby

module Tabber
  extend self
  
  def tab_out(string)
    lines = string.split("\n").map do |line|
      whitespace = string[/^(\s*)/, 1]
      first, rest = line.lstrip.split(/\s+/, 2)
      [whitespace + first, rest.split(/,\s*/)].flatten
    end
    sizes = []
    lines.each do |line|
      line.each_with_index do |field, i|
        sizes[i] ||= 0
        sizes[i] = field.size if sizes[i] < field.size
      end
    end

    lines.each_with_index do |line, i|
      line.each_with_index do |field, j|
        total_length = sizes[j] + 1
        spaces = " " * (total_length - field.size)
        add = ((j == 0) ? "" : ",") + spaces
        lines[i][j] = field + add unless (j == (lines[i].size - 1))
      end
    end
  
    lines.map {|line| line.join}.join("\n")
  end
end

require 'rubygems'
require 'test/spec'

describe 'Tabber' do
  setup do
    @string = <<-EOF
      map.thing '/thing', :controller => 'feet', :method => "default"
      map.thing_two          '/thing_two', :controller => 'f'
      map.thing_three '/thing_three', :controller => 'f', :method => "three"
    EOF
    @result = <<-EOF
      map.thing       '/thing',       :controller => 'feet', :method => "default"
      map.thing_two   '/thing_two',   :controller => 'f'
      map.thing_three '/thing_three', :controller => 'f',    :method => "three"
    EOF
  end
  
  it "should generate the output from the input" do
    Tabber.tab_out(@string).should == @result.rstrip
  end
end