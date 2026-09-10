---
name: issue-triage
description: Triage open GitHub bug issues for an astropy subpackage into a severity/risk document with verified repro scripts. Use when asked to triage issues/bugs for a subpackage label (e.g. "triage the io.ascii bugs").
---

# Triaging astropy subpackage bug issues

Produce two deliverables for a given subpackage label `<label>` (e.g. `table`, `time`,
`io.ascii`):

1. `astropy-<label>-bugs.md` in the repo root — the triage document.
2. `astropy-<label>-bugs-repro/` in the repo root — one runnable `repro_<N>.py` per
   issue that has (or can be given) a reproducible example.

Reference example: `astropy-table-bugs.md` and `astropy-table-bugs-repro/` from the
2026-08 triage of the `table` label (also at
https://gist.github.com/taldcroft/4e435f805889d81282cec93c8e3c562b).

## Workflow

1. **Fetch the issue list** (don't scrape the web view):
   ```bash
   gh issue list -R astropy/astropy --label <label> --label Bug --state open \
     --limit 100 --json number,title,author,createdAt \
     --jq 'sort_by(.createdAt) | reverse | .[] | "\(.number)\t\(.createdAt)\t\(.author.login)\t\(.title)"'
   ```
2. **Do the 5 most recent issues first**, show the user the resulting document, and get
   the format approved before processing the rest.
3. For each issue, fetch the body with `gh issue view <N> --json ...`. Fetch the
   **comments** too when the body alone doesn't settle things — comments often contain
   the real root cause, a workaround, an "actually not our bug" conclusion, or a linked
   fix PR (`gh search prs -R astropy/astropy "<N>"` also helps).
4. **Write and run a repro script per issue** (see below).
5. Assemble the document, then copy the final scripts into
   `astropy-<label>-bugs-repro/`.

## Repro scripts

- Name them `repro_<issue-number>.py`. Draft and run them in the scratchpad directory
  (they drop scratch `.fits`/`.ecsv` files in cwd); copy the final versions to
  `astropy-<label>-bugs-repro/` at the end.
- Run with `conda run -n astropy-dev python repro_<N>.py` from the repo (see CLAUDE.md).
  Record the dev version tested (`astropy.__version__`, numpy version, git commit).
- Each script must end by printing an explicit verdict line: `STILL A BUG` or `FIXED`,
  plus the observed values, so future re-triage is
  `for f in repro_*.py; do python $f | tail -1; done`.
- **Verdict checks lie easily — make them strict, and manually verify every surprising
  verdict.** Real failures from the table triage:
  - Grepped for the word `column` in an error message to detect a column *name*; it
    matched the class name `'Column'` (false FIXED).
  - Checked only the output *dtype* for an int→float bug; the dtype had been fixed but
    the *values* still passed through float64 and were corrupted (false FIXED). Compare
    round-tripped values, not just types.
  - Tested FITS header reordering with a header so small that "moved to the bottom" was
    the same position (false FIXED). Make fixtures big enough that the failure mode can
    actually manifest.
  - A crash may reproduce with a *different* exception than reported — that is still
    "still a bug"; note the changed failure mode.
- Issues without a code example: construct a minimal one from the report (error-message
  complaints, performance complaints — time both sides and report the ratio). For memory
  leaks, use `tracemalloc` around a warmed-up loop and report MB grown.
- For issues that test **fixed** on dev: find what fixed them (`git log -S`, linked
  PRs) and cite it; flag the issue in the document as a candidate for closing.

## Document structure

Header block:

- Title, the GitHub query link, issue count, triage date.
- The exact dev version + commit + numpy version the repros ran against.

Then a **Severity / Risk matrix**: rows = severity, columns = risk, both high→low with
emoji (🔴 high, 🟠 medium, 🟢 low). Cells hold issue-number links pointing at the
**in-document sections**, not GitHub; annotate fixed ones like `[#17418](#issue-17418)
(fixed on dev)`.

Then one section per issue, newest first:

```markdown
<a id="issue-20173"></a>

## [#20173](https://github.com/astropy/astropy/issues/20173) — <issue title>

- **Author:** login (YYYY-MM-DD)
- **Description:** 2–3 sentences max: symptom, then root cause if known.
- **Severity: 🔴 high** — 1–2 sentences on impact.
- **Risk: 🟠 medium** — 1–2 sentences on real-world likelihood.
- **Repro check: still a bug.** What was observed on dev, concretely.
- **Notes:** (optional) root-cause location, linked PRs, related/duplicate issues,
  candidate-for-closing, suggested relabeling.
```

The explicit `<a id="issue-N"></a>` anchors are required — auto-generated heading slugs
break on the backticks/em-dashes in issue titles and differ between GitHub and VSCode.
Heading links point *out* to GitHub; matrix links point *in* to the anchors.

### Severity (impact) rubric

- 🔴 **high** — silent bad results / data corruption, no error or warning.
- 🟠 **medium** — silent data loss with visible traces, crash that blocks a natural
  documented workflow, unbounded resource growth.
- 🟢 **low** — loud crash with workaround, display/cosmetic, error-message quality,
  performance-only.

### Risk (likelihood) rubric

- 🔴 **high** — most users of the subpackage will hit it.
- 🟠 **medium** — a common workflow triggers it deterministically, or it has been hit
  in the wild repeatedly.
- 🟢 **low** — corner case, unusual combination of features, or easy to notice and
  route around.

Judge severity by the *worst silent outcome*, not by how alarming the traceback looks:
silent corruption > silent loss > crash > cosmetic.

## Cross-issue findings

Surface these in the final summary to the user (and in per-issue Notes):

- Issues sharing a root cause (candidates for consolidation).
- Issues that are fixed on dev but still open (candidates for closing, with the fixing
  commit/PR cited).
- Issues whose investigation concluded "not an astropy bug".
- Open PRs that would fix an issue.
- Issues that are really feature requests or doc issues mislabeled as Bug.

## Sharing

If asked to share: `gh gist create astropy-<label>-bugs.md astropy-<label>-bugs-repro/repro_*.py --desc "..."`.
Gists are *secret* (unlisted), not private — say so.
