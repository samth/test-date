#lang racket

(require racket/cmdline)

(define num-dates 5)

(define lib-path "libwarp.so.1.0")

(define arch-path 
  (if (fixnum? (expt 2 40))
      "linux-amd64"
      "linux-i386"))

(command-line
 #:once-each
 ["-d" d "number" (set! num-dates (string->number d))])

(define l 
  (for/list ([i (in-range num-dates)])
    (format "~a" (* -1 86400 i))))

(for ([i l])
  (system 
   (format "WARP=~a LD_PRELOAD=~a/~a racket -l meta/build/test-drracket" 
           i arch-path lib-path)))
