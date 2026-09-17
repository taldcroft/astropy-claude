"""Template for applying one module's annotations in a single reviewable pass.

Copy this to the scratchpad, fill in ``MODULE`` and ``PAIRS``, and run it with the
interpreter directly (``conda run`` drops stdin heredocs, so this is a file on purpose):

    PYTHONPATH=$PWD ~/miniconda3-arm/envs/astropy-dev/bin/python <scratchpad>/annotate.py

Then ``ruff format`` the module and ``ruff check`` it.

Why exact-string pairs with an assertion, rather than a series of Edit calls:

- ``assert s.count(old) == 1`` catches ambiguous matches before anything is written.
  ``table.py`` has four different ``def __repr__(self):``; ``column.py`` has
  ``BaseColumn.__new__`` and ``Column.__new__`` with byte-identical signatures. When a
  bare signature is not unique, extend ``old`` with the following line or two of body
  until it is -- the docstring's first line or the first statement is usually enough.
- The whole module's signatures land in one diff that can be read top to bottom.
- Nothing is written if any pair fails, so a typo cannot leave the module half-done.
"""

import pathlib

MODULE = "astropy/<subpackage>/<module>.py"

# (old, new) pairs. Keep the header edit first so later pairs can rely on the imports.
PAIRS: list[tuple[str, str]] = [
    # --- module header: __future__ import, typing imports, TYPE_CHECKING block ---
    (
        """# Licensed under a 3-clause BSD style license - see LICENSE.rst

import numpy as np
""",
        """# Licensed under a 3-clause BSD style license - see LICENSE.rst
from __future__ import annotations

from typing import TYPE_CHECKING, Any, Self

import numpy as np

if TYPE_CHECKING:
    from collections.abc import Iterator

    from ._typing import ColumnLike
""",
    ),
    # --- defs, in file order ---
    (
        "    def __len__(self):",
        "    def __len__(self) -> int:",
    ),
    # A non-unique signature disambiguated by its first body line:
    (
        "    def __repr__(self):\n        return np.asarray(self).__repr__()",
        "    def __repr__(self) -> str:\n        return np.asarray(self).__repr__()",
    ),
]


def main() -> None:
    p = pathlib.Path(MODULE)
    s = p.read_text()
    for old, new in PAIRS:
        n = s.count(old)
        assert n == 1, f"count={n} for {old[:70]!r}"
        s = s.replace(old, new)
    p.write_text(s)
    print(f"{MODULE}: applied {len(PAIRS)} edits")


if __name__ == "__main__":
    main()
