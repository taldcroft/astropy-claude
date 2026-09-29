---
name: config-set-temp-thread-safe-20471
description: Draft PR #20471 (opened 2026-09-23) makes ConfigItem.set_temp thread-safe via ContextVar; experimental, not yet reviewed by user
metadata:
  type: project
---
Draft PR astropy#20471, worktree astropy-pr-config-set-temp-thread-safe, branch config-set-temp-thread-safe. Title marks it experimental and not reviewed by the author; the AI-disclosure certify box is left unchecked for the user to tick after review.

**Why:** pytest-run-parallel flake in time/test_sidereal traced to set_temp writing global configobj (see HANDOFF.md in the worktree). HANDOFF §3a repro script was buggy (Longitude(1.0, copy=False) fails even single-threaded); use np.array([1.0]).

**How to apply:** Follow-ups not in this PR: units registry (_unit_registries in units/core.py) is the same class of global-state race and causes most of the 108 failures under --parallel-threads=8; coordinates earth.py `180 * u.deg` hardening and caching geodetic were planned as a separate PR.
