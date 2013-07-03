#lang racket
(require net/url
         "vendor/json/main.ss") ; Vendored until fixed!
         ; (planet dherman/json:3:0))

(define (get-thread tweet-id)
  (let parent-tweet ([tweet (get-tweet tweet-id)] [a empty])
    (let ([reply-id (hash-ref tweet 'in_reply_to_status_id_str #\nul)])
      (cond [(eq? #\nul reply-id)                    (append a (list tweet))]
            [else (parent-tweet (get-tweet reply-id) (append a (list tweet)))]))))

(define (get-tweet tweet-id)
  (read-json (get-pure-port (tweet-url tweet-id) (list (format "Authorization: Bearer ~a" (getenv "BEARER_TOKEN"))))))

(define (tweet-url tweet-id)
  (make-url "https"
            #f
            "api.twitter.com"
            #f
            #t
            (list (make-path/param "1.1" empty)
                  (make-path/param "statuses" empty)
                  (make-path/param "show" empty)
                  (make-path/param (string-append tweet-id ".json") empty))
            empty
            #f))

(provide/contract
  [get-thread (string? . -> . list?)]
  [get-tweet (string? . -> . hash-eq?)])

