; options
    .inesprg 1;
    .ineschr 1;
    .inesmir 0;
    .inesmap 0;
; include_bin
    .bank 2
    .org 0
    .incbin "character.chr"
	.bank 1
	.org $FFFA
	.dw __interrupt
	.dw __start
	.dw 0

	.bank 0
	.org $0000
__reg: .ds 8
; global
PPUCTRL1 = $2000
PPUCTRL2 = $2001
PPUSTAT = $2002
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
frame .ds 1
vblankflag .ds 1
scroll0 .ds 1
scroll1 .ds 1
; function main
mainLx .ds 1
mainLy .ds 1
mainL0 .ds 1
mainL1 .ds 1
mainL2 .ds 1
; function reset_scroll
; function wait_vblank
; function interrupt

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

PALLET: .incbin "giko.pal"
; function main
main:
    ; [:load, scroll0, 0]
    lda #0
    sta scroll0
    ; [:load, scroll1, 0]
    lda #0
    sta scroll1
    ; [:load, PPU_CTRL1, 0]
    lda #0
    sta PPUCTRL1
    ; [:load, PPU_CTRL2, 0]
    lda #0
    sta PPUCTRL2
    ; [:load, PPU_ADDR, 63]
    lda #63
    sta PPUADDR
    ; [:load, PPU_ADDR, 0]
    lda #0
    sta PPUADDR
    ; [:asm, [[:lda, "#LOW(PALLET)"], [:sta, "__reg+0"], [:lda, "#HIGH(PALLET)"], [:sta, "__reg+1"], [:lda, 32], [:sta, "__reg+2"], [:jsr, "__ppu_put"]]]
    lda #LOW(PALLET)
    sta __reg+0
    lda #HIGH(PALLET)
    sta __reg+1
    lda #32
    sta __reg+2
    jsr __ppu_put
    ; [:load, PPU_ADDR, 32]
    lda #32
    sta PPUADDR
    ; [:load, PPU_ADDR, 0]
    lda #0
    sta PPUADDR
    ; [:load, main$x, 1]
    lda #1
    sta mainLx
    ; [:label, ".begin_1"]
.begin_1:
    ; [:ne, main$0, main$x, 0]
    lda mainLx
    sec
    sbc #0
    eor #255
    sta mainL0
    ; [:if, main$0, ".end_1"]
    lda mainL0
    beq .end_1
    ; [:load, PPU_DATA, main$x]
    lda mainLx
    sta PPUDATA
    ; [:add, main$1, main$x, 1]
    lda mainLx
    clc
    adc #1
    sta mainL1
    ; [:load, main$x, main$1]
    lda mainL1
    sta mainLx
    ; [:jump, ".begin_1"]
    jmp .begin_1
    ; [:label, ".end_1"]
.end_1:
    ; [:load, PPU_ADDR, 34]
    lda #34
    sta PPUADDR
    ; [:load, PPU_ADDR, 0]
    lda #0
    sta PPUADDR
    ; [:asm, [[:lda, 68], [:sta, "__reg+0"], [:lda, 0], [:sta, "__reg+1"], [:jsr, "__ppu_fill"]]]
    lda #68
    sta __reg+0
    lda #0
    sta __reg+1
    jsr __ppu_fill
    ; [:call, <Function:reset_scroll>]
    jsr reset_scroll
    ; [:load, PPU_CTRL1, 128]
    lda #128
    sta PPUCTRL1
    ; [:load, PPU_CTRL2, 24]
    lda #24
    sta PPUCTRL2
    ; [:label, ".begin_2"]
.begin_2:
    ; [:if, 1, ".end_2"]
    lda #1
    beq .end_2
    ; [:call, <Function:wait_vblank>]
    jsr wait_vblank
    ; [:add, main$2, frame, 1]
    lda frame
    clc
    adc #1
    sta mainL2
    ; [:load, frame, main$2]
    lda mainL2
    sta frame
    ; [:load, PPU_ADDR, 33]
    lda #33
    sta PPUADDR
    ; [:load, PPU_ADDR, frame]
    lda frame
    sta PPUADDR
    ; [:load, PPU_DATA, frame]
    lda frame
    sta PPUDATA
    ; [:call, <Function:reset_scroll>]
    jsr reset_scroll
    ; [:jump, ".begin_2"]
    jmp .begin_2
    ; [:label, ".end_2"]
.end_2:
    rts
; function reset_scroll
reset_scroll:
    ; [:load, PPU_SCROLL, scroll0]
    lda scroll0
    sta PPUSCROLL
    ; [:load, PPU_SCROLL, scroll1]
    lda scroll1
    sta PPUSCROLL
    rts
; function wait_vblank
wait_vblank:
    ; [:load, vblank_flag, 1]
    lda #1
    sta vblankflag
    ; [:label, ".begin_1"]
.begin_1:
    ; [:if, vblank_flag, ".end_1"]
    lda vblankflag
    beq .end_1
    ; [:jump, ".begin_1"]
    jmp .begin_1
    ; [:label, ".end_1"]
.end_1:
    rts
; function interrupt
interrupt:
    ; [:load, vblank_flag, 0]
    lda #0
    sta vblankflag
    rts
