#!/usr/bin/env bash
#
# Create a ready-to-use astropy git worktree for one branch / PR.
#
#   new-worktree.sh <branch>              # existing branch, local or on origin
#   new-worktree.sh <PR-number>           # head branch looked up via gh
#   new-worktree.sh -b <branch> [start]   # brand-new branch, default start upstream/main
#
# Result: a sibling directory of the main tree with the built C extensions copied in and
# CLAUDE.md, .claude/ and .vscode/ symlinked back to the main tree. Named:
#
#   astropy-pr-<number>-<branch>   a PR someone else opened (reviewing their work)
#   astropy-pr-<branch>            your own branch, PR or not
#
# Someone else's PR carries the number because it is known up front, never changes, and
# is how the review is referred to. Your own branch does not: its number does not exist
# until the PR is opened, and renaming the directory later would orphan that directory's
# Claude session history. The number is only added when the PR is looked up BY number --
# pass the number, not the branch name, when you want it.
#
# A worktree made for a PR by number is also associated with that PR the way the VS Code
# GitHub Pull Requests extension's "Check Out" button does it, so the Pull Request view
# (changes, comments, reviews) works in the new window.
#
# NEVER run `pip install -e .` from a worktree -- see CLAUDE.md "Worktrees".

set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }

REPO=${ASTROPY_REPO:-astropy/astropy}

# Where CLAUDE.md, .claude/ and the shared memory store actually live. This script is
# reached through the tree's .claude symlink, so resolving its own path finds the config
# repo without hardcoding it -- and finds nothing if the repo is ever unlinked.
skill_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
config_repo=${skill_dir%/.claude/skills/worktree}
memory_store="$config_repo/memory"

# Point a new worktree's Claude project directory at the shared memory store, so a
# session there starts with what was learned everywhere else instead of an empty store.
# Claude Code keys a project directory on the working directory with the separators
# flattened to dashes; whether dots are also flattened is not something this script can
# know, so it links both spellings when they differ. An unused one is an inert empty dir.
link_memory() {
    local wt_path=$1 root slug proj linked=0
    if [[ ! -d $memory_store ]]; then
        note "no shared memory store at $memory_store -- worktree starts with none"
        return 0
    fi
    for root in "$HOME/.claude-oss/projects" "$HOME/.claude/projects"; do
        [[ -d $root ]] || continue
        for slug in "${wt_path//\//-}" "${wt_path//[\/.]/-}"; do
            proj="$root/$slug"
            [[ -e "$proj/memory" ]] && continue
            mkdir -p "$proj"
            ln -s "$memory_store" "$proj/memory"
            linked=1
        done
    done
    [[ $linked == 1 ]] && note "shared memory store linked into the new project dir"
    return 0
}

create_new=0
if [[ ${1:-} == -b ]]; then
    create_new=1
    shift
fi
[[ $# -ge 1 ]] || die "usage: new-worktree.sh [-b] <branch|PR-number> [start-point]"
arg=$1
start_point=${2:-}

# The main tree is the parent of the common git dir, regardless of where we run.
common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
main_tree=$(dirname "$common_dir")
parent=$(dirname "$main_tree")

# The remote that holds astropy/astropy: upstream if there is one, else origin.
pick_remote() {
    local r
    for r in upstream origin; do
        if git -C "$main_tree" remote get-url "$r" >/dev/null 2>&1; then
            printf '%s' "$r"
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------- resolve args
# A bare number is taken as a PR to look up; anything else is a branch name.
pr_number=""
pr_author=""
if [[ $create_new == 1 ]]; then
    branch=$arg
elif [[ $arg =~ ^[0-9]+$ ]]; then
    pr_number=$arg
    pr_info=$(gh pr view "$pr_number" --repo "$REPO" \
                  --json headRefName,author -q '[.headRefName, .author.login] | @tsv' 2>/dev/null) \
        || die "could not resolve PR #$pr_number via gh"
    IFS=$'\t' read -r branch pr_author <<<"$pr_info"
    [[ -n $branch ]] || die "PR #$pr_number has no head branch"
    note "PR #$pr_number -> branch '$branch' (opened by ${pr_author:-unknown})"
else
    branch=$arg
fi

# ------------------------------------------------------------ name the directory
# Someone else's PR gets the number; your own branches stay bare.
slug=${branch//\//-}
if [[ -n $pr_number ]]; then
    viewer=$(gh api user -q .login 2>/dev/null || true)
    if [[ -z $viewer ]]; then
        note "could not determine your GitHub login -- treating PR #$pr_number as not yours"
        slug="$pr_number-$slug"
    elif [[ $pr_author != "$viewer" ]]; then
        note "PR #$pr_number is not yours -- including the number in the directory name"
        slug="$pr_number-$slug"
    else
        note "PR #$pr_number is yours -- directory named for the branch only"
    fi
fi
dir="$parent/astropy-pr-$slug"

[[ -e $dir ]] && die "$dir already exists"

# ------------------------------------------------------------- resolve the ref
if [[ $create_new == 1 ]]; then
    # New branch: refuse to silently reuse an existing one (usually means a typo).
    git -C "$main_tree" show-ref --verify --quiet "refs/heads/$branch" \
        && die "branch '$branch' already exists -- drop -b to make a worktree for it"

    if [[ -z $start_point ]]; then
        # Branch off a freshly fetched upstream main so the PR starts current.
        if remote=$(pick_remote); then
            echo "==> git fetch $remote main"
            git -C "$main_tree" fetch --quiet "$remote" main
            start_point="$remote/main"
        else
            start_point=main
        fi
    fi
    git -C "$main_tree" rev-parse --verify --quiet "$start_point^{commit}" >/dev/null \
        || die "start point '$start_point' does not resolve to a commit"
    note "new branch '$branch' off $start_point ($(git -C "$main_tree" rev-parse --short "$start_point"))"
    add_args=(-b "$branch" "$dir" "$start_point")
elif git -C "$main_tree" show-ref --verify --quiet "refs/heads/$branch"; then
    # Refuse if some other worktree (usually the main tree) holds this branch.
    holder=$(git -C "$main_tree" worktree list --porcelain \
             | awk -v b="refs/heads/$branch" '/^worktree /{w=$2} /^branch /{if ($2==b) print w}')
    [[ -n $holder ]] && die "branch '$branch' is already checked out in $holder
       switch that tree to another branch first (the main tree should sit on 'main')"
    [[ -n $pr_number ]] && note "using the existing local branch '$branch' (not re-fetched)"
    add_args=("$dir" "$branch")
elif git -C "$main_tree" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    note "creating local branch '$branch' tracking origin/$branch"
    add_args=(-b "$branch" "$dir" "origin/$branch")
elif [[ -n $pr_number ]]; then
    # A PR from a fork has no branch on origin -- fetch the PR head ref itself.
    remote=$(pick_remote) || die "no upstream or origin remote to fetch PR #$pr_number from"
    echo "==> git fetch $remote pull/$pr_number/head:$branch"
    git -C "$main_tree" fetch --quiet "$remote" "pull/$pr_number/head:$branch" \
        || die "could not fetch refs/pull/$pr_number/head from $remote"
    add_args=("$dir" "$branch")
else
    die "no local branch '$branch' and no origin/$branch
       to start a new branch here, pass -b:  new-worktree.sh -b $branch
       for someone else's PR, pass the PR number instead of the branch name"
fi

# ------------------------------------------------------------------- do the work
echo "==> git worktree add $dir  ($branch)"
git -C "$main_tree" worktree add "${add_args[@]}"

# ------------------------------------------------ associate the branch with the PR
# This one config key is what the VS Code GitHub Pull Requests extension writes when you
# click "Check Out", and what makes the Pull Request view (changes, comments, reviews)
# appear for the branch. Without it the extension sees an ordinary branch. Worktrees
# share the common config, so setting it once covers this tree. --replace-all because
# the extension itself appends a duplicate every time it checks a branch out.
if [[ -n $pr_number ]]; then
    echo "==> associating branch with ${REPO/\//#}#$pr_number (VS Code GitHub PR extension)"
    git -C "$main_tree" config --replace-all \
        "branch.$branch.github-pr-owner-number" "${REPO/\//#}#$pr_number"
fi

echo "==> copying built C extensions from $main_tree"
rsync -a --include='*/' --include='*.so' --exclude='*' "$main_tree/astropy/" "$dir/astropy/"
note "$(find "$dir/astropy" -name '*.so' | wc -l | tr -d ' ') .so files"

echo "==> symlinking CLAUDE.md, .claude, .vscode"
for f in CLAUDE.md .claude .vscode; do
    if [[ -e "$main_tree/$f" ]]; then
        ln -s "$main_tree/$f" "$dir/$f"
    else
        note "skipped $f (not present in main tree)"
    fi
done

echo "==> sharing the Claude memory store with this worktree"
link_memory "$dir"

echo "==> verifying the import resolves to this worktree"
# NB: inside a script `conda` is NOT the interactive shell function -- it resolves to
# ska3-dev/bin/conda, which then looks for ska3-dev/envs/astropy-dev and fails. Call the
# astropy-dev interpreter directly instead of going through `conda run`.
PY_DEV=${ASTROPY_DEV_PYTHON:-$HOME/miniconda3-arm/envs/astropy-dev/bin/python}
[[ -x $PY_DEV ]] || die "astropy-dev interpreter not found at $PY_DEV
       set ASTROPY_DEV_PYTHON to override"
(cd "$dir" && "$PY_DEV" -c "
import astropy, sys
print('   ', sys.prefix)
print('   ', astropy.__file__)
") || die "import check failed in $dir

       The .so files copied from the main tree are built against current main. A branch
       far behind main can expect extension modules that no longer exist (e.g. old
       astropy wanting astropy.utils._compiler). Rebase the branch, or build in place
       with 'python setup.py build_ext --inplace' -- NEVER 'pip install -e .'.
       See CLAUDE.md 'Worktrees'."

cat <<EOF

Ready:  $dir
Open:   code $dir${pr_number:+   (Pull Request view wired to #$pr_number)}
Test:   cd $dir && conda run -n astropy-dev python -m pytest astropy/<subpkg>
Remove: .claude/skills/worktree/remove-worktree.sh ${pr_number:-$branch}
EOF
