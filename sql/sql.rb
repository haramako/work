#!/usr/bin/env ruby -Eutf-8
# coding: utf-8

require 'pp'
require 'stringio'

class Object
  def tap_pp
    pp self
    self
  end
end

class String
  # 文字列の表示幅を求める.
  def print_size
    each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
  end  
end

module MiniSql
  
  class Table

    attr_reader :rows, :name

    def initialize( name = 'unknown', opt = Hash.new )
      @name = name
      @rows = opt[:rows] || []
    end

    def select( *params )
      SelectQuery.new(self).select( *params )
    end

    def where( *params )
      SelectQuery.new(self).where( *params )
    end

    def insert( row )
      @rows << row
    end

  end

  class SelectQuery

    attr_reader :table

    def initialize( table )
      @table = table
      @cols = nil
      @where = []
      @join = nil
      @limit = nil
    end

    def select( *cols )
      @cols = cols.clone
      self
    end

    def where( col, op, val )
      @where << [ col, op, val ]
      self
    end

    def limit( num )
      @limit = num
      self
    end

    def join( col_a, col_b, query_or_table )
      if Table === query_or_table
        query = SelectQuery.new(query_or_table)
      else
        query = query_or_table
      end
      @join = [ col_a, col_b, query ]
      self
    end

    def all
      rows = []
      @table.rows.each do |row| 
        if do_where(row)
          rows << row
          break if @limit and rows.size >= @limit 
        end
      end

      if @join
        col_a, col_b, query = *@join
        rows2 = query.all
        rows.each do |row|
          row[query.table.name] = rows2.find {|row2| row2[col_b] = row[col_a] }
        end
      end

      if @cols
        rows = rows.collect do |row|
          Hash[ @cols.map { |col| [col, row[col]] } ]
        end
      end

      rows
    end

    def one
      limit(1).all[0]
    end

    def each
      all.each
    end

    def as_table
      rows_to_table( all )
    end

    def dump
      rows = all
      cols = @cols || rows.map{|row|row.keys}.flatten.uniq
      r = StringIO.new
      r <<  '|'+ cols.join('|')+ "|\n"
      rows.map do |row|
        r << '|' + cols.map{ |col| row[col] }.join('|') + "|\n"
      end
      r.string
    end

    def to_s
      r = ''
      r += "FROM #{@table.name}"
      r += " SELECT #{@cols.join(', ')}" if @cols
      unless @where.empty?
        r += " WHERE "
        r += @where.map do |wh|
          "#{wh[0]} #{wh[1]} #{wh[2]}"
        end.join(" AND ")
      end
      r += " LIMIT #{@limit}" if @limit
      r += "| JOIN #{@join[0]} = #{@join[1]} #{@join[2]}" if @join
      r
    end

    private

    def do_where( row )
      @where.each do |wh|
        col, op, val = *wh
        return false unless row[col].__send__(op,val)
      end
      true
    end

  end

  module_function

  def rows_to_table( rows )
    r = []
    cols = {}

    rows.each do |row|
      row.each do |k,v|
        if Hash === v
          cols[k] ||= Hash.new
          cols[k] = v.keys
        else
          cols[k] ||= k.to_s.length
          len = v.to_s.print_size
          cols[k] = len if len > cols[k] 
        end
      end
    end

    header = '| '
    cols.each do |k,v|
      if Array === v
        header += k.to_s + '( ' + v.join(', ') + ' )'
      else
        header += "%-#{v}s"%k + ' | '
      end
    end
    header += ' |'
    r << header
    r << '-'*header.size

    rows.each do |row|
      line = '| '
      cols.each do |k,len|
        if Array === len
          line += '( ' + row[k].values.join(", ") + ' )'
        else
          line += row[k].to_s + (' '*(len-row[k].to_s.print_size)) + ' | '
        end
      end
      r << line
    end

    r.join( "\n" )
  end

end

include MiniSql

rows = [ 
        { name:'りんご', kind_id:1, price:120 },
        { name:'みかん', kind_id:1, price:40 },
        { name:'キャベツ', kind_id:2, price:150 },
        { name:'わかめ', kind_id:2, price:80 }, 
       ]
fruit = Table.new( :fruit, rows:rows )


rows = [ 
        { id:1, kind:'野菜', en:'fruit' },
        { id:2, kind:'野菜', en:'vegetable' },
       ]
kind = Table.new( :kind, rows:rows )


pp fruit.where(:price,:>,40).join( :kind_id, :kind_id, kind )
puts fruit.where(:price,:>,40).join( :kind_id, :kind_id, kind ).select(:name,:kind).all


# pp MiniSql.tables
