module TestHelper
  def make_root
    @root = Node.new(nil, "")
  end

  def make_tree(parent, depth, file_per_dir, &block)
    node, n = make_tree_inner(parent, depth, file_per_dir, 0, &block)
    node
  end

  def make_tree_inner(parent, depth, file_per_dir, n, &block)
    if depth <= 0
      node = Node.new(parent, "file#{n}")
      n += 1
      node.size = 100
      block&.call(node)
    else
      node = Node.new(parent, "dir#{n}")
      n += 1
      file_per_dir.times do
        child, n = make_tree_inner(node, depth - 1, file_per_dir, n, &block)
      end
    end
    [node, n]
  end
end

RSpec.configure do |c|
  c.include TestHelper
end
