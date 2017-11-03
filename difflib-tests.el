(require 'difflib)

(ert-deftest difflib-test-one-insert ()
  (let ((sm (difflib-sequence-matcher :a (make-string 100 ?b)
                                      :b (concat "a"
                                                 (make-string 100 ?b)))))
    (should (equal (string-to-number (format "%.3f" (difflib-ratio sm)))
                   0.995))
    (should (equal (difflib-get-opcodes sm)
                   '(("insert" 0 0 0 1)
                     ("equal" 0 100 1 101))))
    (should (equal (oref sm :bpopular) nil)))
  (let ((sm (difflib-sequence-matcher :a (make-string 100 ?b)
                                      :b (concat (make-string 50 ?b)
                                                 "a"
                                                 (make-string 50 ?b)))))
    (should (equal (string-to-number (format "%.3f" (difflib-ratio sm)))
                   0.995))
    (should (equal (difflib-get-opcodes sm)
                   '(("equal" 0 50 0 50)
                     ("insert" 50 50 50 51)
                     ("equal" 50 100 51 101))))
    (should (equal (oref sm :bpopular) nil))))

(ert-deftest difflib-test-one-delete ()
  (let ((sm (difflib-sequence-matcher :a (concat (make-string 40 ?a)
                                                 "c"
                                                 (make-string 40 ?b))
                                      :b (concat (make-string 40 ?a)
                                                 (make-string 40 ?b)))))
    (should (equal (string-to-number (format "%.3f" (difflib-ratio sm)))
                   0.994))
    (should (equal (difflib-get-opcodes sm)
                   '(("equal" 0 40 0 40)
                     ("delete" 40 41 40 40)
                     ("equal" 41 81 40 80))))))

(ert-deftest difflib-test-bjunk ()
  (let ((sm (difflib-sequence-matcher
             :isjunk (lambda (x) (equal x (if difflib-pythonic-strings
                                              " "
                                            ?\s)))
             :a (concat (make-string 40 ?a)
                        (make-string 40 ?b))
             :b (concat (make-string 44 ?a)
                        (make-string 40 ?b)))))
    (should (equal (oref sm :bjunk) nil)))
  (let ((sm (difflib-sequence-matcher
             :isjunk (lambda (x) (equal x (if difflib-pythonic-strings
                                              " "
                                            ?\s)))
             :a (concat (make-string 40 ?a)
                        (make-string 40 ?b))
             :b (concat (make-string 44 ?a)
                        (make-string 40 ?b)
                        (make-string 20 ?\s)))))
    (should (equal (oref sm :bjunk) (if difflib-pythonic-strings
                                        '(" ")
                                      '(?\s)))))
  (let ((sm (difflib-sequence-matcher
             :isjunk (lambda (x) (member x
                                         (if difflib-pythonic-strings
                                             '(" " "b")
                                           '(?\s ?b))))
             :a (concat (make-string 40 ?a)
                        (make-string 40 ?b))
             :b (concat (make-string 44 ?a)
                        (make-string 40 ?b)
                        (make-string 20 ?\s)))))
    (should (equal (oref sm :bjunk) (if difflib-pythonic-strings
                                        '("b" " ")
                                      '(?b ?\s))))))

(ert-deftest difflib-test-autojunk ()
  (let ((seq1 (make-string 200 ?b))
        (seq2 (concat "a" (make-string 200 ?b))))
    (let ((sm (difflib-sequence-matcher :a seq1 :b seq2)))
      (should (cl-equalp (string-to-number (format "%.3f" (difflib-ratio sm)))
                         0))
      (should (equal (oref sm :bpopular) (if difflib-pythonic-strings
                                             '("b")
                                           '(?b)))))
    ;; Junk off
    (let ((sm (difflib-sequence-matcher :a seq1 :b seq2 :autojunk nil)))
      (should (cl-equalp (string-to-number (format "%.3f" (difflib-ratio sm)))
                         0.998))
      (should (equal (oref sm :bpopular) nil)))))

(ert-deftest difflib-test-ratio-for-null-seq ()
  (let ((s (difflib-sequence-matcher :a '() :b '())))
    (should (cl-equalp (difflib-ratio s) 1))))
