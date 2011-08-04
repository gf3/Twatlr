#lang scribble/doc
@(require (planet cce/scheme:6/planet)
          (planet cce/scheme:6/scribble)
          scribble/manual
          (for-label scheme
                     "main.rkt"))

@title{memcached}
@author{@(author+email "Jay McCarthy" "jay@racket-lang.org")}

@defmodule/this-package[]

This package provides an interface to @link["http://memcached.org/"]{memcached}.

@section{Low level Interface}

At the moment, only a low-level interface is provided.

@defproc[(memcached-pool? [x any/c]) boolean?]{Identifies memcached pool structures.}

@defproc[(memcached [ip string?] [port (and/c exact-nonnegative-integer? (integer-in 1 65535))] ... ...)
         memcached-pool?]{ Establishes TCP connections to the specified servers at the respective ports. However, only the first connection is used. }

This function should be modified to support UDP connections and its internals should be adapted to use all connections in the recommended way.

@defthing[key? contract?]{ Corresponds to @racket[bytes?]. }
@defthing[value? contract?]{ Corresponds to @racket[bytes?]. }
@defthing[cas? contract?]{ Corresponds to @racket[bytes?] guaranteed to be 8 bytes long. }
@defthing[uint4? contract?]{ Corresponds to @racket[exact-nonnegative-integer?]. }
@defthing[uint8? contract?]{ Corresponds to @racket[exact-nonnegative-integer?]. }
@defthing[empty-cas cas?]{ The null CAS, suitable for use when the CAS is unknown or when you don't care. }

@defproc[(memcached-get [mp memcached-pool?] [k key?])
         (values (or/c false/c value?) cas?)]{ Retrieves the key's value and CAS. }

@defproc[(memcached-set! [mp memcached-pool?] [k key?] [v value?] [#:expiration exp uint4? 0] [#:cas cas cas? empty-cas])
         (or/c false/c cas?)]{ Sets the key to the value with the expiration time if the CAS is still the same, returning the new CAS. }
@defproc[(memcached-add! [mp memcached-pool?] [k key?] [v value?] [#:expiration exp uint4? 0])
         (or/c false/c cas?)]{ Sets the key to the value with the expiration time if it is not bound, returning the new CAS. }
@defproc[(memcached-replace! [mp memcached-pool?] [k key?] [v value?] [#:expiration exp uint4? 0] [#:cas cas cas? empty-cas])
         (or/c false/c cas?)]{ Sets the key to the value with the expiration time if the CAS is still the same and it is bound, returning the new CAS. }
                             
@defproc[(memcached-delete! [mp memcached-pool?] [k key?] [#:cas cas cas? empty-cas])
         boolean?]{ Deletes the key if the CAS is still the same. }
                  
@defproc[(memcached-incr! [k key?] [#:amount amt uint8? 1] [#:initial init false/c #f] [#:expiration exp uint4? 0] [#:cas cas cas? empty-cas])
         (or/c false/c uint8?)]{ Increments the key's value by the amount with the expiration time if the CAS is still the same and it is bound, returning the new value as an integer. }
@defproc[(memcached-decr! [k key?] [#:amount amt uint8? 1] [#:initial init false/c #f] [#:expiration exp uint4? 0] [#:cas cas cas? empty-cas])
         (or/c false/c uint8?)]{ Decrements the key's value by the amount with the expiration time if the CAS is still the same and it is bound, returning the new value as an integer. }

These two functions have a more restrictive contract on the initial value than the API because I do not understand them enough to decide if the contract should be @racket[uint8?] or @racket[value?].
                               
@defproc[(memcached-append! [k key?] [v value?] [#:cas cas cas? empty-cas])
         (or/c false/c cas?)]{ Appends the value to the key's current value if the CAS is still the same, returning the new CAS. }
@defproc[(memcached-prepend! [k key?] [v value?] [#:cas cas cas? empty-cas])
         (or/c false/c cas?)]{ Prepends the value to the key's current value if the CAS is still the same, returning the new CAS. }
