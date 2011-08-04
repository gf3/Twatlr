#lang racket
(require net/url
         "twatlr.rkt")

(define-values (parent child)
               (values "88607275937312768" "88617271240568832"))

; (displayln (format "get-url:\n~s → ~s" parent (url->string (tweet-url parent))))

(displayln "\n")
(displayln (format "get-tweet:\n~a" (get-tweet child)))

(displayln "\n")
(displayln "get-thread:")
(write (get-thread child))
