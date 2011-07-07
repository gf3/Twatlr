#lang setup/infotab
(define name "json")
(define blurb
  (list "Implements the JSON data exchange format."))
(define primary-file "main.ss")
(define categories '(datastructures))
(define scribblings '(("json.scrbl" ())))
(define release-notes
  '((ul (li "Renamed " (tt "json") " datatype to \"JS-Expressions\" or \"jsexprs\". "
            "Thanks to Peter Michaux for pointing out the confusion between " (tt "json") " the datatype and JSON the data format.")
        (li "Renamed " (tt "json->string") " to " (tt "jsexpr->json") ".")
        (li "Renamed " (tt "string->json") " to " (tt "json->jsexpr") ".")
        (li "Renamed gratuitously ambiguous " (tt "read") " and " (tt "write") " to " (tt "read-json") " and " (tt "write-json") ", respectively.")
        (li "Changed the value represented by JSON " (tt "null") " from " (tt "#" lt "void" gt) " to " (tt "#\\null") ".")
        (li "Added some design rationale to the docs."))))
(define repositories '("4.x"))
(define required-core-version "4.0.0.0")
(define version "3")
