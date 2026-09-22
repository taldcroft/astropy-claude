---
name: docstring-param-mismatch-prs
description: "Two doc-only PRs (worktrees) fixing signature/docstring Parameters mismatches; PRs #20437 (public) and #20438 (internal), opened as drafts 2026-09-18"
metadata: 
  node_type: memory
  type: project
  originSessionId: 46568cc1-42f0-48f8-a107-6b664af12659
  modified: 2026-09-18T12:49:22.556Z
---

On 2026-09-18 a scan of astropy (ast signature vs numpydoc Parameters) found 75
mismatches out of 1406 functions with a Parameters section (7317 functions total).
Fixed in two worktrees, both branched off upstream/main, pushed to origin and open as draft PRs:

- `~/git/astropy-pr-fix-docstring-params-public` (branch `fix-docstring-params-public`,
  PR #20437, description in `pr20437-description.md`) — 46 functions with
  a page in the stable API docs.
- `~/git/astropy-pr-fix-docstring-params-internal` (branch
  `fix-docstring-params-internal`, PR #20438, description in
  `pr20438-description.md`) — 29 internal helpers; its description references #20437.

Deliberately not changed (decorator-injected kwargs, docstring is right for the
wrapper): `cosmology_equal` / `_cosmology_not_equal` (`format`), fitter `__call__`
methods (`equivalencies`), and `custom_model` (`*args` documented as `func`).

Scan scripts live in the session scratchpad only (`classify.py`, `in_docs.py`,
`count_funcs.py`); they need `objects.inv` from docs.astropy.org/en/stable.

**Why:** two PRs so the user-visible fixes can be reviewed and merged independently of the lower-priority internal ones.

**How to apply:** address review comments in the matching worktree; no changelog fragments (doc-only). Remove the worktrees with `remove-worktree.sh` once merged.
