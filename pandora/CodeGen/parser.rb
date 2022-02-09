require 'strscan'
require_relative 'parse.tab.rb'

module Pandora::CodeGen 
  class Parser
    def initialize(src, filename = "<unknown>")
      @filename = filename
      @src = src
      @ss = StringScanner.new(src)
      @line = 1
      @pos = 0
    end

    def parse
      do_parse
    end

    def list(val)
      [val[0]].concat(val[1])
    end

    def list2(val)
      [val[0]].concat(val[2])
    end
    
    def on_error(t, val, vstack)
      # pp [t,val, vstack]
      STDERR.puts "#{@filename}:#{@line}:#{@pos}: parse error on '#{val}'."
    end

    def scan(regex)
      matched = @ss.scan(regex)
      if matched
        line_num = matched.count("\n")
        @line += line_num
        if line_num > 0
          @pos = matched.size - matched.rindex("\n")
        else
          @pos += matched.size
        end
      end
      matched
    end
    
    def next_token
      scan(/(\s+|\/\/[^\n]*\n)+/)

      if @ss.eos?
        r = nil
      elsif t = scan(/\(|\)|{|}|;|\[|\]|,/)
        r = [t, t]
      elsif t = scan(/index|table|key|namespace|for|object/)
        r = [t, t]
      elsif t = scan(/\d+/)
        r = [:NUMBER, t.to_i]
      elsif t = scan(/\w+\.[\w\.]+/)
        r = [:NAMESPACE, t]
      elsif t = scan(/\w+/)
        r = [:IDENT, t]
      else
        raise
      end
      # p r
      r
    end
  end

  class AST < Struct.new(:namespace, :decls)
    attr_reader :tables, :objects, :keys
    
    def analyze
      @keys = []
      @tables = []
      @objects = {}
      decls.each do |decl|
        case decl
        when Table
          @tables << decl
        when ObjectDecl
          @objects[decl.name] = decl
        else
          raise
        end
      end
      @objects.each { |_,obj| obj.analyze(self) }
      @tables.each { |t| t.analyze(self) }
    end
  end
  
  class ObjectDecl < Struct.new(:name, :fields)
    attr_reader :fields_hash
    def analyze(ast)
      @fields_hash = {}
      fields.each do |f|
        @fields_hash[f.name] = f
      end
    end
  end
  
  class Table < Struct.new(:idx, :name, :cls_name, :key_names, :indices)
    attr_reader :cls, :key
    def analyze(ast)
      @cls = ast.objects[cls_name]
      @key = Key.new(true, idx, cls, key_names)
      ast.keys << key
      indices.each { |idx| idx.analyze(ast, self) }
    end
  end
  
  class Index < Struct.new(:idx, :key_names, :options)
    attr_reader :key
    def analyze(ast, table)
      @key = Key.new(false, idx, table.cls, key_names)
      ast.keys << key
    end
  end

  Param = Struct.new(:type, :name)
  
  class Key < Struct.new(:is_primary_key, :idx, :cls, :key_names)
    attr_reader :fields
    def initialize(*args)
      super
      @fields = key_names.map do |name|
        cls.fields_hash[name]
      end
    end

  end
  
  class Type
    MAPPING = {
      'int'=>[:int32,4],
      'uint'=>[:uint32,4],
      'string'=>[:string,0],
    }

    attr_reader :size

    def initialize(_name)
      @name, @size = MAPPING[_name]
      raise unless @name
    end

    def name
      @name.to_s
    end

    alias to_s name
    alias inspect name
  end
end

