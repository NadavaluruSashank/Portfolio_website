#!/usr/bin/env python3
"""Basic pre-deploy checks for the static portfolio (no network calls).

Run from the repository root:  python3 cloud/aws/check_site.py
Exits with status 1 if a check fails.
"""
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
errors, notes = [], []


class Collector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.hrefs, self.ldjson, self._in_ld = set(), [], [], False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "a" and a.get("href"):
            self.hrefs.append(a["href"])
        self._in_ld = tag == "script" and a.get("type") == "application/ld+json"

    def handle_endtag(self, tag):
        if tag == "script":
            self._in_ld = False

    def handle_data(self, data):
        if self._in_ld and data.strip():
            self.ldjson.append(data)


for name in ("index.html", "404.html"):
    if not (ROOT / name).is_file():
        errors.append(f"missing {name}")

index = (ROOT / "index.html").read_text(encoding="utf-8") if (ROOT / "index.html").is_file() else ""
c = Collector()
c.feed(index)

# 1. Every in-page anchor in the static HTML points to an existing id.
for h in c.hrefs:
    if h.startswith("#") and len(h) > 1 and h[1:] not in c.ids:
        errors.append(f"broken anchor {h}")

# 2. Structured data is valid JSON.
for block in c.ldjson:
    try:
        json.loads(block)
    except json.JSONDecodeError as e:
        errors.append(f"invalid JSON-LD: {e}")

# 3. Basic metadata is present.
for needle in ('<title>', 'name="description"', 'property="og:title"', 'name="viewport"', '<html lang='):
    if needle not in index:
        errors.append(f"missing metadata: {needle}")

# 4. No credentials in any deployable or repo text file.
secret_patterns = {
    "AWS access key id": r"\b(AKIA|ASIA)[0-9A-Z]{16}\b",
    "private key": r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "aws secret assignment": r"aws_secret_access_key\s*[=:]\s*\S{20,}",
}
for f in ROOT.rglob("*"):
    if ".git" in f.parts or not f.is_file() or f.suffix.lower() in {".pdf", ".png", ".jpg"}:
        continue
    text = f.read_text(encoding="utf-8", errors="ignore")
    for label, pat in secret_patterns.items():
        if re.search(pat, text):
            errors.append(f"possible {label} in {f.relative_to(ROOT)}")

# 5. Links declared in the DATA block use HTTPS (mailto allowed).
for url in re.findall(r'"(https?://[^"]+)"', index):
    if url.startswith("http://"):
        errors.append(f"non-HTTPS link: {url}")

# 6. CV button: if DATA.cvUrl is set, the file must exist.
m = re.search(r'^\s*cvUrl:\s*"([^"]*)"', index, re.M)
if m and m.group(1):
    if not (ROOT / m.group(1)).is_file():
        errors.append(f"cvUrl points to missing file {m.group(1)}")
    else:
        notes.append(f"CV file present: {m.group(1)}")
else:
    notes.append("cvUrl is empty: no Download CV button will be shown")

for n in notes:
    print("note:", n)
if errors:
    for e in errors:
        print("ERROR:", e)
    sys.exit(1)
print(f"OK: {len(c.hrefs)} links, {len(c.ids)} ids, {len(c.ldjson)} JSON-LD block(s) checked")
