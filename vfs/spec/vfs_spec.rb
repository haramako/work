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

  describe "serialization" do
    it "dump and restore make same structure" do
      fs = make_tree(nil, 2, 3)
      bin = VFS.dump(fs)
      fs2 = VFS.load(bin)

      func = proc { |k, f| [k, f.name, f.size, f.mtime] }

      expect(fs.to_list.map(&func)).to eq(fs2.to_list.map(&func))
    end

    it "save aggregation" do
      fs = make_tree(nil, 2, 3)
      VFS.aggregate(fs)
      fs2 = VFS.load(VFS.dump(fs))

      expect(fs2.size).to eq(fs.size)
    end
  end
end

describe VFS do
  describe "aggretation" do
    it "aggregate size" do
      fs = make_tree(nil, 2, 3)
      expect(fs.size).to eq(0)
      VFS.aggregate(fs)
      expect(fs.size).to eq((3 ** 2) * 100)
    end

    it "aggregate stat" do
      fs = make_tree(nil, 2, 3) { |f| f.stat[:n] = 1 }
      expect(fs.stat[:n]).to eq(nil)
      VFS.aggregate(fs)
      expect(fs.stat[:n]).to eq(9)
    end
  end
end

describe FileSystem do
  it "read_dir" do
    fs = FileSystem.new.read_dir(__dir__ + "/../lib", log: false)
    VFS.aggregate(fs)
    expect(fs.to_list.size).to be > 6
    expect(fs.size).to be > 10000
    expect(fs["vfs.rb"].md5).not_to be_nil
  end

  it "read_dir without hash" do
    fs = FileSystem.new.read_dir(__dir__ + "/../lib", hash: false, log: false)
    expect(fs["vfs.rb"].md5).to be_nil
  end
end
