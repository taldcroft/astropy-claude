---
name: worktree-script-imports-main-tree
description: "A Python script run by path from a worktree (e.g. a scratchpad script) imports the MAIN astropy tree, not the worktree; use PYTHONPATH=$PWD or python -c/-m"
metadata: 
  node_type: memory
  type: project
  originSessionId: 64b263b3-e667-4b55-9888-31e0edaddfd8
  modified: 2026-09-05T21:24:04.177Z
---

Running `python /path/to/script.py` from an astropy worktree imports astropy from
`/Users/aldcroft/git/astropy/astropy` (the main tree), not from the worktree, because
`sys.path[0]` becomes the script's directory rather than the cwd, so the editable-install
finder mapping wins. `python -c ...` and `python -m pytest` put the cwd first and do pick
up the worktree.

**Why:** In the UT1/TAI leap-second work (Sept 2026) a hypothesis stress script in the
scratchpad kept "failing" with the original bug while `python -c` reproductions passed;
it was silently testing unpatched main-tree code.

**How to apply:** For scratchpad scripts in a worktree, run
`PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python script.py` and print
`astropy.__file__` at the top to confirm. Also note `conda run` does not forward stdin,
so heredoc scripts must be written to a file first.
