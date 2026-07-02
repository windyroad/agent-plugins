#!/usr/bin/env bash
# check-rfc-stories-ratified.sh — ADR-090 (an RFC may reference only RATIFIED stories).
#
# For each STORY-NNN in the RFC's `stories:` frontmatter, resolve the story file
# under <stories-root>/*/STORY-NNN-*.md and verify it carries
# `human-oversight: confirmed`. Exit non-zero (with a stderr directive naming the
# offending stories) if any listed story is unratified, unconfirmed, or missing.
#
# Composes with check-rfc-has-stories.sh (ADR-089): has-stories checks >=1 story
# exists; this checks each listed story is ratified. An empty `stories:` passes
# vacuously here (the has-stories gate owns the emptiness rejection).
#
# Usage: check-rfc-stories-ratified.sh <rfc-file> [stories-root=docs/stories]
# Exit:  0 = all listed stories ratified (or none listed); 1 = >=1 unratified/missing;
#        2 = usage / file error.
#
# Authority: ADR-090. Driver: P404 Phase 2. Test: check-rfc-stories-ratified.bats.
set -euo pipefail

# Adopter-safe: source the shared lazy-fingerprint lib RELATIVE TO THIS SCRIPT (P317).
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "check-rfc-stories-ratified: cannot locate lib dir" >&2; exit 2; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

rfc="${1:-}"
stories_root="${2:-docs/stories}"
if [ -z "$rfc" ]; then
  echo "check-rfc-stories-ratified: usage: check-rfc-stories-ratified.sh <rfc-file> [stories-root]" >&2
  exit 2
fi
if [ ! -f "$rfc" ]; then
  echo "check-rfc-stories-ratified: file not found: $rfc" >&2
  exit 2
fi

# Collect STORY-NNN ids from the stories: frontmatter (inline list OR block list).
stories_line="$(awk '/^stories:/{print; exit}' "$rfc")"
ids="$(printf '%s' "$stories_line" | grep -oE 'STORY-[0-9]+' || true)"
if [ -z "$ids" ]; then
  ids="$(awk '/^stories:/{f=1;next} f&&/^[[:space:]]*-/{print} f&&/^[^[:space:]-]/{exit}' "$rfc" | grep -oE 'STORY-[0-9]+' || true)"
fi

# No stories listed → vacuously ratified (has-stories gate owns emptiness).
[ -z "$ids" ] && exit 0

unratified=""
for id in $ids; do
  f="$(ls "$stories_root"/*/"$id"-*.md 2>/dev/null | head -1 || true)"
  if [ -z "$f" ]; then
    unratified="$unratified $id(missing)"
    continue
  fi
  if ! is_story_map_ratified "$f"; then
    unratified="$unratified $id(unratified)"
  fi
done

if [ -n "$unratified" ]; then
  echo "check-rfc-stories-ratified: $rfc references unratified stories:$unratified — ADR-090: an RFC may reference only ratified (human-oversight: confirmed) stories. Ratify them first." >&2
  exit 1
fi
exit 0
