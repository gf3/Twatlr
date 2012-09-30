#lang racket

(require net/url
         "vendor/json/main.ss" ; Vendored until fixed!
         "vendor/memcached/main.rkt")
         ; (planet dherman/json:3:0))

(define mp (memcached "127.0.0.1" 11211))

(define (get-thread tweet-id)
  (let parent-tweet ([tweet (get-tweet tweet-id)] [a empty])
    (let ([reply-id (hash-ref tweet 'in_reply_to_status_id_str #\nul)])
      (cond [(eq? #\nul reply-id)                    (append a (list tweet))]
            [else (parent-tweet (get-tweet reply-id) (append a (list tweet)))]))))

(define (get-tweet tweet-id)
  (read-json (open-input-bytes (let-values ([(jsbt cas) (memcached-get mp (string->bytes/utf-8 tweet-id))])
    (if jsbt
      jsbt
      (let ([tweet-bytes (port->bytes (get-pure-port (tweet-url tweet-id)))])
        (memcached-set! mp (string->bytes/utf-8 tweet-id) tweet-bytes)
        tweet-bytes))))))

(define (tweet-url tweet-id)
  (make-url "http"
            #f
            "api.twitter.com"
            #f
            #t
            (list (make-path/param "1" empty)
                  (make-path/param "statuses" empty)
                  (make-path/param "show" empty)
                  (make-path/param (string-append tweet-id ".json") empty))
            empty
            #f))

(provide/contract
  [get-thread (string? . -> . list?)]
  [get-tweet (string? . -> . hash-eq?)])

