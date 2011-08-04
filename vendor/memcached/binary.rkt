#lang racket
(provide (all-defined-out))

(define request-magic #x80)
(define response-magic #x81)

(define (hasheqp id . a)
  (define ht (apply hasheq a))
  (λ (k)
    (hash-ref ht k (λ () (error id "Not found: ~s" k)))))

(define response-status
  (hasheqp 'response-status
   #x0000  "No error"
   #x0001  "Key not found"
   #x0002  "Key exists"
   #x0003  "Value too large"
   #x0004  "Invalid arguments"
   #x0005  "Item not stored"
   #x0006  "Incr/Decr on non-numeric value."
   #x0081  "Unknown command"
   #x0082  "Out of memory"))

(define (rhasheqp id . a)
  (define swap
    (match-lambda
      [(list) empty]
      [(list-rest o (list-rest t r))
       (list* t o (swap r))]))
  (apply hasheqp id (swap a)))

(define-syntax-rule (opcodes . codes)
  (values (hasheqp 'opcodes . codes) (rhasheqp 'opcodes . codes)))

(define-values
  (byte->opcode opcode->byte)
  (opcodes
   #x00    'Get
   #x01    'Set
   #x02    'Add
   #x03    'Replace
   #x04    'Delete
   #x05    'Increment
   #x06    'Decrement
   #x07    'Quit
   #x08    'Flush
   #x09    'GetQ
   #x0A    'No-op
   #x0B    'Version
   #x0C    'GetK
   #x0D    'GetKQ
   #x0E    'Append
   #x0F    'Prepend
   #x10    'Stat
   #x11    'SetQ
   #x12    'AddQ
   #x13    'ReplaceQ
   #x14    'DeleteQ
   #x15    'IncrementQ
   #x16    'DecrementQ
   #x17    'QuitQ
   #x18    'FlushQ
   #x19    'AppendQ
   #x1A    'PrependQ
   
   #x20    'SASL-List-Mechs
   #x21    'SASL-Auth
   #x22    'SASL-Step
   
   #x30    'RGet
   #x31    'RSet
   #x32    'RSetQ
   #x33    'RAppend
   #x34    'RAppendQ
   #x35    'RPrepend
   #x36    'RPrependQ
   #x37    'RDelete
   #x38    'RDeleteQ
   #x39    'RIncr
   #x3a    'RIncrQ
   #x3b    'RDecr
   #x3c    'RDecrQ))

(define raw-data-type #x00)

(define (write-request-header! opcode key-len extras-len total-body-len cas)
  (write-byte request-magic)
  (write-byte (opcode->byte opcode))
  (write-bytes (integer->integer-bytes key-len 2 #f #t))
  (write-byte extras-len)
  (write-byte 0) ; data type
  (write-bytes #"\0\0") ; reserved
  (write-bytes (integer->integer-bytes total-body-len 4 #f #t))
  (write-bytes #"\0\0\0\0") ; opaque (copied back)
  (write-bytes cas))

(define-syntax-rule (define* i e)
  (begin (define _1 (fprintf (current-error-port) "~S = ...~n" 'i))
         (define i e)
         (define _2 (fprintf (current-error-port) "~S = ~S~n" 'i i))))

(define (read-response)
  (define magic (read-byte))
  (define opcode (byte->opcode (read-byte)))
  (define key-len (integer-bytes->integer (read-bytes 2) #f #t))
  (define extras-len (read-byte))
  (define data-type (read-byte))
  (define status (integer-bytes->integer (read-bytes 2) #f #t))
  (define total-body-len (integer-bytes->integer (read-bytes 4) #f #t))
  (define opaque (read-bytes 4))
  (define cas (read-bytes 8))
  (define val-len (- total-body-len key-len extras-len))
  (define extras (read-bytes extras-len))
  (define key (read-bytes key-len))
  (define val (read-bytes val-len))
  (values opcode key extras status val cas))
  
(define (write-get* opcode key)
  (define key-len (bytes-length key))
  (write-request-header! opcode key-len 0 key-len #"\0\0\0\0\0\0\0\0")
  (write-bytes key)
  (flush-output))

(define (read-get*)
  (define-values (opcode key extras status val cas) (read-response))
  ; XXX check opcode and extras-len = 4 and status
  (define flags extras)
  (values (if (zero? status)
              val
              #f)
          cas))

(define (write-set* opcode key value flags expiration cas)
  (define key-len (bytes-length key))
  (write-request-header! opcode key-len 8 (+ key-len 8 (bytes-length value)) cas)
  (write-bytes flags)
  (write-bytes (integer->integer-bytes expiration 4 #f #t))
  (write-bytes key)
  (write-bytes value)
  (flush-output))

(define (read-set*)
  (define-values (opcode key extras status val cas) (read-response))
  ; XXX check opcode and extras = #""
  (if (zero? status)
      cas
      #f))

(define (write-delete* opcode key cas)
  (define key-len (bytes-length key))
  (write-request-header! opcode key-len 0 key-len cas)
  (write-bytes key)
  (flush-output))

(define (read-delete*)
  (define-values (opcode key extras status val cas) (read-response))
  ; XXX check opcode and extras = #"", val = #""
  (zero? status))

(define (write-incr* opcode key amt init expiration cas)
  (define key-len (bytes-length key))
  (write-request-header! opcode key-len 20 (+ key-len 20) cas)
  (write-bytes (integer->integer-bytes amt 8 #f #t))
  (write-bytes (integer->integer-bytes init 8 #f #t))
  (if expiration
      (write-bytes (integer->integer-bytes expiration 4 #f #t))
      (write-bytes #"\xff\xff\xff\xff"))
  (write-bytes key)
  (flush-output))

(define (read-incr*)
  (define-values (opcode key extras status val cas) (read-response))
  ; XXX check opcode and extras = #""
  (if (zero? status)
      (integer-bytes->integer val #f #t)
      #f))

; XXX quit
; XXX flush
; XXX noop
; XXX version

(define (write-append* opcode key val cas)
  (define key-len (bytes-length key))
  (define val-len (bytes-length val))
  (write-request-header! opcode key-len 0 (+ key-len val-len) cas)
  (write-bytes key)
  (write-bytes val)
  (flush-output))

(define (read-append*)
  (define-values (opcode key extras status val cas) (read-response))
  ; XXX check opcode and extras, val = #""
  (and (zero? status) cas))
