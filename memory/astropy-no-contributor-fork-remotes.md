---
name: astropy-no-contributor-fork-remotes
description: The astropy clone has only origin and upstream remotes; the ~73 contributor-fork remotes were deliberately pruned on 2026-09-08.
metadata:
  type: project
---

On 2026-09-08 the 73 contributor-fork remotes in `/Users/aldcroft/git/astropy`
(`astrofrog`, `bsipocz`, `eteq`, `mdboom`, `gaoflow`, ...) were removed at the user's
request, along with their ~2600 remote-tracking refs and the stale `branch.*.remote`
config they left behind. Only `origin` (taldcroft fork) and `upstream` (astropy/astropy)
remain.

**Why:** the user no longer works with contributor forks directly and had long been
bothered by the clutter; everything needed is reachable through `upstream` PR refs.

**How to apply:** never assume a contributor remote exists or suggest re-adding one.
Fetch any contributor PR head with `git fetch upstream pull/<N>/head:<branch>` — see
[[worktree-script-fork-pr-fetch]]. Roughly 196 local branches survive the prune,
including many old `pr/<contributor>/<number>` ones that no longer track anything;
they were left in place deliberately, so don't prune them unasked.
