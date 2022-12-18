module VFS
  class Serializer
    # Deserialize a Node from binary.
    def load(bin)
      load_inner(nil, Marshal.load(bin))
    end

    # Serialize a Node to binary.
    def dump(node)
      Marshal.dump(dump_inner(node))
    end

    private

    def load_inner(parent, data)
      node = Node.new(parent, data[1])
      node.size = data[2]
      node.instance_eval do
        @attr = data[3]
        @stat = data[4]
      end
      if data[0] == 1
        # directory
        data[5].each { |d| load_inner(node, d) }
      else
        # file
        node.mtime = data[5] && Time.at(data[5])
        node.md5 = data[6]
      end
      node
    end

    def dump_inner(node)
      if node.directory?
        [1, node.name, node.size, node.attr, node.stat, node.children.values.map { |c| dump_inner(c) }]
      else
        [0, node.name, node.size, node.attr, node.stat, node.mtime&.to_i, node.md5]
      end
    end
  end
end
