#!/usr/bin/env python3
"""Build the git-sized raw sample in data/raw/ from data/raw_full/ (deterministic, no randomness).

Rule: the 2024 Final (KKR v SRH, Chennai) - its match row plus every delivery of that match.
Rows are copied verbatim except that the space padding of the deliveries mirror is stripped (keeps git small;
sql/02 trims anyway, so results are identical)."""
import csv, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
FULL, OUT = ROOT / "data/raw_full", ROOT / "data/raw"
OUT.mkdir(parents=True, exist_ok=True)
with open(FULL / "matches_2008-2024.csv", newline="", encoding="utf-8") as f:
    rows = list(csv.reader(f))
keep = [r for r in rows[1:] if r[1] == "2024" and r[4] == "Final"]
ids = {r[0] for r in keep}
with open(OUT / "matches_2008-2024.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f, lineterminator="\n").writerows([rows[0]] + keep)
n = 0
with open(FULL / "deliveries_2008-2024.csv", newline="", encoding="utf-8") as f, \
     open(OUT / "deliveries_2008-2024.csv", "w", newline="", encoding="utf-8") as g:
    w = csv.writer(g, lineterminator="\n")
    for i, r in enumerate(csv.reader(f)):
        r = [c.strip() for c in r]
        if i == 0 or r[0] in ids:
            w.writerow(r); n += i > 0
print(f"matches {len(keep)}  deliveries {n}")
