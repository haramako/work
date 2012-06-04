# coding: utf-8

require 'pathname'

module Fc

  FC_HOME = Pathname(File.dirname( __FILE__ )) + '../..'
  LIB_PATH = [Pathname('.'), FC_HOME+'fclib']

  # share以下のファイルを検索する
  def self.find_share( path )
    FC_HOME + 'share' + path
  end

  # fclib以下のファイルを検索する
  def self.find_module( file )
    LIB_PATH.each do |path|
      return path + file if File.exists?( path + file )
    end
    raise CompileError.new( "file #{file} not found" );
  end

  ######################################################################
  # 型
  # Type.new() ではなく Type[] で生成すること
  ######################################################################
  class Type

    attr_reader :type # 種類( :void, :int, :pointer, :array, :lambda のいずれか )
    attr_reader :size # サイズ(単位:byte)
    attr_reader :signed # signedかどうか(intの場合のみ)
    attr_reader :base # ベース型(pointer,array,lambdaの場合のみ)
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
  class Identifier
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
  # 値そのもの
  ######################################################################
  class Value
    attr_reader :kind # 種類( :var, :const, :literal のいずれか）
    attr_reader :type   # Type
    attr_reader :id # 変数名( リテラルの場合は、nil )
    attr_reader :val # リテラルもしくは定数の場合はFixnum
    attr_reader :opt # オプション
    attr_reader :scope # スコープ(Function)
    attr_reader :var_type # varのときのみ( :var, :temp, :arg, :result のいずれか )

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
  # スコープ付きブロック
  ######################################################################
  class ScopedBlock
    attr_reader :upper, :id, :ast, :vars, :ops, :options, :includes
 
    # アセンブラで使用する
    attr_accessor :asm
    attr_accessor :optimized_ops

    def initialize( upper )
      @upper = upper
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

    def to_s
      "<Block:#{@id}>"
    end

  end

  ######################################################################
  # 関数
  ######################################################################
  class Lambda < ScopedBlock
    attr_reader :id, :type, :opt, :ast, :block
    attr_accessor :ops, :args
    attr_accessor :upper

    def initialize( id, type, opt, ast )
      @id = id
      @type = type
      @opt = opt || Hash.new
      @ast = ast
      @block = nil
      super(nil)
    end

    def to_s
      "<Lambda:#{@id} #{@type}>"
    end
  end


end
