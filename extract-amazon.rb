#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'fileutils'

url = ARGV[0] || "http://www.amazon.com/gp/product/images/B000S5XYI2/ref=dp_otherviews_z_6_PT01?ie=UTF8&s=sporting-goods&img=PT01&color%5Fname=x"
user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2"

s = open(url, "User-Agent" => user_agent).read

(z_level, tile_size, image_str, width, height, version) = s.scan(/scaleLevels\[(\d)\] = new MediaServicesZoom[^\n]+\s(\d+)\);\s+DynAPI.addZoomViewer\("(.+?)",\d+,\d+,(\d+),(\d+),(\d+),/m)[0]

r = image_str.split("/")
vip = r[2]
(asin, dash_cust, variant) = r[-1].split(".")
(ou, cust) = dash_cust.split("-")

variant ||= "MAIN"
ext = ".jpg"
size = "RMTILE"

url = "http://%s/R/1/a=%s+d=%s+o=%s+s=%s+va=%s+ve=%s+e=%s"

tiles_x = (width.to_i/tile_size.to_f).ceil
tiles_y = (height.to_i/tile_size.to_f).ceil

tmp_path = "/tmp/imgs-del"
output = "big.jpg"

begin
  FileUtils.mkdir(tmp_path)
rescue Errno::EEXIST
end

tiles_x.times do |x|
  tiles_y.times do |y|
    zoom = "_SCR(#{z_level},#{x},#{y})_"
    image = url % [vip, asin, zoom, ou, size, variant, version, ext]
    %x|curl "#{image}" -o #{tmp_path}/#{y}x#{x}.jpg|
  end
end
# 
%x|montage #{tmp_path}/*.jpg -tile #{tiles_x}x#{tiles_y} -geometry -0-0 #{output}|
FileUtils.rmdir(tmp_path)
%x|open #{output}|
