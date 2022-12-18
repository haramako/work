require "fileutils"

module VFS
  # コマンドとして実行するクラス
  class Command
    HELP = <<~EOT
      VFS: virtual file system
      Usage: vfs <subcommand> [<opt> ...] <target> ...
      Subcommands:
        ls <target>
        dump <target>
        diff <target1> <target2>
        cloc <target>
      Options:
    EOT

    def initialize(args)
      require "optparse"
      if RUBY_PLATFORM =~ /mingw/
      end
      @diff_by = :md5
      @opt_d = false
      @force = false
      @op = OptionParser.new(HELP)
      @op.on("-s", "--size", "diff by size") { @diff_by = :size }
      @op.on("-f", "--force", "force read directory") { @force = true }
      @op.on("-d", "directory only") { @opt_d = true }
      @args = @op.parse(args)
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
      when "cloc"
        run_cloc(@args)
      when nil
        puts @op
        exit
      else
        raise "unknown subcommand #{@subcommand}"
      end
    end

    def run_ls(args)
      fs = VFS.open(args[0])
      VFS.aggregate(fs)
      puts("%-60s %8s %8s" % ["path", "size", "code"])
      fs.walk do |f|
        next if @opt_d && !f.directory?
        # puts f.fullpath
        puts("%-60s %8d %8d" % [f.fullpath, f.size / 1024, f.stat[:code] || 0])
      end
    end

    def run_dump(args)
      vfs_path = FileSystem.vfs_path(args[0])
      FileUtils.rm_f(vfs_path) if @force
      fs = VFS.read_dir(args[0], hash: true)
      fs = VFS::Command.filter_ignored(fs)
      IO.binwrite vfs_path, VFS.dump(fs)
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

    def run_cloc(args)
      vfs_path = FileSystem.vfs_path(args[0])
      fs = VFS.open(args[0])
      Dir.chdir(args[0]) do
        cloc(fs)
      end
      IO.binwrite vfs_path, VFS.dump(fs)
    end

    DEFAULT_IGNORED_NAMES = %w(.git .svn .vfs)

    def self.filter_ignored(fs)
      fs.filter do |f, ancestors|
        if DEFAULT_IGNORED_NAMES.include?(f.name)
          VFS.skip
        else
          true
        end
      end
    end

    CLOC_EXTS = %w(.rb .c .cc .cpp .h)

    def cloc(fs)
      puts "start cloc"
      require "open3"
      require "json"

      files = {}
      fs.walk do |f, ancestors|
        next unless CLOC_EXTS.include?(f.extname)
        files[f.fullpath[1..-1]] = f
      end

      files.keys.each_slice(100) do |file_slice|
        pp file_slice
        result, stat = Open3.capture2("gocloc", "--output-type", "json", "--by-file", *file_slice)
        # result, stat = Open3.capture2("gocloc", "--json", "--by-file", *file_slice)
        next if stat.to_i != 0
        result = JSON.parse(result, symbolize_names: true)
        result[:files].each do |v|
          # next if k == :header || k == :SUM
          f = files[v[:name]]
          f.stat[:code] = v[:code]
          f.stat[:blank] = v[:blank]
          f.stat[:comment] = v[:comment]
        end
      end
      puts "end cloc"
    end
  end
end
