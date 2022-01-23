# coding: utf-8
# Timberbornの食料生産シミュレーター

require 'core'
require 'gnuplot'

#==============================================================
# Entry Point
#==============================================================

# CellKind.new(name, resource, days, ammount, )
CARROT = CellKind.new('Carrot',4, :food, 3, 0.5, 1.5)
POTATO = CellKind.new('Potato',6, :food, 4, 0.5, 1.5)
WHEAT = CellKind.new('Wheat',12, :food, 15, 0.5, 1.5)

BIRCH = CellKind.new('Birch',12, :wood, 2, 1.0, 5.0)
PINE = CellKind.new('Pine',12, :wood, 2, 1.0, 5.0)
CHESTNUT = CellKind.new('Chestnut', 12, :wood, 2, 1.0, 5.0)
MAPLE = CellKind.new('Maple', 30, :wood, 8, 1.0, 5.0)

$debug = false

def with_plot
  Gnuplot.open do |gnuplot|
    Gnuplot::Plot.new(gnuplot) do |plot|
      yield plot
    end
  end
end

def plot_run(plot, w, days, title)
  puts title
  
  data = []
  days.times do
    w.run(24)
    data << w.storage.inject(0){|m,x| m+x[1]}
  end

  plot.data << Gnuplot::DataSet.new(data) do |ds|
    ds.title = title
    ds.with = 'linespoints'
  end
end

def plot_consume(plot, pop, days)
    pop = 22
    data = (0..days).map{|x| x*3*pop}
    plot.data << Gnuplot::DataSet.new(data) do |ds|
      ds.title = "consume:#{pop}"
      ds.with = 'linespoints'
    end
end

case (ARGV[0] || :test).to_sym
when :foods
  # 畑の場合
  days = 50
  types = [:populate]
  pops = [2,4,6,8]
  kinds = [CARROT]
  
  with_plot do |plot|
    plot_consume(plot, 22, days)

    types.product(pops,kinds) do |type,pop,kind|
      w = World.new(20,20)

      case type
      when :half
        w.add_beavers :populate, pop/2
        w.add_beavers :yield, pop-(pop/2)
      when :yield
        w.add_beavers :yield, pop
      when :populate
        w.add_beavers :populate, pop
      end

      w.add_cells kind, 100
      
      plot_run(plot, w, days, "#{type}:#{kind.name}:#{pop}")
    end
  end

when :foods_pop
  # 100マスの人参固定で、人数を変えた場合
  days = 50
  with_plot do |plot|
    plot_consume(plot, 22, days)

    [1,2,4,6].each do |pop|
      w = World.new(20,20)
      w.add_beavers :populate, pop
      w.add_cells CARROT, 100
      plot_run(plot, w, days, "#{pop}")
    end
  end
  
when :foods_work
  # 100マスのジンジンに二人固定で、仕事を変えた場合
  days = 50
  with_plot do |plot|
    plot_consume(plot, 22, days)

    [:half,:populate,:yield].each do |type,pop,kind|
      w = World.new(10,10)

      case type
      when :half
        w.add_beavers :populate, 1
        w.add_beavers :yield, 1
      when :yield
        w.add_beavers :yield, 2
      when :populate
        w.add_beavers :populate, 2
      end

      w.add_cells CARROT, 100

      plot_run(plot, w, days, "#{type}")
    end
  end
  
when :wood_kind
  # 森の場合
  with_plot do |plot|
    cell_counts = [100,150,200,250,300]
    pops = [3]
    kinds = [PINE]
    cell_counts.product(pops, kinds) do |cell_count, pop, kind|
      w = World.new

      w.add_beavers :populate_only, 1
      w.add_beavers :yield_only, pop
      
      w.add_foods kind, cell_count
      
      data = []
      w.run(24*100)
      
      puts '='*80
      w.dump

      data << w.storage.inject(0){|m,x| m+x[1]}
      plot.data << Gnuplot::DataSet.new(data) do |ds|
        ds.title = "#{kind.name}:#{cell_count}:#{pop}"
        ds.with = 'linespoints'
      end
    end
  end

when :wood_cells
  # 森の場合（マス目と人数）
  with_plot do |plot|
    cell_counts = [200,300,400,500]
    pops = [1,2,3,4]
    kind = PINE
    
    pops.each do |pop|
      data = []
      cell_counts.each do |cell_count|
        w = World.new

        w.add_beavers :populate_only, 1
        w.add_beavers :yield_only, pop
        
        w.add_foods kind, cell_count
        
        w.run(24*100)
        
        p [cell_count, pop]

        data << [cell_count, w.storage.inject(0){|m,x| m+x[1]}]
      end
    
      plot.data << Gnuplot::DataSet.new(data.transpose) do |ds|
        ds.title = "#{kind.name}:#{pop}"
        ds.with = 'linespoints'
      end
    end
  end

when :test
  # テスト

  w = World.new(10,10)

  w.add_beavers :populate, 1
  #w.add_beavers :yield, 1

  w.add_cells CARROT, 100
        
  50.times do |n|
    w.run(24)

    if n % 5 == 0
      puts '-' * 80
      puts "DAY #{n}"
      w.dump_cell_stats
      w.dump_cells
    end
  end

  puts '='*80
  w.dump
end
