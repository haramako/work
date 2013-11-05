#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'dxruby'

puts 'hoge'

font = Font.new(16)

# Window.fps = 120

pads = [
        P_BUTTON0,
        P_BUTTON1,
        P_BUTTON2,
       ]

prev = []
pushed = []
pressed = []
piano_keep = 0
piano_str = []
piano_reset = 0

Window.loop do

  prev = pushed
  pushed = pads.map do |b|
    Input.padDown?( b )
  end

  pushed.size.times do |i|
    pressed[i] = ( pushed[i] != prev[i] )
  end
  some_pushed = pushed.find{|x| x}

  piano = pressed.inject(false) do |b,memo|
    memo || b
  end

  if piano_reset <= 0 and some_pushed
    piano_str = []
  end

  piano_str << "#{pushed.map{|x|(x)?1:0}} => #{piano ?1:0}"

  piano_reset = 10 if piano
  piano_reset -= 1

  out = []
  out << "FPS: #{Window.real_fps} pushed: #{pressed.map{|x|(x)?1:0}} piano: #{piano}"
  out = out + piano_str

  Window.drawFont(0,0,out.join("\n"),font)
end

