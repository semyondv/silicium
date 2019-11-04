require 'chunky_png'

# Creating an image from scratch, save as an interlaced PNG
png = ChunkyPNG::Image.new(1280, 720, ChunkyPNG::Color::TRANSPARENT)

(0..100).each do |i|
  png[i,i] = ChunkyPNG::Color.rgb(0,0,0)
end
png.save('filename.png', :interlace => true)
