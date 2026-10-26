---
name: table-group-by-perf-20721
description: "Experimental draft PR #20721 (opened 2026-10-26) speeding up Table.group_by via 16-bit-digit radix sort; parked, not yet reviewed by user"
metadata:
  node_type: memory
  type: project
  originSessionId: d32ae4d8-9c3b-43e0-950e-a09beb02e156
  modified: 2026-10-26T13:35:50.231Z
---

Draft PR astropy#20721, labels table/Performance/Experimental, branch `table-group-by-perf` (renamed from `table-group-by-pandas`; worktree dir is still `~/git/astropy-prs/table-group-by-pandas` to keep the Claude session history). Description file `pr20721-description.md` in that worktree (untracked).

Started as "pandas engine for group_by, following #19860" but the numpy-only LSD radix sort (16-bit digits so each pass hits numpy's radix path) gave 3.5x+ for int keys, ~700x for Time keys (boundary fix), so pandas was dropped. User's bar: pandas only worth it if >=3x; only string keys might qualify.

**Why:** user had no time to continue and wanted it captured, not lost.

**How to apply:** when resuming, the user has NOT reviewed the code yet (AI-disclosure certify box left unchecked on purpose). Open items are listed in the PR body: pandas path for string keys, redundant `Table(...)` copy (meta deep vs shallow copy), threshold tuning, reuse in Table.sort/join/unique.
