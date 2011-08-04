#lang racket
(require "main.rkt"
         "binary.rkt"
         tests/eli-tester)

(define-syntax-rule
  (with-memcached p e ...)
  (local [(define sp #f)]
    (dynamic-wind
     (λ () 
       (define-values (the-sp stdout stdin stderr) (subprocess (current-output-port) #f (current-error-port) "/opt/local/bin/memcached" "-p" (number->string p)))
       (set! sp the-sp)
       (sleep 1))
     (λ () e ...)
     (λ () (subprocess-kill sp #t)))))

(define-syntax with-memcacheds
  (syntax-rules ()
    [(_ () e ...) (let () e ...)]
    [(_ (p . ps) e ...)
     (with-memcached p (with-memcacheds ps e ...))]))

(test
 #:failure-prefix "Binary protocol"
 (test
  (with-output-to-bytes
      (lambda ()
        (write-get* 'Get #"Hello")))
  =>
  #"\x80\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Hello"
  (parameterize ([current-input-port
                  (open-input-bytes
                   #"\x81\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x09\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Not found")])
    (read-get*))
  =>
  (values #f
          #"\0\0\0\0\0\0\0\0")
  
  (parameterize ([current-input-port
                  (open-input-bytes
                   #"\x81\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x09\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\xde\xad\xbe\xefWorld")])
    (read-get*))
  =>
  (values #"World"
          #"\0\0\0\0\0\0\0\1")
  
  (parameterize ([current-input-port
                  (open-input-bytes
                   #"\x81\x00\x00\x05\x04\x00\x00\x00\x00\x00\x00\x0e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\xde\xad\xbe\xefHelloWorld")])
    (read-get*))
  =>
  (values #"World"
          #"\0\0\0\0\0\0\0\1")
  (with-output-to-bytes
      (lambda ()
        (write-set* 'Add #"Hello" #"World" #"\xde\xad\xbe\xef" 3600 #"\0\0\0\0\0\0\0\0")))
  =>
  #"\x80\x02\x00\x05\x08\x00\x00\x00\x00\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xde\xad\xbe\xef\x00\x00\x0e\x10HelloWorld"
  (parameterize ([current-input-port
                  (open-input-bytes
                   #"\x81\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01")])
    (read-set*))
  =>
  #"\0\0\0\0\0\0\0\1"
  (with-output-to-bytes
      (lambda ()
        (write-delete* 'Delete #"Hello" #"\0\0\0\0\0\0\0\0")))
  =>
  #"\x80\x04\x00\x05\x00\x00\x00\x00\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Hello"
  (with-output-to-bytes
      (lambda ()
        (write-incr* 'Increment #"counter" 1 0 3600 #"\0\0\0\0\0\0\0\0")))
  =>
  #"\x80\x05\x00\x07\x14\x00\x00\x00\x00\x00\x00\x1b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0e\x10counter"
  (parameterize ([current-input-port
                  (open-input-bytes
                   #"\x81\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00")])
    (read-incr*))
  =>
  0
  (with-output-to-bytes
      (lambda ()
        (write-append* 'Append #"Hello" #"!" #"\0\0\0\0\0\0\0\0")))
  =>
  #"\x80\x0e\x00\x05\x00\x00\x00\x00\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Hello!")
 
 #:failure-prefix "Commands"
 (local
   [(define port 11211)
    (define mc #f)
    (define cas #f)
    (define-syntax-rule (value-1 e) (let-values ([(x y) e]) x))
    (define-syntax-rule (value-1n e) (integer-bytes->integer (value-1 e) #f #t))
    (define-syntax-rule (record-cas! e)
      (let-values ([(e-v e-cas) e])
        (set! cas e-cas)
        e-v))]
   (with-memcacheds ((+ port 0) (+ port 1) (+ port 2))
     (test
      (set! mc 
            (memcached
             "localhost" (+ port 0)
             "localhost" (+ port 1)
             "localhost" (+ port 2)))
      (memcached-set! mc #"foo" #"bar")
      (value-1 (memcached-get mc #"foo")) => #"bar"
      
      (memcached-add! mc #"foo" #"zog") => #f
      (value-1 (memcached-get mc #"foo")) => #"bar"
      
      (or (memcached-delete! mc #"zag") #t)
      (memcached-add! mc #"zag" #"zog")
      (value-1 (memcached-get mc #"zag")) => #"zog"
      
      (memcached-replace! mc #"zag" #"zig")
      (value-1 (memcached-get mc #"zag")) => #"zig"
      (memcached-replace! mc #"zig" #"zoo") => #f
      (value-1 (memcached-get mc #"zig")) => #f
      
      (memcached-set! mc #"list" #"2")
      (value-1 (memcached-get mc #"list")) => #"2"
      (memcached-append! mc #"list" #"3")
      (value-1 (memcached-get mc #"list")) => #"23"
      (memcached-prepend! mc #"list" #"1")
      (value-1 (memcached-get mc #"list")) => #"123"
      
      (record-cas! (memcached-get mc #"foo")) => #"bar"
      (memcached-set! mc #"foo" #:cas cas #"zog")
      (value-1 (memcached-get mc #"foo")) => #"zog"
      (memcached-set! mc #"foo" #"bleg")
      (value-1 (memcached-get mc #"foo")) => #"bleg"
      (memcached-set! mc #"foo" #:cas cas #"zig") => #f
      (value-1 (memcached-get mc #"foo")) => #"bleg"
      
      (memcached-delete! mc #"foo")
      (value-1 (memcached-get mc #"foo")) => #f
      
      (or (memcached-delete! mc #"k") #t)
      (memcached-incr! mc #"k") => #f
      (memcached-decr! mc #"k") => #f
      (memcached-set! mc #"k" #"0")
      (value-1 (memcached-get mc #"k")) => #"0"
      (memcached-incr! mc #"k")
      (value-1 (memcached-get mc #"k")) => #"1"
      (memcached-incr! mc #"k")
      (value-1 (memcached-get mc #"k")) => #"2"
      (memcached-decr! mc #"k")
      (value-1 (memcached-get mc #"k")) => #"1"
      (memcached-incr! mc #"k" #:amount 3)
      (value-1 (memcached-get mc #"k")) => #"4"
      (memcached-decr! mc #"k" #:amount 3)
      (value-1 (memcached-get mc #"k")) => #"1"
      
      ; XXX statistics
      ))))