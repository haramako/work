;(import '(alexandria))

(setq fcasm-header
"
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
")

(setq fcasm-header2
"
	.org $8000
__start:
	sei
	cli
	ldx #0
	txs
	jsr MAIN
.loop:
    jmp .loop

")

(setq fcasm-code nil)
(setq fcasm-var-list nil)

(defun fcasm-operand (x)
  (if (not x) "#0"
    (if (numberp x)
        (format nil "#~A" x)
      (format nil "~A" x))))

(defmacro fcasm-emit (&rest code)
  `(progn
     (setq fcasm-code (append fcasm-code (list (format nil ,@code ))))
     ))

(defun fcasm-compile-one (op)
  (case (car op)
    (label (fcasm-emit ".~A:" (second op)))
    (add (fcasm-emit "lda ~A" (fcasm-operand (third op)))
         (fcasm-emit "clc")
         (fcasm-emit "adc ~A" (fcasm-operand (fourth op)))
         (fcasm-emit "sta ~A" (fcasm-operand (second op))))
    (sub (fcasm-emit "lda ~A" (fcasm-operand (third op)))
         (fcasm-emit "clc")
         (fcasm-emit "sbc ~A" (fcasm-operand (fourth op)))
         (fcasm-emit "sta ~A" (fcasm-operand (second op))))
    (eq (fcasm-emit "lda ~A" (fcasm-operand (third op)))
        (fcasm-emit "clc")
        (fcasm-emit "sbc ~A" (fcasm-operand (fourth op)))
        (fcasm-emit "sta ~A" (fcasm-operand (second op))))
    (assign (fcasm-emit "lda ~A" (fcasm-operand (third op)))
            (fcasm-emit "sta ~A" (fcasm-operand (second op))))
    (if-not (fcasm-emit "lda ~A" (fcasm-operand (second op)))
            (fcasm-emit "beq .~A" (third op)))
    (jump (fcasm-emit "jmp .~A" (second op)))
    (call (fcasm-emit "jsr ~A" (second op)))
    (return (fcasm-emit "lda ~A" (fcasm-operand (second op)))
            (fcasm-emit "rts"))
    (-- )
    (otherwise (format t "~%error: unknown op ~S" op))
    ))
  
(defun fcasm-compile-func (name vars ops)
  (setq fcasm-cur-func name)
  (fcasm-emit "~A:" name)
  (setq fcasm-var-list (append fcasm-var-list vars))
  (map nil #'fcasm-compile-one ops))

(defun fcasm-output (file)
  (with-open-file
   (out file :direction :output)
   (write-line fcasm-header out)
   (map nil #'(lambda (var)
                (format out "~A: .db 1~%" var)
                )
        fcasm-var-list )
   (write-line fcasm-header2 out)
   (map nil #'(lambda (str)
                (if (find #\: str)
                    (format out "~A~%" str)
                  (format out "    ~A~%" str))
                )
        fcasm-code)))
