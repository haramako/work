#!/bin/env ruby

require 'pp'

require_relative 'parser.rb'
require_relative 'gen_cs.rb'

include Pandora::CodeGen

r = Parser.new(<<EOT).parse
namespace ToydeaCabinet.CodeGenTest;
// Comment
table 1 Characters Character (int Id){
  index 2 (string Name); // [cached];
  index 3 (int Age, int Weight); // [ranged, name("LevelHp")];
}
EOT

pp r

gen = Generator::CSharpGenerator.new
src = gen.generate(r)

puts src

IO.write('../Test/CodeGen/Generated.cs', src);



