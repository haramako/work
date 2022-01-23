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

case (ARGV[0] || :wood_cells).to_sym
when :foods
  # 畑の場合
  with_plot do |plot|
    pop = 22
    data = (0..100).map{|x| x*3*pop}
    plot.data << Gnuplot::DataSet.new(data) do |ds|
      ds.title = "consume:#{pop}"
      ds.with = 'linespoints'
    end
    
    #[:populate,:yield].each do |t|
    [:populate].each do |t|
      #[:yield].each do |t|
      [1,2,3].each do |f|
        [CARROT].each do |target|
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

          w.add_cells target, 100
          
          #puts '='*80
          #w.dump

          data = []
          100.times do
            w.run(24)
            data << w.storage.inject(0){|m,x| m+x[1]}
            #w.dump_foods
          end
          puts '='*80
          w.dump

          plot.data << Gnuplot::DataSet.new(data) do |ds|
            ds.title = "#{t}:#{target.name}:#{f}"
            ds.with = 'linespoints'
          end
        end
      end
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

  w = World.new(5,5)

  w.add_beavers :yield, 1

  w.add_cells CARROT, 13
        
  50.times do |n|
    w.run(24)

    puts '-' * 80
    puts "DAY #{n}"
    w.dump_cell_stats
    w.dump_cells
  end

  puts '='*80
  w.dump
end
