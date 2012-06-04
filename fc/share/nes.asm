    ;; this file is generated by fc command

    ;; options
<%= options_asm %>

    ;; interrupt vector
	.bank 1
	.org $FFFA
	.dw __interrupt
	.dw __start
	.dw 0

    ;; 
	.bank 0
__reg = 0                       ; 汎用レジスタ

	.bank 1
	.org $A000
__start:
	sei
	ldx #255
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

__mul_tbl_l0:
	.db 0,0,1,2,4,6,9,12,16,20,25,30,36,42,49,56
	.db 64,72,81,90,100,110,121,132,144,156,169,182,196,210,225,240
	.db 0,16,33,50,68,86,105,124,144,164,185,206,228,250,17,40
	.db 64,88,113,138,164,190,217,244,16,44,73,102,132,162,193,224
	.db 0,32,65,98,132,166,201,236,16,52,89,126,164,202,241,24
	.db 64,104,145,186,228,14,57,100,144,188,233,22,68,114,161,208
	.db 0,48,97,146,196,246,41,92,144,196,249,46,100,154,209,8
	.db 64,120,177,234,36,94,153,212,16,76,137,198,4,66,129,192
	.db 0,64,129,194,4,70,137,204,16,84,153,222,36,106,177,248
	.db 64,136,209,26,100,174,249,68,144,220,41,118,196,18,97,176
	.db 0,80,161,242,68,150,233,60,144,228,57,142,228,58,145,232
	.db 64,152,241,74,164,254,89,180,16,108,201,38,132,226,65,160
	.db 0,96,193,34,132,230,73,172,16,116,217,62,164,10,113,216
	.db 64,168,17,122,228,78,185,36,144,252,105,214,68,178,33,144
	.db 0,112,225,82,196,54,169,28,144,4,121,238,100,218,81,200
	.db 64,184,49,170,36,158,25,148,16,140,9,134,4,130,1,128
__mul_tbl_l1:
	.db 0,128,1,130,4,134,9,140,16,148,25,158,36,170,49,184
	.db 64,200,81,218,100,238,121,4,144,28,169,54,196,82,225,112
	.db 0,144,33,178,68,214,105,252,144,36,185,78,228,122,17,168
	.db 64,216,113,10,164,62,217,116,16,172,73,230,132,34,193,96
	.db 0,160,65,226,132,38,201,108,16,180,89,254,164,74,241,152
	.db 64,232,145,58,228,142,57,228,144,60,233,150,68,242,161,80
	.db 0,176,97,18,196,118,41,220,144,68,249,174,100,26,209,136
	.db 64,248,177,106,36,222,153,84,16,204,137,70,4,194,129,64
	.db 0,192,129,66,4,198,137,76,16,212,153,94,36,234,177,120
	.db 64,8,209,154,100,46,249,196,144,92,41,246,196,146,97,48
	.db 0,208,161,114,68,22,233,188,144,100,57,14,228,186,145,104
	.db 64,24,241,202,164,126,89,52,16,236,201,166,132,98,65,32
	.db 0,224,193,162,132,102,73,44,16,244,217,190,164,138,113,88
	.db 64,40,17,250,228,206,185,164,144,124,105,86,68,50,33,16
	.db 0,240,225,210,196,182,169,156,144,132,121,110,100,90,81,72
	.db 64,56,49,42,36,30,25,20,16,12,9,6,4,2,1,0
__mul_tbl_h0:
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2
	.db 2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3
	.db 4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6
	.db 6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8
	.db 9,9,9,9,9,9,10,10,10,10,10,11,11,11,11,12
	.db 12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15
	.db 16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19
	.db 20,20,20,21,21,21,21,22,22,22,23,23,23,24,24,24
	.db 25,25,25,25,26,26,26,27,27,27,28,28,28,29,29,29
	.db 30,30,30,31,31,31,32,32,33,33,33,34,34,34,35,35
	.db 36,36,36,37,37,37,38,38,39,39,39,40,40,41,41,41
	.db 42,42,43,43,43,44,44,45,45,45,46,46,47,47,48,48
	.db 49,49,49,50,50,51,51,52,52,53,53,53,54,54,55,55
	.db 56,56,57,57,58,58,59,59,60,60,61,61,62,62,63,63
__mul_tbl_h1:
	.db 64,64,65,65,66,66,67,67,68,68,69,69,70,70,71,71
	.db 72,72,73,73,74,74,75,76,76,77,77,78,78,79,79,80
	.db 81,81,82,82,83,83,84,84,85,86,86,87,87,88,89,89
	.db 90,90,91,92,92,93,93,94,95,95,96,96,97,98,98,99
	.db 100,100,101,101,102,103,103,104,105,105,106,106,107,108,108,109
	.db 110,110,111,112,112,113,114,114,115,116,116,117,118,118,119,120
	.db 121,121,122,123,123,124,125,125,126,127,127,128,129,130,130,131
	.db 132,132,133,134,135,135,136,137,138,138,139,140,141,141,142,143
	.db 144,144,145,146,147,147,148,149,150,150,151,152,153,153,154,155
	.db 156,157,157,158,159,160,160,161,162,163,164,164,165,166,167,168
	.db 169,169,170,171,172,173,173,174,175,176,177,178,178,179,180,181
	.db 182,183,183,184,185,186,187,188,189,189,190,191,192,193,194,195
	.db 196,196,197,198,199,200,201,202,203,203,204,205,206,207,208,209
	.db 210,211,212,212,213,214,215,216,217,218,219,220,221,222,223,224
	.db 225,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239
	.db 240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255

;;; 以下の等式を利用する
;;; a*b = f(a+b) - f(a-b)  | f(x): x*x/4
;;; __reg4 = __reg0 * __reg2
__mul_8:
        lda __reg+0             ; reg6 = (reg0-reg2)^2/4
        sec
        sbc __reg+2
        tax
        bcs .pl1
        lda __mul_tbl_l1,x
        jmp .pl1_end
.pl1:
        lda __mul_tbl_l0,x
.pl1_end:
        sta __reg+6
        lda __reg+0             ; a = (reg0+reg2)^2/4
        clc
        adc __reg+2
        tax
        bcc .pl2
        lda __mul_tbl_l1,x
        jmp .pl2_end
.pl2:
        lda __mul_tbl_l0,x
.pl2_end:
        sta __reg+7
        sec                     ; reg4 = a - reg6
        sbc __reg+6
        sta __reg+4
        rts

__mul_8t16:
        lda __reg+0             ; reg6 = (reg0-reg2)^2/4
        sec
        sbc __reg+2
        tax
        bcs .pl1
        lda __mul_tbl_l1,x
        jmp .pl1_end
.pl1:
        lda __mul_tbl_l0,x
.pl1_end:
        sta __reg+6
        lda __reg+0             ; a = (reg0+reg2)^2/4
        clc
        adc __reg+2
        tax
        bcc .pl2
        lda __mul_tbl_l1,x
        jmp .pl2_end
.pl2:
        lda __mul_tbl_l0,x
.pl2_end:
        sta __reg+7
        sec                     ; reg4 = a - reg6
        sbc __reg+6
        sta __reg+4
        rts
        
__mul_16:
        rts
        
        ;;  __reg4 = __reg0 / __reg2
__div_8:
        ldx #8
        lda #0
        sta __reg+5
.loop:
        rol __reg+0
        rol __reg+5
        
        lda __reg+5
        sec
        sbc __reg+2
        bcc .end
        sta __reg+5
.end:   
        rol __reg+4
        dex
        bne .loop
        rts
        
__div_16:
        rts
        
__mod_8:
        jsr __div_8
        lda __reg+5
        sta __reg+4
        rts
        
__mod_16:
        rts
        
	.bank 0
	.org $8000
        
<%= code_asm %>
<%= chr_asm %>
