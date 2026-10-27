;;; test-helper.el --- Shared helpers for ox-ipynb tests  -*- lexical-binding: t; -*-

;;; Commentary:
;; Helpers to export an Org string with ox-ipynb and inspect the resulting
;; notebook.  Notebooks are parsed with `json-parse-string' into alists with
;; symbol keys and lists for arrays, independent of the user's json settings.
;; Cell ids are random UUIDs, so tests should never compare them literally.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'subr-x)

(defvar ox-ipynb-test-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing the test files.")

(add-to-list 'load-path (expand-file-name ".." ox-ipynb-test-dir))
(require 'ox-ipynb)

(defun ox-ipynb-test-export-string (org &optional exporter)
  "Export ORG source string with EXPORTER and return the notebook JSON string.
EXPORTER defaults to `ox-ipynb-export-to-ipynb-buffer' and must return the
buffer holding the notebook.  Babel evaluation is disabled so tests never
need a Jupyter kernel; give src blocks literal #+RESULTS instead."
  (let ((org-confirm-babel-evaluate nil)
        (org-babel-default-header-args
         (cons '(:eval . "never-export") org-babel-default-header-args))
        (user-full-name "Test Author")
        (inhibit-message t))
    (with-temp-buffer
      (insert org)
      (org-mode)
      (let ((buf (funcall (or exporter #'ox-ipynb-export-to-ipynb-buffer))))
        (unwind-protect
            (with-current-buffer buf (buffer-string))
          (kill-buffer buf))))))

(defun ox-ipynb-test-export (org &optional exporter)
  "Export ORG with EXPORTER and return the parsed notebook as an alist."
  (json-parse-string (ox-ipynb-test-export-string org exporter)
                     :object-type 'alist
                     :array-type 'list
                     :null-object nil
                     :false-object :false))

(defun ox-ipynb-test-cells (nb &optional type)
  "Return the cells of notebook NB, optionally only those of cell TYPE.
TYPE is a string such as \"code\" or \"markdown\"."
  (let ((cells (alist-get 'cells nb)))
    (if type
        (cl-remove-if-not (lambda (c) (equal (alist-get 'cell_type c) type))
                          cells)
      cells)))

(defun ox-ipynb-test-source (cell)
  "Return the source of CELL as a single string.
nbformat allows the source to be a string or a list of strings."
  (let ((src (alist-get 'source cell)))
    (if (stringp src) src (string-join src))))

(defun ox-ipynb-test-all-source (nb &optional type)
  "Return the concatenated source of all cells (of TYPE) in NB."
  (mapconcat #'ox-ipynb-test-source (ox-ipynb-test-cells nb type) "\n"))

(provide 'test-helper)
;;; test-helper.el ends here
