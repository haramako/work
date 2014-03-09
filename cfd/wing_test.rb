# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'

def test( re, speed, angle )
  solver = Cfd::Solver.new(64,32) do |s|

    s.mask.map_with_index! do |v,x,y|
      x2 = (x - 18)/1.4
      y2 = (y - s.height/2)
      y2 = y2 / (x-28.5) * 30
      next v if y >= s.height/2
      next 0 if Math.sqrt(x2**2+y2**2) < 8.2
      v
    end
    
    s.snap_span = 10
    s.re = re
    s.dt = 0.1
    # s.output_gif 'a.gif'
  end

  solver.on_setting = lambda do |s|
    s.u[[1,-1],true] = speed*Math.cos(angle *(Math::PI/180.0))
    s.v[true,[1,-1]] = -speed*Math.sin(angle *(Math::PI/180.0))

    # 左境界でマーカーをブリンクさせる
    s.mark[[0,1],true] = if (s.cur_time.to_i / 20) % 2 == 0 then 1 else 0 end
    
    s.u[true,0] = s.u[true,1]
    s.u[true,-1] = s.u[true,-2]
    s.v[0,true] = s.v[1,true]
    s.v[-1,true] = s.v[-2,true]
  end

  result = []
  solver.on_snap = lambda do |s|
    # STDERR.print '.'
    mask = solver.mask
    total_x = 0.0
    total_y = 0.0
    solver.p.each_with_index do |v,x,y|
      next if x<=1 or y<=1 or x>=solver.width-2 or y>=solver.height-2
      if mask[x-1,y] == 0 and mask[x,y] != 0
        total_x -= v
      end
      if x < solver.width-1 and mask[x+1,y] == 0 and mask[x,y] != 0
        total_x += v
      end
      
      if mask[x,y-1] == 0 and mask[x,y] != 0
        total_y -= v
      end
      if y < solver.height-1 and mask[x,y+1] == 0 and mask[x,y] != 0
        total_y += v
      end
    end
    # puts "x=%.3f y=%.3f"%[total_x, total_y]
    if s.cur_time > 200
      vup = NVector[ Math.cos((angle+90)*Math::PI/180.0), Math.sin((angle+90)*Math::PI/180.0) ]
      vfoward = NVector[ Math.cos((angle+0)*Math::PI/180.0), Math.sin((angle+0)*Math::PI/180.0) ]
      vec = NVector[total_x, -total_y]
      result << [vec*vfoward, vec*vup, Math.sqrt(vec**2)]
    end
  end
  
  solver.solv(400)
  result = NArray[*result]
  [ result[0,true].mean, result[1,true].mean, result[2,true].stddev]
end

re_list = [0.02, 0.001,0.01]#, 0.005, 0.008, 0.010]
speed_list = [1.0] # [0.3, 0.5, 0.8, 1.0, 2.0, 3.0]
angle_list = (0..20) # [5, 10, 20, 30]

re_list.each do |re|
  speed_list.each do |speed|
    angle_list.each do |angle|
      print "testing re=#{re} speed=#{speed} angle=#{angle} ... "
      r = test( re, speed, angle )
      puts "back=%6.3f up=%0.3f flatter=%0.3f"%r.to_a
    end
  end
  puts
end
