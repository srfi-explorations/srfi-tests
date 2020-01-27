;; Copyright 2015 John Cowan
;; Copyright 2020 Lassi Kortela
;; SPDX-License-Identifier: MIT

(test-begin "titlecase")

(define uchar integer->char)
(define (ustring . xs)
  (apply string-append
         (map (lambda (x) (if (string? x) x (string (integer->char x))))
              xs)))

(test-begin "predicate")
(test-assert (char-title-case? (uchar #x01C5)))
(test-assert (char-title-case? (uchar #x1FFC)))
(test-assert (not (char-title-case? #\Z)))
(test-assert (not (char-title-case? #\z)))
(test-end "predicate")

(test-begin "char")
(test-equal (uchar #x01C5) (char-titlecase (uchar #x01C4)))
(test-equal (uchar #x01C5) (char-titlecase (uchar #x01C6)))
(test-equal #\Z (char-titlecase #\Z))
(test-equal #\Z (char-titlecase #\z))
(test-end "char")

(test-begin "string")
(test-equal (ustring #x01C5) (string-titlecase (ustring #x01C5)))
(test-equal (ustring #x01C5) (string-titlecase (ustring #x01C4)))
(test-equal "Ss" (string-titlecase (ustring #x00DF)))
(test-equal (ustring "Xi" #x0307) (string-titlecase (ustring "x" #x0130)))
(test-equal (ustring #x1F88) (string-titlecase (ustring #x1F80)))
(test-equal (ustring #x1F88) (string-titlecase (ustring #x1F88)))
(define Floo (ustring #xFB02 "oo"))
(define Floo-bar (ustring #xFB02 "oo bar"))
(define Baffle (ustring "Ba" #xFB04 "e"))
(define LJUBLJANA (ustring #x01C7 "ub" #x01C7 "ana"))
(define Ljubljana (ustring #x01C8 "ub" #x01C9 "ana"))
(define ljubljana (ustring #x01C9 "ub" #x01C9 "ana"))
(test-equal "Bar Baz" (string-titlecase "bAr baZ"))
(test-equal "Floo" (string-titlecase "floo"))
(test-equal "Floo" (string-titlecase "FLOO"))
(test-equal "Floo" (string-titlecase Floo))
(test-equal "Floo Bar" (string-titlecase "floo bar"))
(test-equal "Floo Bar" (string-titlecase "FLOO BAR"))
(test-equal "Floo Bar" (string-titlecase Floo-bar))
(test-equal Baffle (string-titlecase Baffle))
(test-equal Ljubljana (string-titlecase LJUBLJANA))
(test-equal Ljubljana (string-titlecase Ljubljana))
(test-equal Ljubljana (string-titlecase ljubljana))
(test-end "string")

(test-end "titlecase")
