;;; export-examples.el --- Batch-export org files to ipynb  -*- lexical-binding: t; -*-

;;; Commentary:
;; Usage: emacs -Q --batch -l scripts/export-examples.el FILE.org...
;; Exports each FILE.org next to itself as FILE.ipynb without evaluating any
;; code (existing #+RESULTS are used).  Exits non-zero if an export fails.

;;; Code:

(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))
(require 'ox-ipynb)

(let ((org-confirm-babel-evaluate nil)
      (org-babel-default-header-args
       (cons '(:eval . "never-export") org-babel-default-header-args))
      (failed nil))
  (dolist (file command-line-args-left)
    (condition-case err
        (message "Exported %s" (ox-ipynb-export-org-file-to-ipynb-file file))
      (error (push file failed)
             (message "FAILED %s: %S" file err))))
  (setq command-line-args-left nil)
  (kill-emacs (if failed 1 0)))

;;; export-examples.el ends here
