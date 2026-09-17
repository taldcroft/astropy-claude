---
name: skills-live-in-astropy-claude-repo
description: "A worktree's .claude/ resolves through two symlinks to the ~/git/astropy-claude git repo; new skills written there are shared across all worktrees but land untracked and need committing in that repo"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5615ed8f-1ef6-401d-b44c-41aed4f3c1fe
  modified: 2026-09-17T15:56:33.991Z
---

In every astropy worktree, `.claude` is a symlink to `/Users/aldcroft/git/astropy/.claude`,
which is itself a symlink to `/Users/aldcroft/git/astropy-claude/.claude`. That last
directory is inside the **`astropy-claude` git repo** (the same repo that holds the
shared memory store the worktree skill links to).

**Why:** Writing a new skill under `.claude/skills/<name>/` from any worktree therefore
puts it in one shared place — visible to the main tree and every worktree at once — but
it shows up as `?? skills/<name>/` in `astropy-claude`, not in the astropy repo. Nothing
in the astropy worktree's `git status` will ever mention it, so it is easy to leave
uncommitted and lose track of.

**How to apply:** After creating or editing a skill, check
`git -C ~/git/astropy-claude status --short skills/` and tell the user it needs
committing *there*. Do not commit it yourself — CLAUDE.md's no-commit-without-review
rule applies, and it is a different repo from the one being worked on. First seen when
the `type-annotations` skill was created on 2026-09-17 from the
`astropy-pr-table-add-type-annotations` worktree. Related: [[worktree-script-imports-main-tree]].
