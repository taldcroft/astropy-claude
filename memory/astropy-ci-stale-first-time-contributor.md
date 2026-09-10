---
name: astropy-ci-stale-first-time-contributor
description: "When an astropy PR from a first-time contributor shows no GitHub Actions runs and no \"Approve and run\" button, closing and reopening the PR re-triggers CI."
metadata: 
  node_type: memory
  type: project
  originSessionId: 8c189e05-3875-4d38-a848-828e73d640ac
  modified: 2026-09-05T19:20:06.871Z
---

On astropy PRs from first-time contributors (forks), GitHub holds Actions workflows for maintainer approval. If the head commit is weeks old, GitHub drops the pending runs, so the "Approve and run" button is gone and `gh pr checks` shows only CircleCI / RTD / pre-commit / Codecov with zero workflow runs for the head SHA. Confirmed on PR #19909 (September 2026): close and reopen fired a fresh pull_request event and CI started immediately.

**Why:** Tom read this as CI being "stuck"; it had never started. Diagnose with `gh api "repos/astropy/astropy/actions/runs?head_sha=<sha>"` returning total_count 0 and `author_association` FIRST_TIME_CONTRIBUTOR.

**How to apply:** If the approval banner is missing, recommend close and reopen first. It is harmless to branch and review history. Tom has write access, so this is within his power; no need to ask the author to push.
