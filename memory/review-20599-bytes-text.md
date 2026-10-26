---
name: review-20599-bytes-text
description: "ngoldbaum's PR #20599 (bytes/text coercion) merged 2026-10-20; worktree removed 2026-10-26, notes in pr-descriptions/pr20599-notes/"
metadata:
  type: project
---

PR #20599 (ngoldbaum, "Avoid implicit bytes/text coercion in tables and metadata") merged 2026-10-20. Tom asked for fuller NumpyDoc docstrings, and the author added them in commits f1f2ba637f and 145065c8ad. The worktree was removed and the local branch deleted on 2026-10-26.

Notes are in `/Users/aldcroft/git/astropy/pr-descriptions/pr20599-notes/`: `pr20599-review.md` (draft review comments, never posted; inline comment 4 is wrong), `pr20599-explainer.md`, `issue-from-df-pd-na.md`, and `local-uncommitted-docstrings.patch` (Claude's local docstring draft, superseded by the author's merged version).

The review also turned up a bug that predates the PR: `Table.from_df` raises a TypeError on `pd.NA`. It was filed as issue #20663 and is still a possible follow-up.

**Why:** records that the review is finished and where its notes went.
**How to apply:** look in pr20599-notes/ for context when working on #20663.
