;;; ox-ipynb-test.el --- Tests for ox-ipynb  -*- lexical-binding: t; -*-

;;; Commentary:
;; Baseline tests for the main exporter in ox-ipynb.el.  They pin down current
;; behavior so later changes can be made safely.  Add a test here for every
;; bug fix and feature.

;;; Code:

(require 'test-helper)

;;; Notebook structure

(ert-deftest ox-ipynb-test-nbformat-version ()
  "Exported notebooks are nbformat 4.5."
  (let ((nb (ox-ipynb-test-export "Hello\n")))
    (should (equal 4 (alist-get 'nbformat nb)))
    (should (equal 5 (alist-get 'nbformat_minor nb)))))

(ert-deftest ox-ipynb-test-cells-have-ids ()
  "Every cell has a unique id (required since nbformat 4.5)."
  (let* ((nb (ox-ipynb-test-export
              "* A\ntext\n\n#+BEGIN_SRC jupyter-python\n1\n#+END_SRC\n"))
         (ids (mapcar (lambda (c) (alist-get 'id c)) (ox-ipynb-test-cells nb))))
    (should (cl-every #'stringp ids))
    (should (equal ids (delete-dups (copy-sequence ids))))))

(ert-deftest ox-ipynb-test-python-kernelspec ()
  "A jupyter-python block selects the Python 3 kernel."
  (let* ((nb (ox-ipynb-test-export
              "#+BEGIN_SRC jupyter-python\n1\n#+END_SRC\n"))
         (kernelspec (alist-get 'kernelspec (alist-get 'metadata nb))))
    (should (equal "python3" (alist-get 'name kernelspec)))
    (should (equal "python" (alist-get 'language kernelspec)))))

;;; Markdown cells

(ert-deftest ox-ipynb-test-title-and-author ()
  "Title and author go into the first markdown cell."
  (let* ((nb (ox-ipynb-test-export "#+title: My Title\n#+author: Jane\n\nText\n"))
         (first (ox-ipynb-test-source (car (ox-ipynb-test-cells nb)))))
    (should (string-match-p "My Title" first))
    (should (string-match-p "Jane" first))))

(ert-deftest ox-ipynb-test-headline-own-cell ()
  "Headlines are exported to their own markdown cells."
  (let* ((nb (ox-ipynb-test-export "* Intro\nSome text.\n** Sub\nMore.\n"))
         (sources (mapcar #'ox-ipynb-test-source
                          (ox-ipynb-test-cells nb "markdown"))))
    (should (member "## Intro\n\n" sources))
    (should (cl-some (lambda (s) (string-prefix-p "### Sub" s)) sources))))

(ert-deftest ox-ipynb-test-emphasis ()
  "Org emphasis is converted to Markdown."
  (let ((md (ox-ipynb-test-all-source
             (ox-ipynb-test-export "Some *bold* and /italic/ text.\n")
             "markdown")))
    (should (string-match-p "\\*\\*bold\\*\\*" md))
    (should (string-match-p "\\*italic\\*" md))))

(ert-deftest ox-ipynb-test-inline-latex ()
  "Inline LaTeX math is passed through for MathJax."
  (let ((md (ox-ipynb-test-all-source
             (ox-ipynb-test-export "Energy $E = mc^2$ here.\n") "markdown")))
    (should (string-match-p (regexp-quote "$E = mc^2$") md))))

;;; Code cells

(ert-deftest ox-ipynb-test-code-cell-with-results ()
  "A src block becomes a code cell and its #+RESULTS a stream output."
  (let* ((nb (ox-ipynb-test-export
              "#+BEGIN_SRC jupyter-python\nprint(1)\n#+END_SRC\n\n#+RESULTS:\n: 1\n"))
         (code (ox-ipynb-test-cells nb "code")))
    (should (= 1 (length code)))
    (should (equal "print(1)" (ox-ipynb-test-source (car code))))
    (let ((out (car (alist-get 'outputs (car code)))))
      (should (equal "stream" (alist-get 'output_type out)))
      (should (equal "1" (string-trim (format "%s" (alist-get 'text out))))))
    ;; results must not leak into a markdown cell as well
    (should-not (string-match-p "^ +1$" (ox-ipynb-test-all-source nb "markdown")))))

(ert-deftest ox-ipynb-test-exports-none ()
  "Blocks with :exports none are omitted."
  (let ((nb (ox-ipynb-test-export
             "#+BEGIN_SRC jupyter-python :exports none\nsecret = 1\n#+END_SRC\n\nText\n")))
    (should-not (string-match-p "secret" (ox-ipynb-test-all-source nb)))))

;;; Participant notebooks

(ert-deftest ox-ipynb-test-participant-removes-solution ()
  "Participant export strips ### BEGIN/END SOLUTION regions."
  (let ((nb (ox-ipynb-test-export
             (concat "#+BEGIN_SRC jupyter-python\n"
                     "x = 1\n### BEGIN SOLUTION\nanswer = 42\n### END SOLUTION\n"
                     "#+END_SRC\n")
             ;; Same hooks as `ox-ipynb-export-to-participant-notebook',
             ;; which writes and opens a file instead of returning a buffer.
             (lambda ()
               (let ((ox-ipynb-preprocess-hook '(ox-ipynb-remove-hidden
                                                 ox-ipynb-remove-solution
                                                 ox-ipynb-remove-remove)))
                 (ox-ipynb-export-to-ipynb-buffer))))))
    (should (string-match-p "x = 1" (ox-ipynb-test-all-source nb "code")))
    (should-not (string-match-p "answer" (ox-ipynb-test-all-source nb)))))

(provide 'ox-ipynb-test)
;;; ox-ipynb-test.el ends here
