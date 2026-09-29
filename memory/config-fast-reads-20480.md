---
name: config-fast-reads-20480
description: "Config read cache + fast set_temp branch config-fast-reads (worktree astropy-pr-config-fast-reads), stacked on PR #20471; PR not yet opened as of 2026-09-25, expected number 20480"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7b3afa54-666e-4f88-8ab3-8d4493c71a42
  modified: 2026-09-25T09:56:07.597Z
---

Branch `config-fast-reads` in worktree `/Users/aldcroft/git/astropy-pr-config-fast-reads`, one commit on top of PR #20471's branch `config-set-temp-thread-safe` (see [[config-set-temp-thread-safe-20471]]). Caches the validated value on `ConfigItem` keyed on identity of the stored object and the root ConfigObj; removes the `hasattr` read in `ConfigNamespace.set_temp/reload/reset`; class-based `_TempValue` context manager. Changelog fragment and `pr20480-description.md` use the guessed next number 20480; rename both if the real number differs. Plan copy at `notes-config-fast-reads-plan.md` in the worktree.

**Why:** user (2026-09-25) wanted it thread-safe, so it is stacked on #20471 rather than off main; a separate PR for reviewability. AI-disclosure box left unchecked for the user to tick after reviewing.

**How to apply:** #20471 must merge first; then rebase this branch onto upstream/main. Measured: reads 1.0->0.4 µs, aliased 1.8->0.27 µs, set_temp 5.9 (main)->0.83 µs, Quantity(5, u.m) 2.3->1.6 µs.
