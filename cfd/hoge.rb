# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'
require_relative 'util'

solver = Cfd::Solver.new(32,16) do |s|
  # s.draw_rect 6, 6, 2, 4
  s.draw_rect 6, 6, 4, 2
  #s.draw_rect 8, 6, 2, 8
  #s.draw_circle 15.5, 15.5, 5

  s.snap_span = 5
  s.re = 0.000
  s.dt = 0.1
  s.output_gif 'test2.gif', :mark
end

solver.on_setting = lambda do |s|
  speed = 1.0
  angle = -0.0 *(Math::PI/180.0)
  bound0 s, speed, angle
end

yr = []
solver.on_snap = lambda do |s|
  STDERR.print '.'
  yr << calc_force(s)
end

solver.solv(400)

puts
p NArray[*yr].mean(1).to_a
