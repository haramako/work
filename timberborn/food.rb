# coding: utf-8
# Timberbornの食料生産シミュレーター

require 'core'
require 'gnuplot'

#==============================================================
# Entry Point
#==============================================================

# CellKind.new(name, resource, days, ammount, )
CARROT = CellKind.new('Carrot',4, :food, 3, 0.28, 2.0)
POTATO = CellKind.new('Potato',6, :food, 4, 0.28, 2.0)
WHEAT = CellKind.new('Wheat',12, :food, 15, 0.28, 2.0)

w = 1.0
BIRCH = CellKind.new('Birch',9, :wood, 1, 1.0, 3.0+w*1)
PINE = CellKind.new('Pine',12, :wood, 2, 1.0, 3.0+w*1)
CHESTNUT = CellKind.new('Chestnut', 24, :wood, 4, 1.0, 3.0+w*2)
MAPLE = CellKind.new('Maple', 30, :wood, 8, 1.0, 3+w*4)

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
  days.times do |d|
    w.run(24)
    data << w.storage.inject(0){|m,x| m+x[1]}
    # puts "#{d} #{w.storage.inject(0){|m,x| m+x[1]}}"
  end

  plot.data << Gnuplot::DataSet.new(data) do |ds|
    ds.title = title
    ds.with = 'linespoints'
  end
end

def plot_consume(plot, pop, days)
    data = (0..days).map{|x| x*2.5*pop}
    plot.data << Gnuplot::DataSet.new(data) do |ds|
      ds.title = "consume:#{pop}"
      ds.with = 'linespoints'
    end
end

case (ARGV[0] || :test).to_sym
when :foods
  # 畑の場合
  days = 30
  types = [:populate]
  pops = [2]
  kinds = [CARROT]
  cells = [50,60,70,80,90,100]
  
  with_plot do |plot|
    plot_consume(plot, 22, days)

    types.product(pops,kinds,cells) do |type,pop,kind,cell|
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

      w.add_cells kind, cell
      
      plot_run(plot, w, days, "#{type}:#{kind.name}:#{pop}:#{cell}")
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
  
when :foods_kind
  # 300マスの２人固定で、作物を変えた場合
  days = 50
  with_plot do |plot|
    plot_consume(plot, 22, days)

    [CARROT, POTATO, WHEAT].each do |kind|
      w = World.new(20,20)
      w.add_beavers :populate, 2
      w.add_cells kind, 300
      plot_run(plot, w, days, "#{kind.name}")
    end
  end

when :foods_kind2
  # 100マス固定で、作物を変えた場合
  days = 50
  with_plot do |plot|
    plot.title "100 cells, 8 pop"
    plot_consume(plot, 22, days)
    plot_consume(plot, 40, days)

    [CARROT, POTATO, WHEAT].each do |kind|
      w = World.new(10,10)
      w.add_beavers :populate, 8
      w.add_cells kind, 100
      plot_run(plot, w, days, "#{kind.name}")
    end
  end

when :foods_kind3
  # 畑の場合（人数を固定して、マス数を変更）
  with_plot do |plot|
    cell_counts = [70,80,100,110,200,220,250]
    kinds = [CARROT,POTATO,WHEAT]
    pop = 2
    
    kinds.each do |kind|
      plot.time "Foods, pop=2"
      plot.xrange "[0:]"
      plot.yrange "[0:]"
      data = []
      cell_counts.each do |cell_count|
        w = World.new(20,20)

        w.add_beavers :populate, pop
        
        w.add_cells kind, cell_count
        
        w.run(24*100)
        
        data << [cell_count, w.storage.inject(0){|m,x| m+x[1]}]
      end
    
      plot.data << Gnuplot::DataSet.new(data.transpose) do |ds|
        ds.title = "#{kind.name}"
        ds.with = 'linespoints'
      end
    end
  end
  
  
when :foods_work
  # 100マスのニンジンに二人固定で、仕事を変えた場合
  days = 50
  with_plot do |plot|
    plot_consume(plot, 22, days)

    [:populate,:yield].each do |type,pop,kind|
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
      # w.add_cells POTATO, 100

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

when :wood_kind2
  # 森の場合（マス目と人数）
  with_plot do |plot|
    cell_counts = [180,190,200,250,260,300,350,360, 480,490,500]
    # kinds = [CHESTNUT, MAPLE]
    kinds = [BIRCH, PINE, CHESTNUT, MAPLE]
    pop = 4
    
    kinds.each do |kind|
      plot.xrange "[0:]"
      plot.yrange "[0:]"
      data = []
      cell_counts.each do |cell_count|
        w = World.new(30,30)

        w.add_beavers :populate_only, 1
        w.add_beavers :yield_only, pop
        
        w.add_cells kind, cell_count
        
        w.run(24*100)
        
        data << [cell_count, w.storage.inject(0){|m,x| m+x[1]}]
      end
    
      plot.data << Gnuplot::DataSet.new(data.transpose) do |ds|
        ds.title = "#{kind.name}:#{kind.name}"
        ds.with = 'linespoints'
      end
    end
  end
  

when :wood_cells
  # 森の場合（マス目と人数）
  with_plot do |plot|
    cell_counts = [100,110,120,130,140,150,200,300]
    pops = [1,2,4]
    kind = PINE
    
    pops.each do |pop|
      data = []
      cell_counts.each do |cell_count|
        w = World.new(30,30)

        w.add_beavers :populate_only, 1
        w.add_beavers :yield_only, pop
        
        w.add_cells kind, cell_count
        
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

  w = World.new(20,20)

  #w.add_beavers :populate, 1
  #w.add_beavers :yield, 1
  w.add_beavers :populate_only, 1
  w.add_beavers :yield_only, 3

  w.add_cells PINE, 300
        
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
