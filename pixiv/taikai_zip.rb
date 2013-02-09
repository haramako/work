#!/bin/env ruby

Dir.chdir '/tmp/walker/img/www.taikaisyu.com/00roc'
Dir.glob '*' do |path|
  # next unless /^[\d-]+$/ === path
  puts path
  system "zip -r taikaishu-#{path}.zip #{path}"
end
