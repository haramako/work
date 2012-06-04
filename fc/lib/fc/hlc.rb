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
      @pos_info[ast] = [@filename,@line_no]
    end

    def parse
      ast = do_parse
      [ast, @pos_info]
    rescue Racc::ParseError
      err = CompileError.new( "#{$!.to_s.strip}" )
      err.filename = @filename
      err.line_no = @line_no
      raise err
    end

    def on_error( token_id, err_val, stack )
      # puts "#{@filename}:#{@line_no}: error with #{token_to_str(token_id)}:#{err_val}"
      # pp token_id, err_val, stack
      super
    end
  end

  ######################################################################
  # エラークラス
  ######################################################################
  class CompileError < RuntimeError
    attr_accessor :line_no
    attr_accessor :filename
  end


  ######################################################################
  # High-Level コンパイラ( FCソース -> 中間コード へのコンパイルを行う )
  ######################################################################
  class Hlc
    attr_reader :ast, :pos_info, :root, :lambdas, :includes

    def initialize
      @@debug = 3
      @pos_info = Hash.new
      @src = Hash.new
      @scopes = []
      @label_count = 0
      @tmp_count = 1
      @options = Hash.new
      @includes = []
      @loops = []
    end

    def compile( filename )
      @cur_filename = '(unknown)'
      @cur_line_no = 0

      begin
        @lambdas = Hash.new
        @root = ScopedBlock.new(nil)
        @scopes << @root

        compile_module( filename )

        # interruptがなかったら足す
        unless @root.vars[:interrupt]
          compile_decl( [:function, :interrupt, [], :void, Hash.new, []] )
        end

        @lambdas.each do |id,lmd|
          dout 1, "compiling function #{id}"
          compile_lambda( lmd )
        end


      rescue CompileError
        $!.filename ||= @cur_filename
        $!.line_no ||= @cur_line_no 
        $!.backtrace.unshift "#{$!.filename}:#{$!.line_no}"
        raise
      end

    end

    ############################################
    # モジュールのコンパイル
    ############################################
    def compile_module( filename )
      dout 1, "compiling module #{filename}"
      path = Fc.find_module(filename)
      src = File.read( path )
      @cur_filename = path.to_s
      ast, pos_info = Parser.new(src,path).parse
      @src[filename] = src.split(/\n/)
      @pos_info.merge! pos_info
      ast.each do |ast2|
        compile_decl( ast2 )
      end
    end

    def compile_decl( ast )
      # update_pos( ast )
      case ast[0]
      when :options
        @options.merge!( ast[1] )

      when :include
        filename = ast[1]
        if File.extname(filename) == '.asm'
          @includes << Fc::find_module( filename )
        else
          compile_module( filename )
        end

      when :function
        _, id, args, type, opt, block = ast
        arg_types = args.map { |arg| Type[arg[1]] }
        type = Type[ [:lambda, arg_types, type] ]
        lmd = Lambda.new( id, type, opt, block )
        lmd.upper = @scopes[-1]
        @scopes.push lmd
        arg_vars = args.map { |arg| new_arg( arg[0], Type[arg[1]] ) }
        lmd.args = arg_vars
        new_result( lmd.type.base ) if lmd.type.base.type != :void
        @scopes.pop
        @lambdas[id] = lmd
        new_const( id, type, lmd, opt )

      when :var
        ast[1].each do |v|
          id, type, init, opt = v
          raise CompileError.new("can't init global variable") if init
          type = Type[const_type_eval(type)]
          compatible_type( type, init.type ) if type and init
          new_var( id, type, opt )
        end

      when :const
        ast[1].each do |v|
          id, type, val, opt = v
          # raise CompileError.new("connot define const without value #{v[0]}") unless v[2]
          type = Type[type] if type
          new_const( id, type, val, opt )
        end
      else
        raise CompileError.new("invalid op #{op}")
      end
    end

    ############################################
    # Lambdaのコンパイル
    ############################################
    def compile_lambda( lmd )
      old_lmd, @cur_lmd = @cur_lmd, lmd
      old_block, @cur_block = @cur_block, lmd
      @scopes.push lmd


      @ops = []
      compile_block( lmd.ast )

      # returnを追加する
      if @ops[-1].nil? or @ops[-1][0] != :return
        if lmd.vars[:'0']
          raise CompileError.new( "no return" )
        else
          emit :return
        end
      end

      lmd.ops = @ops
      @ops = nil

      @scopes.pop
      @cur_block = old_block
      @cur_lmd = old_lmd
    end

    # ブロックをコンパイルする
    def compile_block( ast )

      #block = ScopedBlock.new( @scopes[-1] )

      # old_block, @cur_block = @cur_block, block
      # @scopes.push block
      ast.each do |stat|
        compile_statement( stat )
      end
      # @scopes.pop
      # @cur_block = old_block
    end

    # 文をコンパイルする
    def compile_statement( ast )
      update_pos( ast )

      case ast[0]

      when :var
        ast[1].each do |v|
          init = v[2] && rval(const_eval(v[2]))
          type = ( v[1] && const_type_eval(v[1]) ) || init.type
          compatible_type( type, init.type ) if type and init
          var = new_var( v[0], type, v[3] )
          emit :load, var, init if init
        end

      when :const
        ast[1].each do |v|
          # raise CompileError.new("connot define const without value #{v[0]}") unless v[2]
          type = Type[v[1]] if v[1]
          new_const( v[0], type, v[2], v[3] )
        end

      when :'if'
        then_label, else_label, end_label = new_labels('then', 'else','end')
        cond = rval(ast[1])
        emit :if, cond, else_label
        emit :label, then_label
        compile_block(ast[2])
        emit :jump, end_label
        emit :label, else_label
        if ast[3]
          compile_block(ast[3])
        end
        emit :label, end_label

      when :loop
        begin_label, end_label = new_labels('begin', 'end')
        @loops << end_label
        emit :label, begin_label
        compile_block ast[1]
        emit :jump, begin_label
        emit :label, end_label
        @loops.pop
        
      when :'while'
        begin_label, end_label = new_labels('begin', 'end')
        @loops << end_label
        emit :label, begin_label
        cond = rval(ast[1])
        emit :if, cond, end_label
        compile_block ast[2]
        emit :jump, begin_label
        emit :label, end_label
        @loops.pop

      when :for
        compile_block( [[:exp, [:load, ast[1], ast[2]]],
                        [:while, 
                         [:lt, ast[1], ast[3]],
                         ast[4] + [[:exp, [:load, ast[1], [:add, ast[1], 1] ]]]
                        ] ] )

      when :break
        raise CompileError.new("cannot break without loop") if @loops.empty?
        emit :jump, @loops[-1]

      when :return
        if @scopes[-1].vars[:'0']
          # 非void関数
          raise CompileError.new("can't return without value") unless ast[1]
          emit :return, rval(ast[1])
        else
          # void関数
          raise CompileError.new("can't return from void function") if ast[1]
          emit :return
        end

      when :exp
        const_eval( ast[1] )
        rval( ast[1] )

      when :asm
        emit *ast

      else
        raise "unknow op #{ast}"
      end
    end

    def rval( ast )
      v, left = lval( ast )
      if left
        r = new_tmp( v.type.base )
        emit :pget, r, v
        r
      else
        v
      end
    end

    def lval( ast )
      left_value = false
      case ast
      when Symbol
        r = find_var( ast )

      when Numeric
        r = Value.literal( ast )

      when String
        r = new_literal_string(ast)

      when Array
        case ast[0]

        when :load
          left, left_value = lval(ast[1])
          right = rval(ast[2])
          if left_value
            compatible_type( left.type.base, right.type )
            raise CompileError.new("#{left} is not left value") unless left.assignable?
            emit :pset, left, right
            r = left
            left_value = true
          else
            compatible_type( left.type, right.type )
            raise CompileError.new("#{left} is not left value") unless left.assignable?
            emit :load, left, right
            r = left
          end

        when :not, :uminus
          left = rval(ast[1])
          r = new_tmp( left.type )
          emit ast[0], r, left

        when :add, :sub, :mul, :div, :mod, :and, :or, :xor
          left = rval(ast[1])
          right = rval(ast[2])
          r = new_tmp( compatible_type( left.type, right.type ) )
          emit ast[0], r, left, right

        when :eq, :lt
          left = rval(ast[1])
          right = rval(ast[2])
          compatible_type( left.type, right.type )
          r = new_tmp( Type[:int] )
          emit ast[0], r, left, right

        when :ne, :gt, :le, :ge
          # これらは、eq,lt の引数の順番とnotを組合せて合成する
          left = ast[1]
          right = ast[2]
          case ast[0]
          when :ne
            r = rval([:not, [:eq, left, right]])
          when :gt
            r = rval([:lt, right, left])
          when :le
            r = rval([:not, [:lt, right, left]])
          when :ge
            r = rval([:not, [:lt, left, right]])
          end

        when :land
          end_label = new_label('end')
          r = new_tmp( Type[:int] )
          left = rval(ast[1])
          emit :load, r, left
          emit :if, r, end_label
          right = rval(ast[2])
          emit :load, r, right
          emit :label, end_label

        when :lor
          end_label = new_label('end')
          r = new_tmp( Type[:int] )
          r2 = new_tmp( Type[:int] )
          left = rval(ast[1])
          emit :load, r, left
          emit :not, r2, r
          emit :if, r2, end_label
          right = rval(ast[2])
          emit :load, r, right
          emit :label, end_label

        when :call
          func = find_var( ast[1] )
          if func.type.base.type != :void
            r = new_tmp( func.type.base )
          else
            r = nil
          end
          raise CompileError.new("lambda #{func} has #{func.val.args.size} but #{ast[2].size}") if ast[2].size != func.val.args.size
          args = []
          ast[2].each_with_index do |arg,i|
            v = rval(arg)
            compatible_type( func.val.args[i].type, v.type )
            args << v
          end
          emit :call, r, func, *args

        when :index
          left = rval(ast[1])
          right = rval(ast[2])
          raise CompileError.new("index must be pointer or array") unless left.type.type == :pointer or left.type.type == :array
          raise CompileError.new("index must be int") if right.type.type != :int
          r = new_tmp( Type[[:pointer, left.type.base]] )
          emit :index, r, left, right
          left_value = true

        else
          raise "unknown op #{ast}"
        end
      else
        raise "unknown op #{ast}"
      end
      [r,left_value]
    end

    def const_eval( ast )
      r = ast
      case ast
      when Symbol
        var = find_var( ast )
        r = var.val if var.const? and var.type.type == :int
      when Numeric
        r = ast
      when String
        r = ast
      when Array
        case ast[0]
        when :array
          r = [:array, ast[1].map{|v| const_eval(v)} ]
        when :add, :sub, :mul, :div, :mod, :eq, :ne, :lt, :gt, :le, :ge, :rsh, :lsh
          ast[1] = const_eval( ast[1] )
          ast[2] = const_eval( ast[2] )
          if Numeric === ast[1] and Numeric === ast[2]
            case ast[0]
            when :add then r = ast[1] +  ast[2]
            when :sub then r = ast[1] -  ast[2]
            when :mul then r = ast[1] *  ast[2]
            when :div then r = ast[1] /  ast[2]
            when :mod then r = ast[1] %  ast[2]
            when :eq  then r = ast[1] == ast[2]
            when :ne  then r = ast[1] != ast[2]
            when :lt  then r = ast[1] <  ast[2]
            when :gt  then r = ast[1] >  ast[2]
            when :le  then r = ast[1] <= ast[2]
            when :ge  then r = ast[1] >= ast[2]
            end
          end
          r = 0 if r == false
          r = 1 if r == true
        when :not, :uminus
          ast[1] = const_eval( ast[1] )
          if Numeric === ast[1]
            case ast[0]
            when :not then r = (ast[1]==0 ? 1 : 0 )
            when :uminus then r = -ast[1]
            end
          end
        when :call
          ast[2] = ast[2].map {|exp| const_eval(exp)}
        end
      end
      r
    end

    def const_type_eval( ast )
      if Array === ast and ast[0] === :array
        size = const_eval(ast[1])
        size = size.val if Value === size
        Type[ [ast[0], size, ast[2]] ]
      else
        Type[ast]
      end
    end

    def compatible_type( a, b )
      return a if  a == b
      if a.type == :int and b.type == :int
        if a.size > b.size then return a else return b end
      elsif a.type == :pointer and b.type == :array and a.base == b.base
        return a
      end
      raise CompileError.new("cant convert type #{a} and #{b}")
    end

    def update_pos( ast )
      if @compiler.pos_info[ast]
        pos_info = @compiler.pos_info[ast]
        @cur_filename, @cur_line_no, @cur_line_str = @compiler.pos_info[ast]
        # puts "compiling ... line #{@cur_line}"
      end
    end

    def emit( *op )
      @ops << op
    end

    def new_label( name )
      new_labels( name )[0]
    end

    def new_labels( *names )
      @label_count += 1
      names.map { |n| '.'+n+'_'+@label_count.to_s }
    end

    def add_var(var)
      raise CompileError.new("var #{var.id} already defined") if @scopes[-1].vars[var.id]
      @scopes[-1].vars[var.id] = var
      var
    end

    def new_var(id,type,opt)
      add_var Value.new(id,type,nil,opt,@scopes[-1], :var, :var )
    end

    def new_const(id,type,init,opt)
      case init
      when nil, Lambda
      when Numeric
        init_type = Value.literal(init).type
      when String
        init = str.unpack('c*').concat([0])
        init_type = Type[ [:array, init.size, :int] ]
      when Array
        if init[0] == :array
          init = init[1]
          init_type = Type[ [:array, init.size, :int] ]
        else
          raise "not constant value #{@init}"
        end
      else
        raise "not constant value #{@init}"
      end
      if type and init_type
        compatible_type( init_type, type ) 
      end
      type = init_type unless type
      add_var Value.new(id,type,init,opt,@scopes[-1], :const, nil )
    end

    def new_tmp( type )
      var = add_var( Value.new("#{@tmp_count}".intern,type,nil,nil,@scopes[-1], :var, :temp) )
      @tmp_count += 1
      var
    end

    def new_arg(id,type)
      add_var Value.new(id,type,nil,nil,@scopes[-1], :var, :arg)
    end

    def new_result(type)
      add_var Value.new(:'0',type,nil,nil,@scopes[-1], :var, :result )
    end

    def new_literal_string(str)
      var = add_var( Value.new("#{@tmp_count}".intern, 
                               Type[[:array,str.size+1,:int]], 
                               str.unpack('c*').concat([0]), nil, @scopes[-1], :const, nil ) )
      @tmp_count += 1
      var
    end

    def find_var(id)
      @scopes.reverse_each do |s|
        return s.vars[id] if s.vars[id]
      end
      raise CompileError.new(" #{id} not defined")
    end

    def update_pos( ast )
      if @pos_info[ast]
        pos_info = @pos_info[ast]
        @cur_filename, @cur_line_no, @cur_line_str = @pos_info[ast]
        # puts "compiling ... line #{@cur_line}"
      end
    end

    def dout( level, *args )
      if @@debug >= level
        puts args.join(" ")
      end
    end

    ############################################
    # HTML出力用関数群
    ############################################
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
