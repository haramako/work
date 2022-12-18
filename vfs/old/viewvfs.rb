require 'sinatra'
require 'sinatra/reloader' if development?

require_relative 'vfs'


def get_fs(file)
  @fs ||= {}
  if @fs[file].nil?
    @fs[file] = VFS.load(IO.binread(file))
  end
  @fs[file]
end

def calc_total(vfs)
  VFS.walk(vfs, after: true) do |f|
    unless f.directory?
      f.stat[:size] = f.size
      f.stat[:count] = 1
      f.stat["size#{f.extname}"] = f.size
    end
  end
end

def calc_stat(vfs)
  VFS.walk(vfs, after: true) do |f|
    if f.directory?
      f.children.values.each do |c|
        c.stat.each do |k,v|
          f.stat[k] = (f.stat[k] || 0) + v
        end
      end
    end
  end
end


get '/' do
  'HOGE'
end

def sz(n)
  if n.nil?
    ''
  else
    "%3.1f" % [n / 1000.0]
  end
end

def filter_ignore(fs)
  VFS.filter(fs) do |f,ancester|
    if ['.git', '.vs', 'win', 'third_party'].include?(f.name) || ['.o'].include?(f.extname)
      VFS.skip
    else
      true
    end
  end
end

def filter_ext(fs, ext_list)
  VFS.filter(fs) { |f,ancester| ext_list.include? f.extname }
end

get '/v/:file/*' do
  file = params[:file]
  rest = params[:splat][0]
  filter = params[:filter]
  nofilter = params[:nofilter]
  p nofilter
  
  fs = VFS.resolve_path(get_fs(file), rest)
  if filter
    filter_proc = eval("Proc.new{|f,ancester| f.directory? || (#{filter}) }")
    STDERR.puts filter_proc.call(OpenStruct.new(extname:'.cs'),2)
    fs = VFS.filter(fs, &filter_proc)
  end

  min_size = 1000_000
  ext_list = []
  eval(IO.read(file+'.rb'), binding) if !nofilter && File.exist?(file+'.rb')

  fs = filter_ignore(fs)
  calc_total(fs)
  calc_stat(fs)

  html = ["<table><tr><td>path<td>size<td>#{ext_list.join('<td>')}<td>other</tr>"]
  VFS.walk(fs) do |f| 
    size = f.stat[:size]
    next if !f.directory? || size < min_size
    size_stat = f.stat.select{|k,v| k.is_a?(String) && k.start_with?('size.') && !ext_list.include?(k[4..-1]) }.sort_by{|k,v| -v}.take(3).map{|k,v| "#{k[4..-1]}=#{sz(v)}"}.join(', ')

    list = []
    list << "<a href='/v/#{file}#{f.fullpath}'>#{f.fullpath}</a>"
    list << sz(size)
    ext_list.each do |ext|
      list << sz(f.stat['size'+ext])
    end
    list << size_stat

    html << ("<tr><td>" + list.map(&:to_s).join('<td>'))
  end
  html.join
end
