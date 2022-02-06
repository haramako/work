# frozen_string_literal: true

require './mapper_sample'
require './toydea_cabinet'
require 'pp'
require 'yaml'

module MapperSampleUtil
  class Item
    attr_reader :id, :item_type

    def initialize; end

    def self.parse(bin)
      Item.new.merge_from(bin)
    end

    def merge_from(bin)
      r = ToydeaCabinet::Reader.new
      r.f = StringIO.new(bin)
      @id = r.read_int
      @item_type = r.read_int
    end
  end
end

def parse(type, bin)
  case type
  when :int32
    r = ToydeaCabinet::Reader.new
    r.f = StringIO.new(bin)
    r.read_int
  when :string
    bin.encode(Encoding::UTF_8)
  else
    t = Kernel.const_get(type.gsub(/\./, '::'))
    t.parse(bin)
  end
end

def load(mapper, data)
  r = {}
  data.each do |k, v|
    tag = k.getbyte(0)
    column = mapper.tags[tag]
    val = parse(column.type, v)
    key = column.name
    case column.kind
    when :single
      r[key] = val
    when :list
      r[key] ||= {}
      rest_key = k[1, 4].unpack('N')[0]
      r[key][rest_key] = val
    else
      raise
    end
  end
  r
end

data = open('mapper.tc', 'rb') { |f| ToydeaCabinet::Reader.new.read(f) }

mapper = CsharpGenerator::DSL.mappers[0]
kvs = load(mapper, data)
puts YAML.dump(kvs)
