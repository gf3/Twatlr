#lang setup/infotab
(define name "memcached")
(define release-notes
  (list '(ul (li "First version"))))
(define repositories
  (list "4.x"))
(define blurb
  (list "A native Racket interface to memcached"))
(define scribblings '(("memcached.scrbl" ())))
(define primary-file "main.rkt")
(define categories '(net io))
(define compile-omit-paths
  (list "test.ss"))