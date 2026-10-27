# Development tasks for ox-ipynb.  CI runs `make ci`.
#
# Everything runs in a clean `emacs -Q --batch` so results do not depend on
# personal configuration.  Override EMACS to use a different binary.

EMACS ?= emacs
BATCH := $(EMACS) -Q --batch -L .
UV    ?= uv

EL_FILES      := ox-ipynb.el ox-ipynb-v2.el
EXAMPLE_ORGS  := $(filter-out examples/README.org, $(wildcard examples/*.org))
EXAMPLE_NBS   := $(EXAMPLE_ORGS:.org=.ipynb)

.PHONY: help compile test test-v2 examples validate checkdoc ci clean

help:
	@echo "make compile   Byte-compile (STRICT=1 turns warnings into errors)"
	@echo "make test      Run ERT tests for ox-ipynb.el"
	@echo "make test-v2   Run ERT tests for the experimental ox-ipynb-v2.el"
	@echo "make examples  Export examples/*.org to .ipynb (no code evaluation)"
	@echo "make validate  Export examples and validate them with nbformat (needs uv)"
	@echo "make checkdoc  Report docstring style issues"
	@echo "make ci        compile + test + validate"
	@echo "make clean     Remove build artifacts"

# ox-ipynb.el still has many warnings; flip CI to STRICT=1 once it is clean.
STRICT ?=
compile:
	$(BATCH) $(if $(STRICT),--eval "(setq byte-compile-error-on-warn t)") \
	  -f batch-byte-compile ox-ipynb.el
	rm -f ox-ipynb.elc

test:
	$(BATCH) -L tests -l tests/ox-ipynb-test.el \
	  -f ert-run-tests-batch-and-exit

test-v2:
	$(BATCH) -L tests -l ox-ipynb-v2 -l tests/ox-ipynb-v2-test.el \
	  -f ert-run-tests-batch-and-exit

examples:
	$(BATCH) -l scripts/export-examples.el $(EXAMPLE_ORGS)

validate: examples
	$(UV) run --quiet --with nbformat scripts/validate-notebooks.py $(EXAMPLE_NBS)

checkdoc:
	$(BATCH) --eval "(dolist (f '($(patsubst %,\"%\",$(EL_FILES)))) (checkdoc-file f))"

ci: compile test validate

clean:
	rm -f *.elc tests/*.elc $(EXAMPLE_NBS) examples/*.slides.html
