module VFS
  class Node
    class WalkSkip < Exception; end

    def walk(after: false, &block)
      walk_inner([], after, &block)
    end

    # 特定の条件のノードのみを抽出する
    def filter(&block)
      root = Node.new(nil, "")
      walk do |cur, ancestors|
        if block.call(cur, ancestors)
          #puts cur.fullpath
          new_node = root.resolve(cur.fullpath, mkdir: true)
          new_node.copy_from(cur)
        end
      end
      root
    end

    def to_list
      r = []
      walk do |n|
        next if n.directory?
        r << [n.fullpath, n]
      end
      r
    end

    def to_hash
      r = {}
      walk do |n|
        next if n.directory?
        r[n.fullpath] = n
      end
      r
    end

    def display
      walk do |n, ancestors|
        puts (" " * (ancestors.size * 2)) + n.name + " " + n.size.to_s
      end
    end

    def resolve(path, mkdir: false)
      path = path.split("/") if path.is_a?(String)
      resolve_inner(path, mkdir)
    end

    def resolve_path(path)
      names = path.split("/")
      cur = self
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

    def walk_inner(cur, after, &block)
      unless after
        begin
          block.call(self, cur)
        rescue WalkSkip
          return # 子供を調べない
        end
      end

      unless children.empty?
        cur.push self
        children.values.each do |c|
          c.walk_inner(cur, after, &block)
        end
        cur.pop
      end

      block.call(self, cur) if after
    end

    private

    def skip
      raise WalkSkip.new
    end

    def resolve_inner(path, mkdir)
      if path.empty?
        self
      else
        name = path.shift
        return resolve_inner(path, mkdir) if name == "." || name == "" # '.' は特別にカレントディレクトリ

        cur = children[name]

        # mkdirモードなら、ないディレクトリを作る
        if mkdir && !cur
          cur = Node.new(self, name)
          #p "new node #{name}"
        end

        if cur
          cur.resolve(path, mkdir: mkdir)
        else
          raise "invalid path #{path}"
        end
      end
    end
  end
end
