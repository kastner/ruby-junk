#!/usr/bin/env ruby
#####################################################################################
# Extract images from Saks
# 
# Usage: extract-saks.rb <product-id>
#
# Requires:
#   nokogiri gem
#   swftools
#   imagemagick (command line)
#
# Installing imagemagick (for the montage tool):
# brew install imagemagick
#
# Installing swftools (for the swfextract tool):
# brew install swftools
#####################################################################################

prod = ARGV[0] || "845524446172650"

require 'rubygems'
require 'open-uri'
require 'nokogiri'

def split_up(num)
  num.scan(/(..)(...)(....)/).join("/") + "/#{num}/#{num}R_Z/"
end

url = "http://www.saksfifthavenue.com/main/ProductDetail.jsp?PRODUCT%3C%3Eprd_id="

prod_image_id = open(url + prod).read[/<link rel="image_src".+?\/(\d{5,})\//, 1] 

raise "Couldn't find product image id" unless prod_image_id

image_base = "http://images.saksfifthavenue.com/images/products/"
image_base << split_up(prod_image_id)

zoom = Nokogiri.parse(open(image_base + "/zoom.info").read)
width = zoom.at("info")["ImageWidth"].to_i
height = zoom.at("info")["ImageHeight"].to_i
tile_size = zoom.at("info")["TileSize"].to_f

tiles_x = (width/tile_size).ceil
tiles_y = (height/tile_size).ceil

# raise "across: #{tiles_x}, down: #{tiles_y} - size #{tile_size} width: #{width}"

tmp_path = "/tmp/imgs_for_#{prod}"
output = "#{prod}-big.jpg"

FileUtils.mkdir(tmp_path)

tiles_x.times do |x|
  tiles_y.times do |y|
    px = "%02d" % x
    py = "%02d" % y
    new_swf = "#{tmp_path}/#{py}-#{px}.swf"
    %x|curl #{image_base}Tile_00_#{px}_#{py}.swf -o #{new_swf}|
    %x|swfextract #{new_swf} -j 1 -o #{new_swf}.jpg|
  end
end

%x|montage #{tmp_path}/*.jpg -tile #{tiles_x}x#{tiles_y} -geometry -2-2 #{output}|
%x|open #{output}|
