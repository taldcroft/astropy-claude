# astropy-claude

Claude Code configuration for my astropy work: the project instructions, the skills, and
the accumulated memory store. It lives in its own repo because none of it can be
committed to `astropy/astropy`, and because a clone of astropy is a disposable thing
while this is not.

## Layout

| Path | What it is |
| --- | --- |
| `CLAUDE.md` | Project instructions: environment, worktrees, testing, per-subpackage architecture notes |
| `.claude/skills/` | `worktree`, `pr-description`, `issue-triage` |
| `.claude/settings.local.json` | Permission allowlist and the hook that blocks commit/push/PR without review |
| `.claude/handoffs/` | Scratch left over from individual PRs, safe to prune |
| `memory/` | The memory store: one fact per file, indexed by `MEMORY.md` |

## How it is wired up

Nothing here is copied into place. Everything is symlinked, so edits from either side are
the same file:

```
~/git/astropy/CLAUDE.md                    -> ~/git/astropy-claude/CLAUDE.md
~/git/astropy/.claude                      -> ~/git/astropy-claude/.claude
~/.claude-oss/projects/<project>/memory    -> ~/git/astropy-claude/memory
```

`<project>` is the working directory with its separators flattened to dashes, so
`/Users/aldcroft/git/astropy` becomes `-Users-aldcroft-git-astropy`. Every astropy
worktree gets its own project directory and would otherwise start with an empty memory
store, so each one is linked to this same `memory/`. `new-worktree.sh` does that for new
worktrees automatically; it finds this repo by resolving its own path through the
`.claude` symlink, so there is no hardcoded location to keep in sync.

The two symlinks inside the astropy clone are hidden from its git by
`.git/info/exclude`, which lists `CLAUDE.md` and `.claude`.

## Restoring on a new machine, or after re-cloning astropy

```bash
git clone <this repo> ~/git/astropy-claude
cd ~/git/astropy
ln -s ~/git/astropy-claude/CLAUDE.md CLAUDE.md
ln -s ~/git/astropy-claude/.claude   .claude
printf 'CLAUDE.md\n.claude\n' >> .git/info/exclude
mkdir -p ~/.claude-oss/projects/-Users-aldcroft-git-astropy
ln -s ~/git/astropy-claude/memory ~/.claude-oss/projects/-Users-aldcroft-git-astropy/memory
```

Adjust the paths if the checkout or home directory differs; the project directory name is
derived from the astropy path, so it changes with it.

## Notes

`.claude/settings.local.json` is normally a gitignored, machine-local file. It is kept
here on purpose: the permission allowlist and the review hook are part of the workflow,
and losing them means re-approving everything. It holds no secrets.

`CLAUDE.md` mixes two kinds of content. The architecture notes on `time`, `table` and
`io.ascii`, and the testing gotchas, describe astropy itself and could be contributed
upstream. The environment, worktree layout and absolute paths are personal and could not.
