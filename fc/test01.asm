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
; global
PPUCTRL1 = $2000
PPUCTRL2 = $2001
PPUSTAT = $2002
PPUADDR = $2006
PPUDATA = $2007
; function main
mainLx .db 1
mainLy .db 1
mainL0 .db 1
mainL1 .db 1
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

PALLET: .incbin "giko.pal"
; function main
main:
    lda #0
    sta PPUCTRL1
    lda #0
    sta PPUCTRL2
    lda #63
    sta PPUADDR
    lda #0
    sta PPUADDR
    ldx #0
.ppu_put_1:
    lda PALLET, x
    stx $2007
    inx
    cpx 32
    bne .ppu_put_1
    lda #32
    sta PPUADDR
    lda #0
    sta PPUADDR
    lda #1
    sta mainLx
.begin_2:
    lda mainLx
    sec
    sbc #0
    eor #255
    sta mainL0
    lda mainL0
    beq .end_2
    lda mainLx
    sta PPUDATA
    lda mainLx
    clc
    adc #1
    sta mainL1
    lda mainL1
    sta mainLx
    jmp .begin_2
.end_2:
    lda #24
    sta PPUCTRL2
    sei
    rts
; function interrupt
interrupt:
    rts
