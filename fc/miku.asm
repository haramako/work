_Vppu_put:
        lda _Vppu_put_Vto+1
        sta _VPPU_ADDR
        lda _Vppu_put_Vto
        sta _VPPU_ADDR
        ldy #0
.loop:
        lda [_Vppu_put_Vfrom],y
        sta _VPPU_DATA
        iny
        cpy _Vppu_put_Vsize
        bne .loop
        sty $100
        rts


;; function gr_sprite( x:int, y:int, pat:int, mode:int ):void options (extern:true) {}
;; {
;;   if( gr_sprite_idx >= 252 ){ return; }
;;   var p:int = gr_sprite_idx;
;;   gr_sprite_buf[p] = y;
;;   gr_sprite_buf[p+1] = pat;
;;   gr_sprite_buf[p+2] = mode;
;;   gr_sprite_buf[p+3] = x;
;;   gr_sprite_idx += 4;
;; }
;; USING: X
_Vgr_sprite:
        ldy _Vgr_sprite_idx     ; if( gr_sprite_idx >= 252 ){ return; } var p:int = gr_sprite_idx;
        cpy #252
        bcs .end
        lda _Vgr_sprite_Vy      ; gr_sprite_buf[p] = y;
        sta _Vgr_sprite_buf,y   
        iny                     ; gr_sprite_buf[p+1] = pat;
        lda _Vgr_sprite_Vp_0
        sta _Vgr_sprite_buf,y
        iny                     ; gr_sprite_buf[p+2] = mode;
        lda _Vgr_sprite_Vm_0     
        sta _Vgr_sprite_buf,y
        iny                     ; gr_sprite_buf[p+3] = x;
        lda _Vgr_sprite_Vx
        sta _Vgr_sprite_buf,y
        iny                     ; gr_sprite_idx += 4;
        sty _Vgr_sprite_idx
.end:
        rts
        
;; // 敵の弾の処理
;; function en_bul_process():void
;; {
;;   var i = 0;
;;   while( i<EN_BUL_MAX ){
;;     if( en_bul_type[i] ){
;;       en_bul_y[i] += (en_bul_vy[i]+giff16) / 16;
;;       en_bul_x[i] += (en_bul_vx[i]+giff16) / 16;
;;       gr_sprite( en_bul_x[i]-4, en_bul_y[i]-4, SPR_EN_BUL+anim, 1 );
;;       // 自機との当たり判定
;;       if( my_muteki == 0 && my_x + 4 - en_bul_x[i] < 8 && my_y + 4 - en_bul_y[i] < 8 ){
;;         my_bang = 1;
;;         en_bul_type[i] = 0;
;;       }
;;       // 死亡判定
;;       if( en_bul_y[i] < 8 || en_bul_y[i] > 248 || en_bul_x[i] < 8 || en_bul_x[i] > 248 ){
;;           en_bul_type[i] = 0;
;;       }
;;     }
;;     i += 1;
;;   }
;; }
;; USING: X,Y
_Ven_bul_proce_0:
        ldx #0                  ; while(...
.loop:
        lda _Ven_bul_type,x     ; if( en_bul_type[i] ){
        bne .then4
        jmp .end4
.then4:
        lda _Ven_bul_vy,x       ; en_bul_y[i] += (en_bul_vy[i]+giff16) / 16;
        clc
        adc _Vgiff16
        bpl .pl1
        lsr a
        lsr a
        lsr a
        lsr a
        ora #240
        jmp .end1
.pl1:
        lsr a
        lsr a
        lsr a
        lsr a
.end1:
        clc
        adc _Ven_bul_y,x
        sta _Ven_bul_y,x
        lda _Ven_bul_vx,x       ; en_bul_x[i] += (en_bul_vx[i]+giff16) / 16;
        clc
        adc _Vgiff16
        bpl .pl2
        lsr a
        lsr a
        lsr a
        lsr a
        ora #240
        jmp .end2
.pl2:
        lsr a
        lsr a
        lsr a
        lsr a
.end2:
        clc
        adc _Ven_bul_x,x
        sta _Ven_bul_x,x
        lda _Ven_bul_x,x        ; gr_sprite( en_bul_x[i]-4, en_bul_y[i]-4, SPR_EN_BUL+anim, 1 );
        sec
        sbc #4
        sta _Vgr_sprite_Vx
        lda _Ven_bul_y,x        
        sec
        sbc #4
        sta _Vgr_sprite_Vy
        lda #$e0
        clc
        adc _Vanim
        sta _Vgr_sprite_Vp_0
        lda #1                  
        sta _Vgr_sprite_Vm_0
        jsr _Vgr_sprite
        lda _Vmy_muteki         ; if( my_muteki == 0 && my_x + 4 - en_bul_x[i] < 8 && my_y + 4 - en_bul_y[i] < 8 ){
        bne .end3
        lda _Vmy_x              
        clc
        adc #8
        sec
        sbc _Ven_bul_x,x
        cmp #16
        bcs .end3
        lda _Vmy_y
        clc
        adc #8
        sec
        sbc _Ven_bul_y,x
        cmp #16
        bcs .end3
        lda #1
        sta _Vmy_bang           ; my_bang = 1;
        lda #0                  ; en_bul_type[i] = 0;
        sta _Ven_bul_type,x
.end3:
        lda _Ven_bul_y,x        ; if( en_bul_y[i] < 8 || en_bul_y[i] > 248 || en_bul_x[i] < 8 || en_bul_x[i] > 248 ){
        cmp #8
        bcc .kill
        cmp #240
        bcs .kill
        lda _Ven_bul_x,x
        cmp #8
        bcc .kill
        cmp #240
        bcs .kill
        jmp .loop_end
.kill:
        lda #0                  ; en_bul_type[i] = 0;
        sta _Ven_bul_type,x
.end4:
.loop_end:        
        inx                     ; i += 1;
        cpx #48                 ; while( i<EN_BUL_MAX ){
        beq .loop_end2          
        jmp .loop
.loop_end2:
        rts
        
        
;; function memcpy(from:int*, to:int*, size:int):void options (extern:true) {}
;; {
;;   var i = 0;
;;   while( i < size ){
;;     p[i] = c;
;;     i += 1;
;;   }
;; }
;;; USING Y
_Vmemcpy:
        ldy #0
.loop:
        lda [_Vmemcpy_Vfrom],y
        sta [_Vmemcpy_Vto],y
        iny
        cpy _Vmemcpy_Vsize
        bne .loop
        rts
        
;; function memset(p:int*, c:int, size:int):void options (extern:true) {}
;; {
;;   var i = 0;
;;   while( i < size ){
;;     p[i] = c;
;;     i += 1;
;;   }
;; }
;;; USING Y
_Vmemset:
        ldy #0
.loop:
        lda _Vmemset_Vc
        sta [_Vmemset_Vp],y
        iny
        cpy _Vmemset_Vsize
        bne .loop
        rts

;;; USING Y
_Vmemzero:
        lda #0
        tay
.loop:
        sta [_Vmemzero_Vp],y
        iny
        cpy _Vmemzero_Vsize
        bne .loop
        rts
                