#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
#
#

require 'narray'
require 'gnuplot'
require 'pp'

class World
  attr_reader :width, :height
  attr_reader :vx, :vy, :p
  
  def initialize(x, y)
    @width = x
    @height = y
    @vx = NArray.float(x,y)
    @vy = NArray.float(x,y)
    @p = NArray.float(x,y)
    @s = NArray.float(x,y)
    @wall = NArray.int(x,y)
    @wall[3,3] = NArray.int(2,4).fill!(1)
    @wall[true,0] = 1
    @wall[true,-1] = 1
    @wall[0,true] = 1
    @wall[-1,true] = 1
    
    @re = 0.02
    @dt = 0.1
  end

  def step
    iryu_nensei_kou
    gairyoku_kou
    yuushutsu_kou
    sor
  end

  def walk(with_wall = false)
    @width.times do |x|
      @height.times do |y|
        yield x, y if with_wall or @wall[x,y] == 0
      end
    end
  end

  def iryu_nensei_kou
    next_vx = @vx.clone
    next_vy = @vy.clone
    
    walk do |x,y|
      # x移流
      u = @vx[x,y]
      v = (@vy[x-1,y] + @vy[x,y] + @vy[x-1,y+1] + @vy[x,y+1] ) / 4
      if v >= 0
        if u >= 0
          next_vx[x,y] = @vx[x,y] - u * (@vx[x  ,y] - @vx[x-1,y]) * @dt - v * (@vx[x,y] - @vx[x,y-1]) * @dt
        else
          next_vx[x,y] = @vx[x,y] - u * (@vx[x+1,y] - @vx[x  ,y]) * @dt - v * (@vx[x,y] - @vx[x,y-1]) * @dt
        end
      else
        if u >= 0
          next_vx[x,y] = @vx[x,y] - u * (@vx[x  ,y] - @vx[x-1,y]) * @dt - v * (@vx[x,y+1] - @vx[x,y]) * @dt
        else
          next_vx[x,y] = @vx[x,y] - u * (@vx[x+1,y] - @vx[x  ,y]) * @dt - v * (@vx[x,y+1] - @vx[x,y]) * @dt
        end
      end
      
      # y移流
      u = @vy[x,y]
      v = (@vx[x,y-1] + @vx[x,y] + @vx[x+1,y-1] + @vx[x+1,y] ) / 4
      if v >= 0
        if u >= 0
          next_vy[x,y] = @vy[x,y] - u * (@vy[x,y  ] - @vy[x,y-1]) * @dt - v * (@vy[x,y] - @vy[x-1,y]) * @dt
        else
          next_vy[x,y] = @vy[x,y] - u * (@vy[x,y+1] - @vy[x,y  ]) * @dt - v * (@vy[x,y] - @vy[x-1,y]) * @dt
        end
      else
        if u >= 0
          next_vy[x,y] = @vy[x,y] - u * (@vy[x,y  ] - @vy[x,y-1]) * @dt - v * (@vy[x+1,y] - @vy[x,y]) * @dt
        else
          next_vy[x,y] = @vy[x,y] - u * (@vy[x,y+1] - @vy[x,y  ]) * @dt - v * (@vy[x+1,y] - @vy[x,y]) * @dt
        end
      end
    end
      
    # 粘性項
    walk do |x,y|
      next_vx[x,y] += @re * (@vx[x+1,y] + @vx[x,y+1] + @vx[x-1,y] + @vx[x,y-1]) * @dt
      next_vy[x,y] += @re * (@vy[x+1,y] + @vy[x,y+1] + @vy[x-1,y] + @vy[x,y-1]) * @dt
    end
    @vx = next_vx.clone
    @vy = next_vy.clone
  end

  def gairyoku_kou
    walk(true) do |x,y|
      if @wall[x,y] != 0
        @vx[x,y] = 0
        @vx[x+1,y] = 0 if x < @width-1
        @vy[x,y] = 0
        @vy[x,y+1] = 0 if y < @height-1
      end
    end
    
    @vx[1,true] = 1.0
    @vx[@width-1,true] = 1.0
  end

  def yuushutsu_kou
    walk do |x,y|
      @s[x,y] = (-@vx[x,y] - @vy[x,y] + @vx[x+1,y] + @vy[x,y+1]) / @dt
    end
  end

  def get_p( x, y, vx, vy )
    if vx != 0
      if @wall[x+vx,y] != 0 then @p[x,y] else @p[x+vx,y] end
    elsif vy != 0
      if @wall[x,y+vy] != 0 then @p[x,y] else @p[x,y+vy] end
    else
      raise
    end
  end

  def sor
    omega = 1.9
    i = 0
    loop do
      prev_p = @p.clone
      walk do |x,y|
        # @p[x,y] += omega * (-4*@p[x,y] + get_p(x,y,-1,0) + get_p(x,y,1,0) + get_p(x,y,0,-1) + get_p(x,y,0,1) - @s[x,y] )
        @p[x,y] += omega * (-4*@p[x,y] + get_p(x,y,-1,0) + get_p(x,y,1,0) + get_p(x,y,0,-1) + get_p(x,y,0,1) - @s[x,y])/4.0
      end
      break if ( prev_p - @p ).abs.max < 0.01
      i += 1
      raise if i > 200
    end

    pp @p

    # 圧力項(修正項)
    walk do |x,y|
      @vx[x,y] -= ( @p[x,y] - get_p(x,y,-1,0) ) * @dt
      @vy[x,y] -= ( @p[x,y] - get_p(x,y,0,-1) ) * @dt
    end
  end
  
end

w = World.new(16,16)

10.times do |i|
  w.step
end

Gnuplot.open do |gnuplot|
  
  Gnuplot::SPlot.new( gnuplot ) do |plot|
    plot.terminal 'png'
    plot.output 'hoge.png'
    plot.xlabel 'x'
    plot.ylabel 'y'
    plot.title 'CFD'

    plot.yrange "[#{w.height}:0]"
    plot.pm3d 'map'

    d = w.vx
    # d = (w.vy.abs+w.vx.abs)
    plot.data << Gnuplot::DataSet.new( d.transpose(1,0).to_a ) do |ds|
      ds.matrix = true
      ds.notitle
    end
  end
end


