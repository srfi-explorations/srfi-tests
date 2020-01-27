;; Copyright 2019 Lassi Kortela
;; SPDX-License-Identifier: MIT

;;; Convert the generic tests to work with the quirks of particular
;;; Scheme implementations.

(cond-expand
  (chicken)
  (gambit (import (gambit)))
  (r7rs (import (scheme base) (scheme file) (scheme read) (scheme write))))

(cond-expand
  (chicken
   (import (rename (only (chicken file) create-directory)
                   (create-directory ensure-directory-exists))))
  (gambit
   (define (ensure-directory-exists path)
     (or (file-exists? path) (create-directory path))))
  (gauche
   (import (rename (only (file util) create-directory*)
                   (create-directory* ensure-directory-exists)))))

(cond-expand
  (gambit
   (define (pretty-print x)
     (pp x (current-output-port))))
  (gauche
   (import (only (gauche base) pprint))
   (define (pretty-print x)
     (pprint x)))
  (else
   (define (pretty-print x)
     (write x)
     (newline))))

;;

(define (read-source-file filename)
  (with-input-from-file filename
    (lambda ()
      (let loop ((forms '()))
        (let ((form (read)))
          (if (eof-object? form) (reverse forms)
              (loop (cons form forms))))))))

(define (write-source-file dirname basename top-level-forms)
  (ensure-directory-exists dirname)
  (with-output-to-file (string-append dirname "/" basename)
    (lambda ()
      (let loop ((first? #t) (forms top-level-forms))
        (unless (null? forms)
          (unless first? (newline))
          (pretty-print (car forms))
          (newline)
          (loop #f (cdr forms)))))))

;;

(define prelude
  '(

    ;; Sort with SRFI 132 procedure name and args.
    (define (list-sort less? xs)
      (if (null? xs) '()
          (let insert ((x (car xs)) (xs (list-sort less? (cdr xs))))
            (if (null? xs) (list x)
                (let ((y (car xs)) (ys (cdr xs)))
                  (if (less? x y) (cons x xs) (cons y (insert x ys))))))))

    (define (written x)
      (call-with-port (open-output-string)
                      (lambda (out) (write x out) (get-output-string out))))

    (define (symbol<? a b) (string<? (symbol->string a) (symbol->string b)))

    ))

;;

(define (write-chibi-test srfi-number)
  (let ((basename (string-append (number->string srfi-number) ".scm")))
    (write-source-file "chibi" basename
                       `((import (scheme base)
                                 (scheme char)
                                 (scheme write)
                                 (chibi)
                                 (srfi 27)
                                 (srfi 64)  ; snow-chibi install '(srfi 64)'
                                 (srfi ,srfi-number))
                         (define (call-with-false-on-error proc)
                           (guard (_ (else #f)) (proc)))
                         ,@prelude
                         ,@(read-source-file basename)))))

(define (write-gauche-test srfi-number)
  (let ((basename (string-append (number->string srfi-number) ".scm")))
    (write-source-file "gauche" basename
                       `((import (scheme base)
                                 (scheme char)
                                 (scheme write)
                                 (srfi 27)
                                 (srfi 64)
                                 (srfi ,srfi-number))
                         (define (call-with-false-on-error proc)
                           (guard (_ (else #f)) (proc)))
                         ,@prelude
                         ,@(read-source-file basename)))))

(define (write-guile-test srfi-number)
  (let ((basename (string-append (number->string srfi-number) ".scm")))
    (write-source-file "guile" basename
                       `((import (guile)
                                 (srfi :27)
                                 (srfi :64)
                                 (srfi ,(string->symbol
                                         (string-append
                                          ":" (number->string srfi-number)))))
                         (define (call-with-false-on-error proc)
                           (catch #t proc (lambda (return) (return #f))))
                         ,@prelude
                         ,@(read-source-file basename)))))

(define (write-kawa-test srfi-number)
  (let ((basename (string-append (number->string srfi-number) ".scm")))
    (write-source-file "kawa" basename
                       `((import (kawa base) ; base includes SRFI 64
                                 (srfi ,srfi-number))
                         (define (random-integer limit)
                           (let ((source (java.util.Random)))
                             (source:nextInt limit)))
                         (define (call-with-false-on-error proc)
                           (guard (_ (else #f)) (proc)))
                         ,@prelude
                         ,@(read-source-file basename)))))

;;

(define all-srfis '(13 60 69 132 151 175))

(for-each write-chibi-test all-srfis)
(for-each write-gauche-test all-srfis)
(for-each write-guile-test all-srfis)
(for-each write-kawa-test all-srfis)
