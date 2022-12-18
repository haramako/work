require "time"
require "find"
require "digest/md5"
require_relative "node"

# Virutal File System
module VFS
  module_function

  def load(bin)
    Serializer.new.load(bin)
  end

  def dump(node)
    Serializer.new.dump(node)
  end

  def read_dir(path, **opt)
    FileSystem.new.read_dir(path, **opt)
  end

  def open(path)
    FileSystem.new.open(path)
  end

  def skip
    raise Node::WalkSkip.new
  end

  def diff(node1, node2, &block)
    block ||= proc { |n1, n2| n1.nil? || n2.nil? }

    h1 = VFS.to_hash(node1)
    h2 = VFS.to_hash(node2)
    diff = {}
    (h1.keys + h2.keys).sort.each do |key|
      n1 = h1[key]
      n2 = h2[key]
      if block.call(n1, n2)
        diff[key] = [n1, n2]
      end
    end
    diff
  end

  def aggregate(fs)
    fs.walk(after: true) do |f|
      if f.directory?
        f.clear_aggregation
        f.children.values.each do |c|
          f.size += c.size
          c.stat.each do |k, v|
            f.stat[k] = (f.stat[k] || 0) + v
          end
        end
      end
    end
  end
end
