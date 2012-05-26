# coding: utf-8
# インタープリタ

class Runner
  attr_reader :labels, :block, :pc

  def initialize( compiler )
    @compiler = compiler
    @stack = []

    @vars = Hash.new
    @compiler.func.each do |func_id,f|
      f.block.vars.each do |id,v|
        @vars[v] = 0
      end
    end

    @labels = Hash.new
    @compiler.func.each do |id,f|
      f.block.ops.each_with_index do |op,i|
        @labels[f.block.id.to_s+op[1]] = [id,i] if op[0] == :label
      end
    end

    @block = @compiler.func[:main].block
    @pc = 0
    @ret = nil
  end

  def run
    while true
      run_one
      break unless @block.ops[@pc]
    end
    show
  end

  def run_one
    op = @block.ops[@pc]
    @pc += 1
    case op[0]
    when :'if'
      if get(op[1]) == 0
        @pc = @labels[@block.id.to_s+op[2]][1]
      end
    when :load
      put op[1], get(op[2])
    when :add, :sub, :mul, :div, :eq, :ne, :lt, :gt, :le, :ge
      hash = { add: :+, sub: :-, mul: :*, div: :/, eq: :==, ne: :!=, lt: :<, gt: :>, le: :<=, ge: :>= }
      v = get(op[2]).__send__(hash[op[0]], get(op[3]) )
      v = 1 if v === true
      v = 0 if v === false
      put op[1], v
    when :return
      @ret = get(op[1])
      @block, @pc = @stack.pop
    when :call
      unless @ret
        if op[2].id == :print
          puts "OUTPUT: #{get(op[2].block.vars[:i])}"
        else
          @stack << [@block,@pc-1]
          @block = op[2].block
          @pc = 0
        end
      else
        put op[1], @ret
        @ret = nil
      end
    when :jump
      @pc = @labels[@block.id.to_s+op[1]][1]
    when :label
      # DO NOTHING
    else
      show
      raise "unknow op #{op}"
    end
  end

  def get( val )
    if val.id
      @vars[val]
    else
      val.val
    end
  end

  def put( var, v )
    @vars[var] = v
  end

  def show
    puts "STACK:"
    puts "  #{@block.id}:#{@pc}: #{@block.ops[@pc] || 'finished' }"
    @stack.each do |s|
      puts "  #{s[0].id}:#{s[1]}: #{s[0].ops[s[1]]}"
    end
    puts "VARS:"
    @vars.each do |v|
      puts "  #{v[0]} = #{v[1]}"
    end
  end
end


