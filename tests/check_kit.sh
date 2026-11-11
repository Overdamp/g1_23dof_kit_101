#!/usr/bin/env bash
# make check: static checks that need no GPU, conda or repos (CI can run it).
#   1. every shell script parses (bash -n)
#   2. Makefile rules from docs/ROADMAP.md Phase 1:
#      - every target has a "## description" (so `make help` lists it)
#      - no target runs more than 3 commands (the need_ws guard and line
#        continuations do not count); longer logic belongs in a script
#   3. docs/03-reference/make_targets.md has a row for every target, and no
#      row for a target that no longer exists
#   4. every relative link in a .md file points at a file that exists
#   5. no token-shaped strings or one-machine home paths in tracked files
#      (the "no secrets" rule in CONTRIBUTING.md)
#   6. shellcheck (warnings and errors) when it is installed; CI has it
set -uo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok()   { printf '  \e[32mPASS\e[0m  %s\n' "$*"; }
bad()  { printf '  \e[31mFAIL\e[0m  %s\n' "$*"; fails=$((fails + 1)); }

echo "Shell scripts"
for f in "$KIT"/scripts/*.sh "$KIT"/tests/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "${f#$KIT/}"; else bad "${f#$KIT/} does not parse: $(bash -n "$f" 2>&1 | head -1)"; fi
done

echo "Makefile and make_targets.md"
python3 - "$KIT/Makefile" "$KIT/docs/03-reference/make_targets.md" <<'EOF' || fails=$((fails + 1))
import re, sys
mk_path, doc_path = sys.argv[1], sys.argv[2]
lines = open(mk_path).read().split("\n")
target_re = re.compile(r"^([a-z][a-z0-9_-]*):(?!=)(.*)$")
targets, problems = {}, []
i = 0
while i < len(lines):
    m = target_re.match(lines[i])
    if not m:
        i += 1
        continue
    name, rest = m.group(1), m.group(2)
    if "## " not in rest:
        problems.append(f"target '{name}' has no '## description' (make help hides it)")
    cmds, j, cont = 0, i + 1, False
    while j < len(lines) and lines[j].startswith("\t"):
        body = lines[j].strip()
        if not cont and body != "$(need_ws)":
            cmds += 1
        cont = body.endswith("\\")
        j += 1
    if cmds > 3:
        problems.append(f"target '{name}' runs {cmds} commands (max 3): move the logic into a script")
    targets[name] = cmds
    i = j

try:
    doc = open(doc_path).read()
except FileNotFoundError:
    print(f"  \033[31mFAIL\033[0m  {doc_path} missing")
    sys.exit(1)
rows = set(re.findall(r"^\|\s*`([a-z][a-z0-9_-]*)`\s*\|", doc, re.M))
for t in sorted(set(targets) - rows):
    problems.append(f"target '{t}' has no row in make_targets.md")
for t in sorted(rows - set(targets)):
    problems.append(f"make_targets.md has a row for '{t}', which is not a Makefile target")

if problems:
    for p in problems:
        print(f"  \033[31mFAIL\033[0m  {p}")
    sys.exit(1)
print(f"  \033[32mPASS\033[0m  {len(targets)} targets: all described, all <= 3 commands, all in make_targets.md")
EOF

echo "Docs links"
python3 "$KIT/tests/check_links.py" "$KIT" || fails=$((fails + 1))

echo "Secrets and one-machine paths"
# Tracked files only; all files outside .git and repos when this is not a git checkout.
files=$(cd "$KIT" && { git ls-files 2>/dev/null || find . -type f -not -path './.git/*' -not -path './repos/*' | sed 's|^\./||'; })
# Tokens and keys by their shape, and a home path that exists on one person's machine.
pattern='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|/home/luke/'
hits=$(cd "$KIT" && echo "$files" | grep -v -e '^tests/check_kit.sh$' | xargs -d '\n' grep -nE -e "$pattern" 2>/dev/null | cut -c1-120 | head -5)
if [ -z "$hits" ]; then
  ok "no token-shaped strings or maintainer home paths in tracked files"
else
  bad "secret or one-machine path in a tracked file:"
  echo "$hits" | sed 's/^/          /'
fi

echo "shellcheck"
if command -v shellcheck >/dev/null; then
  if out=$(shellcheck -S warning "$KIT"/scripts/*.sh "$KIT"/tests/*.sh 2>&1); then
    ok "scripts/*.sh tests/*.sh (warnings and errors)"
  else
    bad "shellcheck:"
    echo "$out" | head -20 | sed 's/^/          /'
  fi
else
  printf '  \e[33mSKIP\e[0m  shellcheck not installed (CI runs it; sudo apt install shellcheck)\n'
fi

echo
if [ "$fails" -eq 0 ]; then echo "check: all PASS"; else echo "check: $fails FAIL"; exit 1; fi
