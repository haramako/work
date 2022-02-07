require 'strscan'
require_relative 'parse.tab.rb'

module Pandora::CodeGen 
  class Parser
    def initialize(src)
      @ss = StringScanner.new(src)
    end

    def parse
      do_parse
    end

    def next_token
      @ss.scan(/(\s+|\/\/[^\n]*\n)+/)

      if @ss.eos?
        r = nil
      elsif t = @ss.scan(/\(|\)|{|}|;|\[|\]|,/)
        r = [t, t]
      elsif t = @ss.scan(/index|table|key|namespace/)
        r = [t, t]
      elsif t = @ss.scan(/\d+/)
        r = [:NUMBER, t.to_i]
      elsif t = @ss.scan(/\w+\.[\w\.]+/)
        r = [:NAMESPACE, t]
      elsif t = @ss.scan(/\w+/)
        r = [:IDENT, t]
      else
        raise
      end
      # p r
      r
    end
  end

  Prog = Struct.new(:namespace, :tables)
  Table = Struct.new(:idx, :name, :cls, :key, :indices)
  Index = Struct.new(:idx, :params, :options)
  Param = Struct.new(:type, :name)
  
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

