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
  speed = 1.0
  s.u[[0,1,-1],true] = speed*Math.cos(angle)
  s.v[true,[0,1,-1]] = -speed*Math.sin(angle)
  s.u[true,0] = s.u[true,1]
  s.u[true,-1] = s.u[true,-2]
  s.v[0,true] = s.v[1,true]
  s.v[-1,true] = s.v[-2,true]
  s.mark[[0,1],true] = if (s.cur_time/10.0).to_i % 2 == 0 then 1 else 0 end
end

def norm(x,min=0.0,max=1.0)
  if x <= min then 0.0 elsif x >= max then 1.0 else (x-min)/(max-min) end
end

def color_bar(n)
  base = [[0.0, 0,0,0],
          [0.1, 64,0,192],
          [0.2, 0,0,255],
          [0.4, 0,255,255],
          [0.6, 0,255,0],
          [0.85, 255,255,0],
          [0.95, 255,0,0],
          [1.01, 255,255,255]]
  
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

