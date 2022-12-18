module VFS
  class Serializer
    def load(bin)
      load_inner(nil, Marshal.load(bin))
    end

    def dump(node)
      Marshal.dump(dump_inner(node))
    end

    private

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

    def dump_inner(node)
      if node.directory?
        [1, node.name, node.children.values.map { |c| dump_inner(c) }]
      else
        [0, node.name, node.size, node.mtime.to_i, node.md5, node.attr, node.stat]
      end
    end
  end
end
