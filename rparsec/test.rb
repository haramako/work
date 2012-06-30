#!/usr/bin/env ruby

require 'rparsec'
require 'pp'

class TestParser
  include RParsec
  extend RParsec::Parsers

  SEP           = string(/;/)
  NUM           = number
  WORD          = word.token(:word)
  OPEN_PAREN    = string('(')
  CLOSE_PAREN   = string(')')
  OPEN_BRACKET  = string('{')
  CLOSE_BRACKET = string('}')
  OPERATORS     = Operators.new %w( + - = )
  KEYWORDS      = Keywords.case_sensitive %w( function static )

  Lexer         = number.token(:number) | KEYWORDS.lexer | OPERATORS.lexer
  def self.k
    KEYWORDS
  end

  def self.op( token )
    string( token ) >> proc do |left,right|
      [ token, left, right]
    end
  end

  op_table = RParsec::OperatorTable.new do |t|
    t.infixl op('+'), 1
    t.infixl op('-'), 1
    t.infixl op('*'), 2
    t.infixl op('/'), 2
    t.infixl op('='), 3
  end

  TERM = NUM | WORD | OPEN_PAREN >> lazy{ EXP } << CLOSE_PAREN
  EXP = RParsec::Expressions.build( TERM, op_table )
  STATEMENT = EXP << SEP
  STATEMENT_LIST = STATEMENT.many
  BLOCK = OPEN_BRACKET >> STATEMENT_LIST << CLOSE_BRACKET

  FUNCTION_DECL = sequence( k[:function], WORD, OPEN_PAREN, CLOSE_PAREN, BLOCK ) { |f,id,_,_,body| [:function, id,body] }

  def self.parse( str )
    FUNCTION_DECL.parse( str )
  end

end


pp TestParser.k.lexer.lexeme.parse( 'static function hoge fuga' ) #.map(&:text)

#pp TestParser.parse <<EOT
#functionhoge(){x=hoge-(1+fuga);y=hoge;}
#EOT

# pp parser.parse( 'hoge;' )

