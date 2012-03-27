#lang racket

(require racket/cmdline)

(define num-dates 5)

(define lib-path "libwarp.so.1.0")

(command-line
 #:once-each
 ["-d" d "number" (set! num-dates (string->number d))])

(define l 
  (for/list ([i (in-range num-dates)])
    (format "~a" (* -1 86400 i))))

(for ([i l])
  (system 
   (format "WARP=~a LD_PRELOAD=~a racket -l meta/build/test-drracket" 
           i lib-path)))
