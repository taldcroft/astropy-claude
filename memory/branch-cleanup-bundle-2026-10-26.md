---
name: branch-cleanup-bundle-2026-10-26
description: 185 old astropy branches deleted 2026-10-26; all 211 pre-cleanup branches are backed up in ~/git/astropy-branches-2026-10-26.bundle
metadata:
  type: reference
---

On 2026-10-26, local branches in ~/git/astropy went from 211 to 26. The deleted branches were 97 whose PR had merged or closed (Tom's own and `pr/<user>/<N>` review copies) and 88 with no PR whose last commit was over a year old, including local copies of release branches v4.0.x–v7.0.x.

Before deleting, every branch was backed up in `~/git/astropy-branches-2026-10-26.bundle` (96 MB, verified). To restore one: `git fetch ~/git/astropy-branches-2026-10-26.bundle <branch>:<branch>`.

Still to do: review the recent no-PR branches by hand (`timeseries-fix-masked-time-downsample`, `coordinates-skycoord-equality`, `io-ascii-fix-docstring-arguments`, `table-group-and-index-using-get-sortable-arrays`, plus probable junk such as `backup/…-pre-rebase`, `…-rebase-bad`, `pr-20506`, `pr-20130-review`), and delete the merged or closed branches on `origin` (101 there). GitHub's "Automatically delete head branches" does not delete branches in a fork, so it is no help here.

**Why:** a branch someone asks about later may be in the bundle only.
**How to apply:** if Tom asks about an old branch that no longer exists, restore it from the bundle.
