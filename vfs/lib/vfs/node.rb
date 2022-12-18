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
      resolve_path(path)
    end

    def clear_aggregation
      @size = 0
      @stat = {}
    end

    def copy_from(node)
      @size = node.size
      @md5 = node.md5
      @mtime = node.mtime
      @attr = node.attr
      @stat = node.stat
    end
  end
end
