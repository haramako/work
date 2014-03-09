# -*- coding: utf-8 -*-
$LOAD_PATH << "./lib"

require 'cfd'
require 'pp'
require 'fileutils'
require_relative 'util'

FileUtils.mkdir_p "wing_test"

def test( re, speed, angle )
  rad = angle *(Math::PI/180.0)
  solver = Cfd::Solver.new(64,32) do |s|

    wing1 s, 18, s.height/2, 1.0
    
    s.snap_span = 1
    s.re = re
    s.dt = 0.01
    s.output_gif "wing_test/r#{re}_s#{speed}_a#{angle}.gif"
  end

  solver.on_setting = lambda do |s|
    bound0 s, speed, rad
  end

  result = []
  solver.on_snap = lambda do |s|
    # STDERR.print '.'
    mask = solver.mask
    if s.cur_time > 50
      result << calc_force(s) * rot_matrix(rad)
    end
  end
  
  solver.solv(100)
  result = NArray[*result]
  flatter = NMath.sqrt((result**2).sum(0))
  [ result[0,true].mean, result[1,true].mean, flatter.stddev]
end

re_list = [0.8]#, 0.005, 0.008, 0.010]
speed_list = [8,10,12,15,18,20] # [8,10,12,15] # [0.3, 0.5, 0.8, 1.0, 2.0, 3.0]
angle_list = 0.step(20,4) # [5, 10, 20, 30]

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
