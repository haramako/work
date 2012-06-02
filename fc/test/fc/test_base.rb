# coding: utf-8

require 'rspec'
require '../lib/fc/base'

include Fc

describe Type, 'when initialize' do

  it 'as void' do
    v = Type[ :void ]
    v.type.should == :void
    v.base.should == nil
    v.size.should == 1
  end

  it 'as bool' do
    v = Type[ :bool ]
    v.type.should == :bool
    v.base.should == nil
    v.size.should == 1
  end

  it 'as int' do
    v = Type[ :int ]
    v.type.should == :int
    v.signed.should == false
    v.base.should == nil
    v.size.should == 1
  end

  it 'as array' do
    v = Type[ [:array, 10, :int16 ] ]
    v.type.should == :array
    v.base.should == Type[:int16]
    v.length.should == 10
    v.size.should == 20
  end

  it 'as pointer' do
    v = Type[ [:pointer, :int ] ]
    v.type.should == :pointer
    v.size.should == 2
    v.base.should == Type[:int]
  end

  it 'as lambda' do
    v = Type[ [:lambda, [Type[:int], Type[:int]], [:pointer, :int] ] ]
    v.type.should == :lambda
    v.size.should == 2
    v.base.should == Type[ [:pointer,:int] ]
    v.args.should == [ Type[:int], Type[:int] ]
  end

  it 'as complex type' do
    v = Type[ [:array, 10, [:pointer, [:array, 2, :int] ] ] ]
    v.to_s.should == 'int[2]*[10]'
  end

end
