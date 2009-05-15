$:.unshift '../prawn/lib'
require 'prawn'

Prawn::Document.generate("/tmp/bid.pdf") do
  # font "#{Prawn::BASEDIR}/data/fonts/Helvetica.ttf"
  image "/Users/kastner/Documents/metaatem-logo.png", :at => [0, 740], :height => 50
  
  bounding_box [400, 730], :width => 140 do
    text "Erik Kastner"
    text "kastner@metaatem.net"
    text "Meta | ateM"
    stroke do
      line bounds.top_left, bounds.top_right
      line bounds.bottom_left, bounds.bottom_right
    end
  end
end

`open /tmp/bid.pdf`