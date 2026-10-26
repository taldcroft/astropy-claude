---
name: doc-typos-20661
description: "PR #20661 (~75 docs/docstring typos) merged 2026-10-20; worktree and branch removed; ~20 comment-only typos left for a follow-up"
metadata:
  node_type: memory
  type: project
  originSessionId: 4d22046c-668d-40ca-b8d7-6911ab992358
  modified: 2026-10-20T12:19:20.393Z
---

PR #20661 (opened and merged 2026-10-20; worktree and branch `fix-doc-typos` removed, description saved in main tree `pr-descriptions/pr20661-notes/`) fixed about 75 typos in `docs/*.rst` and rendered docstrings. Codespell passes on main, so these were found with scripted repeated-word, rare-word and a/an scans; the scan scripts are not in the repo.

**Why:** codespell in pre-commit misses doubled words and many misspellings.

**How to apply:** about 20 comment-only typos were deliberately left out ("need need" in io/fits/hdu/base.py, "an an array" in two function_helpers.py files, "witihin", "posisble", "distinguist", "brodcastable", "equiivalent", "sexigesimal", ...). They are candidates for a follow-up PR.
