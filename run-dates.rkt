#lang racket/base

(require racket/cmdline
         racket/date
         racket/system)

(define now (current-seconds))
(define now-date (seconds->date now))

(define num-dates 5)
(define start-month (date-month now-date))
(define start-day (date-day now-date))
(define start-year #f)

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
 ["-n" n "number of days (defaults to 5)" (set! num-dates (string->number n))]
 [("-m" "--month") m "start in month m (defaults to current month)" (set! start-month (string->number m))]
 [("-d" "--day") d "start on day d of month (defaults to current day)" (set! start-day (string->number d))]
 [("-y" "--year") y "start in the year y (defaults to this or next year (depending on the date & month))" (set! start-year (string->number y))])

(define racket
  (let ([p (find-system-path 'exec-file)])
    (if (absolute-path? p)
        (path->string p)
        "racket")))

(define start-secs 
  (cond
    [start-year
     (find-seconds 1 0 0 start-day start-month start-year)]
    [else
     (define current-year-secs (find-seconds 1 0 0 start-day start-month (date-year now-date)))
     (define starting-today-secs (find-seconds 1 0 0 (date-day now-date) (date-month now-date) (date-year now-date)))
     (if (< current-year-secs starting-today-secs)
         (find-seconds 1 0 0 start-day start-month (+ (date-year now-date) 1))
         current-year-secs)]))

(for ([i (in-range num-dates)])
  (define secs (+ start-secs (* 86400 i)))
  (define-values (in out) (make-pipe))
  (define s (make-semaphore))
  (thread
   (λ ()
     (define proc-list
       (process/ports
        out
        (current-input-port)
        (current-error-port)
        (string-append (format "WARP=~a LD_PRELOAD=~a" 
                               (- secs now)
                               lib-path)
                       " "
                       racket
                       " -l racket/base -l tests/drracket/private/easter-egg-lib -l racket/date"
                       " -e \"(display (current-seconds))\""
                       " -e \"(newline)\""
                       " -e \"(start-up-and-check-car)\"")))
     (define proc (list-ref proc-list 4))
     (proc 'wait)
     (close-output-port out)
     (semaphore-post s)))
  (define drr-secs (read in))
  (close-input-port in)
  (unless (< (abs (- drr-secs secs)) 3600)
    (error 'run-dates.rkt "time didn't change (enough); wanted drr to be ~a, but it thinks it is ~a, delta=~a"
           secs
           drr-secs
           (abs (- drr-secs secs))))
  (semaphore-wait s))
