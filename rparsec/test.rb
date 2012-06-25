#!/usr/bin/env ruby

require 'rparsec'
require 'pp'

include RParsec

NUM = Parsers.number
WORD = Parsers.word.token(:word)
OPEN_PAREN = Parsers.string('(')
CLOSE_PAREN = Parsers.string(')')

def op( token )
  Parsers.string( token ) >> proc do |left,right|
    [ token, left, right]
  end
end

op_table = OperatorTable.new do |t|
  t.infixl op('+'), 10
  t.infixl op('-'), 10
  t.infixl op('*'), 20
  t.infixl op('/'), 20
end


TERM = NUM | WORD | OPEN_PAREN >> Parsers.lazy{ EXP } << CLOSE_PAREN
EXP = Expressions.build( TERM, op_table )

EXP_LIST = EXP.many

pp EXP_LIST.parse( 'hoge-(1+fuga)fuga' )

pp EXP_LIST.parse( 'hoge' )
