
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

SUB__A: .db 1
SUB__B: .db 1
L16: .db 1
ADD__A: .db 1
ADD__B: .db 1
L10: .db 1
L13: .db 1
L15: .db 1
FIB__X: .db 1
L1: .db 1
L4: .db 1
L5: .db 1
L6: .db 1
L7: .db 1
L8: .db 1
L9: .db 1

	.org $8000
__start:
	sei
	cli
	ldx #0
	txs
	jsr MAIN
.loop:
    jmp .loop


MAIN:
    lda #0
    rts
SUB:
    lda SUB__A
    clc
    sbc SUB__B
    sta L16
    lda L16
    rts
ADD:
    lda ADD__A
    beq .L11
    lda #1
    sta L10
    jmp .L12
.L11:
    lda #2
    sta L10
.L12:
.L14:
    lda ADD__A
    clc
    adc ADD__B
    sta L15
    jmp .L14
    lda L13
    rts
FIB:
    lda FIB__X
    clc
    sbc #0
    sta L4
    lda L4
    beq .L2
    lda #1
    sta L1
    jmp .L3
.L2:
    lda FIB__X
    clc
    sbc #1
    sta L6
    jsr FIB
    lda FIB__X
    clc
    sbc #2
    sta L8
    jsr FIB
    lda L7
    clc
    adc L9
    sta L5
    lda L8
    sta L1
.L3:
    lda L1
    rts
