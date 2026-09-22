---
name: table-index-memory-leak-16089
description: "Issue #16089 (MaskedColumn index memory leak) fixed by PR #20456, merged 2026-09-22; worktree removed, notes in main tree pr-descriptions/pr20456-notes/"
metadata: 
  node_type: memory
  type: project
  originSessionId: a8090223-5125-47c3-b75a-95a9c309bec3
  modified: 2026-09-22T00:00:00.000Z
---

Issue #16089 (memory leak slicing a table with an index on a `MaskedColumn`) was fixed by
PR #20456, **merged 2026-09-22**. Root cause: numpy's `MaskedArray._optinfo` dict carried
the column's live `indices` list into every derived array, so a slice of a slice regained
the original index and `Index.__init__` deep-copied it on every access. Fix is in
`BaseColumn.__array_finalize__` / `MaskedColumn.__new__` in `astropy/table/column.py`,
with tracemalloc-based regression tests in `astropy/table/tests/test_index.py`.

The worktree `~/git/astropy-pr-table-fix-index-memory-leak` has been removed; the local
branch `table-fix-index-memory-leak` was kept. The PR description now lives at
`~/git/astropy/pr-descriptions/pr20456-notes/pr20456-description.md`.

**Why:** Keeps the merged work findable after the worktree is gone.

**How to apply:** Reference PR #20456 for follow-ups on masked-column index behavior.
See [[astropy-pr-template-honeypot]] for the PR body template.
