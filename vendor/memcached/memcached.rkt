#lang racket
(require "binary.rkt")

(define no-flags #"\x00\x00\x00\x00")
(define empty-cas #"\0\0\0\0\0\0\0\0")
(define key? bytes?)
(define value? bytes?)
(define (cas? x)
  (and (bytes? x) (= (bytes-length x) 8)))
; XXX
(define uint4? exact-nonnegative-integer?)
; XXX
(define uint8? exact-nonnegative-integer?)

;; Pool Interface
(struct memcached-pool (servers))

(define (memcached . ss)
  (define servers
    (match-lambda
      [(list) empty]
      [(list-rest s (list-rest p ss))
       (list* (connect s p) (servers ss))]))
  (memcached-pool (servers ss)))

(struct conn (from to))

(define (connect s p)
  (define-values (from to) (tcp-connect s p))
  (conn from to))

(define (memcached-pool-comm! mp thnk)
  ; XXX use pool, maybe by spawning threads and racing?
  (define conn (first (memcached-pool-servers mp)))
  (parameterize ([current-input-port (conn-from conn)]
                 [current-output-port (conn-to conn)])
    (thnk)))

;; Command interface
(define-syntax-rule
  (define-command (id . args) contract e ...)
  (begin
    (define (id mp . args)
      (memcached-pool-comm! mp (λ () e ...)))
    (provide/contract
     [id contract])))

(define-command (memcached-get k)
  (memcached-pool? key? . -> . (values (or/c false/c value?) cas?))
  (write-get* 'Get k) (read-get*))

(define-command (memcached-set! k v #:expiration [exp 0] #:cas [cas empty-cas])
  ((memcached-pool? key? value?) (#:expiration uint4? #:cas cas?) . ->* . (or/c false/c cas?))
  (write-set* 'Set k v no-flags exp cas) (read-set*))
(define-command (memcached-add! k v #:expiration [exp 0])
  ((memcached-pool? key? value?) (#:expiration uint4?) . ->* . (or/c false/c cas?))
  (write-set* 'Add k v no-flags exp empty-cas) (read-set*))
(define-command (memcached-replace! k v #:expiration [exp 0] #:cas [cas empty-cas])
  ((memcached-pool? key? value?) (#:expiration uint4? #:cas cas?) . ->* . (or/c false/c cas?))
  (write-set* 'Replace k v no-flags exp cas) (read-set*))

(define-command (memcached-delete! k #:cas [cas empty-cas])
  ((memcached-pool? key?) (#:cas cas?) . ->* . boolean?)
  (write-delete* 'Delete k cas) (read-delete*))

; XXX I don't understand the initial argument value
(define-command (memcached-incr! k #:amount [amt 1] #:initial [init #f] #:expiration [exp 0] #:cas [cas empty-cas])
  ((memcached-pool? key?) (#:amount uint8? #:initial (or/c false/c #;uint8?) #:expiration uint4? #:cas cas?) . ->* . (or/c false/c uint8?))
  (write-incr* 'Increment k amt (or init 0) (and init exp) empty-cas) (read-incr*))
(define-command (memcached-decr! k #:amount [amt 1] #:initial [init #f] #:expiration [exp 0] #:cas [cas empty-cas])
  ((memcached-pool? key?) (#:amount uint8? #:initial (or/c false/c #;uint8?) #:expiration uint4? #:cas cas?) . ->* . (or/c false/c uint8?))
  (write-incr* 'Decrement k amt (or init 0) (and init exp) empty-cas) (read-incr*))

(define-command (memcached-append! k v #:cas [cas empty-cas])
  ((memcached-pool? key? value?) (#:cas cas?) . ->* . (or/c false/c cas?))
  (write-append* 'Append k v cas) (read-append*))
(define-command (memcached-prepend! k v #:cas [cas empty-cas])
  ((memcached-pool? key? value?) (#:cas cas?) . ->* . (or/c false/c cas?))
  (write-append* 'Prepend k v cas) (read-append*))

;;; Interface
(provide/contract
 [memcached-pool? (any/c . -> . boolean?)]
 [key? (any/c . -> . boolean?)]
 [value? (any/c . -> . boolean?)]
 [cas? (any/c . -> . boolean?)]
 [uint4? (any/c . -> . boolean?)]
 [uint8? (any/c . -> . boolean?)]
 [empty-cas cas?]
 ; XXX
 [memcached (() () #:rest list? . ->* . memcached-pool?)])