# Handoff: type annotations for `astropy.<SUBPACKAGE>`

Untracked scratch doc for continuing the work in this worktree
(`~/git/astropy-pr-<BRANCH>`, branch `<BRANCH>`). Delete it, along with
`external-review-prompt.md`, `codex-reviews/` and `pr<N>-description.md`, before running
`remove-worktree.sh` — that script refuses to tear down a worktree with untracked
non-build files.

This is the handoff for the *next annotation session* (a future Claude in this
directory). The handoff for the *adversarial reviewer* is a different document —
`external-review-prompt.md` — and must not contain the rationale recorded here.

## Where things stand

- **PR #<N>** — "<title>", **draft** / ready, opened <date>. Rebase base: `<sha>`.
- Coverage: <done>/<total> defs (`count-annotations.py astropy/<SUBPACKAGE> --skip ...`).
  On the rebase base it was <done>/<total>.
- Commits: one per module, each `[skip ci]`. <list any that are not>
- Green: `ruff check`, `ruff format --check`, full `pre-commit`, and the test set in
  "Mechanics" below (<N passed>).
- Pushed / unpushed: <state>. `origin` is at `<sha>`.

## The decisions that came out of PR review

This is the part that isn't recoverable from the diff. Read it before writing more
annotations. Keep the standing ones from `astropy.table` (PR #20276) unless a
maintainer has reopened them:

- Static type checking is a non-goal; runtime `get_type_hints()` is a non-goal.
- No `py.typed` ships; that is the agreed mitigation for imprecise annotations.
- Two-phase strategy: mechanical annotations as correct as the docstrings first,
  precision later. Not "few annotations, all correct".
- Reviewer time is the real constraint. One commit per module; decline scope creep with
  a one-line reason (mutable defaults, dead-code removal, docstring fixes).

<Decisions specific to this subpackage's review thread, with who said what and where.>

## Conventions specific to this subpackage

<Aliases defined in `_typing.py` and why each resolves to what it does. Any Literal
aliases defined locally in a module and why they are not shared. Subclass-hook classes
that need the annotate-in-`__init__` treatment. Optional-dependency return types left as
`Any`.>

## Don't trust the docstrings — cases settled by the code

<Each place the docstring said one thing and the call sites or a runtime probe said
another, with the probe. These are the most valuable lines in this document.>

## Bugs found and fixed while annotating

<Pre-existing wrong annotations corrected, broken TYPE_CHECKING imports fixed. Each with
the file and what it was.>

## Found but deliberately not fixed

<Dead code, mutable defaults, stale docstrings — with the one-line reason each was left.>

## Adversarial review

- Reviewers: <model / harness per module set>.
- Findings: <N> across <M> modules; <K> applied. Per-module dispositions in
  `codex-reviews/<module>-review.md`; the collated PR comment in
  `codex-reviews/collated-review.md`.
- Declined findings and why: <list>.
- Left open for a maintainer: <e.g. `Self | NotImplementedType` on binary dunders>.

## Open items

<Anything unresolved on the PR thread that the next session should not re-litigate
without checking the thread first.>

## Next modules / next subpackage

<Remaining work, sized: module, defs to do, lines, one-line note on what makes it hard.>

## Mechanics

```bash
# ALWAYS from inside this worktree — cwd determines which source tree is imported
cd ~/git/astropy-pr-<BRANCH>
conda run -n astropy-dev python -m pytest astropy/<SUBPACKAGE> docs/<SUBPACKAGE> -q -n auto
conda run -n astropy-dev ruff check astropy/<SUBPACKAGE>/<mod>.py
conda run -n astropy-dev ruff format astropy/<SUBPACKAGE>/<mod>.py
conda run -n astropy-dev pre-commit run --files astropy/<SUBPACKAGE>/<mod>.py
# scripts: conda run drops stdin heredocs, so write a file and use the interpreter
PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python <scratchpad>/probe.py
```

Downstream test set that also has to stay green for this subpackage: <list>.
