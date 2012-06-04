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

    attr_reader :kind # 種類( :void, :int, :pointer, :array, :lambda のいずれか )
    attr_reader :size # サイズ(単位:byte)
    attr_reader :signed # signedかどうか(intの場合のみ)
    attr_reader :base # ベース型(pointer,array,lambdaの場合のみ)
    attr_reader :length # 配列の要素数(arrayのみ)
    attr_reader :args # 引数クラスのリスト(lambdaの場合のみ)

    BASIC_TYPES = { int:[1,false], uint:[1,false], int8:[1,true], uint8:[1,false], int16:[2,true], uint16:[2,false] }

    private_class_method :new

    def initialize( ast )
      if ast == :void
        @kind = :void
        @size = 1
      elsif ast == :bool
        @kind = :bool
        @size = 1
      elsif Symbol === ast
        @kind = :int
        if BASIC_TYPES[ast]
          @size = BASIC_TYPES[ast][0]
          @signed = BASIC_TYPES[ast][1]
        else
          raise
        end
      elsif Array === ast
        if ast[0] == :pointer
          @kind = :pointer
          @base = Type[ ast[1] ]
          @size = 2
        elsif ast[0] == :array
          @kind = :array
          @base = Type[ ast[2] ]
          @length = ast[1]
          @size = @length && @base.size * @length
        elsif ast[0] == :lambda
          @kind = :lambda
          @base = Type[ ast[2] ]
          @args = ast[1]
          @size = 2
        end
      end

      case @kind
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
  # 変数、定数など識別子で区別されるもの
  #
  # 区別したいのは以下のもの
  #                 例                          代入 id     val       kind          asm
  # 引数            function( arg:int )]:void   o    arg    -         arg           __STACK__+0,x
  # 帰り値          return 0;                   o    -      -         result        __STACK__-1,x
  # ローカル変数    var i:int;                  o    i      -         var           __STACK_+1,x
  # テンポラリ変数                              x    i      -         temp          __STACK_+1,x
  # ローカル定数    const c = 1;                x    c      1         const         #1
  # ローカル定数2   const c = [1,2]             x    c      -         symbol        .c
  # 文字列リテラル  "hoge"                      x    a0     [1,2]     symbol        .a0 ( int[]の定数として保持 )
  # グローバル変数  var i:int;                  o    i      -         global_var    i
  # グローバル定数  const c = 1;                x    c      1         global_const  #1
  # グローバル定数2 function f():void;          x    f      1         global_symbol f
  #
  # シンボルをもつか、値をもつか
  # アセンブラでシンボルを使うか、スタックを使うか
  # 定数か変数か
  # 代入可能か？
  #
  ######################################################################
  class Identifier
    
    attr_reader :kind # 種類
    attr_reader :type # Type
    attr_reader :id   # 変数名
    attr_reader :val  # 定数の場合はその値( Fixnumか配列 )
    attr_reader :opt  # オプション

    # 以下は、アセンブラで使用
    attr_accessor :address # アドレス
    attr_accessor :lr # 生存期間([from,to]という２要素の配列)
    attr_accessor :nonlocal # クロージャから参照されているかどうか
    attr_accessor :reg # 格納場所( :mem, :none, :a, :carry, :not_carry, :zero, :not_zero, :negative, :not_negative のいずれか )

    def initialize( kind, id, type, val, opt )
      raise "invalid type, #{type}" unless Type === type
      unless [:arg, :result, :var, :temp, :const, :symbol, :global_var, :global_const, :global_symbol].include?( kind )
        raise "invalid kind, #{kind}" 
      end
      @kind = kind
      @id = id
      @type = type
      @val = val
      @opt = opt || Hash.new
    end

    def assignable?
      [:arg, :result, :var, :global_var].include?( @kind )
    end
    
    def const?
      [:const, :global_const ].include?( @kind )
    end
    
    def symbol?
      [:symbol, :global_symbol ].include?( @kind )
    end

    def to_s
      "#{id}:#{type}"
    end

  end

  ######################################################################
  # 値そのもの
  ######################################################################
  class Value
    attr_reader :kind # 種類( :val, :id のいずれか )
    attr_reader :type # Type
    attr_reader :id   # 識別子( kind == :idのときのみ )
    attr_reader :val  # 値( kind == :literalのときのみ )

    def initialize( id_or_val )
      if Identifier === id_or_val
        @kind = :id
        @type = id.type
        @id = id
      elsif Fixnum === id_or_val
        @kind = :val
        @type = Type[:int]
        @val = id_or_val
      else
        raise "invalid id or val #{id_or_val}"
      end
    end

    def to_s
      if @kind == id
        "#{id}"
      else
        "#{val}"
      end
    end
    
  end

  ######################################################################
  # モジュール
  ######################################################################
  class Module
    attr_reader :vars, :lambdas, :opt, :includes

    def initialize
      @vars = Hash.new
      @lambdas = []
      @opt = Hash.new
      @includes = []
    end

  end

  ######################################################################
  # 関数
  ######################################################################
  class Lambda
    attr_reader :id, :args, :type, :opt, :ast, :ops

    def initialize( id, args, base_type, opt, ast )
      @id = id
      @args = args
      @type = Type[[:lambda, args.map{|arg|arg[1]}, base_type]]
      @opt = opt || Hash.new
      @ast = ast
      @ops = []
    end

    def to_s
      "<Lambda:#{@id} #{@type}>"
    end
  end


end
