require 'pp'
require 'ostruct'
require 'optparse'
require './vfs'

def filter_svn(vfs)
  VFS.filter(vfs) do |d, ancestors| 
    if d.name == '.svn'
      VFS.skip
    else
      true
    end
  end
end

def filter_orig(vfs)
  VFS.filter(vfs) do |d, ancestors| 
    fp = d.fullpath
    if false && ancestors[1] && ancestors[1].name == 'data'
      VFS.skip
    elsif fp == '/data/text/work/'
      VFS.skip
    elsif fp.start_with?('/project/') && !fp.start_with?('/project/data/WIN/')
      false
    elsif fp.start_with?('/project/')
      true
    elsif fp.start_with?('/data_model/')
      if ['ps4','vita'].include?(d.name)
        VFS.skip
      else
        true
      end
    elsif d.directory? && ['PS4', 'VITA', 'output', 'flash_output', 'tmp', 'xml_lib2', 'game_resident', 'mastering'].include?(d.name)
      VFS.skip
    elsif ['.psd', '.psb', '.srdv', '.srdi', '.srd'].include?(d.extname)
      false
    else
      true
    end
  end
end

def calc_total(vfs)
  data = Hash.new{|h,k| h[k] = OpenStruct.new(size:0, count:0, sample:[]) }
  n = 0
  VFS.walk(vfs, after: true) do |f|
    d = data[f.extname]
    d.count += 1
    d.size += f.size
    d.sample << f.fullpath if d.sample.size < 3
    if f.directory?
      f.attr[:total_size] = f.children.values.reduce(0){|m,c| m + c.attr[:total_size] }
      f.attr[:total_count] = f.children.values.reduce(0){|m,c| m + c.attr[:total_count] }
    else
      f.attr[:total_size] = f.size
      f.attr[:total_count] = 1
    end
  end
  $ext_stat = data
end

def cmd_dir_summary
  VFS.walk($vfs) do |f, ancestors|
    next unless f.directory?
    VFS.skip if ancestors.size >= 3 || f.attr[:total_size] <= 100_000_000
    puts "%8d %s" % [f.attr[:total_size] / 1_000_000, f.fullpath]
  end
end

def cmd_large_dir
  VFS.walk($vfs) do |f, ancestors|
    next unless f.directory? 
    VFS.skip if f.attr[:total_size] <= 400_000_000
    puts "%8d %s" % [f.attr[:total_size] / 1_000_000, f.fullpath]
  end
end

def cmd_ext_stat
  puts( "%-10s %6s %12s %8s %s" % ['ext', 'count', 'total[MB]', 'mean[KB]', 'path(s)'] )
  puts '-'*80
  $ext_stat.sort_by{|k,d| d.size }.reverse.take($num).each do |k,d|
    puts( "%-10s %6d %12d %8d %s" % [k, d.count, d.size/1000_000, d.size / d.count / 1000, d.sample.join(',')] )
  end
end

def cmd_ls
  VFS.walk($vfs) do |f, ancestors|
    next if f.directory?
    puts f.fullpath
  end
end

def cmd_cp
  require 'fileutils'
  VFS.walk($vfs) do |f, ancestors|
    next if f.directory? || f.size == 0
    out = "E:/V3NEW" + f.fullpath
    unless File.exist?(out)
      FileUtils.mkdir_p File.dirname(out), verbose: false
      FileUtils.cp "D:/Dangan/Dangan3/V3OUT" + f.fullpath, out, preserve: true, verbose: true
    end
  end
end

DEFAULT_COMMANDS = ['ext_stat', 'large_dir', 'dir_summary']
ALL_COMMANDS = DEFAULT_COMMANDS + ['ls', 'cp']


def main
  $num = 10
  $vfs_file = 'v3out.vfs'
  root = nil
  no_filter = false

  op = OptionParser.new("ruby #{$0} [options ...] (#{ALL_COMMANDS.join('|')}) ...")
  op.on('--all', 'フィルタ'){ no_filter = true }
  op.on('--root=root_directory', 'ルートを指定'){|v| root = v }
  op.on('-n:', '表示数'){|v| $num = v.to_i }
  op.on('-f:', '対象のファイル'){|v| $vfs_file = v }
  op.parse!

  if ARGV.empty?
    cmds = DEFAULT_COMMANDS
  else
    cmds = ARGV
  end

  vfs = VFS.load(IO.binread($vfs_file))

  puts root
  vfs = vfs[root] if root

  vfs = filter_svn(vfs)

  vfs = filter_orig(vfs) unless no_filter

  calc_total(vfs)

  puts "total %d files, %d MB" % [vfs.attr[:total_count], vfs.attr[:total_size] / 1000_000]

  $vfs = vfs

  cmds.each do |cmd|
    puts "---- #{cmd} ----"
    method('cmd_'+cmd).call
  end
end

main


