# coding: utf-8

require 'pp'
require 'strscan'
require 'erb'
require_relative 'base'
require_relative 'parser'

module Fc

  ######################################################################
  # パーサー
  ######################################################################
  class Parser

    def initialize( src, filename='(unknown)' )
      @filename = filename
      @scanner = StringScanner.new(src)
      @line_no = 1
      @pos_info = Hash.new
    end

    def next_token
      # コメントと空白を飛ばす
      while @scanner.scan(/ \s+ | \/\/.+?\n | \/\*.+?\*\/ /mx)
        @scanner[0].gsub(/\n/){ @line_no += 1 }
      end
      if @scanner.eos?
        r = nil
      elsif @scanner.scan(/<=|>=|==|\+=|-=|!=|->|&&|\|\||\(|\)|\{|\}|;|:|<|>|\[|\]|\+|-|\*|\/|%|&|\||\^|=|,|@|!/)
        # 記号
        r = [@scanner[0], @scanner[0]]
      elsif @scanner.scan(/0[xX]([\d\w]+)/)
        # 16進数
        r = [:NUMBER, @scanner[1].to_i(16)]
      elsif @scanner.scan(/0[bB](\d+)/)
        # 2進数
        r = [:NUMBER, @scanner[1].to_i(2)]
      elsif @scanner.scan(/\d+/)
        # 10進数
        r = [:NUMBER, @scanner[0].to_i]
      elsif @scanner.scan(/\w+/)
        # 識別子/キーワード
        if /^(include|function|const|var|options|if|else|loop|while|for|return|break|continue|asm)$/ === @scanner[0]
          r = [@scanner[0], @scanner[0]]
        else
          r = [:IDENT, @scanner[0].to_sym ]
        end
      elsif @scanner.scan(/"([^\\"]|\\.)*"/)
        # ""文字列
        r = [:STRING, @scanner[0][1..-2]]
      elsif @scanner.scan(/'([^\\']|\\.)*'/)
        # ''文字列
        r = [:STRING, @scanner[0][1..-2]]
      else
        raise "invalid token at #{@line_no}"
      end
      # pp r
      r
    end

    def info( ast )
      @pos_info[ast] = [@filename,@line_no,@line_str]
    end

    def parse
      ast = do_parse
      [ast, @pos_info]
    end

    def on_error( token_id, err_val, stack )
      puts "#{@filename}:#{@line_no}: error with #{token_id}"
      # pp token_id, err_val, stack
      super
    end
  end

  # エラークラス
  class CompileError < RuntimeError
    attr_accessor :line
    attr_accessor :file
  end


  ######################################################################
  # コンパイラ
  ######################################################################
  class Compiler
    attr_reader :ast, :pos_info, :root

    def initialize
      @pos_info = nil
    end

    def compile( src, filename=nil )
      ast, @pos_info = Parser.new(src,filename).parse

      @root = ScopedBlock.new( self, nil, :'', ast )
      @root.compile

      # interruptがなかったら足す
      unless @root.vars[:interrupt]
        blk = ScopedBlock.new(self,@root,:interrupt,[])
        blk.compile
        lmd = Lambda.new(:interrupt,TypeDecl[[:lambda,[],:void]],[],nil,blk)
        @root.new_const(:interrupt,lmd.type,lmd,nil)
      end
    end

    def to_html
      @template_main ||= File.read( Fc.find_share('main.html.erb') )
      left_bar = make_left_bar(@root)
      ERB.new(@template_main,nil,'-').result(binding)
    end

    def block_to_html(block)
      require 'differ'
      @template_block ||= File.read( Fc.find_share('block.html.erb') )
      if block.optimized_ops
        diff = Differ.diff_by_line(block.optimized_ops.map{|l|l.to_s}.join("\n"), block.ops.map{|l|l.to_s}.join("\n"))
        optimized_ops = diff.format_as(:html)
      end
      ERB.new(@template_block,nil,'-').result(binding)
    end

    def make_left_bar(block)
      id = block.id 
      id = '(root block)' if block.id == :''
      r = "<li><a href='##{id}'>#{id}</a><ul>"
      block.vars.each do |id,v|
        r += make_left_bar(v.val.block) if v.val and Lambda === v.val and v.val.type.type == :lambda
      end
      r += '</ul></li>'
      r
    end
  end

end
