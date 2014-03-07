require 'narray'
require 'rmagick'

class NArray
  def each_with_index
    shape[1].times do |y|
      shape[0].times do |x|
        yield self[x,y], x, y
      end
    end
    self
  end
  def map_with_index!
    each_with_index { |v,x,y| self[x,y] = yield(v, x, y) }
  end
  def map_with_index( typecode, &block )
    r = NArray.new(typecode, self.shape[0], self.shape[1])
    self.each_with_index do |v,x,y|
      r[x,y] = yield v,x,y
    end
    r
  end
end

class Plot
  
  def initialize( filename_ )
    @filename = filename_
    @img_list  = Magick::ImageList.new
    begin
      yield self
    ensure
      @img_list.write @filename
    end
  end

  def norm(x,min=0.0,max=1.0)
    if x <= min then 0.0 elsif x >= max then 1.0 else (x-min)/(max-min) end
  end

  def plot( flags, data )
    w,h = data.shape
    img = @img_list.new_image(w,h)

    max_v = data.max
    min_v = data.min

    pixels = data.map_with_index(NArray::ROBJ) do |v,x,y|
      if flags[x,y] == 0
        Magick::Pixel.new(0,0,0)
      else
        # pow = norm(v, 0, 1)
        pow = norm(v, min_v, max_v)
        Magick::Pixel.from_hsla( (1-pow)*240, 100, 100 )
      end
    end
    
    img.store_pixels( 0, 0, w, h, pixels.to_a.flatten )
  end
end
