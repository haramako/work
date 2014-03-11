# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'
require_relative 'util'

@yr = []
$dx = 1

solver = Cfd::Solver.new(64/$dx,32/$dx) do |s|
  # s.draw_rect 6, 6, 2, 4
  #s.draw_rect 6, 6, 4, 2
  #s.draw_rect 8, 6, 2, 8
  #s.draw_circle 15.5, 15.5, 5
  s.draw_circle s.width/8-0.5, s.height/2-0.5, s.height/10.0

  s.snap_span = 5
  s.re = 0.2 / $dx
  s.dt = 0.1 * $dx
  s.output_gif 'test2.gif', :mark
  speed = 1.0 / $dx
  angle = -0.0 *(Math::PI/180.0)
  
  __re = 0.1
  s.re = 1.0 / (__re * (s.height/10.0*2) * speed) # 0.4
  
  s.on_setting = lambda do |s|
    bound0 s, speed, angle
  end
  
  s.on_snap = lambda do |s|
    STDERR.print '.'
    # @yr << calc_force(s)
  end
end

solver.solv(400)

puts
# p NArray[*@yr].mean(1).to_a
