require 'erb'

module Pandora::CodeGen::Generator
  class CSharpGenerator
    def initialize
      @erb_cls = ERB.new(IO.read('gen_cs.erb'), trim_mode: '-')
      @erb_cls.filename = 'gen_cs.erb'
      @s = []
    end

    def generate(ast)
      gen_table(ast)
    end

    def gen_table(prog)
      keys = []
      prog.tables.each do |t|
        keys << [t.idx, t.name];
        keys.concat(t.decls.map {|d| [d.idx, t.name + '_' + param_funcname(d.params)] })
      end
        
      e = @erb_cls
      @erb_cls.result(binding)
    end

    def param_funcname(params)
      params.map do |p|
        "#{p.name}"
      end.join('')
    end
    
    def param_args(params, len, is_range = true)
      params[0,len].map.with_index do |p,i|
        if is_range && i == len-1
          "#{type_exp_class(p.type)} #{p.name}"
        else
          "#{p.type} #{p.name}"
        end
      end.join(',')
    end

    def keyname(t, decl)
      "#{t.name}_#{param_funcname(decl.params)}"
    end

    def param_make_key_save(table, decl, prefix: nil)
      r = []
      r << "kb.Cleared().Store(Keys.#{keyname(table, decl)})"
      r << decl.params.map.with_index do |tn,i|
        ".Store(#{prefix}#{tn[1]})"
      end
      r << ".Store(#{prefix}#{table.key[0][1]})"
      r << '.Build()'
      r.flatten.join
    end

    def param_make_key(table, decl, len=nil, field=nil)
      len ||= decl.params.size
      r = []
      r << "kb.Cleared().Store(Keys.#{keyname(table, decl)})"
      r << decl.params[0,len].map.with_index do |tn,i|
        if field && i == len-1
          ".Store(#{tn[1]}.#{field})"
        else
          ".Store(#{tn[1]})"
        end
      end
      r << '.Build()'
      r.flatten.join
    end

    def type_exp_class(type)
      "Range<#{type}>"
    end
    
  end
end
