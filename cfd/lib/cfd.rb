# -*- coding: utf-8 -*-
require 'cfd/version'
require 'narray'
require 'cfd/narray_ext'
require 'cfd/cfd'
require 'rmagick'

module Cfd
  
  class Solver
    attr_reader :width, :height
    attr_reader :u, :v, :p, :mask, :mask_u, :mask_v, :mark
    attr_reader :cur_time
    attr_accessor :on_snap, :on_step, :on_setting
    attr_accessor :dt, :re, :snap_span
    
    def initialize(width_, height_)
      @dt = 0.1
      @re = 0.001
      @snap_span = 4.0
        
      @width = width_
      @height = height_
      @u = NArray.float(width_, height_)
      @v = @u.clone
      @u4v = @u.clone # Y節上のu
      @v4u = @u.clone # X節上のv
      @p = @u.clone
      @mark = @u.clone
      @mask = NArray.int(width_, height_).fill!(1)
      @mask[[0,-1],true] = 0
      @mask[true,[0,-1]] = 0
      @mask_u = nil
      @mask_v = nil
      @cur_time = 0
      @time_from_last_snap = 0
      @plot = nil
      @on_snap = nil
      @on_step = nil
      @on_setting = nil
      
      yield self
      
      @un = @u.clone
      @vn = @v.clone
      @markn = @mark.clone

      update_mask
    end

    def draw_rect(x,y,w,h)
      @mask[x,y] = NArray.float(w,h)
    end

    def draw_circle(cx,cy,r)
      @mask.map_with_index! do |v,x,y|
        if Math.sqrt( (cx.to_f-x)**2 + (cy.to_f-y)**2 ) < r
          0
        else
          v
        end
      end
    end
    
    def output_gif(filename, attr = :mark)
      @plot = Plot.new(filename)
      @plot_attr = attr
    end

    def update_mask
      @mask_u = @mask.map_with_index{|_,x,y| @mask[x,y] * @mask[x-1,y] }
      @mask_v = @mask.map_with_index{|_,x,y| @mask[x,y] * @mask[x,y-1] }
    end

    def setting
      @u.mul! @mask_u
      @v.mul! @mask_v
      @on_setting.call self if @on_setting
    end
    
    def solv( total )
      begin
        0.step(total,dt) do |i|
          step
          
          @time_from_last_snap += dt
          if @time_from_last_snap >= @snap_span
            @on_snap.call self if @on_snap
            @time_from_last_snap -= @snap_span
            if @plot
              @plot.plot @mask, self.__send__(@plot_attr)
            end
          end
        end
      rescue
        puts "error at time #{@cur_time}"
        pp @u, @v, @p
        raise
      ensure
        @plot.close if @plot
      end
    end

    def step
      setting

      Cfd.solve_poisson( @dt, @p, @u, @v, @mask, {max_iteration:100000, omega:1.9, permissible:0.001} )
      Cfd.rhs( @dt, @un, @vn, @p, @u, @v, @mask )
      @u, @v, @un, @vn = @un, @vn, @u, @v

      setting
      
      Cfd.middle4( @u4v, @u, 1, -1)
      Cfd.middle4( @v4u, @v, -1, 1)
      
      Cfd.advect_roe( @dt, @un, @u, @u, @v4u, {} )
      Cfd.advect_roe( @dt, @vn, @v, @u4v, @v, {} )
      @u, @v, @un, @vn = @un, @vn, @u, @v
      
      Cfd.viscosity( @dt, @re, @un, @vn, @u, @v )
      @u, @v, @un, @vn = @un, @vn, @u, @v

      Cfd.advect_roe( @dt, @markn, @mark, @u, @v, {} )
      @mark, @markn = @markn, @mark

      @on_step.call self if @on_step
      
      @cur_time += dt

    end
  end
  
  class Plot
    
    def initialize( filename_ )
      @filename = filename_
      @img_list  = Magick::ImageList.new
    end

    def norm(x,min=0.0,max=1.0)
      if x <= min then 0.0 elsif x >= max then 1.0 else (x-min)/(max-min) end
    end

    def plot( flags, data )
      w,h = data.shape
      img = @img_list.new_image(w,h)

      max_v = [data.max, 1].max
      min_v = [data.min, 0].min

      pixels = data.map_with_index(NArray::ROBJ) do |v,x,y|
        if flags[x,y] == 0
          Magick::Pixel.new(0,0,0)
        else
          pow = norm(v, 0, 1)
          # pow = norm(v, min_v, max_v)
          Magick::Pixel.from_hsla( (1-pow)*240, 100, 100 )
        end
      end
      
      img.store_pixels( 0, 0, w, h, pixels.to_a.flatten )
    end

    def start
      yield self
    ensure
      close
    end

    def close
      @img_list.write @filename if @img_list.length > 0
    end
    
    def self.create(filename)
      plot = Plot.new(filename)
      plot.start{ yield plot }
    end
  end
end
