#!/usr/bin/env bash
# make clone: clone every repo in repos.lock into WS and check out its pinned
# commit. Existing folders are left alone (never reset or force-checked-out).
set -euo pipefail

LOCK="${1:?usage: $0 repos.lock WS}"
WS="${2:?usage: $0 repos.lock WS}"
mkdir -p "$WS"

while read -r dir url branch commit; do
  [[ -z "${dir:-}" || "$dir" == \#* ]] && continue
  if [ -e "$WS/$dir" ]; then
    echo "skip  $dir (exists; make doctor reports whether it matches $commit)"
    continue
  fi
  echo "clone $dir  ($branch @ $commit)"
  git clone --branch "$branch" "$url" "$WS/$dir"
  git -C "$WS/$dir" -c advice.detachedHead=false checkout "$commit"
  # Stay on a branch so new commits are not lost on a detached HEAD.
  git -C "$WS/$dir" switch -c "kit-$branch" >/dev/null
done < "$LOCK"

echo "done. Next: make envs, make sdk2, make build, make doctor"
