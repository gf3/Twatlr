#lang racket
(require net/url
         "twatlr.rkt")

; Deleted Tweet: http://twitter.com/runlevel6/status/156239090294075392
; Child Tweet:   http://twitter.com/gf3/status/156239162536763392
; Deleted Child of Child: https://twitter.com/runlevel6/status/156245695735672833

(define-values (parent child deleted child-2)
               (values "88607275937312768" "88617271240568832" "156239090294075392" "156239162536763392"))

(displayln (format "get-url:\n~s → ~s" parent (url->string (tweet-url parent))))

(displayln "\n")
(displayln (format "get-tweet:\n~a" (get-tweet child)))

(displayln "\n")
(displayln "get-thread:")
(write (get-thread child))

