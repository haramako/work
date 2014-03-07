# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'
require_relative 'cfd_plot'
# require 'wx'

XSIZE = 64
YSIZE = 16
u = NArray.float(XSIZE,YSIZE)
v = u.clone
u4v = u.clone # Y節上のu
v4u = u.clone # X節上のv
p = u.clone
mark = u.clone
flag = NArray.int(XSIZE,YSIZE).fill!(1)

flag[0,true] = 0
flag[-1,true] = 0
flag[true,0] = 0
flag[true,-1] = 0
flag[3,3] = NArray.float(4,4)

def setting( flag, u, v, mark )
  flag.each_with_index do |_,x,y|
    if flag[x,y] == 0
      u[x,y] = 0
      v[x,y] = 0
      u[x+1,y] = 0 if x < flag.shape[0]-1
      v[x,y+1] = 0 if y < flag.shape[1]-1
    end
  end
  speed = 1.0
  u[0,true] = speed
  u[1,true] = speed
  u[-1,true] = speed
  v[true,0] = 0
  v[true,1] = 0
  v[true,-1] = 0
  mark[0,true] = 1.0
  mark[1,true] = 1.0
end

Plot.new('test2.gif') do |plot|
  
  RE = 0.001
  dt = 0.1
  step = 4/dt
  total = (step*40).to_i
  total.times do |i|
    begin
      un = u.clone
      vn = v.clone
      markn = mark.clone
      
      setting( flag, u, v, mark )
      Cfd.solve_poisson( dt, p, u, v, flag, {max_iteration:1000, omega:1.9} )
      Cfd.rhs( dt, un, vn, p, u, v, flag )
      u, v = un.clone, vn.clone

      setting( flag, u, v, mark )
      Cfd.middle4( u4v, u, 1, -1)
      Cfd.middle4( v4u, v, -1, 1)
      
      Cfd.advect_roe( dt, un, u, u, v4u, {} )
      Cfd.advect_roe( dt, vn, v, u4v, v, {} )
      u, v = un.clone, vn.clone
      Cfd.viscosity( dt, RE, un, vn, u, v )
      # pp u
      # pp un

      Cfd.advect_roe( dt, markn, mark, un, vn, {} )

      if i % step == 0
        STDERR.print '.'
        #data << [flag, un]
        plot.plot flag, mark
        #data << [flag, un**2 + vn**2]
        #data << [flag, p.clone]
      end
      u, v, mark = un, vn, markn
    rescue
      pp u, v, p
      raise
    end
  end

end


