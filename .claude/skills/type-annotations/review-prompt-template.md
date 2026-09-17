# External review prompt — astropy PR #<NUMBER>

This is the handoff document for the *adversarial reviewer* — an independent agent
(Codex, another Claude, a Copilot session) that has not seen the annotation work. Fill
in the `<...>` placeholders, save it as `external-review-prompt.md` in the repo root, and
give it to the user to paste into the other agent, pointed at branch `<BRANCH>` of
`<FORK URL>` (PR astropy/astropy#<NUMBER>).

**Give the reviewer the rules, not the answers.** Everything below tells it what the
project decided and what counts as a finding. Nothing below explains *why* any
individual annotation was chosen. If it read "ColumnLike resolves to Any because mixins
share no base class", it would nod along; the point is for it to derive the type from
the code first and only then notice a mismatch. Do not paste the handoff doc, the PR
description's rationale, or commit messages into this prompt.

---

You are reviewing a pull request that adds type annotations to every module in
`astropy/<SUBPACKAGE>/`. Review the diff against `main`.

## What this PR is trying to do

Make the code easier to read and edit for humans — hovering over a parameter in an
editor should say what it accepts. The annotations are intended to be **only as precise
as the existing docstrings**.

## Explicit non-goals — do NOT report findings of these kinds

These are settled project decisions, not oversights. Findings in these categories are
noise and will be discarded:

- **Supporting static type checkers is a non-goal.** The package ships no `py.typed`, so
  under PEP 561 downstream checkers ignore these annotations. Do not report that a
  signature would fail mypy/pyright, or that a type is insufficiently precise for a
  checker.
- **Runtime annotation retrieval (`typing.get_type_hints()`) is a non-goal.**
- **Imprecision is acceptable.** `np.ndarray` rather than `npt.NDArray[np.float64]`,
  `Any` rather than a protocol, `list` rather than `list[str]` — do not report these
  unless the annotation is *contradicted* by the code, not merely looser than possible.
- **Bare `**kwargs` is intentional** and exempted via ruff ANN003.
- **<Any deliberately skipped modules, e.g. `astropy/table/bst.py` (deprecated)>.**
- Style, formatting and import ordering are already enforced by ruff and pre-commit.
  Do not report them.

## What to look for

Report only cases where an annotation is **contradicted by the code**. For each def in
the diff, derive the types yourself from the implementation and its call sites, then
compare against what was written. Specifically:

1. **Return type contradicts the body.** A declared return type that some `return`
   statement cannot produce — including early returns, `return []`, bare `return`, and
   generator functions annotated by their apparent return rather than `Iterator[...]`.
2. **Parameter union too narrow.** A caller in the repo passes something the union
   excludes, or the body branches on a type the union omits (e.g. `isinstance` checks
   for a type not in the annotation).
3. **Parameter union wrong, not just loose.** The annotation names a type the function
   would actually reject.
4. **`Self` vs concrete class errors.** Methods returning a new instance annotated with a
   concrete class where a subclass is actually returned, or vice versa.
5. **Mutated defaults / sentinel mismatches.** A default value that is not an instance of
   the declared parameter type, where that is not a deliberate documented sentinel.
6. **Annotations that disagree with the docstring** where the *code* shows the docstring
   is the correct one.

## How to report

Write one file per module, `codex-reviews/<module>-review.md`. For each finding give:
file and line, the annotation as written, the specific code that contradicts it (quote
it), and the corrected annotation. Rank by confidence. If you are uncertain whether
something is a real contradiction, say so explicitly rather than padding the list.

If you find nothing in a module, say so in one or two sentences — do not invent
findings. An empty report for a module is a useful result.

## Areas worth extra attention

These involve types derived by reading implementations rather than copied from
docstrings, so they are the likeliest places for an error:

- <module — the specific functions whose types came from the body, not the docstring>
- <module — any multi-element tuple return types>
- <module — Literal alias sets that differ between similar functions>
- <module — Self return types on subclasses>
- Pre-existing annotations *changed* in this PR as bug fixes. Verify each is now right:
  <list them>
