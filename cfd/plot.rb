require 'json'
require 'rmagick'
require 'pp'

json = JSON.parse( File.read( 'test1.json' ), symbolize_names: true )


img_list  = Magick::ImageList.new

def norm(x)
  if x < 0 then 0 elsif x > 1 then 1.0 else x end
end

json.each do |data|
  STDERR.print '.'
  h = data[:vx].size
  w = data[:vx][0].size
  img = img_list.new_image(w,h)

  vx = data[:vx]
  vy = data[:vy]
  p = data[:p]
  marker = data[:marker]
  flag = data[:flag]

  type = :marker
  pixels = (0...h).map do |y|
    (0...w).map do |x|
      next Magick::Pixel.new( 0, 0, 0, 0 ) if flag[x+y*w] == 0

      case type
      when :spin
        r = g = b = 0
        spin = vy[y][x-1] + vx[y][x] - vy[y][x] - vx[y-1][x]
        if spin > 0
          r = norm(spin)
        else
          g = norm(-spin)
        end
        Magick::Pixel.new( r*63336, g*63336, b*65536, 0 )
      when :speed
        speed = Math.sqrt(((vx[y][x]+vx[y][x+1])/2.0) ** 2 + ((vy[y][x]+vy[y+1][x])/2.0) ** 2)
        pow = norm((speed-1.0)*10)
        Magick::Pixel.from_hsla( (1-pow)*240, 100, 100 )
      when :marker
        pow = norm(marker[y][x]*1.8-0.4)
        Magick::Pixel.from_hsla( (1-pow)*240, 100, 100 )
      when :p
        pow = norm(0.5 + p[y][x] * 0.3 )
        Magick::Pixel.from_hsla( (1-pow)*240, 100, 100 )
      end
    end
  end
  
  img.store_pixels( 0, 0, w, h, pixels.flatten )
end

img_list.write 'test1.gif'

