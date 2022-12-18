require "sinatra"
require "sinatra/reloader" if development?

$LOAD_PATH << __dir__ + "/../lib"

require "vfs"

def get_fs(file)
  @fs ||= {}
  if @fs[file].nil?
    @fs[file] = VFS.load(IO.binread(file))
    VFS.aggregate(@fs[file])
  end
  @fs[file]
end

def calc_total(vfs)
  vfs.walk(after: true) do |f|
    unless f.directory?
      f.stat[:size] = f.size
      f.stat[:count] = 1
      f.stat["size#{f.extname}"] = f.size
    end
  end
end

def calc_stat(vfs)
  vfs.walk(after: true) do |f|
    if f.directory?
      f.children.values.each do |c|
        c.stat.each do |k, v|
          f.stat[k] = (f.stat[k] || 0) + v
        end
      end
    end
  end
end

get "/" do
  "HOGE"
end

def sz(n)
  if n.nil?
    ""
  else
    "%3.0f" % [n / 1000.0]
  end
end

def filter_ignore(fs)
  fs.filter do |f, ancester|
    if [".git", ".vs", "win", "third_party"].include?(f.name) || [".o"].include?(f.extname)
      VFS.skip
    else
      true
    end
  end
end

def filter_ext(fs, ext_list)
  fs.filter { |f, ancester| ext_list.include? f.extname }
end

get "/v/:file/*" do
  file = params[:file]
  rest = params[:splat][0]
  filter = params[:filter]
  nofilter = params[:nofilter]

  fs = get_fs(file).resolve_path(rest)
  if filter
    filter_proc = eval("Proc.new{|f,ancester| f.directory? || (#{filter}) }")
    fs = fs.filter(&filter_proc)
  end

  min_size = 1_000_000
  ext_list = []
  eval(IO.read("old/" + file + ".rb"), binding) if !nofilter && File.exist?("old/" + file + ".rb")

  fs = filter_ignore(fs)
  calc_total(fs)
  calc_stat(fs)

  VFS.aggregate(fs)
  min_size = fs.size * 0.03

  html = []
  html << "<style>table { border-collapse: collapse; }  table, th, td {  border: 0.1px solid; }  </style>"
  html << ["<table><tr><td>path<td>size[KB]<td>#{ext_list.join("<td>")}<td>other</tr>"]
  fs.walk do |f|
    size = f.size
    next if (!f.directory? || size < min_size) && f.parent != fs
    size_stat = f.stat.select { |k, v| k.is_a?(String) && k.start_with?("size.") && !ext_list.include?(k[4..-1]) }.sort_by { |k, v| -v }.take(3).map { |k, v| "#{k[4..-1]}=#{sz(v)}" }.join(", ")

    list = []
    list << "<td><a href='/v/#{file}#{f.fullpath}'>#{f.fullpath}</a>"
    list << "<td align='right'>#{sz(size)}"
    ext_list.each do |ext|
      list << "<td align='right'>" + sz(f.stat["size" + ext])
    end
    list << "<td>" + size_stat

    html << ("<tr>" + list.map(&:to_s).join)
  end
  html.join
end
