#!/bin/env ruby

require 'pp'

require_relative 'parser.rb'
require_relative 'gen_cs.rb'

include Pandora::CodeGen

r = Parser.new(<<EOT).parse
// Comment
table 1 Characters Character {
  key 0 (uint Id); // key is unique index.

  index 1 (string Name); // [cached];
  index 2 (int Level, int Hp); // [ranged, name("LevelHp")];
}
EOT

pp r

gen = Generator::CSharpGenerator.new
src = gen.generate(r)

puts src

IO.write('TestProj/Generated.cs', src);



