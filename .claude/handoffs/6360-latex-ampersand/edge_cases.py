import astropy
print("astropy from", astropy.__file__)
from astropy.io import ascii
from astropy.io.ascii.core import InconsistentTableError

def tryread(label, lines, fmt="latex"):
    try:
        t = ascii.read(lines, format=fmt)
        print(f"{label}: OK cols={t.colnames} rows={[list(r) for r in t]}")
    except Exception as e:
        print(f"{label}: {type(e).__name__}: {str(e).splitlines()[0]}")

tryread("issue example", r"""
\begin{tabular}{ccc}
First & Second & Ref\\
1 & 2 & \cite{other_ref}\\
11 & 22 & \cite{2013A&A...558A..33A}\\
\end{tabular}
""")

tryread("escaped open brace in cell", r"""
\begin{tabular}{cc}
a & b\\
x \{ & y\\
\end{tabular}
""")

tryread("escaped close brace in cell", r"""
\begin{tabular}{cc}
a & b\\
x \} & y\\
\end{tabular}
""")

tryread("escaped ampersand", r"""
\begin{tabular}{cc}
a & b\\
x \& y & z\\
\end{tabular}
""")

tryread("multicolumn with braced &", r"""
\begin{tabular}{ccc}
a & b & c\\
\multicolumn{2}{c}{x & y} & z\\
\end{tabular}
""")

tryread("header braced &", r"""
\begin{tabular}{cc}
{A & B} & C\\
1 & 2\\
\end{tabular}
""")

tryread("aastex header colhead with &", r"""
\begin{deluxetable}{cc}
\tablehead{\colhead{A&B} & \colhead{C}}
\startdata
1 & 2\\
\enddata
\end{deluxetable}
""", fmt="aastex")

tryread("aastex data cite with &", r"""
\begin{deluxetable}{cc}
\tablehead{\colhead{A} & \colhead{C}}
\startdata
1 & \cite{2013A&A...558A..33A}\\
\enddata
\end{deluxetable}
""", fmt="aastex")

tryread("literal \\x1f in data", "\\begin{tabular}{cc}\na & b\\\\\n1 & x\x1fy\\\\\n\\end{tabular}\n")

# Round trip write/read
from astropy.table import Table
t = Table({"Ref": [r"\cite{2013A&A...558A..33A}"], "n": [1]})
import io
s = io.StringIO()
t.write(s, format="ascii.latex")
print("written:", s.getvalue())
tryread("roundtrip", s.getvalue())


# ---------------------------------------------------------------------------
# Prototype brace- and backslash-aware split (no sentinel). See README.md.
def _split_outside_braces(line, delimiter="&"):
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


print("\n--- prototype split ---")
for c in [
    r"11 & 22 & \cite{2013A&A...558A..33A}",
    r"x \{ & y",
    r"\{ & \}",
    r"a \& b & c",
    r"{a & b} & c",
    r"\textbf{\cite{A&B}} & c",
    "x\x1fy & z",
    r"a { & b",
]:
    print(repr(c), "->", _split_outside_braces(c))
