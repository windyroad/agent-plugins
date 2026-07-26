#!/usr/bin/env bash
# detect-unratified-stories-maps.sh — ADR-090 detector.
#
# Token-cheap detection of story maps + stories that are NOT ratified. Mirrors
# wr-architect detect-unoversighted.sh but spans two artefact types and is
# DRIFT-AWARE via the shared lazy-fingerprint helper: an artefact is ratified
# only when it carries a `confirmed` human-oversight marker AND a stored
# oversight-hash matching its current content. This surfaces three cases as the
# drain queue:
#   - never ratified   (no marker)
#   - drift-reopened   (marker says confirmed, but content changed → hash mismatch)
#   - legacy confirmed  (confirmed but no fingerprint yet — needs one re-ratify)
#
# With `--with-afk-accepted` (ADR-101) it ALSO lists, on stderr, stories whose
# `confirmed` marker was machine-written by the AFK pure-decomposition carve-out
# rather than by a human — they are awaiting post-hoc human ratification. The
# listing keys on the UNION of `afk-accept:` and `oversight-basis:`, because the
# latter is excluded from the content hash and could otherwise be stripped to
# hide a machine-accepted story from this drain; `afk-accept:` stays in the hash.
# stdout is untouched by the flag, so the Step 2.4 drain consumer is unaffected.
#
# Usage: detect-unratified-stories-maps.sh [--with-afk-accepted] [STORIES_DIR=docs/stories] [MAPS_DIR=docs/story-maps]
# Output: one unratified artefact path per line, sorted. Empty = all ratified.
# Always exits 0 (detector, not a gate). Consumed by the work-problems Step 2.4
# oversight-unconfirmed drain.
set -euo pipefail

# Adopter-safe: source the shared hash lib RELATIVE TO THIS SCRIPT (P317).
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "detect-unratified-stories-maps: cannot locate lib dir" >&2; exit 0; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

WITH_AFK=0
if [ "${1:-}" = "--with-afk-accepted" ]; then
  WITH_AFK=1
  shift
fi

STORIES_DIR="${1:-docs/stories}"
MAPS_DIR="${2:-docs/story-maps}"

shopt -s nullglob

{
  if [ -d "$STORIES_DIR" ]; then
    for f in "$STORIES_DIR"/*.md "$STORIES_DIR"/*/*.md; do
      [ "$(basename "$f")" = "README.md" ] && continue
      is_story_map_ratified "$f" || echo "$f"
    done
  fi
  if [ -d "$MAPS_DIR" ]; then
    for f in "$MAPS_DIR"/*.html "$MAPS_DIR"/*/*.html; do
      is_story_map_ratified "$f" || echo "$f"
    done
  fi
} | sort

# ADR-101 post-hoc drain — stderr only, so the stdout path contract is preserved.
if [ "$WITH_AFK" = "1" ] && [ -d "$STORIES_DIR" ]; then
  for f in "$STORIES_DIR"/*.md "$STORIES_DIR"/*/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    if oversight_declares_pure_decomposition "$f" || oversight_is_pure_decomposition "$f"; then
      echo "AFK-ACCEPTED (awaiting post-hoc human ratification): $f" >&2
    fi
  done
fi

exit 0
