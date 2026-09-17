#!/usr/bin/env python
"""Report type-annotation coverage for every module in an astropy subpackage.

A def counts as done when it has a return annotation and every parameter is annotated,
except that a bare ``**kwargs`` is exempt (``.ruff.toml`` ignores ANN003). Nested
functions and ``@overload`` stubs count as defs, because ``ast.walk`` finds them and
because they show up in editor hover just like top-level ones.

Usage, always from inside the worktree::

    python .claude/skills/type-annotations/count-annotations.py astropy/table
    python .claude/skills/type-annotations/count-annotations.py astropy/table --ref bed180c642
    python .claude/skills/type-annotations/count-annotations.py astropy/table --gaps
    python .claude/skills/type-annotations/count-annotations.py astropy/table --skip bst.py

``--ref`` reads the files from a git ref instead of the working tree, for a before/after
comparison. Measure "before" against the branch's actual rebase base (``git merge-base
upstream/main HEAD``), not against a live ``upstream/main`` -- that moves, and a module
gaining a def upstream looks like a def you deleted.

Run it with the interpreter directly rather than ``conda run`` so ``--gaps`` output is
not buffered, and remember this script imports nothing from astropy so ``PYTHONPATH``
does not matter here.
"""

from __future__ import annotations

import argparse
import ast
import pathlib
import subprocess
import sys


def params(fn: ast.FunctionDef | ast.AsyncFunctionDef) -> list[ast.arg]:
    a = fn.args
    p = [*a.posonlyargs, *a.args, *a.kwonlyargs]
    if p and p[0].arg in ("self", "cls"):
        p = p[1:]
    for extra in (a.vararg, a.kwarg):
        if extra is not None:
            p.append(extra)
    return p


def classify(fn: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    """'done', 'kwargs' (only a bare **kwargs is missing) or 'todo'."""
    missing = [x.arg for x in params(fn) if x.annotation is None]
    if fn.returns is None:
        return "todo"
    if not missing:
        return "done"
    kw = fn.args.kwarg.arg if fn.args.kwarg else None
    return "kwargs" if all(m == kw for m in missing) else "todo"


def read_source(path: pathlib.Path, ref: str | None) -> str | None:
    if ref is None:
        return path.read_text()
    out = subprocess.run(
        ["git", "show", f"{ref}:{path.as_posix()}"], capture_output=True, text=True
    )
    return out.stdout if out.returncode == 0 else None


def list_modules(pkg: pathlib.Path, ref: str | None) -> list[pathlib.Path]:
    if ref is None:
        return sorted(pkg.glob("*.py"))
    out = subprocess.run(
        ["git", "ls-tree", "--name-only", f"{ref}:{pkg.as_posix()}"],
        capture_output=True,
        text=True,
        check=True,
    )
    return sorted(pkg / n for n in out.stdout.split() if n.endswith(".py"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("package", help="subpackage directory, e.g. astropy/table")
    ap.add_argument("--ref", help="git ref to read from instead of the working tree")
    ap.add_argument("--gaps", action="store_true", help="list each unfinished def")
    ap.add_argument(
        "--skip", action="append", default=[], metavar="FILE", help="module to exclude"
    )
    args = ap.parse_args()

    pkg = pathlib.Path(args.package)
    tot = done = 0
    print(f"{'module':26s} {'done':>9s}   gaps")
    for f in list_modules(pkg, args.ref):
        if f.name in args.skip:
            print(f"{f.name:26s} {'--':>9s}   skipped")
            continue
        src = read_source(f, args.ref)
        if src is None:
            continue
        defs = [
            n
            for n in ast.walk(ast.parse(src))
            if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
        ]
        if not defs:
            continue
        kinds = {n: classify(n) for n in defs}
        n_done = sum(k != "todo" for k in kinds.values())
        n_kw = sum(k == "kwargs" for k in kinds.values())
        todo = [n for n, k in kinds.items() if k == "todo"]
        tot += len(defs)
        done += n_done
        note = f"**kwargs-only: {n_kw}" if n_kw else ""
        print(f"{f.name:26s} {n_done:4d}/{len(defs):4d}   {note}")
        if args.gaps and todo:
            print("    " + ", ".join(f"{n.name}:{n.lineno}" for n in todo))
    print(f"\n{'TOTAL':26s} {done:4d}/{tot:4d}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
