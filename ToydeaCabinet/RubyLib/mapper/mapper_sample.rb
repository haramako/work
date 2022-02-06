# coding: utf-8
# frozen_string_literal: true

#
# DSLのサンプル
#

require './codegen'

mapper 'MapperSample' do
  column 1, :int32, 'hp'
  column 2, :int32, 'attack'
  column 3, :string, 'name'
  list 4, 'MapperSampleUtil.Item', 'items', %w[id item_id]
end

if $0 == __FILE__
  emit 'using Message = MapperSampleUtil.Message;'
  puts CsharpGenerator::DSL.generate
end
