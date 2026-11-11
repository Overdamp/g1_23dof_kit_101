"""Used by tests/check_kit.sh: every relative link in a .md file must point at
a file or folder that exists. Links inside code blocks, http(s)/mailto links
and same-page anchors (#...) are not checked.

Usage: python3 tests/check_links.py <kit folder>
"""

import pathlib
import re
import sys

kit = pathlib.Path(sys.argv[1])
bad, n = [], 0
for md in sorted(kit.rglob("*.md")):
    if any(part in (".git", "repos") for part in md.relative_to(kit).parts):
        continue
    text = re.sub(r"```.*?```", "", md.read_text(), flags=re.S)
    text = re.sub(r"`[^`\n]*`", "", text)
    for target in re.findall(r"\]\(([^)\s]+)\)", text):
        if re.match(r"[a-z]+:", target) or target.startswith("#"):
            continue
        n += 1
        if not (md.parent / target.split("#")[0]).resolve().exists():
            bad.append(f"{md.relative_to(kit)}: broken link ({target})")

for b in bad:
    print(f"  \033[31mFAIL\033[0m  {b}")
if bad:
    sys.exit(1)
print(f"  \033[32mPASS\033[0m  {n} relative links resolve")
