# coding: utf-8

######################################################################
# 中間コードコンパイラ
######################################################################
module OpCompiler
  module_function

  def to_asm( op )
    if op.respond_to?(:to_asm)
      op.to_asm
    elsif Numeric === op
      "#"+op.to_s
    else
      op.to_s
    end
  end

  def compile( ops )
    r = []
    ops.each do |op|
      r << "; #{op.inspect}"
      case op[0]
      when :label
        r << op[1] + ':'
      when :if
        r << "lda #{to_asm(op[1])}"
        r << "beq #{to_asm(op[2])}"
      when :jump
        r << "jmp #{to_asm(op[1])}"
      when :return
        r << "lda #{to_asm(op[1])}"
        r << "rts"
      when :call
        r << "jsr #{to_asm(op[1])}"
      when :load
        r << "lda #{to_asm(op[2])}"
        r << "sta #{to_asm(op[1])}"
      when :add
        r << "lda #{to_asm(op[2])}"
        r << "clc"
        r << "adc #{to_asm(op[3])}"
        r << "sta #{to_asm(op[1])}"
      when :sub
        r << "lda #{to_asm(op[2])}"
        r << "sec"
        r << "sbc #{to_asm(op[3])}"
        r << "sta #{to_asm(op[1])}"
      when :ne
        r << "lda #{to_asm(op[2])}"
        r << "sec"
        r << "sbc #{to_asm(op[3])}"
        r << "eor #255"
        r << "sta #{to_asm(op[1])}"
      when :not
        r << "lda #{to_asm(op[2])}"
        r << "eor #255"
        r << "sta #{to_asm(op[1])}"
      when :asm
        op[1].each do |line|
          r << "#{line[0]} " + line[1..-1].map{|o|to_asm(o)}.join(",")
        end
      else
        raise "unknow op #{op}"
      end
    end
    # ラベル行以外はインデントする
    r = r.map do |line|
      if line.index(':') and line[0] != ';'
        line
      else
        "    "+line
      end
    end
    r
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
__putc_pos: .ds 1

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

__ppu_put:
    ldy #0
.loop:
    lda [__reg+0],y
    sta $2007
    iny
    cpy __reg+2
    bne .loop
    rts

__ppu_fill:
    ldx #0
.loop:
    lda __reg+0
    sta $2007
    inx
    cpx __reg+1
    bne .loop
    rts

__putc:
    sta $70,x
    inx
    rts

@FUNCS
