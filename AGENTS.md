# AGENTS.md — guide for coding agents working on ox-ipynb

## Project goal

This is a fork of [jkitchin/ox-ipynb](https://github.com/jkitchin/ox-ipynb), an
Org-mode exporter that turns `.org` files into Jupyter notebooks (`.ipynb`).

The fork exists so that **course notebooks for AI, ML and NLP university
courses can be written in Org-mode and exported to `.ipynb` files that work
without manual fixes in Google Colab** (and in plain Jupyter). Work proceeds in
small, incremental improvements, each one a separate GitHub issue + PR.

- Fork (where all development happens): https://github.com/andras-simonyi/ox-ipynb
- Upstream (read-only for us): https://github.com/jkitchin/ox-ipynb
- Backlog of candidate improvements: [`ROADMAP.org`](ROADMAP.org)

## Repository layout

| Path | What it is |
|------|------------|
| `ox-ipynb.el` | **Main exporter (primary target of this fork).** Org → cells → JSON. |
| `ox-ipynb-v2.el` | Experimental upstream rewrite via ox-md/jupytext. Not used for course material; don't change it unless an issue says so. |
| `tests/test-helper.el` | Helpers: `ox-ipynb-test-export` (Org string → parsed notebook alist), `ox-ipynb-test-cells`, `ox-ipynb-test-source`, `ox-ipynb-test-all-source`. |
| `tests/ox-ipynb-test.el` | ERT tests for `ox-ipynb.el`. |
| `tests/ox-ipynb-v2-test.el`, `tests/fixtures/` | Upstream tests/fixtures for v2. |
| `examples/*.org` | Feature showcase; every one must export and pass nbformat validation. `examples/Makefile` is upstream's (needs Jupyter, opens files). |
| `scripts/export-examples.el` | Batch export without evaluating code. |
| `scripts/validate-notebooks.py` | nbformat schema validation. |
| `Makefile` | Dev/CI tasks (see below). |

## Commands

```sh
make test       # ERT tests for ox-ipynb.el (clean emacs -Q --batch)
make validate   # export all examples/*.org and validate with nbformat (needs uv)
make compile    # byte-compile; STRICT=1 makes warnings fatal
make test-v2    # v2 tests (some currently fail; not a CI gate)
make ci         # compile + test + validate — what CI runs
```

**On the maintainer's machine an Emacs server is running, and agents should use
`emacsclient --eval` instead of starting `emacs` themselves** (see the
`emacsclient` skill). Load the code from the repo and run tests without
exiting the server — never call `ert-run-tests-batch-and-exit` or `kill-emacs`
through emacsclient:

```sh
emacsclient --eval '
(progn
  (load "/path/to/ox-ipynb/ox-ipynb.el" nil t)
  (load "/path/to/ox-ipynb/tests/test-helper.el" nil t)
  (load "/path/to/ox-ipynb/tests/ox-ipynb-test.el" nil t)
  (let ((stats (ert-run-tests-batch "^ox-ipynb-test-")))
    (list :total (ert-stats-total stats)
          :unexpected (ert-stats-completed-unexpected stats))))'
```

The interactive session has personal config (newer Org 10.0-pre, flycheck,
non-default json settings); CI (`emacs -Q`, Emacs 30.1 / Org 9.7 and Emacs
snapshot) is the authoritative clean run. A test that passes in one but not the
other is a real problem — usually a missing `let`-binding of some user option.

Python tooling goes through `uv` (`uv run --with nbformat ...`); don't
`pip install` into the system Python.

## Workflow for every change

1. Work from a GitHub issue on the fork (or a `ROADMAP.org` item). One concern per branch.
2. Branch from `master`: `fix/<issue>-short-name` or `feat/<issue>-short-name`.
3. **Write a failing test first** in `tests/ox-ipynb-test.el`, using
   `ox-ipynb-test-export` on a minimal Org string. For user-visible features also
   add or extend an `examples/NN-*.org` file.
4. Implement the smallest change that makes it pass. Run `make test` and
   `make validate` (or the emacsclient equivalent).
5. Update `README.org` for user-visible behavior, and the "Fork changes" list there.
6. Commit with a descriptive message referencing the issue (`Fixes #N`).
7. Open the PR **against `andras-simonyi/ox-ipynb`, not upstream**. With `gh`,
   run `gh repo set-default andras-simonyi/ox-ipynb` once; otherwise `gh pr create`
   on a fork targets the parent repo.

Do not push to `master` directly, force-push shared branches, or open
issues/PRs on upstream `jkitchin/ox-ipynb` unless explicitly asked.

## Conventions

- Emacs ≥ 30, Org ≥ 9.7 (`Package-Requires`). Avoid Org APIs newer than 9.7
  unless guarded, and avoid ones obsolete in 9.8+ when a 9.7-compatible
  replacement exists (`org-link-any-re`, not `org-any-link-re`).
- `lexical-binding: t`; prefix public symbols `ox-ipynb-`, internal ones `ox-ipynb--`.
- No new package dependencies (upstream deliberately removed `s.el`/`dash.el`).
- New user options are `defcustom`s with defaults that keep existing behavior,
  unless the issue explicitly changes a default.
- Don't reformat or reindent code you are not otherwise changing — keep diffs
  reviewable. `ox-ipynb.el` is large (~1700 lines) and has many byte-compile
  warnings; fixing warnings is its own task, not drive-by work.
- Tests must not need a Jupyter kernel, network, or `user-full-name`; the helper
  disables babel evaluation, so put literal `#+RESULTS:` in test input.
  Never compare cell `id`s (random UUIDs).

## What "works in Colab" means

Generated notebooks must:

- pass `nbformat.validate` (nbformat 4.5, every cell has a unique `id`);
- render headings, emphasis, lists, tables, code and LaTeX (`$…$`, `$$…$$`)
  correctly in Colab's Markdown renderer;
- not depend on files next to the `.org` file — Colab opens a single notebook,
  so local images must be embedded or referenced by URL;
- open with a sensible kernel (Python 3) without "kernel not found" prompts.

When behavior in Colab itself matters and can't be checked locally, say so in
the PR and list what the maintainer should verify manually in Colab.
