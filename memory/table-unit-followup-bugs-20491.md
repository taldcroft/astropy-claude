---
name: table-unit-followup-bugs-20491
description: "11 table unit-handling bugs found while writing PR #20491 (column unit warning); list with repros saved in main tree pr-descriptions/pr20491-notes/"
metadata:
  node_type: memory
  type: project
  originSessionId: 2d2b66fa-cb98-45ca-906e-cce7f57df4ba
  modified: 2026-10-12T12:25:59.163Z
---

While writing PR #20491 ("EXPERIMENTAL: Warn when a Column operation ignores its unit",
still OPEN as of 2026-10-10, worktree ~/git/astropy-prs/table-column-unit-warning), Claude
found 11 separate unit-handling bugs in astropy.table, each with a verified repro.

The list lives in `~/git/astropy/pr-descriptions/pr20491-notes/pr20491-followup-bugs.md`
(copied there 2026-10-10 from the worktree, where it was untracked, so it would survive
worktree removal). Whether any have been filed as GitHub issues was not checked.

**Why:** the user lost track of these once and asked to find them again.
**How to apply:** when asked about "those table bugs" or follow-ups to #20491, point here;
copy the file over again if the worktree copy was edited later.

Progress: bug #3 (QTable.join ignores units on Quantity keys) fixed in PR #20586, opened
2026-10-12, merged 2026-10-12; worktree removed 2026-10-26, description in pr-descriptions/pr20586-notes/.
Plain Table (Column-with-unit keys) deliberately left unchanged in that PR.
Bug #2 (MaskedColumn → Quantity drops mask) fixed in PR #20587, opened 2026-10-12
(bugfix fragment), merged 2026-10-12; worktree removed 2026-10-26, HANDOFF.md and
description in pr-descriptions/pr20587-notes/.
Only table side fixed (`MaskedColumn.quantity` returns Masked(Quantity) view); units
routes (`Quantity(mc)`, `mc * u.s`, `<<`, ufuncs) left alone, see #14579.
Bug #4 (Column.searchsorted ignores Quantity): worktree `column-searchsorted-quantity` made
2026-10-12 with HANDOFF.md; Tom's decision: raise on any Quantity argument, to discourage
mixing Column and Quantity (general direction for these unit bugs). Committed c9b83e5bae
2026-10-12 (raises ValueError, not TypeError: numpy _wrapfunc swallows TypeError from the
method so np.searchsorted(col, q) would stay silently wrong). PR #20591 opened 2026-10-12, api
fragment; merged 2026-10-12. Worktree removed 2026-10-26, HANDOFF.md and
pr20591-description.md in pr-descriptions/pr20591-notes/.
Found while testing #4: `QTable(t)` from an indexed `Table` keeps the old index whose key
is still a plain Column, so qt.loc with Quantity keys hits Column.searchsorted (now raises,
was silently wrong). A fresh QTable index is fine. Not in the list of 11; unfiled.
Worktree `qtable-copied-index-quantity` made 2026-10-12 with HANDOFF.md (cause: column.py:594
deepcopy + table.py:4588 reuses index; also qt['a'][0]=0.5*u.m raises UnitConversionError;
related: Table(qt) drops index but keeps primary_key). Tom: both directions in scope,
rebuild index in both; bugfix fragment. Draft PR #20592 opened 2026-10-12 (commit
b30108638e, pr20592-description.md in worktree root). Fix: Table.__init__ calls
_rebuild_indices_on_converted_cols; simplified at Tom's request, so QTable(t, names=...)
is deliberately not handled. Unfixed, pre-existing (no unit conversion needed): Table(t)
multi-column index keeps one key column pointing at t's column; Table(t, names=...) keeps
stale primary_key and duplicates an index.
