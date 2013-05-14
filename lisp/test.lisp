(define a 'hoge)
(display a #f)
(set! a 'fuga)
(display a #t)
(define x 1 )

(if #t
	(display 1 a)
  (display 2 a))

(let ((a 1) (x (+ x 1)))
  (display a x))

(define +1 (lambda (x) (+ x 1)))

(display (+1 3))

(define +n (lambda (x) (lambda (y) (+ x y))))

(define +3 (+n 3))
(define +4 (+n 4))

(display (+3 (+4 0)))

(display `(1 (2 ,x)))

(define m+1 (macro (x) `(+ ,x 1)))

(display (m+1 1))

(display (macro-expand (m+1 1)))

(display '())

(define +2 (lambda (x) (m+1 1)))

(display (+2 1))

(define n 0)
(loop
 (display n)
 (set! n (+ n 1))
 (if (eq? n 10) (break)))

(display (gemsym))
(display (gemsym))
(define sym (gemsym))
(display (eq? sym sym))

(display (car '(1 2)))
(display (cdr '(1 2 3)))


