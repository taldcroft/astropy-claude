#!/usr/bin/env python
"""Count how many annotated functions in a subpackage resolve under get_type_hints().

Runtime resolution is not a goal of the annotation work, but it is the honest measure of
whether a name in an annotation exists at runtime, which is what runtime tools (pydantic,
beartype, ``inspect.get_annotations(eval_str=True)``) and PEP 649 evaluation need. Use it
to compare import strategies (what stays under ``TYPE_CHECKING``), not as a target.

Run from the worktree root so the worktree's source is imported:

    PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python \\
        .claude/skills/type-annotations/check-type-hints.py astropy.table --skip bst setup_package

Every failure is a ``NameError`` naming something that exists only under
``TYPE_CHECKING``; the residue after moving non-cyclic imports to runtime is the floor
(circular imports and optional dependencies), and it is the same with or without
``from __future__ import annotations``.
"""

import argparse
import collections
import importlib
import inspect
import pkgutil
import typing


def functions(mod):
    for name, obj in vars(mod).items():
        if inspect.isfunction(obj) and obj.__module__ == mod.__name__:
            yield name, obj
        elif inspect.isclass(obj) and obj.__module__ == mod.__name__:
            for an, attr in vars(obj).items():
                f = attr.fget if isinstance(attr, property) else getattr(attr, "__func__", attr)
                if inspect.isfunction(f):
                    yield f"{name}.{an}", f


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("package", help="dotted package name, e.g. astropy.table")
    ap.add_argument("--skip", nargs="*", default=[], help="module basenames to skip")
    args = ap.parse_args()

    pkg = importlib.import_module(args.package)
    ok, bad, examples = 0, collections.Counter(), {}
    for m in pkgutil.iter_modules(pkg.__path__):
        if m.ispkg or m.name == "tests" or m.name in args.skip:
            continue
        mod = importlib.import_module(f"{args.package}.{m.name}")
        for qn, f in functions(mod):
            if not getattr(f, "__annotations__", None):
                continue
            try:
                typing.get_type_hints(f)
                ok += 1
            except Exception as e:
                key = f"{type(e).__name__}: {e}".split("\n")[0][:70]
                bad[key] += 1
                examples.setdefault(key, f"{m.name}.{qn}")
    print(f"get_type_hints OK: {ok}   failed: {sum(bad.values())}")
    for k, v in bad.most_common():
        print(f"  {v:4d}  {k}   e.g. {examples[k]}")


if __name__ == "__main__":
    main()
