#lang racket/base

(require racket/cmdline
         racket/date
         racket/system)

(define num-dates 5)

(define 64bit? (fixnum? (expt 2 40)))

(define lib-path 
  (case (system-type)
    [(unix)
     (if 64bit?
         "linux-amd64/libwarp.so.1.0"
         "linux-i386/libwarp.so.1.0")]
    [(macosx)
     (if 64bit?
         "mac-amd64/libwarp.dylib.1.0"
         "mac-i386/libwarp.dylib.1.0")]
    [else (error 'run-date "warp is not supported on windows")]))

(command-line
 #:once-each
 ["-d" d "number of days (defaults to 5)" (set! num-dates (string->number d))])

(define racket
  (let ([p (find-system-path 'exec-file)])
    (if (absolute-path? p)
        (path->string p)
        "racket")))

(define now (current-seconds))
(for ([i (in-range num-dates)])
  (define secs (+ now (* 86400 i)))
  (system 
   (string-append (format "WARP=~a LD_PRELOAD=~a" i lib-path)
                  " "
                  racket
                  " -l racket/base -l tests/drracket/private/easter-egg-lib"
                  " -e \"(start-up-and-check-car)\"")))
