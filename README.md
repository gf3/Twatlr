# Twatlr

Easy Twitter threads.

### LOL NOTE

This package depends on `(planet dherman/json:3:0)` however it is affected by [this bug](http://planet.racket-lang.org/trac/ticket/265), luckily there is a working patch which you can [grab here](http://planet.racket-lang.org/trac/ticket/317).

### API

    (get-thread tweet-id) → list?
      tweet-id : string?

    (get-tweet tweet-id) → hash-eq?
      tweet-id : string?

    (tweet-url tweet-id) → url?
      tweet-id : string?
