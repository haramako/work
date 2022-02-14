#!/bin/env ruby

require 'pp'

require_relative 'parser.rb'
require_relative 'gen_cs.rb'

include Pandora::CodeGen

f = ARGV[0]

ast = Parser.new(IO.read(f), f).parse
#pp ast
ast.analyze
code = Generator::CSharpGenerator.new.generate(ast)

puts code

IO.write(ARGV[1], code);
