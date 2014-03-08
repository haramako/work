# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'
ENV['RUBYSDLFFI_PATH'] = '/opt/boxen/homebrew/lib'
require 'rubygame'

WING0 = ['1111111111111111111111',
         '1000000000011111111111',
         '1110000000000000001111',
         '1111111111111111000001',
         '1111111111111111111100']

def init_solver

  $solver = Cfd::Solver.new(64,32) do |s|
    #s.draw_rect 8, 6, 4, 4
    s.draw_circle 15.5, 15.5, 5

    w = WING0
    #s.mask[8,s.height/2] = w.map do |a| p a.chars.map(&:to_i) end

    s.snap_span = 2
    s.re = 0.001
    s.dt = 0.05
  end

  $solver.on_setting = lambda do |s|
    speed = 1.0
    angle = 0.0 *(Math::PI/180.0)
    s.u[[1,-1],true] = speed*Math.cos(angle)
    s.v[true,[1,-1]] = -speed*Math.sin(angle)

    #s.mark.mul! s.mask
    #s.mark.add!((1.0-s.mask)*2)
    # s.mark[[0,1,-1],true] = 0
    # s.mark[true,[0,-1]] = 0

    s.mark[[0,1],true] = if (s.cur_time.to_i / 20) % 2 == 0 then 1 else 0 end
    
    s.u[true,0] = s.u[true,1]
    s.u[true,-1] = s.u[true,-2]
    s.v[0,true] = s.v[1,true]
    s.v[-1,true] = s.v[-2,true]
  end

  yr = []
  $solver.on_snap = lambda do |s|
    STDERR.print '.'
    mask = $solver.mask
    total_x = 0.0
    total_y = 0.0
    $solver.p.each_with_index do |v,x,y|
      next if x<=1 or y<=1 or x>=$solver.width-2 or y>=$solver.height-2
      if mask[x-1,y] == 0 and mask[x,y] != 0
        total_x -= v
      end
      if x < $solver.width-1 and mask[x+1,y] == 0 and mask[x,y] != 0
        total_x += v
      end
      
      if mask[x,y-1] == 0 and mask[x,y] != 0
        total_y -= v
      end
      if y < $solver.height-1 and mask[x,y+1] == 0 and mask[x,y] != 0
        total_y += v
      end
    end
    # puts "x=%.3f y=%.3f"%[total_x, total_y]
    yr << [total_x, total_y]
  end
end

#=====================================================================================

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
  p n
  raise
end

def update
  surface = Rubygame::Screen.get_surface
  zw = $screen.width.to_f / $solver.width
  zh = $screen.height.to_f / $solver.height
  z = [zh,zw].min
  surface.fill([0,0,0])
  $solver.p.each_with_index do |v,x,y|
    if $solver.mask[x,y] == 0
      col = [64,64,64]
    else
      case $disp
      when :mark
        col = color_bar( $solver.mark[x,y] )
      when :pressure
        col = color_bar( norm($solver.p[x,y], $disp_min, $disp_max) )
      when :velocity
        v = Math.sqrt($solver.u[x,y]**2 + $solver.v[x,y]**2)
        col = color_bar( norm(v, $disp_min, $disp_max) )
      when :vorticity
        v = $solver.v[x-1,y] + $solver.u[x,y] - $solver.v[x,y] - $solver.u[x,y-1]
        if v > 0
          col = [norm(v)*255,0,0]
        else
          col = [0,norm(-v)*255,0]
        end
      else
        raise
      end
    end
    surface.draw_box_s([x*z,y*z],[(x+1)*z,(y+1)*z], col)
  end
  $screen.update
end

def process
  step = 1 / $solver.dt
  (step.to_i).times { $solver.step }
end

def mainloop
  $screen = Rubygame::Screen::set_mode [400,300]
  $screen.title = 'CFD'
  running = true
  queue = Rubygame::EventQueue.new

  $disp = :mark

  finished = false
  until finished do
    ev = queue.wait(0) do |ev|
      if running
        process
        update
      end
      sleep 0.01
    end
    
    case ev
    when Rubygame::ActiveEvent
      $screen.update
    when Rubygame::KeyDownEvent
      case ev.string.downcase
      when 'n'
        process
        update
        running = false
      when 'r'
        running = !running
      when 'q'
        finished = true
      when '!'
        $disp = :mark
        update
      when '@'
        $disp = :velocity
        vel = NMath.sqrt($solver.u**2 + $solver.v**2)
        $disp_min = vel.min
        $disp_max = vel.max
        update
      when '$'
        $disp = :vorticity
        update
      when '#'
        $disp = :pressure
        $disp_min = $solver.p.min
        $disp_max = $solver.p.max
        update
      else
        puts ev.string
      end
    when Rubygame::QuitEvent
      finished = true
    else
      # pp ev
    end

  end

  Rubygame.quit
end

init_solver
mainloop
