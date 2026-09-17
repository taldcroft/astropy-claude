---
name: table-index-memory-leak-16089
description: "Fix for issue #16089 (MaskedColumn index memory leak) lives in worktree astropy-pr-table-fix-index-memory-leak; changelog uses PR number 20396, uncommitted as of 2026-09-14"
metadata: 
  node_type: memory
  type: project
  originSessionId: a8090223-5125-47c3-b75a-95a9c309bec3
  modified: 2026-09-14T15:49:08.802Z
---

Issue #16089 (memory leak slicing a table with an index on a `MaskedColumn`) was fixed
on 2026-09-14 in worktree `~/git/astropy-pr-table-fix-index-memory-leak`, branch
`table-fix-index-memory-leak`. Root cause: numpy's `MaskedArray._optinfo` dict carried
the column's live `indices` list into every derived array, so a slice of a slice regained
the original index and `Index.__init__` deep-copied it on every access. Fix is in
`BaseColumn.__array_finalize__` / `MaskedColumn.__new__` in `astropy/table/column.py`.

**Why:** The changelog fragment was named `20396.bugfix.rst` from the latest issue
number at the time; the PR was not yet opened, so the number may need renaming.

**How to apply:** When opening or updating that PR, check the real PR number against the
fragment name. The RSS reproduction script lives in the main-tree session scratchpad as
`leak16089.py` (not in the repo); the repo has tracemalloc-based regression tests in
`astropy/table/tests/test_index.py` instead. See [[astropy-pr-template-honeypot]] for the
PR body template.
