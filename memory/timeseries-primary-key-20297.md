---
name: timeseries-primary-key-20297
description: "Fix for #20297/#11704 (TimeSeries primary_key None): timeseries PR #20361 merged 2026-09-17 (worktree removed); table PR #20362 still open; supersedes closed PR #20354"
metadata: 
  node_type: memory
  type: project
  originSessionId: afa8f91f-f19b-4fb6-866c-7b71b5a3a24b
  modified: 2026-09-17T00:00:00.000Z
---

Work on astropy issue #20297 (and #11704, same root cause) was done on branch
`fix-timeseries-primary-key` off upstream/main, created 2026-09-10. It superseded
contributor PR #20354, which Tom reviewed on 2026-09-10 and then closed.

**Status (2026-09-17):** split into two PRs at Tom's request.
- Timeseries PR **#20361**: **merged** as of 2026-09-17. Fixes #20297 and #11704 on
  its own. Its worktree `~/git/astropy-pr-fix-timeseries-primary-key` and local
  branch were removed on 2026-09-17. The handoff files (`notes-20297.md`,
  `pr-20354-review.md`, `pr-20354-reference.patch`, `pr20361-description.md`) were
  moved to `~/git/astropy/pr-descriptions/pr20361-notes/` in the main tree.
- Table PR **#20362** (open): worktree `~/git/astropy-pr-table-primary-key-from-indices`,
  branch `table-primary-key-from-indices`, pushed to origin. `table.py`,
  `test_index.py`, `docs/changes/table/20362.bugfix.rst`, description file
  `pr20362-description.md`. Independent of #20361 (disjoint files, verified by
  ablation both ways); carries the `to_pandas` behavior change.

**Why:** #20354 patched the symptom in four places instead of the root cause.
The real mechanism: `Table.primary_key` is set only by `add_index`, so tables
built from columns that already carry indices (`Table([col])`, column-name
slicing, and `TimeSeries.__init__` re-adding the *same* `time` column object
after `remove_column`) end up with indices but `primary_key is None`.

**How to apply:** the fix as implemented: `Table._init_from_cols` makes the
first carried-in index primary; `Table.__getitem__` keeps the parent's primary
key on a column slice when that index survived; `BaseTimeSeries._add_primary_index`
(shared helper) indexes `time` / `time_bin_start` only if no such index exists
and always sets it as primary key. Do NOT call `remove_indices("time")` in the
constructors (an earlier draft did): with a multi-column index involving `time`,
`ts["time", "a"]` then crashes in `Table.remove_indices` with
`ValueError: list.remove(x): x not in list` because the slice holds two copies of
that index. Reusing the carried-in index is safe; there is a regression test. Behavior change to mention in the PR:
`t[["a","b"]].to_pandas()` now uses `a` as DataFrame index. See
[[worktree-script-imports-main-tree]] for running probe scripts inside the worktree.
