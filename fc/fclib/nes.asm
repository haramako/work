
ppu_put:
		lda __STACK__+1,x
		sta PPU_ADDR
		lda __STACK__+0,x
		sta PPU_ADDR
		
		lda __STACK__+2,x		; reg[2,3] = addr
		sta __reg+0
		lda __STACK__+3,x
		sta __reg+1
		lda __STACK__+4,x
		sta __reg+2
		ldy #0
.loop:
		lda [__reg],y
		sta $40,y
		sta PPU_DATA
		iny
		cpy __reg+2
		bne .loop
.end:
		rts
		
print:
		lda print_addr+1
		sta PPU_ADDR
		lda print_addr+0
		sta PPU_ADDR
		
		lda __STACK__+0,x
		sta __reg+0
		lda __STACK__+1,x
		sta __reg+1

		ldy #0
.loop:	
		lda [__reg],y
		beq .end
		iny
		cmp #10
		bne .not_lf
		
		lda print_addr+0
		and #%11100000
		clc
		adc #32
		sta print_addr+0
		lda #0
		adc print_addr+1
		sta print_addr+1
		sta PPU_ADDR
		lda print_addr+0
		sta PPU_ADDR
		jmp .loop
		
.not_lf:		
		sta PPU_DATA
		inc print_addr+0		; print_addr[0,1] += y
		bne .loop
		inc print_addr+1
		jmp .loop
.end:
		rts

print_int16:
		lda __STACK__+0,x
		sta __reg+4
		jsr print_int8
		lda __STACK__+1,x
		sta __reg+4
		jsr print_int8
		rts
		
print_int8:
		lda __reg+4
		ror a
		ror a
		ror a
		ror a
		and #15
		tay
		lda .char,y
		sta __reg+5

		lda __reg+4
		and #15
		tay
		lda .char,y
		sta __reg+6
		
		lda #0
		sta __reg+7

		lda #LOW(__reg+5)
		sta __STACK__+0,x
		lda #HIGH(__reg+5)
		sta __STACK__+1,x
		jsr print
		
		rts
.char:
		.db	48,49,50,51,52,53,54,55,56,57,65,66,67,67,69,70
		
interrupt:
		lda #1
		sta vsync_flag
		rts
		
wait_vsync:
		lda #0
		sta vsync_flag
.loop:
		lda vsync_flag
		beq .loop
		rts
		