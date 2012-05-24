	.inesprg 1 ;   - プログラムにいくつのバンクを使うか。今は１つ。
	.ineschr 1 ;   - グラフィックデータにいくつのバンクを使うか。今は１つ。
	.inesmir 0 ;   - 水平ミラーリング
	.inesmap 0 ;   - マッパー。０番にする。

	.bank 2       ; バンク２
	.org $0000    ; $0000から開始

	.incbin "giko.spr"  ; 背景データのバイナリィファイルをincludeする
	.incbin "giko.spr"  ; スプライトデータのバイナリィファイルをincludeする

	.bank 1
	.org $FFFA
	.dw 0
	.dw __start
	.dw 0

	.bank 0
	.org $0000
; global
PPUCTRL1 = $2000
PPUCTRL2 = $2001
PPUSTAT = $2002
; function main

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
    lda #%00000000
    sta PPUCTRL1
    lda #%00011000
    sta PPUCTRL2
        lda #$3F
        sta $2006
        lda #$00
        sta $2006
        
        lda #12
        sta $2007
        lda #23
        sta $2007
        lda #10
        sta $2007
        lda #11
        sta $2007
    rts