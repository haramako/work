require 'narray'

def rot_matrix(rad)
  NMatrix[ [Math.cos(rad), -Math.sin(rad)], [Math.sin(rad), Math.cos(rad)] ]
end

def calc_force(sol)
  total_x = 0
  total_y = 0
  mask = sol.mask
  sol.p.each_with_index do |v,x,y|
    next if x<=1 or y<=1 or x>=sol.width-2 or y>=sol.height-2
    if mask[x-1,y] == 0 and mask[x,y] != 0
      total_x -= v
    end
    if x < sol.width-1 and mask[x+1,y] == 0 and mask[x,y] != 0
      total_x += v
    end
    
    if mask[x,y-1] == 0 and mask[x,y] != 0
      total_y -= v
    end
    if y < sol.height-1 and mask[x,y+1] == 0 and mask[x,y] != 0
      total_y += v
    end
  end
  NVector[total_x, -total_y]
end

def wing1( s, cx, cy, scale = 1.0)
  s.mask.map_with_index! do |v,x,y|
    x = (x - cx)/scale
    y = (y - cy)/scale
    x2 = x / 1.4
    y2 = y / (x-22.5) * 80
    next v if y > 0
    next 0 if Math.sqrt(x2**2+y2**2) < 8.2
    v
  end
end

def bound0( s, speed, angle )
  s.u[[0,1,-1],true] = speed*Math.cos(angle)
  s.v[true,[0,1,-1]] = -speed*Math.sin(angle)
  s.u[true,0] = s.u[true,1]
  s.u[true,-1] = s.u[true,-2]
  s.v[0,true] = s.v[1,true]
  s.v[-1,true] = s.v[-2,true]
  s.mark[0,true] = if (s.cur_time/(s.snap_span*3)).to_i % 2 == 0 then 1 else 0 end
end

def norm(x,min=0.0,max=1.0)
  if x <= min then 0.0 elsif x >= max then 1.0 else (x-min)/(max-min) end
end

def color_bar(n)
  base = [[0.0, 0,0,255],
          [0.2, 0,255,255],
          [0.5, 0,255,0],
          [0.8, 255,255,0],
          [1.0001, 255,0,0]]
  
  n = [[n,0].max,1].min.to_f
  
  base.each.with_index do |c1,i|
    if c1[0] > n
      c0 = base[i-1]
      a = 1-(c1[0]-n)/(c1[0]-c0[0])
      return [c0[1]*(1-a)+c1[1]*a, c0[2]*(1-a)+c1[2]*a, c0[3]*(1-a)+c1[3]*a]
    end
  end
  raise
end

def j2(a,x,y)
  v1 = x + ((a**2)*x) / (x**2+y**2)
  v2 = y - ((a**2)*y) / (x**2+y**2)
  [v1,v2]
end

def wing_j(s,x,y,w,h,p1=0.08,p2=0.15)
  0.2.step(Math::PI*2-0.2,0.01) do |r|
    z = j2(1.0+p1, Math.cos(r) + p1, Math.sin(r) + p2)
    s.mask[x+z[0]*w, y-z[1]*h] = 0
  end
end
