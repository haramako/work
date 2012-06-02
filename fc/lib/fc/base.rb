# coding: utf-8

require 'pathname'

module Fc

  FC_HOME = Pathname(File.dirname( __FILE__ )) + '../..'
  LIB_PATH = [FC_HOME]

  # share以下のファイルを検索する
  def self.find_share( path )
    FC_HOME + 'share' + path
  end

  # fclib以下のファイルを検索する
  def self.find_lib( path )
    FC_HOME + 'fclib' + path
  end

  ######################################################################
  # 型
  # Type.new() ではなく Type[] で生成すること
  ######################################################################
  class Type

    attr_reader :type # 種類( :void, :int, :pointer, :array, :lambda のいずれか )
    attr_reader :size # サイズ(単位:byte)
    attr_reader :signed # signedかどうか(intの場合のみ)
    attr_reader :base # ベース型(pointerとarrayの場合のみ)
    attr_reader :length # 配列の要素数(arrayのみ)
    attr_reader :args # 引数クラスのリスト(lambdaの場合のみ)

    BASIC_TYPES = { int:[1,false], uint:[1,false], int8:[1,true], uint8:[1,false], int16:[2,true], uint16:[2,false] }

    private_class_method :new

    def initialize( ast )
      if ast == :void
        @type = :void
        @size = 1
      elsif ast == :bool
        @type = :bool
        @size = 1
      elsif Symbol === ast
        @type = :int
        if BASIC_TYPES[ast]
          @size = BASIC_TYPES[ast][0]
          @signed = BASIC_TYPES[ast][1]
        else
          raise
        end
      elsif Array === ast
        if ast[0] == :pointer
          @type = :pointer
          @base = Type[ ast[1] ]
          @size = 2
        elsif ast[0] == :array
          @type = :array
          @base = Type[ ast[2] ]
          @length = ast[1]
          @size = @base.size * @length
        elsif ast[0] == :lambda
          @type = :lambda
          @base = Type[ ast[2] ]
          @args = ast[1]
          @size = 2
        end
      end

      case @type
      when :int, :void, :bool
        @str = "#{ast}"
      when :pointer
        @str = "#{@base}*"
      when :array
        @str = "#{@base}[#{@length||''}]"
      when :lambda
        @str = "#{@base}(#{args.join(",")})"
      else
        raise "invalid type declaration #{ast}"
      end
    end

    def to_s
      @str
    end

    def self.[]( ast_or_type )
      return ast_or_type if Type === ast_or_type
      @@cache = Hash.new unless defined?(@@cache)
      type = new( ast_or_type )
      @@cache[type.to_s] = type unless @@cache[type.to_s]
      @@cache[type.to_s]
    end

  end

  ######################################################################
  # 値を持つもの(変数、テンポラリ変数、リテラル、定数など）
  ######################################################################
  class Value
    attr_reader :kind # 種類( :var, :const, :literal のいずれか）
    attr_reader :id # 変数名( リテラルの場合は、nil )
    attr_reader :type # Type
    attr_reader :val # リテラルもしくは定数の場合は数値
    attr_reader :opt # オプション
    attr_reader :scope # スコープ(Function)
    attr_reader :var_type # varのときのみ( :var, :temp, :arg, :reterun_val のいずれか )

    # 以下は、アセンブラで使用
    attr_accessor :address # アドレス
    attr_accessor :lr # 生存期間([from,to]という２要素の配列)
    attr_accessor :nonlocal # クロージャから参照されているかどうか
    attr_accessor :reg # 格納場所( :mem, :none, :a, :carry, :not_carry, :zero, :not_zero, :negative, :not_negative のいずれか )

    def self.literal( val )
      if val >= 256
        Value.new( nil, Type[:int16], val, nil, nil, :literal, nil )
      else
        Value.new( nil, Type[:int], val, nil, nil, :literal, nil )
      end
    end

    def initialize( id, type, val, opt, scope, kind=:var, var_type )
      raise "invalid type, #{type}" unless Type === type
      @id = id
      @type = type
      @val = val
      @opt = opt || Hash.new
      @scope = scope
      @kind = kind
      @var_type = var_type
    end

    def assignable?
      ( ( @kind == :var and @var_type != :temp ) or @type.type == :pointer )
    end

    def const?
      ( @kind != :var )
    end

    def to_s
      if @id
        if @scope
          "#{scope.id}$#{id}:#{type}"
        else
          "#{id}:#{type}"
        end
      else
        @val.inspect
      end
    end

  end

  ######################################################################
  # 関数
  ######################################################################
  class Lambda
    attr_reader :id, :type, :args, :block, :opt
    def initialize( id, type, args, opt, block )
      @id = id
      @type = type
      @args = args
      @opt = opt || Hash.new
      @block = block
    end

    def to_s
      "<Lambda:#{@id} #{@type}>"
    end
  end

  ######################################################################
  # スコープ付きブロック
  ######################################################################
  class ScopedBlock
    attr_reader :upper, :id, :ast, :vars, :ops, :options, :includes
    attr_accessor :asm
    attr_accessor :optimized_ops

    def initialize( compiler, upper, id, ast )
      @compiler = compiler
      @upper = upper
      @id = id
      @ast = ast
      @vars = Hash.new
      @tmp_count = 1
      @label_count = 0
      @ops = []
      @options = Hash.new
      @asm = []
      @loops = []
      @cur_filename = nil
      @cur_line = 0
      @cur_line_str = nil
      @includes = []
    end

    def compile
      begin
        # メインブロックのコンパイル
        compile_block( @ast )

        # returnを追加する
        if @ops[-1].nil? or @ops[-1][0] != :return
          if @vars[:'0']
            raise CompileError.new( "no return" )
          else
            emit :return
          end
        end

        # lambdaのコンパイル
        @vars.each do |id,v|
          if v.val and Lambda === v.val
            v.val.block.compile
          end
        end

      rescue CompileError
        puts @cur_line_str if @cur_line_str
        puts "#{@cur_filename}:#{@cur_line_no}: #{$!}"
        raise
      end
    end

    def compile_block( ast )
      ast.each do |stat|
        compile_statement( stat )
      end
    end

    def compile_statement( ast )
      update_pos( ast )
      case ast[0]
      when :options
        @options.merge!( ast[1] )

      when :include_bin
        @include_bin << e[1]
        if e[1][:name]
          var = Value.new( e[1][:name] )
          var.include_bin = true
          @vars[e[1]] = var
        end

      when :include
        filename = ast[1]
        if File.extname(filename) == '.asm'
          @includes << Fc::find_lib( filename )
        else
          src = File.read(Fc::find_lib(filename))
          ast, pos_info = Parser.new(src,filename).parse
          @compiler.pos_info.merge!( pos_info )
          compile_block( ast )
        end

      when :function
        block = ScopedBlock.new( @compiler, self, ast[1], ast[5] )
        args = ast[2].map do |v|
          block.new_arg( v[0], Type[v[1]] )
        end
        type = Type[ [:lambda, args, ast[3]] ]
        lmd = Lambda.new( ast[1], type, args, ast[4], block )
        block.new_return_val(type.base) if type.base != Type[:void]
        new_const( ast[1], lmd.type, lmd, nil )

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
        if @vars[:'0']
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
      raise CompileError.new("var #{var.id} already defined") if @vars[var.id]
      @vars[var.id] = var
      var
    end

    def new_var(id,type,opt)
      add_var Value.new(id,type,nil,opt,self, :var, :var )
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
      add_var Value.new(id,type,init,opt,self, :const, nil )
    end

    def new_tmp( type )
      var = add_var( Value.new("#{@tmp_count}".intern,type,nil,nil,self, :var, :temp) )
      @tmp_count += 1
      var
    end

    def new_arg(id,type)
      add_var Value.new(id,type,nil,nil,self, :var, :arg)
    end

    def new_return_val(type)
      add_var Value.new(:'0',type,nil,nil,self, :var, :return_val )
    end

    def new_literal_string(str)
      var = add_var( Value.new("#{@tmp_count}".intern, 
                               Type[[:array,str.size+1,:int]], 
                               str.unpack('c*').concat([0]), nil, self, :const, nil ) )
      @tmp_count += 1
      var
    end

    def find_var(id)
      if @vars[id]
        @vars[id]
      elsif @upper 
        @upper.find_var(id)
      else
        raise CompileError.new(" #{id} not defined")
      end
    end

    def to_s
      "<Block:#{@id}>"
    end

  end

end
