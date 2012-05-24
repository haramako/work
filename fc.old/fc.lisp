;(import 'alexandria)
(require 'fcasm)

(setq fc-func-alist (make-hash-table))
(setq fc-cur-func nil)
(setq fc-op-list nil)
(setq fc-reg-list nil)
(setq fc-label-counter 0)

(defun fc-emit (op)
  (setq fc-op-list (append fc-op-list (list op))))

(defun fc-new-label ()
  (setq fc-label-counter (1+ fc-label-counter))
  (intern (format nil "L~A" fc-label-counter)))

(defun fc-new-reg ()
  (let ((reg (fc-new-label)))
    (setq fc-reg-list (append fc-reg-list (list reg)))
    reg))

(defun fc-2op (op exp)
  (setq result (fc-new-reg))
  (fc-emit (list op result
                 (fc-compile-exp (second exp))
                 (fc-compile-exp (third exp))))
  result)

(defun fc-print-op (op)
  (map nil #'(lambda (x) (print x)) op))

(defun fc-compile-block (block)
  (let ((x))
    (setq x (map 'list #'fc-compile-exp block))
    (car (last x))))

(defun fc-compile-exp (exp)
  (cond
   ((numberp exp) exp)
   ((symbolp exp) (intern (format nil "~A__~A" fc-cur-func exp)))
   ((listp exp)
      (setq exp (macroexpand exp))
      (let ((f (first exp)) (result nil))
        (fc-emit (list '-- f))
        (case f
          (quote (second exp))
          (+ (fc-2op 'add exp))
          (- (fc-2op 'sub exp))
          (eq (fc-2op 'eq exp))
          (eql (fc-2op 'eq exp))
          (if (setq result (fc-new-reg))
              (let ((else-label (fc-new-label)) (end-label (fc-new-label)))
                (fc-emit (list 'if-not (fc-compile-exp (second exp)) else-label))
                (fc-emit (list 'assign result (fc-compile-exp (third exp))))
                (fc-emit (list 'jump end-label))
                (fc-emit (list 'label else-label))
                (fc-emit (list 'assign result (fc-compile-exp (fourth exp))))
                (fc-emit (list 'label end-label))
                result))
          (fc-loop (setq result (fc-new-reg))
                 (let ((loop-label (fc-new-label)))
                   (fc-emit (list 'label loop-label))
                   (fc-compile-block (cdr exp))
                   (fc-emit (list 'jump loop-label))
                   result))
          (progn (fc-compile-block (cdr exp)))
          (let
              (map nil #'(lambda (x)
                           (setq fc-reg-list (append fc-reg-list (list (car x))))
                           (fc-emit (list 'assign (first x) (second x))))
                   (second exp))
              (fc-compile-block (nthcdr 2 exp)))
          (otherwise
           (if (symbolp f)
               (let ((args (map 'list #'fc-compile-exp (cdr exp)))
                     (func (gethash f fc-func-alist))
                     (tmp))
                 (setq result (fc-new-reg))
                 (map-into args #'(lambda (name arg)
                                    (fc-emit (list 'assign (intern (format nil "~A__~A" f name)) arg))
                                    arg
                                    )
                           (second func) args)
                 (fc-emit (list 'call f))
                 result)
             (progn (format t "~%error: unknown symbol ~S" f) nil)
             )
           ))))))

(defmacro fc-func (name args &rest block)
  (print "====")
  (format t "~%name: ~S~%args: ~S~%block: ~S" name args block)
  (setq args (map 'list #'(lambda (v) (intern (format nil "~A__~A" name v))) args))
  (setq fc-op-list nil)
  (setq fc-reg-list args)
  (setq fc-cur-func name)
  (setf (gethash name fc-func-alist) (list args))
  (fc-emit (list 'return (fc-compile-block block)))
  (setf (gethash name fc-func-alist) (list args fc-reg-list fc-op-list))
  ;(fc-print-op fc-op-list)
  ;(print fc-reg-list)
  nil
  )