require_relative "helper"

require "vfs"

include VFS

describe TestHelper do
  it "make tree" do
    fs = make_tree(nil, 2, 3)
    expect(fs.to_list.size).to eq(3 ** 2)
  end
end

describe Node do
  let(:root) { Node.new(nil, "") }

  it "fullpath returns full path" do
    dir = Node.new(root, "dir")
    file = Node.new(dir, "file")
    expect(file.fullpath).to eq("/dir/file")
  end

  it "resolve create directory recursive" do
    file = root.resolve("dir1/dir2/file", mkdir: true)
    expect(file.fullpath).to eq("/dir1/dir2/file")
  end

  it "resolve create directory recursive" do
    file = root.resolve("dir1/dir2/file", mkdir: true)
    expect(file.fullpath).to eq("/dir1/dir2/file")
  end
end

describe Node do
  it "dump" do
    fs = make_tree(nil, 2, 3)
    bin = VFS.dump(fs)
    fs2 = VFS.load(bin)

    func = proc { |k, f| [k, f.name, f.size, f.mtime] }

    expect(fs.to_list.map(&func)).to eq(fs2.to_list.map(&func))
  end
end

describe VFS do
  it "aggregate" do
    fs = make_tree(nil, 2, 3)
    VFS.aggregate(fs)
    expect(fs.size).to eq((3 ** 2) * 100)
  end
end
