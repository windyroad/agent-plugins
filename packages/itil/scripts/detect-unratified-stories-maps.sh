#!/usr/bin/env bash
# detect-unratified-stories-maps.sh — ADR-090 detector.
#
# Token-cheap detection of story maps that are NOT ratified, plus the stories
# those maps leave unapproved. Mirrors wr-architect detect-unoversighted.sh.
#
# A MAP is ratified only when it carries a `confirmed` human-oversight marker AND
# a stored oversight-hash matching its current substance, so three cases enter
# the drain queue:
#   - never ratified   (no marker)
#   - drift-reopened   (marker says confirmed, but substance changed → mismatch)
#   - legacy confirmed  (confirmed but no fingerprint yet — needs one re-ratify)
#
# A STORY carries no marker at all (ADR-103). It is listed when any map in its
# `story-maps:` field is unratified, or when it names no map — and the remedy is
# always to ratify the map, never the story.
#
# Usage: detect-unratified-stories-maps.sh [STORIES_DIR=docs/stories] [MAPS_DIR=docs/story-maps]
# Output: one unratified artefact path per line, sorted. Empty = all ratified.
# Always exits 0 (detector, not a gate). Consumed by the work-problems Step 2.4
# oversight-unconfirmed drain.
set -euo pipefail

# Adopter-safe: source the shared hash lib RELATIVE TO THIS SCRIPT (P317).
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "detect-unratified-stories-maps: cannot locate lib dir" >&2; exit 0; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

STORIES_DIR="${1:-docs/stories}"
MAPS_DIR="${2:-docs/story-maps}"

shopt -s nullglob

{
  if [ -d "$STORIES_DIR" ]; then
    for f in "$STORIES_DIR"/*.md "$STORIES_DIR"/*/*.md; do
      [ "$(basename "$f")" = "README.md" ] && continue
      # ADR-103: a story's approval may be its MAP's. Using the map predicate
      # here would report every story as unratified — stories carry no marker at
      # all — and send the drain to ratify a surface ADR-103 removed.
      story_is_approved "$f" "$MAPS_DIR" || echo "$f"
    done
  fi
  if [ -d "$MAPS_DIR" ]; then
    for f in "$MAPS_DIR"/*.html "$MAPS_DIR"/*/*.html; do
      is_story_map_ratified "$f" || echo "$f"
    done
  fi
} | sort

exit 0
