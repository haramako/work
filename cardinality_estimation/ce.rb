#!/usr/bin/env ruby
# coding: utf-8

# cardinality estimation (基数見積り) の実験
# http://metamarkets.com/2012/fast-cheap-and-98-right-cardinality-estimation-for-big-data/
require 'pp'

m = 2**16
alpha_m = 0.7213/(1+1.079/m)

tbl = Hash.new
bucket = Array.new(m){0}

100.times do
  n = rand(2**28)
  tbl[n] = 1
  high = n % m
  low = ('%016b'%[n / m]).reverse.match(/^0*/)[0].length
  bucket[high] = [bucket[high],low+1].max
end

e = 0.0
bucket.each do |x|
  e += 2 ** (-x)
end
# pp [m,alpha_m,e]
e = alpha_m * (m**2) / e
# pp e
if e < m*5/2
  v = bucket.count(0)
  e = m*Math.log(1.0*m/v) if v != 0
end
pp e
pp e / tbl.size
