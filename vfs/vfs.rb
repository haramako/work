require "time"
require "find"
require "digest/md5"

# Virutal File System
module VFS

  # ノード
  # 一つのファイルかディレクトリを表す
  class Node
    attr_reader :name
    attr_reader :parent
    attr_reader :children
    attr_reader :attr
    attr_reader :stat

    attr_accessor :md5
    attr_accessor :size
    attr_accessor :mtime

    def basename
      File.basename(@name)
    end

    def extname
      File.extname(@name)
    end

    def initialize(parent, name)
      @parent = parent
      @name = name
      @size = 0
      @md5 = nil
      @mtime = nil
      @children = {}
      @attr = {}
      @stat = {}

      @parent.children[name] = self if @parent
    end

    def fullpath
      if @parent
        @parent.fullpath + @name + (directory? ? "/" : "")
      else
        "/"
      end
    end

    def directory?
      @children.size > 0
    end

    def to_s
      "#{@name} #{@size} #{@md5}"
    end

    def [](path)
      VFS.resolve_path(self, path)
    end

    def copy_from(node)
      @size = node.size
      @md5 = node.md5
      @mtime = node.md5
      @attr = node.attr
      @stat = node.stat
    end
  end

  module_function

  def load(bin)
    load_inner(nil, Marshal.load(bin))
  end

  def load_inner(parent, data)
    node = Node.new(parent, data[1])
    if data[0] == 1
      # directory
      data[2].each { |d| load_inner(node, d) }
    else
      # file
      node.size = data[2]
      node.mtime = Time.at(data[3])
      node.md5 = data[4]
      node.instance_eval do
        @attr = data[5]
        @stat = data[6]
      end
    end
    node
  end

  private :load_inner

  def dump(node)
    Marshal.dump(dump_inner(node))
  end

  def dump_inner(node)
    if node.directory?
      [1, node.name, node.children.values.map { |c| dump_inner(c) }]
    else
      [0, node.name, node.size, node.mtime.to_i, node.md5, node.attr, node.stat]
    end
  end

  private :dump_inner

  # ディレクトリを指定して、Nodeを取得する
  def read_dir(path, hash: true)
    Dir.chdir(path) do
      root = Node.new(nil, "")
      n = 0
      Find.find(".") do |f|
        next if File.directory?(f)
        file = VFS.resolve(root, f, mkdir: true)
        begin
          stat = File.stat(f)
        rescue Errno::ENOENT
          puts $!
          next
        end
        file.size = stat.size
        file.mtime = stat.mtime
        if hash
          file.md5 = Digest::MD5.file(f).hexdigest
        end
        STDERR.puts("reading #{n} files") if n % 1000 == 0
        n += 1
      end
      root
    end
  end

  def open(path)
    if File.directory?(path)
      vfs_path = path + "/.vfs"
    else
      vfs_path = path
    end

    unless File.exist?(vfs_path)
      fs = VFS.read_dir(path, hash: false)
      fs = VFS::Command.filter_ignored(fs)
      Dir.chdir(path) do
        VFS::Command.stat_cloc(fs)
      end
      IO.binwrite vfs_path, VFS.dump(fs)
    end

    VFS.load(IO.binread(vfs_path))
  end

  class WalkSkip < Exception; end

  def walk(node, after: false, &block)
    walk_inner(node, [], after, &block)
  end

  def walk_inner(node, cur, after, &block)
    unless after
      begin
        block.call(node, cur)
      rescue WalkSkip
        return # 子供を調べない
      end
    end

    unless node.children.empty?
      cur.push node
      node.children.values.each do |c|
        walk_inner(c, cur, after, &block)
      end
      cur.pop
    end

    block.call(node, cur) if after
  end

  private :walk_inner

  def skip
    raise WalkSkip.new
  end

  # 特定の条件のノードのみを抽出する
  def filter(node, &block)
    root = Node.new(nil, "")
    walk(node) do |cur, ancestors|
      ok = block.call(cur, ancestors)
      if ok
        #puts cur.fullpath
        new_node = resolve(root, cur.fullpath, mkdir: true)
        new_node.copy_from(cur)
      end
    end
    root
  end

  def to_list(node)
    r = []
    walk(node) do |n|
      next if n.size == 0
      r << [n.fullpath, n]
    end
    r
  end

  def to_hash(node)
    r = {}
    walk(node) do |n|
      next if n.size == 0
      r[n.fullpath] = n
    end
    r
  end

  def resolve(node, path, mkdir: false)
    path = path.split("/") if path.is_a?(String)
    resolve_inner(node, path, mkdir)
  end

  def resolve_inner(node, path, mkdir)
    if path.empty?
      node
    else
      name = path.shift
      return resolve_inner(node, path, mkdir) if name == "." || name == "" # '.' は特別にカレントディレクトリ

      cur = node.children[name]

      # mkdirモードなら、ないディレクトリを作る
      if mkdir && !cur
        cur = Node.new(node, name)
        #p "new node #{name}"
      end

      if cur
        resolve_inner(cur, path, mkdir)
      else
        raise "invalid path #{path}"
      end
    end
  end

  private :resolve_inner

  def display(node)
    walk(node) do |n, ancestors|
      puts (" " * (ancestors.size * 2)) + n.name + " " + n.size.to_s
    end
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

  def resolve_path(node, path)
    names = path.split("/")
    cur = node
    names.each do |name|
      case name
      when "."
        cur = cur
      when ".."
        cur = cur.parent
      else
        cur = cur.children[name]
      end
    end
    cur
  end

  def aggregate(fs)
    VFS.walk(fs, after: true) do |f|
      if f.directory?
        f.size = 0
        f.children.values.each do |c|
          f.size += c.size
          c.stat.each do |k, v|
            f.stat[k] = (f.stat[k] || 0) + v
          end
        end
      end
    end
  end

  # コマンドとして実行するクラス
  class Command
    def initialize(args)
      require "optparse"
      if RUBY_PLATFORM =~ /mingw/
      end
      @diff_by = :md5
      @opt_d = false
      op = OptionParser.new
      op.on("--size", "diff by size") { @diff_by = :size }
      op.on("-d", "directory only") { @opt_d = true }
      @args = op.parse(args)
      @subcommand = @args.shift
    end

    def run
      case @subcommand
      when "ls"
        run_ls(@args)
      when "dump"
        run_dump(@args)
      when "diff"
        run_diff(@args)
      when nil
        puts op
        exit
      else
        raise "unknown subcommand #{subcommand}"
      end
    end

    def find_vfs(path)
      if File.directory?(path)
        path + "/.vfs"
      else
        path
      end
    end

    def run_ls(args)
      fs = VFS.load(IO.binread(find_vfs(args[0])))
      VFS.aggregate(fs)
      VFS.walk(fs) do |f|
        next if @opt_d && !f.directory?
        # puts f.fullpath
        puts("%-60s %8d %8d" % [f.fullpath, f.size, f.stat[:code] || 0])
      end
    end

    def run_dump(args)
      fs = VFS.read_dir(args[0], hash: true)
      fs = VFS::Command.filter_ignored(fs)
      Dir.chdir(args[0]) do
        VFS::Command.stat_cloc(fs)
      end
      IO.binwrite (args[1] || find_vfs(args[0])), VFS.dump(fs)
    end

    def run_diff(args)
      fs1 = VFS.load(IO.binread(find_vfs(args[0])))
      fs2 = VFS.load(IO.binread(find_vfs(args[1])))
      diff = VFS.diff(fs1, fs2) do |n1, n2|
        next true if n1.nil? || n2.nil?
        next true if @diff_by == :md5 && n1.md5 != n2.md5
        next true if @diff_by == :size && n1.size != n2.size
        false
      end

      diff.each do |k, v|
        if v[0] && v[1]
          if @diff_by == :md5
            puts "M %-80s %32s %32s" % [k, v[0] && v[0].md5, v[1] && v[1].md5]
          else
            puts "M %-80s %10d %10d" % [k, v[0] && v[0].size, v[1] && v[1].size]
          end
        else
          puts "%s %-80s" % [v[0] ? "-" : "+", k]
        end
      end
    end

    DEFAULT_IGNORED_NAMES = %w(.git .svn .vfs)

    def self.filter_ignored(fs)
      VFS.filter(fs) do |f, ancestors|
        if DEFAULT_IGNORED_NAMES.include?(f.name)
          VFS.skip
        else
          true
        end
      end
    end

    CLOC_EXTS = %w(.rb .c .cc .cpp .h)
    def self.stat_cloc(fs)
      puts "start cloc"
      require "open3"
      require "json"

      files = {}
      VFS.walk(fs) do |f, ancestors|
        next unless CLOC_EXTS.include?(f.extname)
        files[f.fullpath[1..-1]] = f
      end

      files.keys.each_slice(100) do |file_slice|
        result, stat = Open3.capture2("cloc", "--json", "--by-file", *file_slice)
        next if stat.to_i != 0
        result = JSON.parse(result, symbolize_names: true)
        result.each do |k, v|
          next if k == :header || k == :SUM
          f = files[k.to_s]
          f.stat[:code] = v[:code]
          f.stat[:blank] = v[:blank]
          f.stat[:comment] = v[:comment]
        end
      end
      puts "end cloc"
    end
  end
end

# 直接呼ばれた場合は、スクリプトとして動く
VFS::Command.new(ARGV).run if $0 == __FILE__
