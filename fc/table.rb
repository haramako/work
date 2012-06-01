
atan = []
sin = []
include Math

16.times do |y|
  r = []
  16.times do |x|
    r << [ Math.atan2(y,x)/Math::PI*128, 63].min.to_i
  end
  atan << r
end

64.times do |i|
  sin << [ Math.sin(Math::PI/2*i/64) *128, 127].min.to_i
end

puts "const atan_table = [#{atan.join(',')}];"
puts "const sin_table = [#{sin.join(',')}];"
