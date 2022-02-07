require 'erb'

module Pandora::CodeGen::Generator
  class CSharpGenerator
    def initialize
      @erb_cls = ERB.new(IO.read('gen_cs.erb'), trim_mode: '-')
      @s = []
    end

    def generate(ast)
      gen_table(ast)
    end

    def emit(s)
      @s << s
    end

    def gen_table(t)
      e = @erb_cls
      @erb_cls.result(binding)
    end

    def param_funcname(params)
      params.map do |p|
        "#{p.name}"
      end.join('')
    end
    
    def param_args(params)
      params.map do |p|
        "#{type_exp_class(p.type)} #{p.name}"
      end.join(',')
    end

    def type_exp_class(type)
      "Range<#{type}>"
    end
  end
end
