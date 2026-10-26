---
name: review-20506-tdat-parsing
description: "Second-round review of jrunge777 PR #20506 (TDAT field-line parser + UCD checks); draft in worktree, not posted"
metadata:
  node_type: memory
  type: project
  originSessionId: a4c1c459-050a-4117-ad85-5a567fd70e6f
  modified: 2026-10-24T12:37:52.178Z
---

PR #20506 (jrunge777, HEASARC) rewrites the TDAT field-line parser in astropy/io/ascii/tdat.py.
User posted a first-round "Claude Fable review" comment earlier; second-round draft (2026-10-24,
at 9fe218d539) is in worktree `~/git/astropy-prs/20506-tdat-add-error-trapping/pr20506-review.md`,
not yet posted.

**Why:** esabol/d-giles are the TDAT domain experts; user's role is general io.ascii review.

**How to apply:** Comparisons against main were done by temporarily swapping the merge-base
tdat.py into the worktree. Similar pattern to [[review-20599-bytes-text]].
