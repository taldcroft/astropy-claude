---
name: worktree
description: Create, list, or remove an astropy git worktree — one per open branch/PR — with the built C extensions and CLAUDE.md/.claude/.vscode symlinks in place. Use when asked to make a worktree for a branch or PR, to start a new branch, to remove or tear down a worktree, to start work on a different PR, or when a worktree fails to import a compiled submodule.
---

# astropy worktrees — one per open PR

Every branch under active review gets its own directory, so Claude Code sessions (keyed
by directory) and VS Code windows stay one-to-one with PRs. The main tree
`/Users/aldcroft/git/astropy` stays on **`main`** and is never used for PR work.

Naming, with slashes in the branch name turned into dashes:

| Case | Directory |
| --- | --- |
| A PR someone else opened (you are reviewing it) | `../astropy-pr-<number>-<branch>` |
| Your own branch, PR or not | `../astropy-pr-<branch>` |

The `astropy-pr-` prefix keeps shell tab completion useful — `~/git/` holds many
unrelated `astropy-*` directories, and this narrows to worktrees in one tab.

**Someone else's PR carries the number.** It is known up front, it never changes, and it
is how the review gets referred to — "what did we decide on 20354" beats recalling the
contributor's branch name.

**Your own branch does not.** Its number does not exist yet when the worktree is made,
and renaming the directory later would orphan that directory's Claude session history.

The script adds the number only when the PR is looked up **by number**, since that is
when it knows both the number and the author. So for someone else's PR, pass the number,
not the branch name. It compares the PR author against `gh api user` to decide, and
treats an unknown login as not-yours.

## The Pull Request view in the new window

Creating a worktree by PR number also writes the one git config key that the VS Code
**GitHub Pull Requests** extension uses to tie a branch to a PR:

```
branch.<branch>.github-pr-owner-number = astropy#astropy#<number>
```

That key is the whole association — it is exactly what the extension's **Check Out**
button writes, and it is what makes the Pull Request icon and view (changes, comments,
reviews, checks) appear for the branch. Without it the extension sees an ordinary branch
and offers nothing. For a contributor's fork the extension adds no remote and no
`branch.*.remote` / `.merge`, so neither does the script.

Worktrees share the common git config, so the key is set once in the main tree and is
visible in the worktree. `--replace-all` is used because the extension appends a fresh
duplicate of this key every time it checks a branch out, and the config here already
holds long runs of them.

The key is written only when the PR is given **by number** — another reason to pass the
number rather than the branch name. `git branch -d/-D` deletes the whole
`branch.<name>` config section, so removing a worktree with `--delete-branch` cleans the
association up as a side effect.

## Creating one

Run the script. Do not perform the steps by hand.

```bash
.claude/skills/worktree/new-worktree.sh <branch>          # existing branch
.claude/skills/worktree/new-worktree.sh 20291             # bare number: head branch via gh
.claude/skills/worktree/new-worktree.sh -b <branch>       # brand-new branch
.claude/skills/worktree/new-worktree.sh -b <branch> <start-point>
```

`-b` starts a new branch off a freshly fetched `upstream/main` (override with an explicit
start point) and refuses if the branch already exists — without `-b` an unknown branch is
an error, so a typo can never silently create one.

A bare number is looked up with `gh` to get its head branch and author; anything else is
taken as a branch name. When the branch exists neither locally nor on `origin` — the
normal case for a PR from a contributor's fork — the number form fetches
`refs/pull/<number>/head` into a local branch of the PR's own name. The branch-name form
cannot do that, and errors telling you to pass the number instead. The script runs `git worktree add`, copies the 18 built `*.so` files from
the main tree, symlinks `CLAUDE.md`, `.claude/` and `.vscode/`, then verifies that
`import astropy` inside the new directory resolves to the worktree.
It refuses to clobber an existing directory and refuses a branch that is already checked
out somewhere else, naming the tree that holds it.

If the branch the user wants is currently checked out in the main tree, switch the main
tree to `main` first (`git -C /Users/aldcroft/git/astropy switch main`), then run the
script. Untracked scratch files in the main tree survive that switch untouched.

Afterwards, tell the user to run `code <dir>` — a separate VS Code window with its own
Claude session. Do not open it for them.

## The shared memory store

The Claude memory store is keyed on the working directory, so a worktree gets its own
project directory under `~/.claude-oss/projects/` and would start with an **empty** store
— none of what earlier sessions learned, and anything it learns invisible to the main
tree and lost when the worktree goes.

So the script symlinks each new worktree's `memory` to the shared store at
`~/git/astropy-claude/memory`, which the main tree and every other worktree also use. One
set of memories for all astropy sessions.

It finds that repo by resolving its own path through this tree's `.claude` symlink, so
there is nothing hardcoded to keep in sync. If the repo is missing it says so and carries
on rather than failing. Because the exact directory-name mangling for dots is not
knowable from outside Claude Code, it links both spellings when a path contains a dot; an
unused one is an inert empty directory.

## Why the copied `.so` files are needed

They are not in git, and there is exactly **one** editable install in `astropy-dev`
whose finder is *appended* to `sys.meta_path`. So the checkout you stand in shadows the
install's `MAPPING`, and a worktree without its own `.so` files fails on
`astropy.table._column_mixins`, `_np_utils`, `cparser` or `time._parse_times`.

Two rules, and they are the only ways to get this wrong:

- **Never run `pip install -e .` from a worktree.** It rewrites `MAPPING` to that
  worktree and silently shadows the main tree from then on. If it happened, recover by
  re-running the editable install from `/Users/aldcroft/git/astropy`.
- **Always run tests from inside the worktree directory.** `conda run -n astropy-dev`
  pins the interpreter; the cwd pins the source tree. Both matter.

A `ModuleNotFoundError` on a compiled submodule means missing `.so` files. Fix it with
the rsync line, never with a reinstall:

```bash
rsync -a --include='*/' --include='*.so' --exclude='*' \
    /Users/aldcroft/git/astropy/astropy/ astropy/
```

The copied binaries are a snapshot, fine for the pure-Python `table` / `time` /
`io.ascii` work that most PRs here are. If the branch touches `.pyx` or `.c`, build
inside the worktree with `python setup.py build_ext --inplace` — **not**
`pip install -e .`.

## Listing and removing

```bash
git worktree list
```

To remove one, use the script — not a bare `git worktree remove`:

```bash
.claude/skills/worktree/remove-worktree.sh <dir|branch|PR-number>
.claude/skills/worktree/remove-worktree.sh --delete-branch <target>
```

Targets resolve through the branch rather than the directory name, so both naming forms
are found whichever way you name them.

A plain `git worktree remove` refuses on *any* untracked file, and these trees always
have the three symlinks and 18 copied `*.so` files — so it always needs `--force`, which
then also discards real work. The script separates the two cases: it force-removes the
cruft it knows `new-worktree.sh` created (the symlinks, `*.so`, `__pycache__`,
`.pytest_cache`, `.ruff_cache`, `build/`, `*.pyc`) and **refuses**, listing what it
found, on anything else:

- uncommitted changes to tracked files,
- untracked files that are not build cruft,
- commits on the branch that exist on no remote.

A branch fetched from `refs/pull/<number>/head` lives on the contributor's fork, which is
not a remote here, so all of its commits look unpushed. When the worktree's PR number is
known — given as the target, or read back out of an `astropy-pr-<number>-…` directory
name — the script compares the branch tip against the PR head and stays quiet when they
match. Commits beyond the PR head still count as work and still refuse.

It also refuses a directory that is not a registered worktree, and refuses the main tree.

The branch is kept unless `--delete-branch` is given, which uses `git branch -d` (so an
unmerged branch survives). `--force` overrides the refusals and discards the work — only
use it when the user has said so explicitly, after showing them what would be lost.

Use `git worktree prune` after a manual `rm -rf`.
