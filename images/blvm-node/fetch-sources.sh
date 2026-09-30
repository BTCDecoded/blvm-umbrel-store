#!/bin/sh
# Check out every repo in sources.txt at its pinned commit into ./src (the Docker build context).
#   ./fetch-sources.sh && docker build -t blvm-umbrel-node .
set -eu
cd "$(dirname "$0")"
mkdir -p src
grep -v '^#' sources.txt | while read -r repo commit; do
  [ -n "$repo" ] || continue
  dir="src/$repo"
  if [ ! -d "$dir/.git" ]; then
    git init -q "$dir"
    git -C "$dir" remote add origin "https://github.com/BTCDecoded/$repo.git"
  fi
  git -C "$dir" fetch -q --depth 1 origin "$commit"
  git -C "$dir" checkout -q --force FETCH_HEAD
  echo "$repo $(git -C "$dir" rev-parse --short HEAD)"
  # Store-only fixes, applied on top of the upstream commit (see patches/README.md).
  for p in patches/"$repo"/*.patch; do
    [ -f "$p" ] || continue
    git -C "$dir" apply "$(pwd)/$p"
    echo "  patched: $p"
  done
done
