# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib" << '.'

require 'cfd'
require 'pp'
ENV['RUBYSDLFFI_PATH'] = '/opt/boxen/homebrew/lib'
require 'rubygame'
require 'util'

def init_solver

  $solver = Cfd::Solver.new(64,32) do |s|
    #s.draw_rect 8, 6, 4, 4
    s.draw_circle 12.5, 15.5, 5
    #wing1 s, 18, s.height/2, 1.0

    # 0.1.step(Math::PI*2-0.1,0.01) do |r|
    #   a = 1.0
    #   z = j2(1.2, a*Math.cos(r) + 0.2, a*Math.sin(r) + 0.1)
    #   s.mask[38+z[0]*12, s.height/2-z[1]*10] = 0
    # end
    

    $dx = 0.1
    s.snap_span = 1
    # s.re = 0.00089 / $dx # 水
    # s.re = 1.8e-5 / $dx # 空気
    s.re = 0.05 / $dx
    s.re = 0.001 / $dx
    s.dt = 0.01
    $speed = 0.5
    $angle = 0.0 *(Math::PI/180.0)

    s.on_setting = lambda do |s|
      bound0 s, $speed/$dx, $angle
    end
  end
end

#=====================================================================================

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
        col = [norm($solver.mark[x,y])*255,0,0]
      when :pressure
        col = color_bar( norm($solver.p[x,y], $disp_min, $disp_max) )
      when :velocity
        v = Math.sqrt($solver.u[x,y]**2 + $solver.v[x,y]**2)
        col = color_bar( norm(v, $disp_min, $disp_max) )
      when :vorticity
        v = $solver.v[x-1,y] + $solver.u[x,y] - $solver.v[x,y] - $solver.u[x,y-1]
        if v > 0
          col = [norm(v,$disp_min,$disp_max)*255,0,0]
        else
          col = [0,norm(-v,$disp_min,$disp_max)*255,0]
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
  ($solver.snap_span / $solver.dt).to_i.times { $solver.step }

  #force = calc_force($solver) * rot_matrix($angle) * $dx
  #puts "%0.3f %0.3f"%[force[0],force[1]]
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
        $disp_min = 0
        $disp_max = [$solver.v.abs.max, $solver.u.abs.max].max / 2
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
