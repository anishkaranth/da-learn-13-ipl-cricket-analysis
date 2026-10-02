#!/usr/bin/env python3
"""Download the full IPL 2008-2024 dataset into data/raw_full/ and verify SHA-256.

Kaggle page : https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020 (IPL Complete Dataset 2008-2024)
Mirror      : https://github.com/avinashyadav16/ipl-analytics (same two files, deliveries space-padded)
Licence     : Kaggle page lists no explicit licence; underlying ball-by-ball data originates from Cricsheet
              (https://cricsheet.org, ODC-BY 1.0). Use for learning / non-commercial analysis with attribution.
"""
import hashlib, pathlib, urllib.request

BASE = "https://raw.githubusercontent.com/avinashyadav16/ipl-analytics/main/"
FILES = {
    "matches_2008-2024.csv": "161188bddca2018c5a87c5ea303884de67dd6c86746b699f8be72fd456d09418",
    "deliveries_2008-2024.csv": "183d4860c0a99dd215492fdcba2cc2ead35a05ee4ba6a5e2771f5876a41b1684",
}
out = pathlib.Path(__file__).resolve().parents[1] / "data" / "raw_full"
out.mkdir(parents=True, exist_ok=True)
bad = 0
for name, sha in FILES.items():
    p = out / name
    if not p.exists():
        print("downloading", BASE + name)
        urllib.request.urlretrieve(BASE + name, p)
    got = hashlib.sha256(p.read_bytes()).hexdigest()
    print(f"{name:28s} {p.stat().st_size:>11,} bytes  {'OK' if got == sha else 'CHECKSUM MISMATCH ' + got}")
    bad += got != sha
raise SystemExit(1 if bad else 0)
