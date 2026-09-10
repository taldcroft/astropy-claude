---
name: bash-profile-hard-link
description: ~/.bash_profile is a hard link into the ~/shell_inits git repo; edit in place to keep the link
metadata: 
  node_type: memory
  type: user
  originSessionId: 867bff58-3474-444c-b7db-af208e42ae07
  modified: 2026-09-05T11:08:17.934Z
---

`~/.bash_profile` is a hard link to `~/shell_inits/.bash_profile`, and `~/shell_inits` is a
git repo. The user thinks of the profile as unversioned and makes a `.bash_profile.bak`
copy before edits, but changes do show up as modified in that repo.

**Why:** Tools that write a temp file and rename (BSD `sed -i`, `perl -pi`, some editor
saves) break the hard link, silently detaching the profile from the repo.

**How to apply:** Edit with an inode-preserving method (write new content to a scratch file,
then `cat scratch > ~/.bash_profile`), then confirm with `stat -f %i` that the inode is
unchanged. Do not commit in `~/shell_inits` unless asked. Zsh reads this file via
`~/.zshrc`, which sources it; the conda env is chosen there by
`conda activate "${DEFAULT_CONDA:-ska3-dev}"`.
