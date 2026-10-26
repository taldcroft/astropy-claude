---
name: leap-second-discontinued
description: Retiring the leap-second auto-update machinery after CGPM 2026 Resolution 5 made UTC continuous from 2027-05-20; #20627 bugfix + backports + #20651 merged, #20636 deprecations open; plan in pr-descriptions/pr20627-notes/
metadata:
  node_type: memory
  type: project
  originSessionId: 6ac7184f-8d4e-42b1-9ca4-c3176d908968
  modified: 2026-10-16T11:39:32.794Z
---

CGPM 2026 Resolution 5 makes UTC continuous from 2027-05-20. Bulletin C 72 already
rules out a leap second through 2027-06-28, so the table ending at 2017-01-01 (TAI-UTC
37 s) is final and ERFA's built-in table already contains it.

The plan is `~/git/astropy/pr-descriptions/pr20627-notes/leap-second-discontinued-plan.md`
(moved there 2026-10-26 when the merged #20627 worktree was removed, together with
`pr20627-description.md`): remove `_check_leapsec` and the
lock in `astropy/time/core.py`, deprecate `update_leap_seconds`,
`LeapSeconds.auto_open` and the three `iers.conf` leap-second items, trim the tests and
docs. Split on 2026-10-17 into two draft PRs:
- #20627 (branch `leap-second-discontinued`, worktree removed 2026-10-26, commit 57bc5843f3): bugfix,
  milestone v7.2.4, labels backport-v7.2.x + backport-v8.0.x (set by Tom 2026-10-17).
  Only removes the `_check_leapsec` call and lock; public API unchanged. Both backports
  hit the same trivial conflict in test_update_leap_seconds.py (release branches lack
  `import sys` + emscripten skipif); take the PR's version of the file. Verified on a
  v7.2.x trial cherry-pick: time + iers tests pass.
- #20627 squash-merged 2026-10-18 as a64a40bae7 (cherry-pick it WITHOUT -m1). Manual
  backport to v8.0.x: PR #20644 (worktree auto-backport-of-pr-20627-on-v8.0.x, opened
  2026-10-19); v7.2.x: PR #20645 (worktree auto-backport-of-pr-20627-on-v7.2.x), same
  resolution (git rerere replayed it). Both merged 2026-10-19.
- Issue #20648 (pllim): the subprocess test fails in the pyinstaller bundle
  (sys.executable is the frozen runner). Fix PR #20651 adds it to SKIP_TESTS in
  .pyinstaller/run_astropy_tests.py (worktree pyinstaller-skip-leap-second-subprocess-test,
  Extra CI label, backport labels). Pyinstaller cron was failing on main, v8.0.x, v7.2.x. #20651 merged 2026-10-19.
  The backport, #20651 and #20627 worktrees were all removed 2026-10-26.
- #20636 (branch/worktree `leap-second-discontinued-deprecations`, milestone v8.1.0):
  rebased onto main 2026-10-19 after #20627 merged (no longer stacked): 6ea4192fe6 deprecates update_leap_seconds,
  auto_open, open() without file, three conf items. Second commit (c20f7b97a1)
  narrows scope per Tom: LeapSeconds.from_erfa() (now with day/mjd columns) is the only
  supported source; open() defaults to "erfa"; deprecated from_iers_leap_seconds,
  from_leap_seconds_list, update_erfa_leap_seconds, open(other), and the
  IERS_LEAP_SECOND_FILE/URL + IETF_LEAP_SECOND_URL constants (module __getattr__ in
  iers.py and iers/__init__.py). `expires` kept because pyerfa reads table.expires.
  Long-term plan: remove all leap-second files/URLs/functionality in 9.0 or 10.0.

Removal of the deprecated API is a later follow-up PR.

Expiry decision (Tom, 2026-10-17): keep `erfa.leap_seconds` consistent with
liberfa/pyerfa#359 (built-in table never expires; expires = now + 180 d). Tom's choice:
`LeapSeconds.from_erfa()` sets private `erfa.leap_seconds._expires` to midnight today
+ 180 d when pyerfa reports expired (Tom considers it equivalent to what the old
auto-update did via `update()`; remove once #359 is required). NOT done at import, so
on old pyerfa `expired` is True until from_erfa() runs. Tests verified under pyerfa
2.0.1.5 and #359 emulated by a pytest plugin patching `erfa.leap_seconds.expires`.


**Why:** the plan file is untracked scratch, so this note is the only pointer to it
from other sessions.

**How to apply:** when Tom asks about leap seconds, the leap-second worktree, or
`update_leap_seconds`, start from that plan file. Related: liberfa/erfa#114 (dubious
year warnings from 2029) is a separate problem the plan explicitly leaves out.
