def log_(*args)
  puts *args if $debug
end

#==============================================================
# World
#==============================================================
class World
  attr_reader :beavers, :cells, :storage
  
  def initialize(w,h)
    @beavers = []
    @cell_width = w
    @cell_height = h
    @cells = Array.new(w*h)
    @storage = Hash.new{|h,k| h[k] = 0}
  end

  def add_beaver(b,n=1)
    b.id = @beavers.size
    @beavers << b
  end

  def add_beavers(behaviour,n)
    n.times do
      add_beaver(Beaver.new(self,behaviour))
    end
  end

  def add_cell(idx, c)
    c.set_pos(idx2pos(idx))
    @cells[idx] = c
  end

  def add_cells(kind, n=1)
    n.times do
      idx = blank_idx
      if idx
        add_cell idx, Cell.new(self, kind)
      else
        raise "can't find blank pos"
      end
    end
  end

  def idx2pos(idx)
    [idx % @cell_width, idx / @cell_width]
  end

  def blank_idx
    @cells.each_with_index do |c,i|
      return i unless c
    end
    nil
  end
  
  def cell_available
    @cells.lazy.select{|c| c }
  end

  def cell(pos)
    @cells[pos2idx(pos)]
  end

  def set_cell(pos,v)
    @cells[pos2idx(pos)] = v
  end

  def pos2idx(pos)
    pos[1] * @cell_width + pos[0]
  end
  
  def run(time)
    while time > 0
      tick
      time -= 1.0
    end
  end

  def tick
    @beavers.each do |obj|
      obj.wait -= 1.0
      while obj.wait <= 0
        obj.wait += obj.process
      end
    end
    cell_available.each do |obj|
      obj.wait -= 1.0
      while obj.wait <= 0
        obj.wait += obj.process
      end
    end
  end

  def dump
    puts "BEAVERS"
    b = @beavers.group_by{|b| b.type}
    b.each do |k,v|
      puts "  #{k}: #{v.size}"
    end
    puts "CELLS"
    dump_cell_stats
    puts "STORAGE"
    @storage.each do |k,v|
      puts "  %-8s: %2d" % [k,v]
    end
  end
  
  def dump_cell_stats
    [CARROT].each do |kind|
      fs = cell_available.find_all{|f| f.kind == kind}
      populated = fs.count{|f| !f.populated}
      growing = fs.count{|f| f.populated && !f.yield_ready?}
      yield_ready = fs.count{|f| f.yield_ready?}
      puts '  %-8s: %3d %3d %3d' % [kind.name, populated, growing, yield_ready]
    end
  end
  
  def dump_cells
    out = @cells.each_slice(@cell_width).map do |s|
      s.map do |f|
        if f.nil?
          ' '
        elsif f.yield_ready?
          '@'
        elsif f.populated
          'w'
        else
          '.'
        end
      end.join
    end
    puts out.join("\n")
  end
end

#==============================================================
#==============================================================
class GameObject
  attr_accessor :id, :wait
  def initialize(world, *args)
    @w = world
    @wait = 0
  end

  def log(*args)
    log_ "ID(#{@id}): #{args.join(' ')}"
  end

end

#==============================================================
# Beaver
#==============================================================
class Beaver < GameObject
  attr_reader :type
  
  def initialize(world, type)
    super
    @type = type
  end
  
  def process
    case @type
    when :yield
      try_yield || try_populate || 1.0
    when :populate
      try_populate || try_yield || 1.0
    when :yield_only
      try_yield || 1.0
    when :populate_only
      try_populate || 1.0
    else
      raise
    end
  end

  def try_yield
    f = @w.cell_available.find {|f| f.yield_ready? }
    if f
      f.yield_
      @w.storage[f.kind.resource] += f.kind.ammount
      1.5
    else
      nil
    end
  end

  def try_populate
    f = @w.cell_available.find {|f| !f.populated }
    if f
      f.populate
      0.5
    else
      nil
    end
  end
end

#==============================================================
# Cell
#==============================================================
class Cell < GameObject
  attr_reader :kind, :growth, :populated, :x, :y
  
  def initialize(world, kind)
    super
    @x = nil
    @y = nil
    @kind = kind
    @growth = 0
    @populated = false
  end

  def set_pos(pos)
    @x = pos[0]
    @y = pos[1]
  end

  def pos
    [@x, @y]
  end
  
  def process
    return 1.0 unless @populated
    @growth = [@growth + @kind.growth_per_hour, 1.0].min
    log "grow #{@growth}"
    1.0
  end

  def yield_
    @growth = 0
    @populated = false
  end

  def yield_ready?
    @growth >= 1.0
  end

  def populate
    @populated = true
  end
end

#==============================================================
# Cell Kind
#==============================================================
class CellKind
  attr_reader :name, :growth_days, :growth_per_hour, :resource, :ammount
  attr_reader :yield_time, :populate_time
  def initialize(name, growth_days, resource, ammount, populate_time, yield_time)
    @name = name
    @growth_days = growth_days
    @growth_per_hour = 1.0 / (growth_days * 24)
    @resource = resource
    @ammount = ammount
    @populate_time = populate_time
    @yield_time = yield_time
  end
end
