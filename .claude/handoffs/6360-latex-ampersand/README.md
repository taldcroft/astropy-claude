# Handoff: independent fix for astropy issue #6360 (LaTeX reader splits on `&` inside braces)

Written 2026-09-06 by a Claude session in the main tree after reviewing PR #20324.
Read this whole file before writing code. The scripts referenced here live in this
directory.

## Goal

Make the `latex` and `aastex` readers in `astropy/io/ascii/latex.py` treat `&` as a
column separator only when it is outside any `{...}` group and not backslash-escaped.
Issue example:

```latex
\begin{table}
\begin{tabular}{ccc}
First & Second & Ref\\
1 & 2 & \cite{other_ref}\\
11 & 22 & \cite{2013A&A...558A..33A}\\
\end{tabular}
\end{table}
```

Expected: 3 columns, 2 rows, `Ref` column equal to
`[r"\cite{other_ref}", r"\cite{2013A&A...558A..33A}"]`.

## What PR #20324 did, and why not to copy it

PR #20324 (author IMGillusion, branch `fix-6360-latex-cite-ampersand`) replaces braced
`&` with the sentinel `\x1f` in `LatexSplitter.process_line` and restores it in
`LatexSplitter.process_val`. A worktree with that branch is at
`/Users/aldcroft/git/astropy-pr-fix-6360-latex-cite-ampersand` for comparison.

Confirmed problems with that approach (all verified by running code):

1. Escaped braces `\{` and `\}` are counted as group delimiters. A row `x \{ & y\\`
   reads as 2 columns on main and raises `InconsistentTableError` with 1 column on the PR.
   Regression.
2. The unmask lives in `process_val`, which `core.BaseSplitter`'s docstring and
   `docs/io/ascii/read.rst` document as a user-replaceable hook. Setting
   `reader.data.splitter.process_val = None` leaks `\x1f` into table values.
3. `\x1f` is whitespace to `str.strip()`, and `process_val` strips before unmasking, so a
   row ending `{a &\\` silently reads the cell as `{a` with the `&` gone. Main raised.
4. Any literal U+001F in input is rewritten to `&`.
5. `AASTexHeaderSplitter.process_line` does not call the mask, so
   `\colhead{\cite{A&B}}` in a `\tablehead` still splits while the same data cell reads.
6. A per-character Python loop runs on every line. Reading a 100k-row, 3-column numeric
   table: main 0.166 s, PR 0.313 s.

## Recommended design

`LatexSplitter` already overrides `__call__` and only defers to `BaseSplitter.__call__`,
whose body is: `process_line` on each line, `line.split(self.delimiter)`, then
`process_val` on each value. Replace the split step with a brace-aware and
backslash-aware split, called from `LatexSplitter.__call__`. No sentinel, and
`process_line` / `process_val` keep their documented meanings.

`AASTexHeaderSplitter.__call__` currently calls `super(LatexSplitter, self).__call__`
to skip the trailing-`\\` logic. Route it through the same brace-aware split so the
`\tablehead` path is fixed too.

Prototype that passed every edge case below (also in `edge_cases.py`):

```python
def _split_outside_braces(line: str, delimiter: str = "&") -> list[str]:
    """Split on ``delimiter`` only at brace depth 0, skipping backslash-escaped chars."""
    vals, buf, depth, i, n = [], [], 0, 0, len(line)
    while i < n:
        ch = line[i]
        if ch == "\\" and i + 1 < n:
            buf.append(line[i : i + 2])
            i += 2
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth = max(depth - 1, 0)
        elif ch == delimiter and depth == 0:
            vals.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    vals.append("".join(buf))
    return vals
```

Performance: add a fast path so lines with no `{` and no `\` just use `line.split("&")`.
That removes essentially all overhead for ordinary numeric tables. Consider
`re.finditer(r"[{}&\\]")` with slice copying if the general path still matters.

Prototype results:

| input                              | result                                    |
|------------------------------------|-------------------------------------------|
| `11 & 22 & \cite{2013A&A...558A..33A}` | `['11 ', ' 22 ', ' \cite{2013A&A...558A..33A}']` |
| `x \{ & y`                         | `['x \{ ', ' y']`                         |
| `\{ & \}`                          | `['\{ ', ' \}']`                          |
| `a \& b & c`                       | `['a \& b ', ' c']`                       |
| `{a & b} & c`                      | `['{a & b} ', ' c']`                      |
| `\textbf{\cite{A&B}} & c`          | `['\textbf{\cite{A&B}} ', ' c']`          |
| `x\x1fy & z`                       | `['x\x1fy ', ' z']`                       |
| `a { & b`                          | `['a { & b']` (unbalanced bare brace, acceptable) |

Note the `\&` case: this design also fixes the LaTeX-standard escaped ampersand on the
read side for free. Whether the writer (`LatexSplitter.join`) should escape `&` as `\&`
is a separate decision; it is out of scope for #6360 but worth a sentence in the PR.

## Tests to add

In `astropy/io/ascii/tests/test_read.py` next to `test_latex_no_trailing_backslash`:

- The issue example above, format `latex`.
- The same `\cite{...&...}` in a `latex` header cell and in an `aastex` `\colhead{}`.
- Nested braces: `\textbf{\cite{A&B}}`.
- Escaped braces: a row containing `\{` still splits correctly (regression guard for
  problem 1 above).
- Escaped ampersand `\&` outside braces is not a separator.
- A cell containing a literal `\x1f` survives unchanged (guards against any future
  sentinel approach).
- Custom `process_val = None` on a Latex reader still gives raw text with `&` intact.

Adjacent pre-existing bug: `text_aastex_no_trailing_backslash` at roughly line 1730 is
misspelled (`text_` not `test_`) so it never runs, and its expected values are wrong
(three data rows, asserts expect two). Fixing it is optional and separate; if touched,
do it as its own commit.

## Changelog

`docs/changes/io.ascii/<PR>.bugfix.rst`. The PR number is unknown until the PR is
opened; `https://github.com/astropy/astropy-tools/blob/main/next_pr_number.py` predicts
it. Suggested wording:

> The LaTeX and AASTex readers no longer treat an ampersand inside a braced ``{...}``
> group or an escaped ``\&`` as a column separator, so tables with a reference column
> such as ``\cite{2013A&A...558A..33A}`` now read correctly. [#6360]

## Verification commands

Run from inside the worktree. A script run by path from a worktree imports the main
tree unless `PYTHONPATH=$PWD` is set.

```bash
PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python .claude/handoffs/6360-latex-ampersand/edge_cases.py
PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python .claude/handoffs/6360-latex-ampersand/perf.py
conda run -n astropy-dev python -m pytest astropy/io/ascii/tests/test_read.py -k latex
conda run -n astropy-dev python -m pytest astropy/io/ascii astropy/io/ascii/tests/test_write.py -q
```

Expected `edge_cases.py` output on a correct fix: every case reads, including the ones
that fail on main and on PR #20324. Expected `perf.py`: within noise of main (0.17 s).

## Etiquette

PR #20324 is open. Before opening a competing PR, Tom decides whether to comment there
first. Credit the contributor for the test case if it is reused.
