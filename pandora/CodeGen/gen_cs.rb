require 'erb'

module Pandora::CodeGen::Generator
  class CSharpGenerator
    attr_reader :ast
    
    def initialize
      @erbs = {}
    end

    def generate(ast)
      partial(:gen_cs, {ast: ast})
    end

    def partial(template,vars)
      erb = @erbs[template]
      unless erb
        filename = template.to_s + '.erb'
        erb = ERB.new(IO.read(filename), trim_mode: '-')
        erb.filename = filename
        @erbs[template] = erb
      end
      
      vars[:gen] = self
      erb.result_with_hash(vars)
    end

  end
end

# Extensions
module Pandora::CodeGen

  class Table
  end

  class Entity
  end

  class Field
    def fname
      "_#{name.downcase}"
    end
    def old_name
      "_old#{name}"
    end
    def frozen_name
      "_frozen#{name}"
    end
    def pname
      name
    end
  end
  
  class Index

    def type_exp_class(type)
      "Range<#{type}>"
    end
    
  end

  class Key
    def func_args(len = fields.size, is_range: true)
      fields[0,len].map.with_index do |f,i|
        if is_range && i == len-1
          "#{f.type.range_type} #{f.name}"
        else
          "#{f.type} #{f.name}"
        end
      end.join(',')
    end

    def funcname
      key_names.join
    end
    
    def keyname
      "#{cls.name}_#{funcname}"
    end

    def index_size
      1 + fields.sum{|f| f.type.size}
    end

    def make_get_key(len=fields.size, access_field = nil)
      make_key(len, access_field: access_field)
    end
    
    def make_put_key(prefix)
      make_key(fields.size, prefix: prefix)
    end
    
    def make_key(len, access_field: nil, prefix: nil)
      r = []
      r << "kb.Cleared().Store(Keys.#{keyname})"
      r << fields[0,len].map.with_index do |f,i|
        if access_field && i == len-1
          ".Store(#{f.name}.#{access_field})"
        else
          ".Store(#{prefix}#{f.name})"
        end
      end
      if prefix && !is_primary_key
        r << ".Store(v.Id)"
      end
      r << '.Build()'
      r.flatten.join
    end

    def make_diff_cond(a,b)
      fields.map do |f|
        "#{a}.#{f.name} != #{b}.#{f.name}"
      end.join(' || ')
    end

  end

  class Type
    NAMES = {
      int32: ['int', 'Int32'],
      uint32: ['uint', 'Int32'],
      string: ['string', 'String']
    }
    def to_s
      NAMES[@name][0]
    end

    # Name in type part of function.
    def funcname
      NAMES[@name][1]
    end

    def range_type
      "Range<#{to_s}>"
    end
  end
end


