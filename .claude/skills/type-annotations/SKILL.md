---
name: type-annotations
description: Add type annotations to an astropy subpackage, module by module, with the conventions and review process settled on PR #20276 (astropy.table). Use when asked to add or continue type annotations / type hints for a subpackage or module, to write or update a TYPING-HANDOFF doc, to set up or process an adversarial (Codex / Copilot / other-model) review of annotations, or to collate such a review for a PR comment.
---

# Adding type annotations to an astropy subpackage

Reference example: PR astropy/astropy#20276, "Add type annotations to the astropy.table
subpackage" — 21 modules, 496/496 defs, one commit per module, then an independent
adversarial review that found 16 real errors of which 14 were applied. The handoff doc
from that work, `TYPING-HANDOFF.md`, and the review record in `codex-reviews/` are the
worked examples for the documents this skill produces.

## The goal, and the non-goals that are settled

**Goal:** make the code easier to read and edit for humans. Hovering over a parameter in
an editor should say what it accepts. The bar is annotations **as correct as the
docstrings**, complete across the subpackage — explicitly *not* "few annotations, all
correct".

These were decided by the maintainers on #20276 and are not reopened per PR:

- **Static type checking is a non-goal.** Never add or narrow an annotation whose only
  justification is satisfying mypy/pyright.
- **Runtime annotation retrieval (`get_type_hints()`) is a non-goal.**
- **Astropy ships no `py.typed`.** Under PEP 561 that means downstream checkers ignore
  inline annotations, which is the agreed mitigation for shipping imprecise ones. If
  anyone proposes adding `py.typed`, everything changes — stop and take it to the
  maintainers.
- **Two-phase strategy.** Phase 1 (this skill): mechanical annotations consistent with
  the docstrings. Phase 2, later, as resources allow: precision improvements.
- **Reviewer time is the real constraint.** There is no funding or roadmap status for
  this work (APE astropy/astropy-APEs#94, stalled). Every decision below that trades
  precision for reviewability is deliberate.
- **Do not touch test modules.**

Expect some reviewers to be more typing-strict than this
goal. The productive pattern: take cheap precision wins that also help a human reader
(that is how `@overload` got in), and decline scope creep with a one-line reason.

## Deliverables

In the worktree for the branch, all **untracked** except the source changes:

| what | where |
|---|---|
| annotations | `astropy/<pkg>/*.py`, one commit per module |
| shared aliases | `astropy/<pkg>/_typing.py`, its own commit, first |
| session handoff | `TYPING-HANDOFF.md` (repo root) — from `handoff-template.md` |
| reviewer handoff | `external-review-prompt.md` (repo root) — from `review-prompt-template.md` |
| review record | `codex-reviews/<module>-review.md`, `README.md`, `collated-review.md` |
| PR description | `pr<N>-description.md` via the `pr-description` skill |

Every untracked file has to be deleted before `remove-worktree.sh` will tear the
worktree down. Say so in the handoff.

## Workflow

### 0. Set up

- Work in a worktree (`worktree` skill). The main tree stays on `main`.
- **Rebase onto a freshly fetched `upstream/main` first** and record the base SHA
  (`git merge-base upstream/main HEAD`). Two reasons: the Python floor decides which
  syntax is legal (see PEP 695 below), and every before/after number must be measured
  against this base, not against a live `upstream/main` that keeps moving — a module
  gaining a def upstream looks exactly like a def you deleted.
- Get the commit cadence authorized up front. CLAUDE.md says never commit without
  stopping for review; for this work the user has authorized "one commit per module,
  `[skip ci]`" once the first module has been shown and approved. Do not assume it —
  ask, then proceed without re-asking per module.

### 1. Inventory

```bash
python .claude/skills/type-annotations/count-annotations.py astropy/<pkg> --gaps --skip <deprecated>.py
python .claude/skills/type-annotations/count-annotations.py astropy/<pkg> --ref <base-sha> --skip <deprecated>.py
```

A def is done when it has a return annotation and every parameter annotated; a bare
`**kwargs` is exempt because `.ruff.toml` ignores ANN003. Nested functions and
`@overload` stubs count. Skip deprecated modules (`bst.py`) by decision, and say so.

Order the modules by value, not size: the container class first (it was already done for
`table`), then whatever `ColumnLike`-style aliases resolve to, then the index/operations
machinery, then the cheap leaves. Reading a module end-to-end is what the work costs;
writing the annotations is mechanical.

### 2. Shared aliases first, in their own commit

Any alias two modules want goes in a **private** `astropy/<pkg>/_typing.py` — private
because most such aliases resolve to `Any` and making them public API is a commitment.
Every alias gets a docstring so it hovers usefully. Consumers import it inside
`if TYPE_CHECKING:`. The module itself is runtime-importable: its own imports of the
concrete classes sit under `TYPE_CHECKING`, so there is no import cycle.

For `table` the four were `ColumnLike` (a `Column`, `MaskedColumn` or any mixin — `Any`
because mixins share no base class, only a working `info`), `DataLike`, `TableLike` and
`SortKind`. Reuse them for a subpackage that consumes tables; define the analogues for
one that does not.

### 3. Per-module loop

For each module, in order:

1. **Read it end-to-end.** Not the def lines — the bodies and the call sites. This is
   where the docstrings turn out to be wrong (below).
2. **Probe anything uncertain at runtime** before writing it down. A five-line script
   answers "does `__eq__` return `np.bool_` or `bool`" or "is this a generator"
   conclusively; guessing does not. Write the script to the scratchpad and run it with
   `PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python` — `conda run` drops
   stdin heredocs, and a script run by path from a worktree otherwise imports the *main*
   tree.
3. **Apply with an exact-string edit script** (`annotate-template.py`): `(old, new)`
   pairs, `assert s.count(old) == 1` on each, one run. When a bare signature is not
   unique — `table.py` has four `def __repr__(self):`, `column.py` has two byte-identical
   `__new__` signatures — extend `old` with the first body line until it is.
4. `ruff format`, `ruff check`, `pre-commit run --files`, then the tests (below).
5. Re-run the inventory for that module. Anything left should be `**kwargs`-only.
6. Commit: `Add type annotations to <pkg>/<module>.py [skip ci]`, with a body that
   records the *non-obvious* decisions — which docstring was wrong and how the code
   settled it, what was declined and why, any lint that woke up. The commit message is
   where a reviewer who takes one module at a time finds the reasoning.

Show the user the first module before continuing. After that, keep going.

### 4. Finish the branch

- Run the full verification set (below) once more across everything.
- Update `TYPING-HANDOFF.md` from the template — especially "Don't trust the
  docstrings" and "Found but deliberately not fixed".
- Retitle the PR and write the description with the `pr-description` skill. Include the
  user's original prompts verbatim in the AI disclosure — a maintainer asked for that on
  #20276 as a precondition of review. Say it is one commit per module so it can be read
  file by file.
- No changelog fragment: there is no behavior change. If one is demanded it is
  `docs/changes/<N>.other.rst` at the *top level* — `other` is not allowed inside a
  subpackage directory.
- Push with `--force-with-lease` only, and only when asked.

### 5. Adversarial review

Do this before asking a human to review. See the dedicated section below.

## Conventions

**Module header.** `from __future__ import annotations` goes *after the module
docstring*, then a blank line. A module with no docstring puts it right after the license
comment, which is why `table.py` looks different from `table_helpers.py`. Get this wrong
and the docstring becomes a no-op expression and ruff flags every later import as E402.
Then `from typing import TYPE_CHECKING, Any, Literal, Self, overload` as needed.

**`TYPE_CHECKING` block** after all runtime imports: `collections.abc` names,
`numpy.typing as npt`, `astropy.units.typing.UnitLike`, the package's `_typing` aliases,
and any class that would create an import cycle (`Table` from a module `table.py`
imports). A module that already imports `groups` or `pprint` at runtime spells
`groups.ColumnGroups` / `pprint.TableFormatter` rather than adding a `TYPE_CHECKING`
import for them.

**PEP 695 `type X = ...`, not `X: TypeAlias = ...`.** Python ≥ 3.12 is required
(#20223). `.ruff.toml` currently ignores UP040, so `TypeAlias` still lints clean today —
but #20307 removes that ignore while converting the codebase, so `type` is the form that
is green both before and after it merges. Lazy evaluation also means the right-hand side
need not be quoted even when its names are `TYPE_CHECKING`-only. The one carve-out: an
alias that must be runtime-`isinstance`-able keeps `TypeAlias` with `# noqa: UP040` and a
comment (see `units/typing.py::UnitScale`).

**`Self`** for anything returning a new instance of the same class — `copy`, `insert`,
`group_by`, `__deepcopy__`, `__getitem__` slices, descriptor `__get__`, anything built via
`self.__class__(...)`. Confirm subclass preservation with a probe when unsure. Use the
concrete class only where the code literally constructs `Table(...)` regardless of
subclass, or where the *point* is to change class (`MaskedColumn.filled() -> Column`).

**`@overload` for `__getitem__`** whenever the return type genuinely depends on the key
type. Keep the flat implementation signature underneath. When a later fix widens a key
union, add it to the overload, do not flatten.

**`Literal` aliases beat repetition.** Define them in the module's `TYPE_CHECKING` block
when a union of strings appears in more than two signatures. Check the sets are really
the same first — `operations.py` needed both `JoinType` and `StackJoinType` because
stacking accepts `exact` and rejects `left`/`right`/`cartesian`.

**Subclass-hook attributes are annotated in `__init__`, not the class body.** A class
with `TableColumns = TableColumns` as a hook makes a class-body `columns: TableColumns`
resolve to `type[TableColumns]`. Write `self.columns: TableColumns = ...` at the
assignment instead. `table` does this deliberately for `Row`, `Column`, `MaskedColumn`,
`TableColumns`, `TableFormatter`.

**Dunders.** `__eq__(self, other: object)`; ordering dunders take the actual accepted
type. Return what the code returns — `np.bool_ | np.ndarray` for a comparison that hands
off to numpy, not `bool`. `__or__` and friends: `other: object` when there is an
`isinstance` guard with a `NotImplemented` fallback. Whether to spell the return as
`Self | NotImplementedType` is a maintainer style call — flag it, do not decide it.

**Generators** are `Iterator[T]`, not their apparent return. `@contextmanager` functions
are `Iterator[None]`. This is the single most common way a return annotation is flatly
wrong.

**Optional dependencies.** A return type from a lazily imported optional package
(IPython, ipydatagrid, a DataFrame backend) is `Any` with a note, not a `TYPE_CHECKING`
import of the package. `Table.show_in_notebook` set the precedent.

**`*args` / `**kwargs`.** Adding a return annotation to a bare function makes ruff enforce
ANN002 on `*args` — give it `*args: Any`. `**kwargs` stays bare (ANN003 ignored) and is
counted as done.

**Sentinel defaults.** Spell them. `out: IO[str] | Literal[""] | None = ""` documents an
otherwise baffling default where `""` means stdout and `None` means "return instead".

**Sized vs iterable.** If the body calls `len()` on it, it is `Collection`/`Sequence`,
not `Iterable`. If one path calls `len()` and the common path does not, leave `Iterable`
and say so — do not make the annotation wrong for the common case to describe the rare
one.

**`list | tuple` vs `Sequence`.** When the code does `isinstance(x, (list, tuple))` or
a `_is_list_or_tuple_of_str` check, write `list[str] | tuple[str, ...]`. `Sequence`
promises a `UserList` would work, and it will not.

## Don't trust the docstrings

The docstring is where to start, not where to stop. Every one of these was settled by
reading the body or a call site, and each is the kind of thing a reviewer will find if
you do not:

- `filled(fill_value)` documented as `str`; accepts anything.
- `copy` is tri-state `bool | None` through the whole init path.
- `get_auto_format_func(col)` documented as "hashable id"; the body uses
  `col.info._format_funcs`, so it is a column.
- `sorted_data()` was annotated `-> None` and returned `self.row_index` — a wrong
  pre-existing annotation copied into a `Protocol` too. **Fix these; they are in scope.**
- `Column.insert(axis)` documented as `int`; forwards to `np.insert` where `None` means
  flatten, and a test uses it.
- `meta` conventionally string-keyed; a test uses integer keys and the docstring says
  only "dict".
- Two join helpers took `list[str]` per their docstrings; every caller passes a tuple.
- A `TYPE_CHECKING` import from `units.typing` instead of `astropy.units.typing` had
  never resolved for anyone. **Fix these too.**

## Gotchas that cost real time

- **A precise annotation can wake a dormant lint.** Annotating a parameter `dict[str,
  Any]` let ruff infer the type and start reporting PERF403 on a loop it had ignored.
  When ruff offers no autofix and the fix would be a logic change, suppress with a
  `# noqa` and a comment. **Never weaken an annotation to dodge a lint.**
- **`from __future__ import annotations` triggers UP037** on every quoted forward
  reference already in the file. Unquote them in the same commit.
- **`conda run` drops stdin heredocs** and buffers output; scripts go in the scratchpad
  and run with the interpreter directly, with `PYTHONPATH=$PWD` so they import the
  worktree and not the main tree.
- **`cd` in a compound command persists.** A later relative path silently resolves
  against the wrong directory. Use absolute paths or `cd` back explicitly.
- **Check `git log -1` after every commit.** A heredoc trailer is easy to duplicate or
  mangle; amend immediately, before anything is pushed.
- **PEP 695 syntax is a hard parse error below 3.12**, not a lint. If the branch predates
  the Python bump, rebase before writing a `type` statement.

## Verification

Per module: `pytest astropy/<pkg> docs/<pkg> -q -n auto`. `docs/<pkg>` matters because
`--doctest-rst` is in `addopts` and repr changes break doctests far from the edit — not
a risk for annotations, but cheap insurance.

Before committing anything central (`column.py`, `serialize.py`, the container class)
and once at the end, the downstream consumers too. For `table` that is
`astropy/io/ascii astropy/time docs/time astropy/io/fits/tests/test_connect.py
astropy/io/misc/tests/test_hdf5.py astropy/cosmology
astropy/coordinates/tests/test_sky_coord.py`. Never the full suite unless asked.

Never say tests pass without having run them; quote the real counts. After applying
review fixes, re-run the behavior probes and confirm every case that raised still raises
with the same message — that is the proof the change was annotation-only.

## Adversarial review

An independent agent reviewing the annotations is worth doing, **as a bug finder, not an
approval signal**. On #20276 it found 16 real contradictions across 21 modules — nine of
them in the one module that had already had the most human review. The value is
asymmetric: a "looks good" from an LLM is a correlated-error non-result; a "this cannot
return that, see line 96" is a falsifiable lead checkable in thirty seconds.

**Set it up.**

- Fill in `review-prompt-template.md` → `external-review-prompt.md`. It gives the reviewer
  the *rules* (the non-goals, what counts as a contradiction, how to report) and **not
  the answers** — no handoff doc, no commit messages, no rationale for any annotation.
  A reviewer that reads the rationale nods along; one that derives the type from the
  code first is the point.
- Fill in "Areas worth extra attention" with the places where types came from reading
  bodies rather than docstrings, and every pre-existing annotation you *changed*.
- Prefer a different vendor from the model that wrote the annotations, for
  decorrelation. Two vendors, keeping only what they disagree on, is cheap and useful.
- The user runs it; the reviewer writes `codex-reviews/<module>-review.md`.

**Process the findings.** Verify every one yourself against the source and at runtime
before touching anything — reviewers produce confident false positives, and a wrong
"fix" to a correct annotation is worse than the original. Expect to decline some. On
#20276: one was a decision already taken on the thread; one had a true premise but a
correction that did not fix it (a scalar dtype *is* valid when structured, so the
constraint was value-level and inexpressible); one had to be split because narrowing
the common path to fix the rare one would have been wrong.

Then, per module, append a **Disposition** section to its review file: for each finding,
did it reproduce, accepted or declined, and the decisive evidence (the probe output, the
call-site line, the test that exercises it). For null-result modules say plainly that a
null result is not verifiable the way a finding is — confirming nothing was missed would
mean redoing the review, not checking it. Add a `codex-reviews/README.md` with the
model/harness split and the results table.

Apply the accepted fixes in one commit per review round, with a message that lists what
was declined and why. Fold widened key unions into existing `@overload` blocks.

**Collate for the PR.** `codex-reviews/collated-review.md`, written in the user's first
person for pasting as a PR comment: what the reviewers were told and not told, the
results table, one collapsed `<details>` per module with findings (claim, disposition,
evidence — no boilerplate), the null-result modules as a bare list, and a limits section
that says the null results are not proof, that LLM reviewers share blind spots with the
LLM author, and that none of this touches the design questions (whether `ColumnLike`
should be `Any`, whether dead code should be deleted rather than annotated, whether the
subpackage should carry annotations at all). Validate that every `<summary>` is followed
by a blank line or GitHub renders the markdown inside as raw text.

## Scope discipline

Decline, with one line, in the commit message or the thread:

- Mutable defaults (`table_names=["1", "2"]`, `equivalencies=[]`). Pre-existing.
- Deleting dead code found while annotating (`SlicedIndex.where()` calls a method that
  does not exist). Annotate it as written; flag it.
- Docstring fixes, even when the annotation now contradicts the docstring. Note it so
  nobody "corrects" the annotation back.
- Making a checker happy.

Do **not** decline: correcting a pre-existing annotation that is flatly wrong, or a
broken `TYPE_CHECKING` import. Those are typing fixes in a typing PR.
