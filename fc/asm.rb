# coding: utf-8

def mangle(str)
  str.gsub(/\$|_/){|v| { '$'=>'_V', '_'=>'__' }[v] }
end

######################################################################
# 中間コードコンパイラ
######################################################################
class OpCompiler
  attr_reader :code_asm, :data_asm

  def initialize
    @label_count = 0
    @code_asm = []
    @data_asm = []
  end

  def compile( com )
    com.func.each do |id,f|
      # 関数のデータをコンパイル
      @data_asm << "; function #{id}"
      f.block.vars.each do |id,v|
        @data_asm << "#{to_asm(v)}: .ds #{v.type.size}"
      end
      @data_asm << ''

      # 関数のコードをコンパイル
      @code_asm << "; function #{id}"
      @code_asm << "_#{id}:"
      @code_asm << compile_block( f.block )
      @code_asm << ''
    end
  end

  def compile_block( block )
    ops = block.ops
    r = []
    ops.each do |op| # op=オペランド
      r << "; #{op.inspect}"
      a = op.map{|x| if Value === x then to_asm(x) else x end } # アセンブラ表記に直したop, Value以外はそのまま
      case op[0]

      when :label
        r << op[1] + ':'

      when :if
        then_label = new_label
        op[1].type.size.times do |i|
          r << "lda #{byte(op[1],i)}"
          r << "bne #{then_label}"
        end
        r << "jmp #{op[2]}"
        r << "#{then_label}:"

      when :jump
        r << "jmp #{op[1]}"

      when :return
        r.concat load( block.vars[:'0'], op[1] )
        r << "rts"

      when :call
        r << "jsr #{to_asm(op[2])}"
        r.concat load( op[1], op[2].block.vars[:'0'] )

      when :load
        r.concat load( op[1], op[2] )

      when :add
        op[1].type.size.times do |i|
          r << "clc" if i == 0
          if op[2].type.size > i
            r << "lda #{byte(op[2],i)}"
          elsif op[2].type.size == i
            r << "lda #0"
          end
          r << "adc #{byte(op[3],i)}" if op[3].type.size > i
          r << "sta #{byte(op[1],i)}"
        end

      when :sub
        op[1].type.size.times do |i|
          r << "sec" if i == 0
          if op[2].type.size > i
            r << "lda #{byte(op[2],i)}"
          elsif op[2].type.size == i
            r << "lda #0"
          end
          r << "sbc #{byte(op[3],i)}" if op[3].type.size > i
          r << "sta #{byte(op[1],i)}"
        end

      when :eq
        true_label, end_label = new_label(2)
        ([op[2].type.size,op[3].type.size].max-1).downto(0) do |i|
          if op[2].type.size > i
            r << "lda #{byte(op[2],i)}"
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
        r << "sta #{a[1]}"
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << "sta #{a[1]}"
        r << "#{end_label}:"

      when :lt
        true_label, end_label = new_label(2)
        ([op[2].type.size,op[3].type.size].max-1).downto(0) do |i|
          if op[2].type.size > i
            r << "lda #{byte(op[2],i)}"
          elsif op[2].type.size == i
            r << "lda #0"
          end
          if op[3].type.size > i
            r << "cmp #{byte(op[3],i)}" 
          else
            r << "cmp #0" 
          end
          r << "bcs #{true_label}"
        end
        # falseのとき
        r << "lda #0"
        r << "sta #{a[1]}"
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << "sta #{a[1]}"
        r << "#{end_label}:"

      when :not
        true_label, end_label = new_label(2)
        op[2].type.size.times do |i|
          r << "lda #{byte(op[2],i)}"
          r << "beq #{true_label}"
        end
        # falseのとき
        r << "lda #0"
        r << "sta #{a[1]}"
        r << "jmp #{end_label}"
        # trueのとき
        r << "#{true_label}:"
        r << "lda #1"
        r << "sta #{a[1]}"
        r << "#{end_label}:"

        r << "lda #{to_asm(op[2])}"
        r << "eor #255"
        r << "sta #{to_asm(op[1])}"

      when :asm
        op[1].each do |line|
          r << "#{line[0]} " + line[1..-1].map{|o|to_asm(o)}.join(",")
        end

      when :index
        raise if op[3].type != TypeDecl[:int]
        raise if op[2].kind != :var
        r << "clc"
        r << "lda LOW(#{a[2]})+0"
        r << "adc #{a[3]}"
        r << "sta #{a[1]}+0"
        r << "lda HIGH(#{a[2]})+1"
        r << "adc #0"
        r << "sta #{a[1]}+1"

      when :pget
        r << "lda LOW(#{a[2]})"
        r << "sta __reg+0"
        r << "lda HIGH(#{a[2]})"
        r << "sta __reg+1"
        r << "ldy #0"
        r << "lda (__reg+0),y"
        r << "sta #{a[1]}"

      when :pset
        r << "lda LOW(#{a[2]})"
        r << "sta __reg+0"
        r << "lda HIGH(#{a[2]})"
        r << "sta __reg+1"
        r << "ldy #0"
        r << "lda #{a[1]}"
        r << "sta (__reg+0),y"

      else
        raise "unknow op #{op}"
      end
    end

    # ラベル行以外はインデントする
    r = r.map do |line|
      if line.index(':') and line[0] != ';'
        line
      else
        "\t"+line
      end
    end

    r
  end

  def load( to, from )
    r = []
    to.type.size.times do |i|
      if from.type.size > i
        r << "lda #{byte(from,i)}"
      elsif from.type.size == i
        r << "lda #0"
      end
      r << "sta #{byte(to,i)}"
    end
    r
  end

  def new_label
    @label_count += 1
    "._#{@label_count}"
  end

  def new_labels( n )
    Array.new(n){new_label }
  end

  def to_asm( v )
    if Function === v
      "_#{v.id}"
    elsif v.const?
      "##{v.val.to_s}"
    else
      "_#{v.scope.id}_D#{v.id}"
    end
  end

  def byte( v, n )
    if v.const?
      "##{v.val >> (n*8) % 256}"
    else
      "#{to_asm(v)}+#{n}"
    end
  end

end

__END__
@@base.asm
@OPTIONS
@INCLUDES
	.bank 1
	.org $FFFA
	.dw __interrupt
	.dw __start
	.dw 0

	.bank 0
	.org $0000
__reg: .ds 8

	.org $0200
@VARS

	.org $8000
__start:
	sei
	ldx #0
	txs
	jsr main
.loop:
    jmp .loop

__interrupt:
    pha
    txa
    pha
    tya
    pha
    jsr interrupt
    pla
    tay
    pla
    tax
    pla
    rti

@FUNCS
