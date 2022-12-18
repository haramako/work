# hoge

require "optparse"

require_relative "vfs"

IGNORED = ["tmp", "vendor", "font.gen.c"]

def view(path, summary)
  fs = VFS.open(path)
  fs = VFS.filter(fs) do |f, _|
    if IGNORED.include?(f.name) then VFS.skip else true end
  end
  VFS.aggregate(fs)

  code_size = 0 # fs.stat[:code] + fs.stat[:blank] + fs.stat[:comment]
  code_ratio = 100.0 * (fs.stat[:code] || 0) / code_size
  comment_ratio = 100.0 * (fs.stat[:comment] || 0) / code_size
  blank_ratio = 100.0 * (fs.stat[:blank] || 0) / code_size

  if summary
    puts "%-30s line %8d, code %4.1f%%, comment %4.1f%%, blank %4.1f%%" % [path, fs.stat[:code], code_ratio, comment_ratio, blank_ratio]
    return
  end
  puts "=" * 40
  puts path
  puts "code %3.1f%%, comment %3.1f%%, blank %3.1f%%" % [code_ratio, comment_ratio, blank_ratio]

  puts "-" * 40
  total_size = (fs.size || 0)
  puts total_size
  VFS.walk(fs) do |f, ancesters|
    # next unless f.directory?
    # next if !f.directory? && (f.stat[:code] || 0) < total_size * 0.05
    next if (f.size || 0) < total_size * $threshold

    puts "%10d %10d %s" % [f.size / 1024, f.stat[:code] || 0, f.fullpath]
    if (f.size || 0) < total_size * $threshold
      VFS.skip
    end
    true
  end
end

$threshold = 0.1
op = OptionParser.new
op.on("--summary") { $summary = true }
op.on("-t:", "--threshold", "% of show threshold") { |v| $threshold = v.to_i / 100.0 }
op.parse!
view(ARGV[0], $summary)
