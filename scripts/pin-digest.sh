#!/usr/bin/env bash
# Pins both services in btc-commons-node-view/docker-compose.yml to the multi-arch digest.
# Usage: scripts/pin-digest.sh [image-tag]
# With no argument, the tag already written in docker-compose.yml is kept.
# The app version in umbrel-app.yml is separate and is not the image tag.
set -euo pipefail
cd "$(dirname "$0")/../btc-commons-node-view"
if [[ $# -ge 1 ]]; then
  V="$1"
else
  mapfile -t tags < <(sed -n 's/^ *image: ghcr.io\/btcdecoded\/blvm-ui:\([^@ ]*\).*/\1/p' docker-compose.yml)
  if [[ ${#tags[@]} -eq 0 || -z "${tags[0]}" ]]; then
    printf 'pin-digest: no ghcr.io/btcdecoded/blvm-ui image tag in docker-compose.yml\n' >&2
    exit 1
  fi
  V="${tags[0]}"
  for tag in "${tags[@]}"; do
    if [[ "$tag" != "$V" ]]; then
      printf 'pin-digest: image tags differ (%s vs %s); pass one tag explicitly\n' "$V" "$tag" >&2
      exit 1
    fi
  done
fi
D="${DIGEST:-$(docker buildx imagetools inspect "ghcr.io/btcdecoded/blvm-ui:$V" --format '{{.Manifest.Digest}}')}"
if [[ ! "$D" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  printf 'pin-digest: refusing to write digest %q (want sha256: and 64 hex digits)\n' "$D" >&2
  exit 1
fi
sed -i.bak -E "/TODO-fill-after-blvm-ui-release|# PIN \(run scripts/d; s#^( *image: ghcr.io/btcdecoded/blvm-ui):[^@ ]+(@sha256:[0-9a-f]+)?\$#\1:$V@$D#" docker-compose.yml
rm -f docker-compose.yml.bak
grep -n 'image:' docker-compose.yml
