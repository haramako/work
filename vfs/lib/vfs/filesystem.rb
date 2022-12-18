module VFS
  class FileSystem
    def read_dir(path, hash: true)
      Dir.chdir(path) do
        root = Node.new(nil, "")
        n = 0
        Find.find(".") do |f|
          next if File.directory?(f)
          file = root.resolve(f, mkdir: true)
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
      vfs_path = FileSystem.vfs_path(path)

      if File.exist?(vfs_path)
        VFS.load(IO.binread(vfs_path))
      else
        fs = VFS.read_dir(path, hash: false)
        IO.binwrite vfs_path, VFS.dump(fs)
        fs
      end
    end

    def self.vfs_path(path)
      if File.directory?(path)
        path + "/.vfs"
      else
        path
      end
    end
  end
end
