# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Vocabulary

Avoid using words that have an association with war or violence. In particular avoid:
- Blast radius (instead: impact radius)
- Landmine (instead: hidden hazard)

## Where this file lives

`CLAUDE.md` and `.claude/` are **symlinks** into `~/git/astropy-claude`, a separate git
repo, together with the Claude memory store. Editing them here edits that repo; commit
there, not in astropy. See its `README.md` for the wiring and how to restore it.

Astropy's `.git/info/exclude` hides both symlinks from astropy's git.

Every worktree gets its own Claude project directory, and each one's memory store is
symlinked to the same `~/git/astropy-claude/memory`, so all astropy sessions share one
set of memories. `new-worktree.sh` links new worktrees in automatically.

## Scope of this file

This clone is used almost exclusively for work on three subpackages: **`astropy/time`**,
**`astropy/table`**, and **`astropy/io/ascii`**. The architecture notes below cover only
those. For any other subpackage, read the code rather than assuming these patterns apply.

## Environment — read before running anything

**All astropy development happens in the conda environment `astropy-dev`**, which holds
the pip editable install of this source tree.

The interactive shell profile **auto-activates a different environment (`ska3-dev`)**
unless `DEFAULT_CONDA` is set, and the workspace `.vscode/settings.json` sets that to
`astropy-dev` for VS Code integrated terminals only. Claude's Bash tool never reads the
profile: its environment is inherited from the VS Code extension host, so
`CONDA_DEFAULT_ENV` / `CONDA_PREFIX` report whatever env launched VS Code (usually
`ska3-dev`). The front of `PATH` in Claude's shells comes from the workspace
`python.defaultInterpreterPath` (now `astropy-dev`), not from conda. Do not trust the conda
env vars, and do not rely on bare `python` resolving correctly.

**Prefix every command with `conda run -n astropy-dev`:**

```bash
conda run -n astropy-dev python -m pytest astropy/table
```

This is the preferred form — it is explicit, independent of `PATH` order, and does not
depend on whatever the profile activated. Exit codes propagate correctly. Note that a bare
`conda activate` does **not** work across tool calls, since each Bash invocation starts a
fresh shell; `conda run` sidesteps that entirely.

Output is buffered until the command finishes. If live progress matters for a long run,
add `--no-capture-output`.

**Inside a shell script this does not work.** In Claude's Bash tool `conda` is a *shell
function* from the session snapshot; a script started from that shell sees only
`$PATH`, where `conda` is `~/miniconda3-arm/envs/ska3-dev/bin/conda`. That binary treats
`ska3-dev` as its root prefix, so `conda run -n astropy-dev` fails with
`EnvironmentLocationNotFound: .../envs/ska3-dev/envs/astropy-dev`. In scripts, call the
interpreter directly instead:

```bash
~/miniconda3-arm/envs/astropy-dev/bin/python ...
```

To confirm which environment a command actually used:

```bash
conda run -n astropy-dev python -c "import sys, astropy; print(sys.prefix, astropy.__file__)"
# expect: .../envs/astropy-dev  /Users/aldcroft/git/astropy/astropy/__init__.py
```

For brevity the command examples below are written as bare `python`; prefix each with
`conda run -n astropy-dev` in practice.

## Worktrees — one per open PR

Multiple PRs are easier to keep straight with one git worktree per PR instead of
branch-switching in a single directory. Claude Code keys its sessions by **directory**,
so a directory per branch also gives a session history per branch — `claude -c` in each
VS Code window then resumes the right conversation instead of whichever ran last.

### How the editable install behaves here (important)

There is **one** conda env, `astropy-dev`, with **one** editable install, and that stays
true no matter how many worktrees exist. The install is the finder-based flavor:
`site-packages/__editable___astropy_*_finder.py` holds a hardcoded
`MAPPING = {'astropy': '/Users/aldcroft/git/astropy/astropy'}` and registers itself with
`sys.meta_path.append(...)`.

Because it *appends*, it sits after the stdlib `PathFinder`, and `python -m pytest` puts
the cwd at `sys.path[0]`. So the checkout you are standing in shadows the mapping:

```
cwd = a worktree   ->  import astropy  ->  <worktree>/astropy/__init__.py
cwd = anywhere else ->  import astropy  ->  /Users/aldcroft/git/astropy/astropy/__init__.py
```

Two rules follow, and they are the only ways to get this wrong:

- **Never run `pip install -e .` from a worktree.** It rewrites `MAPPING` to point at that
  worktree, and from then on the *main* tree is the one silently shadowed whenever you are
  not standing in it. Recover by re-running the editable install from `~/git/astropy`.
- **Always run tests from inside the worktree directory.** The shadowing is cwd-dependent.
  `conda run -n astropy-dev` pins the interpreter; the cwd pins the source tree. Both matter.

### Setting up a worktree

**Use the `worktree` skill** (`.claude/skills/worktree/SKILL.md`), which wraps
`.claude/skills/worktree/new-worktree.sh`. Do not do the steps by hand:

```bash
.claude/skills/worktree/new-worktree.sh some-branch-name   # existing branch
.claude/skills/worktree/new-worktree.sh 20319              # bare number: branch via gh
.claude/skills/worktree/new-worktree.sh -b new-branch      # new branch off upstream/main
```

The script copies the 18 built `*.so` files, symlinks `CLAUDE.md`, `.claude/` and
`.vscode/`, and verifies the import. A PR **someone else** opened becomes
`../astropy-pr-<number>-<branch>`; your own branch becomes `../astropy-pr-<branch>`. The
number is included only where it is durable: for a review it is known up front and is how
the PR gets referred to, whereas your own branch has no number yet when the worktree is
made, and a later rename would orphan that directory's Claude session history. Pass the
PR number, not the branch name, for someone else's PR — that is when the script can see
both the number and the author. Looking a PR up by number also associates the
branch with it for the VS Code **GitHub Pull Requests** extension, by writing the same
`branch.<branch>.github-pr-owner-number = astropy#astropy#<number>` key that the
extension's Check Out button writes — that key is what makes the Pull Request view
(changes, comments, reviews) work in the new window. The `astropy-pr-` prefix keeps tab completion in `~/git/`
useful, where many unrelated `astropy-*` directories live. Then `code <dir>` for its own
VS Code window and Claude session.

The two things it does that a bare `git worktree add` does not:

1. **Built C extensions are not in git** — without them the first import fails with
   `ModuleNotFoundError: No module named 'astropy.table._column_mixins'`.
2. **`CLAUDE.md`, `.claude/` and `.vscode/` are untracked**, so a fresh worktree has none
   of them. Symlinking keeps edits in sync with the main tree, and `.vscode/` carries the
   `astropy-dev` interpreter for the workspace. Without it Claude starts with no project
   instructions at all.

The copied `.so` files are a snapshot, which is fine for the pure-Python work that most
`table` / `time` / `io.ascii` PRs are. If a branch touches `.pyx` or `.c`, build inside
that worktree with `python setup.py build_ext --inplace` (**not** `pip install -e .`).
That also gives the worktree its own binaries, which removes the cross-contamination
hazard described under "Environment" above — worktrees are safer than the shared tree for
extension work, not riskier.

Tear down with the companion script once the PR merges — a bare `git worktree remove`
always needs `--force` here (the symlinks and `*.so` files are untracked) and would
discard real work along with the cruft:

```bash
.claude/skills/worktree/remove-worktree.sh <dir|branch|PR-number> [--delete-branch]
```

It refuses, and shows you what it found, on uncommitted tracked changes, untracked files
that are not build cruft, or commits that exist on no remote.

### For Claude

- Check `git worktree list` before assuming which directory is which; the main tree is
  always `/Users/aldcroft/git/astropy`, and it **stays on `main`** — PR work happens only
  in worktrees.
- If a test run fails with `ModuleNotFoundError` on a compiled submodule
  (`_column_mixins`, `_np_utils`, `cparser`, `_parse_times`), the worktree is missing its
  `.so` files — rsync them from the main tree rather than reinstalling anything:
  `rsync -a --include='*/' --include='*.so' --exclude='*' ~/git/astropy/astropy/ astropy/`
- Never suggest `pip install -e .` as a fix for an import problem in a worktree.

## Committing changes

Never commit a change without stopping for review first.

## Commands

Astropy is a setuptools + Cython/C project installed in editable mode. The working tree
already has built in-place C extensions (`*.so` next to the `.pyx`/`.c` sources).

Because the in-place `*.so` files live in the source tree rather than in an environment,
they are shared by any environment with an editable install of this tree — so a rebuild
run from the wrong environment silently affects the right one. Another reason to pin the
interpreter.

```bash
# Editable install with all dev dependencies (rarely needed again once set up)
python -m pip install --editable . --group dev_all

# Rebuild C/Cython extensions after touching .pyx or .c sources.
# Required after editing: table/_np_utils.pyx, table/_column_mixins.pyx,
# io/ascii/cparser.pyx + src/tokenizer.c, time/src/parse_times.c
python -m pip install --editable . --no-build-isolation

# Run tests for one subpackage
python -m pytest astropy/time
python -m pytest astropy/table
python -m pytest astropy/io/ascii

# Single file / single test / keyword match
python -m pytest astropy/table/tests/test_index.py
python -m pytest astropy/table/tests/test_index.py::TestIndex::test_loc
python -m pytest astropy/time -k "sidereal and not remote"

# Useful flags: -x (stop on first failure), --pdb, -q --no-header,
# -n auto (xdist), --remote-data (network tests, off by default)

# Style: ruff + a large pre-commit suite (codespell, sphinx-lint, clang-format, ...)
tox -e codestyle                      # everything, all files
pre-commit run --files <paths>        # just what you changed
```

Testing notes that bite:

- `filterwarnings = ["error", ...]` in `pyproject.toml` — **any unexpected warning fails
  the test**. New deprecations need an explicit entry or a `pytest.warns` in the test.
- `xfail_strict = true` — an xfail that starts passing is a failure.
- `--doctest-rst` is in `addopts`, so `docs/*.rst` and docstring examples are executed as
  tests. Changing repr/format output in `table` or `time` breaks doctests far from the
  code you edited; run `python -m pytest docs/table docs/time` after such changes.
- `remote_data_strict = true`; network tests are skipped unless `--remote-data`.
- Tests run against the installed astropy, but editable install means the source tree is
  live for pure-Python changes — no rebuild needed unless C/Cython changed.

## Testing

Do not run the full astropy test suite unless specifically directed. The
full suite (`pytest astropy`) takes several minutes and is most often not
needed.

## Changelog fragment

When making a PR we usually need a changelog fragment with the PR number. The full
changelog (https://docs.astropy.org/en/stable/changelog.html#changelog) gives a
comprehensive set of examples to guide you.

You can also look at changelogs within the particular subpackage to refine the style.

Once you have a changelog ready you should stage the file on git.

### Getting the PR number for the changelog fragment

The changelog fragment file name has the PR number in it.
Unfortunately we don't have that number until we make the PR.

One option is to run the script available at:
https://github.com/astropy/astropy-tools/blob/main/next_pr_number.py

This outputs the next PR if we open the PR without too much delay.

## Writing the PR description

Use the `pr-description` skill (`.claude/skills/pr-description/SKILL.md`) whenever asked
to draft or update a PR description. It always goes into a file named
`pr<PR-NUMBER>-description.md` in the repo root, and PR #20240 is the reference for the
structure (Summary / AI disclosure / collapsed Details).

## Contribution conventions

- PRs go against `main`. Changelog fragments live in `docs/changes/<subpackage>/` named
  `<PR-NUMBER>.<type>.rst` where type is `feature`, `api`, `bugfix`, `perf`, or `other`.
  Subpackage dirs here are `time/`, `table/`, `io.ascii/` (dotted, not nested).
  `other` is **not allowed** inside a subpackage dir — it only goes at `docs/changes/` top level.
  No fragment needed for fixes to bugs never released, or for pure doc/test changes.
- `perf` is reserved for improvements measurable through the public API.
- Preview the rendered changelog with `towncrier --draft --version <ver>`.

## astropy/time

**Core representation.** Every `Time`/`TimeDelta` stores its value as two float64 arrays,
`jd1` (integer part) and `jd2` (fraction in [-0.5, 0.5]), giving sub-nanosecond precision
over astronomical timespans. `astropy/time/utils.py::day_frac` and `two_sum`/`two_product`
implement the exact (error-free-transformation) arithmetic that keeps this invariant. Any
new arithmetic path must go through these rather than naive float ops, or precision
silently degrades — `tests/test_precision.py` is the guard.

**Three-layer object model:**

- `core.py::TimeBase` → `Time` / `TimeDelta`. Holds shape/mask/scale logic and delegates
  value representation to `self._time`, an instance of a `TimeFormat` subclass.
- `formats.py::TimeFormat` subclasses own the conversion between the user-visible value
  (`iso` string, `unix` float, `datetime` object, ...) and `jd1`/`jd2`. Registration is
  automatic via `__init_subclass__` writing into the `TIME_FORMATS` /
  `TIME_DELTA_FORMATS` dicts keyed on the class's `name` attribute — adding a format means
  adding a subclass, nothing else.
- Scale conversion (`utc`↔`tai`↔`tt`↔`tdb`...) is done by ERFA calls. `core.py` defines
  the scale graph: `STANDARD_TIME_SCALES`, `LOCAL_SCALES`, and `MULTI_HOPS` which encodes
  the intermediate scales needed for non-adjacent conversions. `Time.scale` setter walks
  this graph. `TimeDelta` uses `TIME_DELTA_SCALES` (no `utc` — leap seconds make deltas
  in UTC ill-defined).

**String parsing performance.** `TimeString` subclasses (`iso`, `isot`, `yday`, `fits`)
have both a Python parser and a fast C parser in `src/parse_times.c` (exposed as the
`_parse_times` extension). Which one runs is governed by the `use_fast_parser` config item
(`'True'` = try C then fall back, `'False'` = Python only, `'force'` = C or raise). The
subclass declares a fixed-width format spec that the C code consumes; formats that don't
fit that shape have no fast path.

**Masking.** `Time` inherits `MaskableShapedLikeNDArray` and integrates with
`astropy.utils.masked`. Masked support was retrofitted, so when adding methods check both
the masked and unmasked paths. `time_helper/function_helpers.py` holds the
`__array_function__` implementations (`CUSTOM_FUNCTIONS`, `UNSUPPORTED_FUNCTIONS`) that
decide which NumPy functions work on `Time`.

**Leap seconds** come from IERS tables via `update_leap_seconds()`; `_check_leapsec()` is
called lazily before UTC conversions.

## astropy/table

**Table is a container, not an ndarray.** `Table` holds a `TableColumns` (an
`OrderedDict` subclass) mapping name → column object. Columns may be `Column`,
`MaskedColumn`, or any **mixin** (`Quantity`, `Time`, `SkyCoord`, `Masked`, dask arrays).
Subclass hooks are the class attributes `Table.Row`, `.Column`, `.MaskedColumn`,
`.TableColumns` — override these rather than reimplementing methods.

`QTable` differs from `Table` in exactly two overrides: `_is_mixin_for_table` (anything
with a `MixinInfo`) and `_convert_col_for_table` (a `Column` with a `unit` becomes a
`Quantity`). Understanding those two methods explains essentially all Table/QTable
behavioral differences.

**The `info` protocol is the backbone.** Mixin support is not special-cased per type; it
works because every column-like object exposes `.info` (`ColumnInfo` / `MixinInfo` in
`astropy/utils/data_info.py`). `info` supplies `name`, `dtype`, `shape`, `unit`,
`description`, `format`, plus `_represent_as_dict()` / `_construct_from_dict()` used for
serialization and `new_like()` used by `vstack`/`join` to build output columns. To make a
new type usable as a mixin column, give it a working `info` — that's the whole contract.

**Serialization round-trip.** `serialize.py` converts mixin columns into plain columns
plus a `__serialized_columns__` entry in `table.meta`
(`represent_mixins_as_columns`), and reverses it on read
(`_construct_mixins_from_columns`). This is the shared machinery behind ECSV, FITS, HDF5,
and parquet mixin support — a mixin round-trip bug is usually here, not in the format
reader. `serialize_method` controls how masked values are encoded per format (e.g.
ECSV's `data_mask` writing data and mask as separate columns).

**Indices** (`index.py`, with a long developer-oriented module docstring worth reading
before touching it). Indices live on *columns*, not the table: `add_index()` appends a
`SlicedIndex` to `col.indices` for each indexed column, and `Table.indices` collects them
on the fly. `SlicedIndex` wraps an `Index`, which delegates to a pluggable engine —
`SortedArray` (default), `SCEngine` (sortedcontainers), or `BST` (deprecated, not for
production). Slicing a table does not rebuild the index; `SlicedIndex.orig_coords()` /
`sliced_coords()` translate between views. `.loc`/`.iloc`/`.loc_indices` are
`TableLoc`/`TableILoc`/`TableLocIndices` instances created fresh per access, all funneling
through `_get_row_idxs_as_list_or_int()`.

**Operations** (`operations.py`): `join`, `vstack`, `hstack`, `dstack`, `setdiff`,
`unique`. Column-name resolution and output dtype promotion are shared through
`get_col_name_map()` / `get_descrs()` / `result_type()`. `join` has two index-computation
backends selected by `_select_join_engine()` (astropy's own vs. a pandas path); key
sorting goes through `_get_join_sortable_arrays()`, which is where mixin/masked key
columns get converted to something sortable.

**Other entry points:** `pprint.py` (all repr/formatting — the code doctests depend on),
`groups.py` (`group_by`, aggregation), `connect.py` (unified I/O registration),
`_np_utils.pyx` and `_column_mixins.pyx` (Cython hot paths for join and column
`__getitem__`).

## astropy/io/ascii

**Reader pipeline.** A reader is a `BaseReader` composed of five swappable pieces, all in
`core.py`: `Inputter` (bytes/file → lines) → `Splitter` (line → field strings) →
`Header` (column names/types) → `Data` (rows) → `Outputter` (→ `Table`). A new format is
normally a subclass that swaps one or two of these, not a new parser.

**Format registration is metaclass-driven.** `MetaBaseReader` fires on class creation: a
class attribute `_format_name` registers it in `FORMAT_CLASSES` and simultaneously
registers `ascii.<name>` readers/writers/identifiers into the *unified* I/O registry
(`Table.read`/`Table.write`). Related class attributes: `_fast` (adds to `FAST_CLASSES`),
`_io_registry_suffix`, `_io_registry_format_aliases`, `_io_registry_can_write`. So
`ascii.read(fmt=...)` and `Table.read(format='ascii....')` are wired from the same
declaration — see `connect.py` for the thin adapter functions.

**Two parallel implementations.** `basic.py` etc. are pure-Python readers; `fastbasic.py`
provides `FastBasic`/`FastCsv`/`FastTab`/`FastNoHeader`/`FastCommentedHeader`/`FastRdb`
backed by the C tokenizer (`cparser.pyx` + `src/tokenizer.c`). The `fast_reader` kwarg
selects between them and passes tokenizer options. **Behavior must match between the two**
— most io.ascii tests are parametrized over fast/slow, and a fix applied to only one side
is the classic incomplete patch here. Options the C parser cannot express raise
`FastOptionsError`/`ParameterError` so the caller can fall back.

**Guessing** (`ui.py::_guess`) tries an ordered list of (format, delimiter, quotechar)
combinations from `_get_guess_kwargs_list()` and returns the first that yields a
consistent table. It is expensive and a frequent source of surprising behavior; the
`guess_limit_lines` config item (default 10000) caps how much input the trial parses read.
`get_read_trace()` returns the record of what guessing attempted — the first thing to
inspect when a file reads as the "wrong" format.

**ECSV** (`ecsv.py`) is the format that preserves full astropy type fidelity: a YAML header
carrying per-column `datatype`/`unit`/`description`/`meta` plus the
`__serialized_columns__` block from `table/serialize.py`. `ECSV_VERSION`, allowed
`ECSV_DATATYPES`, and permitted `DELIMITERS` (space, comma only) are module constants and
are validated on write. Changes to mixin serialization must be tested through ECSV
round-trip, since that is where the `table` and `io.ascii` layers meet.
