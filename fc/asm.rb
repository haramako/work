# coding: utf-8

######################################################################
# 中間コードコンパイラ
######################################################################
class OpCompiler
  attr_reader :asm

  def initialize
    @label_count = 0
    @asm = []
    @address = 0x200
    @address_zeropage = 0x010
  end

  def compile( block )

    # lambdaのコンパイル
    block.vars.each do |id,v|
      if Lambda === v.val
        compile v.val.block
      end
    end

    @asm << "; function #{block.id}" 

    # 関数のコードをコンパイル
    code_asm = compile_block( block )

    # 関数のデータをコンパイル
    block.vars.each do |id,v|
      if v.opt and v.opt[:address]
        @asm << "#{to_asm(v)} = #{v.opt[:address]}"
        v.address = v.opt[:address]
      elsif v.const?
        if Array === v.val
          @asm << "#{to_asm(v)}: .db #{v.val.join(',')}"
        end
      else
        if v.reg == :mem
          if v.type.type == :pointer
            # ポインターはzeropageに配置する
            @asm << "#{to_asm(v)} = $#{'%04x'%[@address_zeropage]}"
            v.address = @address_zeropage
            @address_zeropage += v.type.size
          else
            # ポインター以外なら普通に配置
            @asm << "#{to_asm(v)} = $#{'%04x'%[@address]}"
            v.address = @address
            @address += v.type.size
          end
        end
      end
    end

    @asm.concat code_asm
    @asm << ''

  end

  def compile_block( block )
    ops = block.ops
    ops = optimize( block, ops )
    block.ops[0..-1] = ops
    alloc_register( block, ops )

    r = []
    if block.id == :''
      r << "__init:" 
    else
      r << "#{to_asm(block)}:" 
    end

    ops.each_with_index do |op,op_no| # op=オペランド
      r << "; #{'%04d'%[op_no]}: #{op.inspect}"
      a = op.map{|x| if Value === x then to_asm(x) else x end } # アセンブラ表記に直したop, Value以外はそのまま
      case op[0]

      when :label
        r << op[1] + ':'

      when :if
        then_label = new_label
        op[1].type.size.times do |i|
          r << load_a( op[1],i)
          r << "bne #{then_label}"
        end
        r << "jmp #{op[2]}"
        r << "#{then_label}:"

      when :jump
        r << "jmp #{op[1]}"

      when :return
        r.concat load( block.vars[:'0'], op[1] ) if op[1]
        r << "rts"

      when :call
        op[3..-1].each_with_index do |arg,i|
          r.concat load( op[2].val.args[i], arg)
        end
        r << "jsr #{to_asm(op[2])}"
        r.concat load( op[1], op[2].val.block.vars[:'0'] ) if op[1]

      when :load
        r.concat load( op[1], op[2] )

      when :add
        op[1].type.size.times do |i|
          r << "clc" if i == 0
          if op[2].type.size > i
            r << load_a( op[2],i)
          elsif op[2].type.size == i
            r << "lda #0"
          end
          r << "adc #{byte(op[3],i)}" if op[3].type.size > i
          r << store_a(op[1],i)
        end

      when :sub
        op[1].type.size.times do |i|
          r << "sec" if i == 0
          if op[2].type.size > i
            r << load_a( op[2],i)
          elsif op[2].type.size == i
            r << "lda #0"
          end
          r << "sbc #{byte(op[3],i)}" if op[3].type.size > i
          r << store_a(op[1],i)
        end

      when :eq
        true_label, end_label = new_labels(2)
        ([op[2].type.size,op[3].type.size].max-1).downto(0) do |i|
          if op[2].type.size > i
            r << load_a( op[2],i)
          elsif op[2].type.size == i
            r << "lda #0"
          end
          if op[3].type.size > i
            r << "cmp #{byte(op[3],i)}" 
          else
            r << "cmp #0" 
          end
          r << "beq #{true_label}"
        end
        # falseのとき
        r << "lda #0"
        r << store_a(op[1],0)
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << store_a(op[1],0)
        r << "#{end_label}:"

      when :lt
        true_label, end_label = new_labels(2)
        ([op[2].type.size,op[3].type.size].max-1).downto(0) do |i|
          if op[2].type.size > i
            r << load_a( op[2],i)
          elsif op[2].type.size == i
            r << "lda #0"
          end
          if op[3].type.size > i
            r << "cmp #{byte(op[3],i)}" 
          else
            r << "cmp #0" 
          end
          r << "bcc #{true_label}"
        end
        # falseのとき
        r << "lda #0"
        r << store_a(op[1],0)
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << store_a(op[1],0)
        r << "#{end_label}:"

      when :not
        true_label, end_label = new_labels(2)
        op[2].type.size.times do |i|
          r << load_a( op[2],i)
          r << "beq #{true_label}"
        end
        # falseのとき
        r << "lda #0"
        r << store_a(op[1],0)
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << store_a(op[1],0)
        r << "#{end_label}:"

      when :asm
        op[1].each do |line|
          r << "#{line[0]} " + line[1..-1].map{|o|to_asm(o)}.join(",")
        end

      when :index
        raise if op[3].type != TypeDecl[:int]
        # raise if op[2].kind != :var
        if op[2].type.type == :array
          r << "clc"
          r << "lda #LOW(#{a[2]})"
          r << "adc #{a[3]}"
          r << "sta #{a[1]}+0"
          r << "lda #HIGH(#{a[2]})"
          r << "adc #0"
          r << "sta #{a[1]}+1"
        elsif op[2].type.type == :pointer
          r << "clc"
          r << "lda #{byte(op[2],0)}"
          r << "adc #{a[3]}"
          r << "sta #{byte(op[1],0)}"
          r << "lda #{byte(op[2],1)}"
          r << "adc #0"
          r << "sta #{byte(op[1],1)}"
        else
          raise
        end

      when :pget
        r << "ldy #0"
        r << "lda [#{to_asm(op[2])}],y"
        r << store_a(op[1],0)

      when :pset
        r << "ldy #0"
        r << load_a( op[2],0)
        r << "sta [#{to_asm(op[1])}],y"

        # 最適化後のオペレータ
      when :index_pget
        if op[2].type.type == :array
          r << "ldy #{byte(op[3],0)}"
          r << "lda #{a[2]},y"
          r << store_a(op[1],0)
        elsif op[2].type.type == :pointer
          r << "ldy #{byte(op[3],0)}"
          r << "lda [#{a[2]}],y"
          r << store_a(op[1],0)
        else
          raise
        end

      when :index_pset
        if op[1].type.type == :array
          r << "ldy #{byte(op[2],0)}"
          r << load_a( op[3],0)
          r << "sta #{a[1]},y"
        elsif op[1].type.type == :pointer
          r << "ldy #{byte(op[2],0)}"
          r << load_a( op[3],0)
          r << "sta [#{a[1]}],y"
        end

      else
        raise "unknow op #{op}"
      end
    end

    # 空の行を削除
    r.delete(nil)
    # ラベル行以外はインデントする
    r = r.map do |line|
      if line.index(':') and line[0] != ';'
        line
      else
        "\t"+line
      end
    end

    block.asm = r

    r
  end

  def load( to, from )
    r = []
    if to.type.type == :pointer and from.type.type == :array 
      raise "can't convert from #{from} to #{to}" unless from.type.base == to.type.base
      # 配列からポインタに変換
      r << "lda #LOW(#{to_asm(from)})"
      r << "sta #{byte(to,0)}"
      r << "lda #HIGH(#{to_asm(from)})"
      r << "sta #{byte(to,1)}"
    else
      # 通常の代入
      if from.type.type != :int
        raise "can't convert from #{from} to #{to}" unless from.type.base == to.type.base
      end
      to.type.size.times do |i|
        if from.type.size > i
          r << load_a(from,i)
        elsif from.type.size == i
          r << "lda #0"
        end
        r << store_a(to,i)
      end
    end
    r
  end

  def load_a( v, n )
    case v.reg
    when :mem
      "lda #{byte(v,n)}"
    when :a
      # DO NOTHING
      nil
    else
      "lda #{byte(v,n)}"
    end
  end

  def store_a( v, n )
    case v.reg
    when :mem
      "sta #{byte(v,n)}"
    when :a
      # DO NOTHING
      nil
    else
      "sta #{byte(v,n)}"
    end
  end

  def new_label
    @label_count += 1
    "._#{@label_count}"
  end

  def new_labels( n )
    Array.new(n){new_label }
  end

  def to_asm( v )
    if ScopedBlock === v
      if v.upper
        "#{to_asm(v.upper)}_V#{v.id}"
      else
        "#{v.id}"
      end
    elsif v.kind == :literal
      "##{v.val.to_s}"
    else
      if v.scope
        "#{to_asm(v.scope)}_V#{v.id}"
      else
        "#{v.id}"
      end
    end
  end

  def byte( v, n )
    if v.const? and Numeric === v.val
      "##{v.val >> (n*8) % 256}"
    else
      "#{to_asm(v)}+#{n}"
    end
  end

  def optimize( block, ops )
    ops = optimize_unuse( block, ops )
    ops = optimize_pointer( block, ops )
    ops = optimize_unuse( block, ops )
    ops = optimize_pointer( block, ops )
    ops
  end

  def optimize_unuse( block, ops )
    ops = ops.clone

    # 未使用変数の削除
    r = []
    calc_liverange( block, ops )
    ops.each_with_index do |op,i|
      next unless op
      case op[0]
      when :pget, :pset
        if Value === op[1] 
          if op[1].lr.nil? or op[1].lr[0] == op[1].lr[1]
            next
          end
        end
      when :call
        r << [op[0]]+[nil]+op[2..-1]
        next
      end
      r << op
    end
    r
  end

  def optimize_pointer( block, ops )
    ops = ops.clone

    # index + pget/pset の最適化
    r = []
    calc_liverange( block, ops )
    ops.each_with_index do |op,i|
      next unless op
      case op[0] 
      when :index
        next_op = ops[i+1]
        if next_op
          if next_op[0] == :pget 
            if op[1] == next_op[2] and # 同じ変数を連続で使っていて
                op[1].lr[1] <= op[1].lr[0]+1 and # その変数をそこでしか使ってなくて
                ( op[2].kind == :var or op[2].kind == :const ) and 
                op[3].type.size == 1 # サイズが１なら
              r << [:index_pget, next_op[1], op[2], op[3]]
              ops[i+1] = nil
              next
            end
          elsif next_op[0] == :pset
#            pp op[1].lr
            if op[1] == next_op[1] and # 同じ変数を連続で使っていて
#                op[1].lr[1] <= op[1].lr[0]+1 and # その変数をそこでしか使ってなくて
                ( op[2].kind == :var or op[2].kind == :const ) and # 
                op[3].type.size == 1 # サイズが１なら
              r << [:index_pset, op[2], op[3], next_op[2]]
              ops[i+1] = nil
              next
            end
          end
        end
      end
      r << op
    end
    r
  end

  def alloc_register( block, ops )
    calc_liverange( block, ops )
    block.vars.each do |id,v|
      if v.kind != :var or # 変数じゃないか
          v.nonlocal or # ローカルじゃないか
          v.var_type == :arg or # 引数か
          v.var_type == :return_val # 帰り値
        v.reg = :mem
      elsif v.opt and v.opt[:address] 
        v.reg = :mem
      elsif v.lr.nil? 
        v.reg = :none
      elsif v.type.size > 1 # サイズが2byte以上
        v.reg = :mem
      else
        if v.lr[1] <= v.lr[0]
          if v.var_type == :temp
            v.reg = :none
          else
            v.reg = :mem
          end
        elsif v.lr[1] == v.lr[0]+1
          # pp '*',v,ops[v.lr[0]], ops[v.lr[1]]
          op1 = ops[v.lr[0]]
          op2 = ops[v.lr[1]]
          if op1[1] == v
            case op2[0]
            when :load
              if op2[2] == v
                v.reg = :a
              else
                v.reg = :mem
              end
            when :add, :sub, :lt, :eq
              if op2[2] == v
                v.reg = :a
              else
                v.reg == :mem
              end
            else
              v.reg = :mem
            end
          else
            v.reg = :mem
          end
        elsif v.var_type == :temp
          v.reg = :stack
        else
          v.reg = :mem
        end
      end
    end
  end

  def calc_liverange( block, ops )
    block.vars.each do |id,v|
      v.lr = nil
    end
    ops.each_with_index do |op,i|
      update_liverange( block, i, op[1..-1] )
    end
  end

  def update_liverange( block, i, vars )
    vars.each do |v|
      next unless Value === v
      if v.scope != block
        v.nonlocal = true
      else
        if v.lr
          v.lr[1] = i
        else
          v.lr = [i,i]
        end
      end
    end
  end

end

