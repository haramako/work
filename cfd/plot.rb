require 'json'
require 'rmagick'
require 'pp'

json = JSON.parse( File.read( 'test1.json' ), symbolize_names: true )


img_list  = Magick::ImageList.new

def norm(x)
  [[x * 65536, 65535].min, 0].max
end

json.each do |data|
  STDERR.print '.'
  h = data[:vx].size
  w = data[:vx][0].size
  img = img_list.new_image(w,h)

  vx = data[:vx]
  vy = data[:vy]
  p = data[:p]
  flag = data[:flag]

  pixels = (0...h).map do |y|
    (0...w).map do |x|
      r = g = b = 0
      spin = vy[y][x-1] + vx[y][x] - vy[y][x] - vx[y-1][x]
      if spin > 0
        r = norm(spin)
      else
        g = norm(-spin)
      end


      # if flag[x+y*w] == 1
      #   speed = Math.sqrt(((vx[y][x]+vx[y][x+1])/2.0) ** 2 + ((vy[y][x]+vy[y+1][x])/2.0) ** 2)
      #   r = g = norm(speed/2)
      # end
      
      # r = g = norm(0.5 + p[y][x] * 0.3 )
      
      r = g = b = 65535 if flag[x+y*w] == 0
      Magick::Pixel.new( r, g, b, 0 )
    end
  end
  
  img.store_pixels( 0, 0, w, h, pixels.flatten )
end

img_list.write 'test1.gif'

