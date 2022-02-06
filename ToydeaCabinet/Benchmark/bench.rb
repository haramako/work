# frozen_string_literal: true

require 'benchmark'
require 'open3'

include Benchmark

# rubocop: disable Metrics/ParameterLists

def sys(*args)
  out, stat = Open3.capture2(*args.reject(&:nil?).map(&:to_s))
  if stat != 0
    puts out
    raise
  end
  # puts out
end

bm 10 do |r|
  storages = ['f'] # ['m','f']
  flashs = [false] # [false, true]
  commits = [1, 10, 1000]
  ns = [10**4, 10**6]
  cs = [10_000] # [1000, 10_000, 100_000]
  rss = [16] # [8,256]
  factors = [4] # [2,4,8,16]

  ns.product(cs).each do |n, c|
    r.report("|golevel n=%10d c=%7d|" % [n, c]) do
      sys('golevel.exe', n, c) rescue nil
    end
  end

  storages.product(commits, ns, cs, rss, flashs, factors).each do |storage, commit, n, c, rs, flash, factor|
    r.report("|s=%s n=%10d commit=%4d c=%7d r=%6d flash=%5s fct=%d|" % [storage, n, commit, c, rs, flash, factor]) do
      sys(
        'dotnet', '../Client/bin/Release/netcoreapp2.1/pdcli.dll', 'bench',
        '-s', storage,
        '-n', n,
        '-r', rs,
        '--commit', commit,
        '-c', c,
        (flash ? '--flash' : nil),
        '--factor', factor
      )
    end
  end
end
