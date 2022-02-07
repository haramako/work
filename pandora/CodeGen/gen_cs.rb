require 'erb'

module Pandora::CodeGen::Generator
  class CSharpGenerator
    def initialize
      @erb = ERB.new(IO.read('gen_cs.erb'), trim_mode: '-')
      @erb.filename = 'gen_cs.erb'
      @s = []
    end

    def generate(ast)
      gen_table(ast)
    end

    def gen_table(prog)
      keys = []
      prog.tables.each do |t|
        keys << [t.idx, t.name];
        keys.concat(t.indices.map {|d| [d.idx, t.name + '_' + d.funcname] })
      end
        
      @erb.result(binding)
    end

  end
end

# Extensions
module Pandora::CodeGen

  class Table

    def make_key_save
      "kb.Cleared().Store(Keys.#{name}).Store(v.#{key[0][1]}).Build()"
    end

    def key_func_args
      "#{key[0].type} #{key[0].name}"
    end
  end
  
  class Index
    def funcname
      params.map do |p|
        "#{p.name}"
      end.join('')
    end

    def type_exp_class(type)
      "Range<#{type}>"
    end
    
    def func_args(len, is_range = true)
      params[0,len].map.with_index do |p,i|
        if is_range && i == len-1
          "#{type_exp_class(p.type)} #{p.name}"
        else
          "#{p.type} #{p.name}"
        end
      end.join(',')
    end

    def keyname(table)
      "#{table.name}_#{funcname}"
    end

    def make_key_save(table, prefix: nil)
      r = []
      r << "kb.Cleared().Store(Keys.#{keyname(table)})"
      r << params.map.with_index do |tn,i|
        ".Store(#{prefix}#{tn[1]})"
      end
      r << ".Store(#{prefix}#{table.key[0][1]})"
      r << '.Build()'
      r.flatten.join
    end

    def make_key(table, len=nil, field=nil)
      len ||= params.size
      r = []
      r << "kb.Cleared().Store(Keys.#{keyname(table)})"
      r << params[0,len].map.with_index do |tn,i|
        if field && i == len-1
          ".Store(#{tn[1]}.#{field})"
        else
          ".Store(#{tn[1]})"
        end
      end
      r << '.Build()'
      r.flatten.join
    end

    def index_size
      1 + params.sum{|p| p.type.size}
    end
  end

  class Type
    def to_s
      case @name
      when :int32
        'int'
      when :uint32
        'uint'
      when :string
        'string'
      else
        raise
      end
    end
  end
end


