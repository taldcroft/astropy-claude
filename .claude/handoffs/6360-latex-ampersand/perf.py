import time, astropy
from astropy.io import ascii
n = 100000
lines = ["\\begin{tabular}{ccc}", "a & b & c\\\\"] + [f"{i} & {i*1.5} & {i*2}\\\\" for i in range(n)] + ["\\end{tabular}"]
text = "\n".join(lines)
ascii.read(text, format="latex")
ts = []
for _ in range(3):
    t0 = time.perf_counter(); ascii.read(text, format="latex"); ts.append(time.perf_counter() - t0)
print(astropy.__file__.split("/")[4], f"min {min(ts):.3f}s")
