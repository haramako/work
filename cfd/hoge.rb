# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'

solver = Cfd::Solver.new(32,32) do |s|
  #s.draw_rect 8, 6, 4, 4
  s.draw_circle 15.5, 15.5, 5

  s.snap_span = 5
  s.re = 0.02
  s.dt = 0.1
  s.output_gif 'test2.gif', :mark
end

solver.on_setting = lambda do |s|
  speed = 1.0
  angle = 10.0 *(Math::PI/180.0)
  s.u[1,true] = speed*Math.cos(angle)
  s.u[-1,true] = speed*Math.cos(angle)
  s.v[true,1] = -speed*Math.sin(angle)
  s.v[true,-1] = -speed*Math.sin(angle)

  #s.mark.mul! s.mask
  #s.mark.add!((1.0-s.mask)*2)
  # s.mark[[0,1,-1],true] = 0
  # s.mark[true,[0,-1]] = 0

  mark_orig = 1
  if (s.cur_time.to_i / 20) % 2 == 0
    s.mark[[0,1],true] = mark_orig
  else
    s.mark[[0,1],true] = 0
  end
  
  s.u[true,0] = s.u[true,1]
  s.u[true,-1] = s.u[true,-2]
  s.v[0,true] = s.v[1,true]
  s.v[-1,true] = s.v[-2,true]
  #s.v[true,1] = 0.2
  #s.v[true,-1] = 0.2
end

yr = []
solver.on_snap = lambda do |s|
  STDERR.print '.'
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
  yr << [total_x, total_y]
end

solver.solv(400)

puts
p yr.inject{|x,m|[x[0]+m[0], x[1]+m[1]]}.map{|x|x/yr.size}
  
