#lang racket

(require racket/cmdline)

(define num-dates 5)

(define lib-path 
  (case (system-type)
    [(unix)
     (if (fixnum? (expt 2 40))
         "linux-amd64/libwarp.so.1.0"
         "linux-i386/libwarp.so.1.0")]
    [(macosx)
     (if (fixnum? (expt 2 40))
         "mac-amd64/libwarp.dylib.1.0"
         "mac-i386/libwarp.dylib.1.0")]
    [else (error 'run-date "warp is not supported on windows")]))

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
