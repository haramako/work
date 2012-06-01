
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

srand(-999)
rand_table = []
256.times do |i|
  rand_table << rand(256)
end

puts "const atan_table = [#{atan.join(',')}];"
puts "const sin_table = [#{sin.join(',')}];"
puts "const rand_table = [#{rand_table.join(',')}];"
