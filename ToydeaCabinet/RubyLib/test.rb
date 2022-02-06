# frozen_string_literal: true

require './toydea_cabinet'
require 'net/http'
require 'json'

c = ToydeaCabinet::Cabinet.new('hoge.tc')

c2 = ToydeaCabinet::Cabinet.new
r = ToydeaCabinet::Reader.new
chunks = r.split_chunks(IO.binread('hoge.tc'))

def post(url, session_key = nil, body = nil)
  body = JSON.dump(body) if body.is_a? Hash
    
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri.path)
  req['Content-Type'] = 'application/octet-stream'
  req['X-Tc-Session-Key'] = session_key if session_key
  req.body = body if body
  res = http.request(req)
  raise "error in #{url} #{res.code}" if res.code.to_i >= 400
  res.body
end

def get(url)
  Net::HTTP.get(URI.parse(url))
end

d2 = {}
res = JSON.parse(post("http://localhost:4567/api/u/1/login", nil, {name:'test'}))
session_key = res['sessionKey']

puts post("http://localhost:4567/api/u/1/dump", session_key, IO.binread('hoge.tc'))

chunks.each_slice(3).each do |chunk|
  header = "TC\x01"
  bin = ([header] + chunk).join
  r.merge_commit(d2, bin)
  # p [r.first_commit, r.last_commit]
  post("http://localhost:4567/api/u/1/commit", session_key, bin)
end

dump = get('http://localhost:4567/u/1/bdump/110')
c2 = ToydeaCabinet::Cabinet.new(StringIO.new(dump))

puts "#{d2.size} #{c.data.size} #{c2.data.size}"

100.step(110, 1) do |n|
  dump = get("http://localhost:4567/u/1/bdump/#{n}")
  next if dump.size <= 0
  c2 = ToydeaCabinet::Cabinet.new(StringIO.new(dump))
  p [n, c2.data.size]
end
