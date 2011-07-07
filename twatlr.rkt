#lang racket
(require net/url
         "vendor/json/main.ss") ; Vendored until fixed!
         ; (planet dherman/json:3:0))

(define (get-thread tweet-id)
  (let parent-tweet ([tweet (get-tweet tweet-id)] [a empty])
    (cond [(eq? #\nul (hash-ref tweet 'in_reply_to_status_id_str)) (append a (list tweet))]
          [else (parent-tweet (get-tweet (hash-ref tweet 'in_reply_to_status_id_str)) (append a (list tweet)))])))

(define (get-tweet tweet-id)
  (read-json (get-pure-port (tweet-url tweet-id))))

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

