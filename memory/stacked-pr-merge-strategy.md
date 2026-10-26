---
name: stacked-pr-merge-strategy
description: "For stacked astropy PRs, merge the bottom PR with a merge commit; after a squash merge, restack with git rebase --onto upstream/main <old bottom commit>"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 0e8c80bf-7fa3-4450-b0d7-5efb324808ec
  modified: 2026-10-19T15:24:09.835Z
---

When a PR is stacked on another (the top PR's branch contains the bottom PR's
commit), Tom's takeaway (2026-10-19, after #20627 was squash-merged under stacked
#20636) is that a normal merge commit for the bottom PR makes life easier: main then
contains the bottom commit itself, so the top PR stays conflict-free. Squash and
"rebase and merge" both create new hashes and make the top PR show conflicts.

**Why:** the squash of #20627 left #20636 CONFLICTING on GitHub until it was rebased.

**How to apply:**
- When a bottom PR of a stack is about to be merged, remind Tom that a merge commit
  avoids restacking (only if its final commit is the one the stack is built on).
- Backports of a merge commit need `git cherry-pick -x -m1 <merge>` (MrMeeseeks's
  default); of a squash commit, plain `git cherry-pick -x <squash>`.
- After a squash merge, restack the top branch with
  `git rebase --onto upstream/main <old bottom-PR commit>`, check the PR's files are
  unchanged, rerun tests, and drop any "stacked on" note from the description.

Related: [[leap-second-discontinued]].
