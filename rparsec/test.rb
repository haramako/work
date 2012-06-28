#!/usr/bin/env ruby

require 'rparsec'
require 'pp'

class TestParser
  include RParsec
  include RParsec::Parsers

  attr_reader :lexer

  def initialize

    # lexer
    @keyword = Keywords.case_sensitive %w( var function ), word.token(:id)
    @sym = Operators.new %w( ; ( ) [ ] { } )
    @op = Operators.new %w( + - * / = )
    @lexer = ( @keyword.lexer | number.token(:num) | @op.lexer | @sym.lexer ).lexeme

    # program parser
    op_parser = proc do |op|
      @op[ op ] >> proc { |left,right| [ Token.new( op, op.to_s ), left, right ] }
    end
    op_table = OperatorTable.new do |t|
      t.infixl op_parser.(:'='), 0
      t.infixl op_parser.(:+), 10
      t.infixl op_parser.(:-), 10
      t.infixl op_parser.(:*), 20
      t.infixl op_parser.(:/), 20
    end

    @term           = token(:num) | token(:id)
    @exp            = Expressions.build( @term, op_table )
    @statement      = @exp << token(:';')
    @statement_list = @statement.many
    @block          = token(:'{') >> @statement_list << token(:'}')
    @function_decl  = sequence( @keyword[:function], token(:id), token(:'('), token(:')'), @block.optional ){ |_,id,_,_,body| [:function, id, body] }
    @program = @function_decl

    @parser = @lexer.nested( @program << eof )
  end

  def parse( str )
    @parser.parse str
  end

  private

  alias s sequence

  def watch_this
    watch { |x| puts x }
  end

end


parser = TestParser.new
# pp parser.lexer.parse ' a + 1 var '

pp parser.parse <<EOT
function hoge(){
  a = a + 1;
  b = 2;
}
EOT
