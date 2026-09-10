#!/usr/bin/env bash
#
# Tear down an astropy worktree created by new-worktree.sh.
#
#   remove-worktree.sh <dir|branch|PR-number>
#   remove-worktree.sh --delete-branch <target>   # also delete the local branch
#   remove-worktree.sh --force <target>           # ignore the safety refusals
#
# Targets resolve through the branch, not the directory name, so both naming forms
# (astropy-pr-<number>-<branch> and astropy-pr-<branch>) are found either way.
#
# Safe by default: it removes only the cruft that new-worktree.sh itself created
# (the three symlinks, copied *.so files, caches). Anything else -- modified tracked
# files, real untracked files, unpushed commits -- makes it refuse and show you what it
# found, rather than quietly discarding work.

set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }

delete_branch=0
force=0
while [[ ${1:-} == -* ]]; do
    case $1 in
        --delete-branch) delete_branch=1 ;;
        --force) force=1 ;;
        *) die "unknown option $1" ;;
    esac
    shift
done
[[ $# -ge 1 ]] || die "usage: remove-worktree.sh [--delete-branch] [--force] <dir|branch|PR-number>"
target=$1

common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
main_tree=$(dirname "$common_dir")

# Path of the registered worktree holding a given branch, if any.
worktree_for_branch() {
    git -C "$main_tree" worktree list --porcelain \
        | awk -v b="refs/heads/$1" '/^worktree /{w=$2} /^branch /{if ($2==b) print w}'
}

# ------------------------------------------------------------- resolve the target
pr_number=""
if [[ $target =~ ^[0-9]+$ ]]; then
    pr_number=$target
    branch=$(gh pr view "$pr_number" --repo astropy/astropy --json headRefName -q .headRefName 2>/dev/null) \
        || die "could not resolve PR #$pr_number via gh"
    note "PR #$pr_number -> branch '$branch'"
    wt=$(worktree_for_branch "$branch")
    [[ -n $wt ]] || die "no worktree holds branch '$branch' (PR #$pr_number)
       run 'git worktree list' to see what is checked out where"
elif [[ -d $target || $target == */* ]]; then
    wt=$(cd "$target" 2>/dev/null && pwd) || die "no such directory: $target"
else
    branch=$target
    wt=$(worktree_for_branch "$branch")
    [[ -n $wt ]] || die "no worktree holds branch '$branch'
       run 'git worktree list' to see what is checked out where"
fi

# Match it against the registered worktrees so we never rm an unrelated directory.
line=$(git -C "$main_tree" worktree list --porcelain \
       | awk -v d="$wt" '/^worktree /{w=$2} /^branch /{if (w==d) print $2}')
[[ -n $line ]] || die "$wt is not a registered git worktree
       run 'git worktree list' to see what is"
branch=${line#refs/heads/}
[[ $wt != "$main_tree" ]] || die "refusing to remove the main tree"

# A directory named astropy-pr-<number>-<branch> tells us the PR even when the target
# given was a path or a branch name.
if [[ -z $pr_number && $(basename "$wt") =~ ^astropy-pr-([0-9]+)- ]]; then
    pr_number=${BASH_REMATCH[1]}
fi

echo "==> $wt  (branch $branch${pr_number:+, PR #$pr_number})"

# ------------------------------------------------------------------ safety checks
problems=0

# Modified / staged / deleted tracked files.
tracked=$(git -C "$wt" status --porcelain --untracked-files=no)
if [[ -n $tracked ]]; then
    echo "  uncommitted changes to tracked files:"
    printf '%s\n' "$tracked" | sed 's/^/    /'
    problems=1
fi

# Untracked files, minus what new-worktree.sh and the test suite generate.
untracked=$(git -C "$wt" ls-files --others --exclude-standard \
            | grep -vE '^(CLAUDE\.md|\.claude|\.vscode)$' \
            | grep -vE '(^|/)(__pycache__|\.pytest_cache|\.ruff_cache|build)/' \
            | grep -vE '\.(so|pyc|pyo)$' || true)
if [[ -n $untracked ]]; then
    echo "  untracked files that are not build cruft:"
    printf '%s\n' "$untracked" | sed 's/^/    /'
    problems=1
fi

# Commits on this branch that exist on no remote. A branch fetched from refs/pull/N/head
# lives on the contributor's fork, which is not a remote here, so every commit looks
# unpushed -- check the PR head instead before believing it.
unpushed=$(git -C "$main_tree" log --oneline "$branch" --not --remotes 2>/dev/null || true)
if [[ -n $unpushed && -n $pr_number ]]; then
    head_oid=$(gh pr view "$pr_number" --repo astropy/astropy --json headRefOid -q .headRefOid 2>/dev/null || true)
    tip=$(git -C "$main_tree" rev-parse "$branch")
    if [[ -n $head_oid && $head_oid == "$tip" ]]; then
        note "branch tip is the head of PR #$pr_number -- nothing local to lose"
        unpushed=""
    fi
fi
if [[ -n $unpushed ]]; then
    echo "  commits not present on any remote:"
    printf '%s\n' "$unpushed" | sed 's/^/    /'
    problems=1
fi

if [[ $problems == 1 ]]; then
    [[ $force == 1 ]] || die "refusing to remove $wt -- see above
       push or commit the work, or re-run with --force to discard it"
    note "--force given: proceeding despite the above"
fi

# ------------------------------------------------------------------- do the removal
git -C "$main_tree" worktree remove --force "$wt"
git -C "$main_tree" worktree prune
echo "==> removed $wt"

if [[ $delete_branch == 1 ]]; then
    if [[ $force == 1 ]]; then
        git -C "$main_tree" branch -D "$branch"
    else
        git -C "$main_tree" branch -d "$branch" \
            || die "branch '$branch' not fully merged -- kept it; use --force to delete anyway"
    fi
    echo "==> deleted branch $branch"
else
    note "branch '$branch' kept -- pass --delete-branch to remove it too"
fi
