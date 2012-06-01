# coding: utf-8
require 'digest/md5'

######################################################################
# 中間コードコンパイラ
######################################################################
class OpCompiler
  attr_reader :asm, :char_banks, :includes, :address, :address_zeropage

  def initialize
    @label_count = 0
    @asm = []
    @address = 0x200
    @address_zeropage = 0x010
    @trim_table = Hash.new
    @char_banks = Hash.new {|h,k| h[k] = [] } # バンクごとのアセンブラ
  end

  def compile( block, extern = false )

    # lambdaのコンパイル
    block.vars.each do |id,v|
      if Lambda === v.val 
        compile v.val.block, v.val.opt[:extern]
      end
    end

    @asm << "; function #{block.id}" 

    # include(.asm)の処理
    block.includes.each do |file|
      @asm << "\t.include \"#{file}\""
    end

    # 関数のコードをコンパイル
    code_asm = compile_block( block )

    # 関数のデータをコンパイル
    block.vars.each do |id,v|
      if v.opt and v.opt[:address]
        @asm << "#{to_asm(v)} = #{v.opt[:address]}"
        v.address = v.opt[:address]
      elsif v.const?
        # constの場合
        if v.opt[:file]
          raise "invalid const #{v}" unless v.opt[:char_bank] and Numeric === v.opt[:char_bank]
          @char_banks[v.opt[:char_bank]] << "\t.incbin \"#{v.opt[:file]}\""
        elsif Array === v.val
          @asm << "#{to_asm(v)}:"
          v.val.each_slice(16) do |slice|
            @asm << "\t.db #{slice.join(',')}"
          end
        elsif Numeric === v.val or Lambda === v.val
          # function, 数値定数
        else
          raise "invalid const #{v}"
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

    if extern
      # DO NOTHING
    else
      @asm.concat code_asm
    end
    @asm << ''

  end

  def compile_block( block )
    ops = block.ops
    block.optimized_ops = Marshal.load(Marshal.dump(ops))
    ops = optimize( block, ops )
    block.optimized_ops = ops
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

      when :and, :or, :xor
        op[1].type.size.times do |i|
          if op[2].type.size > i
            r << load_a( op[2],i)
          elsif op[2].type.size == i
            r << "lda #0"
          end
          as = {and:'and', or:'ora', xor:'eor'}[op[0]]
          r << "#{as} #{byte(op[3],i)}"
          r << store_a(op[1],i)
        end

      when :mul, :div, :mod
        # 定数で２の累乗の場合の最適化
        if Numeric === op[3].val and [0,1,2,4,8,16,32,64,128,256].include?(op[3].val) and op[1].type.size == 1
          n = Math.log(op[3].val,2).to_i
          r << load_a( op[2], 0 )
          case op[0]
           when :mul
            n.times { r << "asl a" }
          when :div
            if op[2].type.signed
              negative_label, end_label = new_labels(2)
              r << "bmi #{negative_label}"
              n.times { r << "lsr a" }
              r << "jmp #{end_label}"
              r << "#{negative_label}:"
              r << "sta __reg+0"
              r << "sec"
              r << "lda #0"
              r << "sbc __reg+0"
              n.times { r << "lsr a" }
              r << "sta __reg+0"
              r << "lda #0"
              r << "sec"
              r << "sbc __reg+0"
              r << "#{end_label}:"
            else
              n.times { r << "lsr a" }
            end
          when :mod
            r << "and ##{op[3].val-1}"
          end
          r << store_a( op[1], 0 )
        elsif Numeric === op[3].val and [0,1,2,4,8,16,32,64,128,256].include?(op[3].val) and op[1].type.size > 1
          n = Math.log(op[3].val,2).to_i
          size = op[1].type.size
          case op[0]
          when :mul
            r.concat load( op[1], op[2] )
            n.times do 
              size.times do |i| 
                rot = ( i == 0 ? 'asl' : 'rol' )
                r << "#{rot} #{byte(op[1],i)}" 
              end
            end
          when :div
            r.concat load( op[1], op[2] )
            n.times do 
              (size-1).downto(0) do |i| 
                rot = ( i == size-1 ? 'lsr' : 'ror' )
                r << "#{rot} #{byte(op[1],i)}"
              end
            end
          when :mod
            size.times do |i| 
              r << load_a( op[2], i )
              r << "and ##{((op[3].val-1)>>(i*8))%256}"
              r << store_a( op[1], i )
            end
          end
        else
          op[1].type.size.times do |i|
            r << load_a(op[2],i)
            r << "sta __reg+0+#{i}"
            r << load_a(op[3],i)
            r << "sta __reg+2+#{i}"
          end
          if op[1].type.size == 1
            r << "jsr __#{op[0]}_8"
          else
            r << "jsr __#{op[0]}_16"
          end
          op[1].type.size.times do |i|
            r << "lda __reg+4+#{i}"
            r << store_a(op[1],i)
          end
        end

      when :uminus
        raise if op[1].type.type != :int
        op[1].type.size.times do |i|
          r << "sec" if i == 0
          r << "lda #0"
          r << "sbc #{byte(op[2],i)}" if op[2].type.size > i
          r << store_a(op[1],i)
        end

      when :eq
        false_label, end_label = new_labels(2)
        [ op[2].type.size, op[3].type.size ].max.times do |i|
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
          r << "bne #{false_label}"
        end
        # falseのとき
        r << "lda #1"
        r << store_a(op[1],0)
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{false_label}:"
        r << "lda #0"
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
        r << op[1]

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
          r.concat load_y_idx(op[3],op[2])
          op[1].type.size.times do |i|
            r << "lda #{a[2]}+#{i},y"
            r << store_a(op[1],i)
          end
        elsif op[2].type.type == :pointer
          r.concat load_y_idx(op[3],op[2])
          op[1].type.size.times do |i|
            r << "iny" if i != 0
            r << "lda [#{a[2]}],y"
            r << store_a(op[1],i)
          end
        else
          raise
        end

      when :index_pset
        if op[1].type.type == :array
          r.concat load_y_idx(op[2],op[1])
          op[3].type.size.times do |i|
            r << load_a( op[3],i)
            r << "sta #{a[1]}+#{i},y"
          end
        elsif op[1].type.type == :pointer
          r.concat load_y_idx(op[2],op[1])
          op[3].type.size.times do |i|
            r << "iny" if i != 0
            r << load_a( op[3],i)
            r << "sta [#{a[1]}],y"
          end
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

  def load_y_idx( idx, ptr )
    r = []
    if ptr.type.base.size == 1
      r << "ldy #{byte(idx,0)}"
    else
      r << "lda #{byte(idx,0)}"
      (ptr.type.base.size-1).times { r << 'asl a'}
      r << "tay"
    end
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
    when :stack
      "pla"
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
    when :stack
      "pha"
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
        mangle "#{to_asm(v.upper)}_V#{v.id}"
      else
        mangle "#{v.id}"
      end
    elsif v.kind == :literal
      "##{v.val.to_s}"
    else
      if v.scope
        mangle "#{to_asm(v.scope)}_V#{v.id}"
      else
        mangle "#{v.id}"
      end
    end
  end

  # 長すぎる場合は、だめっぽいのでカットする
  def mangle(str)
    return str if str.size < 16
    n = 0
    while true
      trimed = str[0,14]+'_'+n.to_s
      if @trim_table[trimed] == str
        return trimed
      elsif @trim_table[trimed].nil?
        @trim_table[trimed] = str
        return trimed
      end
      n += 1
    end
    raise
  end

  def byte( v, n )
    if v.const? and Numeric === v.val
      "##{(v.val >> (n*8)) % 256}"
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
      when :load
        if op[1].lr.nil? or op[1].lr[0] == op[1].lr[1] 
          unless op[1].opt[:address] or op[1].nonlocal
            #puts "omit #{op}"
            next
          end
        end
      when :pget, :pset
        if Value === op[1] 
          if op[1].lr.nil? or op[1].lr[0] == op[1].lr[1]
            #puts "omit #{op}"
            next
          end
        end
      when :call
        if Value === op[1] 
          if op[1].lr.nil? or op[1].lr[0] == op[1].lr[1]
            #puts "omit #{op}"
            r << [op[0]]+[nil]+op[2..-1]
            next
          end
        end
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
              # puts "replace #{op}"
              r << [:index_pget, next_op[1], op[2], op[3]]
              ops[i+1] = nil
              next
            end
          elsif next_op[0] == :pset
            if op[1] == next_op[1] and # 同じ変数を連続で使っていて
                op[1].lr[1] <= op[1].lr[0]+1 and # その変数をそこでしか使ってなくて
                ( op[2].kind == :var or op[2].kind == :const ) and # 
                op[3].type.size == 1 # サイズが１なら
              # puts "replace #{op}"
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
          v.var_type == :return_val # 返り値
        v.reg = :mem
      elsif v.opt and v.opt[:address] # address指定なら mem
        v.reg = :mem
      elsif v.lr.nil? # 使われてないなら none
        v.reg = :none
      elsif v.type.size > 1 # サイズが2byte以上なら mem
        v.reg = :mem
      else
        if v.lr[1] <= v.lr[0] # 寿命が0ならそれは使ってないよね
          v.reg = :none
        elsif v.lr[1] == v.lr[0]+1
          # pp '*',v,ops[v.lr[0]], ops[v.lr[1]]
          op1 = ops[v.lr[0]]
          op2 = ops[v.lr[1]]
          if op1[1] == v
            case op2[0]
            when :load
              v.reg = :a if op2[2] == v
            when :add, :sub, :lt, :eq, :mul, :div, :mod
              v.reg = :a if op2[2] == v
            end
          end
        elsif v.var_type == :temp
          v.reg = :mem
          #v.reg = :stack
        end
      end
      unless v.reg
        v.reg = :mem
      end
    end
  end

  def calc_liverange( block, ops )
    block.vars.each do |id,v|
      if v.var_type == :arg or v.var_type == :return_val
        v.lr = [0, ops.size-1]
      else
        v.lr = nil
      end
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

