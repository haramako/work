	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	.bank 1
	.org $FFFA
	.dw 0
	.dw __start
	.dw 0

	.bank 0
	.org $0000
; global
PPU = $2022
; function main
; function add
addLa .db 1
addLb .db 1
addL0 .db 1
addL1 .db 1

	.org $8000
__start:
	sei
	cli
	ldx #0
	txs
	jsr main
.loop:
    jmp .loop

; function main
main:
    lda #8
    sta PPU
.begin_0:
    lda #1
    beq .end_0
    lda PPU
    sta addLa
    lda #2
    sta addLb
    jsr add
    jmp .begin_0
.end_0:
    rts
; function add
add:
    lda addLa
    beq .else_0
.then_0:
    lda addLa
    clc
    adc addLb
    sta addL0
    lda addL0
    rts
    jmp .end_0
.else_0:
    lda addLa
    clc
    sbc addLb
    sta addL1
    lda addL1
    rts
.end_0:
    rts