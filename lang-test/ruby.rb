# coding: utf-8
require 'pp'

a = 0

def foo
  puts a
end

foo rescue nil


A = 0

def bar
  puts A
end

bar


# 定数のスコープ
#
# See: [変数と定数 \(Ruby 3\.0\.0 リファレンスマニュアル\)](https://docs.ruby-lang.org/ja/latest/doc/spec=2fvariables.html)
# 親クラスの定数は直接参照できる
# ネストしたクラスはクラスの継承関係上は無関係であるがネストの外側の定数も直接参照できる
# トップレベルの定数定義はネストの外側とはみなされません
#
# See: [Rubyの定数が怖いなんて言わせない \- Qiita](https://qiita.com/fursich/items/a1b742795cf10eebc73f)

GLOBAL_CONSTANT = 2

module Hoge
  # GLOBAL_CONSTANT = 4
  HOGE_CONSTANT = 1
  
  class Fuga
    FUGA_CONSTANT = 3
    
    def initialize
      puts HOGE_CONSTANT
      puts GLOBAL_CONSTANT
    end
  end

  class FugaDerived < Fuga
    
    def initialize
      puts HOGE_CONSTANT
      puts GLOBAL_CONSTANT
      puts FUGA_CONSTANT
    end
  end
  
end

module Hoge
  class Piyo
    puts HOGE_CONSTANT
  end
end

Hoge::Fuga.new
Hoge::FugaDerived.new

pp Hoge::Fuga


# ローカル変数とメソッドのスコープ

puts '='*80
puts 'local scope'

class LocalScope
  attr_accessor :prop

  def initialize
    @prop = 1
  end

  def method
    puts 'method'
    puts prop
  end
  
  def hidden_method
    puts 'hidden_method'
    puts "prop = #{defined?(prop)} #{prop}, self.prop = #{self.prop}" # ローカル変数がないなら、propは自動的にself.prop扱いになる
    prop = 2 # ローカル変数が作成された後は、selfなしのpropは、ローカル変数になる
    puts "prop = #{defined?(prop)} #{prop}, self.prop = #{self.prop}"
  end

  def block_scope
    puts 'block scope'
    a = 1
    1.times do
      puts a
      a = 2
    end
    puts a
  end

  x = 1
  puts "class definition scope x = #{defined?(x)} #{x}, self = #{self}" # クラス定義スコープ
end

obj = LocalScope.new
obj.method
obj.hidden_method
obj.block_scope
