# coding: utf-8
# Timberbornの食料生産シミュレーター

require 'gnuplot'

def log_(*args)
  puts *args if $debug
end

#==============================================================
# World
#==============================================================
class World
  attr_reader :beavers, :foods, :storage
  
  def initialize
    @beavers = []
    @foods = []
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

  def add_food(f)
    f.id = @foods.size
    @foods << f
  end

  def add_foods(kind, n=1)
    n.times do
      add_food Food.new(self, kind)
    end
  end
  
  def run(time)
    while time > 0
      tick
      time -= 1.0
    end
  end

  def tick
    (@beavers + @foods).each do |obj|
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
    puts "FOODS"
    dump_foods
    puts "STORAGE"
    @storage.each do |k,v|
      puts "  %-8s: %2d" % [k,v]
    end
  end
  
  def dump_foods
    [CARROT].each do |kind|
      fs = @foods.find_all{|f| f.kind == kind}
      populated = fs.count{|f| !f.populated}
      growing = fs.count{|f| f.populated && !f.yield_ready?}
      yield_ready = fs.count{|f| f.yield_ready?}
      puts '  %-8s: %3d %3d %3d' % [kind.name, populated, growing, yield_ready]
    end
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
    else
      raise
    end
  end

  def try_yield
    f = @w.foods.find {|f| f.yield_ready? }
    if f
      f.yield_
      @w.storage[f.kind.name] += f.kind.ammount
      1.5
    else
      nil
    end
  end

  def try_populate
    f = @w.foods.find {|f| !f.populated }
    if f
      f.populate
      0.5
    else
      nil
    end
  end
end

#==============================================================
# Food
#==============================================================
class Food < GameObject
  attr_reader :kind, :growth, :populated
  
  def initialize(world, kind)
    super
    @kind = kind
    @growth = 0
    @populated = false
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
# Food Kind
#==============================================================
class FoodKind
  attr_reader :name, :growth_days, :growth_per_hour, :ammount
  def initialize(name, growth_days, ammount)
    @name = name
    @growth_days = growth_days
    @growth_per_hour = 1.0 / (growth_days * 24)
    @ammount = ammount
  end
end

#==============================================================
# Entry Point
#==============================================================

CARROT = FoodKind.new('Carrot',4,3)
POTATO = FoodKind.new('Potato',6,1)
WHEAT = FoodKind.new('Wheat',12,3)

$debug = false

if true
Gnuplot.open do |gnuplot|
  Gnuplot::Plot.new(gnuplot) do |plot|

    pop = 22
    data = (0..100).map{|x| x*3*pop}
    plot.data << Gnuplot::DataSet.new(data) do |ds|
      ds.title = "consume:#{pop}"
      ds.with = 'linespoints'
    end
    
    #[:populate,:yield].each do |t|
    [:populate].each do |t|
    #[:yield].each do |t|
      [2,4].each do |f|
        w = World.new

        case t
        when :half
          w.add_beavers :populate, f/2
          w.add_beavers :yield, f-(f/2)
        when :yield
          w.add_beavers :yield, f
        when :populate
          w.add_beavers :populate, f
        end

        #w.add_foods CARROT, 100
        #w.add_foods POTATO, 100
        w.add_foods WHEAT, 200
        
        #puts '='*80
        #w.dump

        data = []
        50.times do
          w.run(24)
          data << w.storage.inject(0){|m,x| m+x[1]}
          #w.dump_foods
        end
        puts '='*80
        w.dump

        plot.data << Gnuplot::DataSet.new(data) do |ds|
          ds.title = "#{t}:#{f}"
          ds.with = 'linespoints'
        end
      end
    end
  end
end

else
  w = World.new

  w.add_beavers :populate, 1

  w.add_foods CARROT, 100
        
  #puts '='*80
  #w.dump

  50.times do
    w.run(24)
    w.dump_foods
  end

  puts '='*80
  w.dump
end
