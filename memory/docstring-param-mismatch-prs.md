---
name: docstring-param-mismatch-prs
description: "Doc-only signature/docstring Parameters mismatch PRs: #20437 (public) merged 2026-09-25, #20438 (internal) closed unmerged; both worktrees removed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 46568cc1-42f0-48f8-a107-6b664af12659
  modified: 2026-09-25T23:40:22.889Z
---

On 2026-09-18 a scan of astropy (ast signature vs numpydoc Parameters) found 75
mismatches out of 1406 functions with a Parameters section (7317 functions total).
Split into two doc-only PRs so the user-visible fixes could merge independently.

Outcome (2026-09-25):

- **PR #20437** (public API, 46 functions with a page in the stable API docs) —
  **merged** as squash commit `5920706` on `upstream/main`.
- **PR #20438** (29 internal helpers) — **closed unmerged**.

Both worktrees are removed. Branches `fix-docstring-params-public` and
`fix-docstring-params-internal` are kept locally (not deleted). Descriptions moved to
`~/git/astropy/pr-descriptions/pr20437-notes/` and `pr-descriptions/pr20438-notes/`.

Deliberately not changed (decorator-injected kwargs, docstring is right for the
wrapper): `cosmology_equal` / `_cosmology_not_equal` (`format`), fitter `__call__`
methods (`equivalencies`), and `custom_model` (`*args` documented as `func`).

Scan scripts lived in the session scratchpad only (`classify.py`, `in_docs.py`,
`count_funcs.py`) and are gone; they needed `objects.inv` from docs.astropy.org/en/stable.
Re-run the scan from scratch if the internal-helper work is ever revived.

**Why:** #20438's internal-helper churn was judged not worth the review cost, so only
the user-visible half landed.

**How to apply:** if the internal fixes come up again, start from the surviving
`fix-docstring-params-internal` branch rather than rescanning. See
[[skills-live-in-astropy-claude-repo]] for how a new worktree's `.claude/` resolves.
