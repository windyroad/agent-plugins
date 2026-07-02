#!/usr/bin/env bash
# detect-unratified-stories-maps.sh — ADR-090 detector.
#
# Token-cheap detection of story maps + stories lacking the ratified
# `human-oversight: confirmed` marker. Mirrors wr-architect detect-unoversighted.sh
# but spans two artefact types with different marker encodings:
#   - stories:    markdown YAML frontmatter  `human-oversight: confirmed`
#   - story-maps: HTML meta tag              `<meta name="human-oversight" content="confirmed">`
#
# ADR-090's marker is DRIFT-INVALIDATED (unlike ADR-066 write-once): an edit
# re-opens it to `unconfirmed`, so this detector surfaces both the never-ratified
# (no marker) and the drift-reopened (`unconfirmed`) cases as the drain queue.
#
# Usage: detect-unratified-stories-maps.sh [STORIES_DIR=docs/stories] [MAPS_DIR=docs/story-maps]
# Output: one unratified artefact path per line, sorted. Empty = all confirmed.
# Always exits 0 (detector, not a gate). Consumed by the work-problems Step 2.4
# oversight-unconfirmed drain (mirror of the architect/jtbd detectors).
set -euo pipefail

STORIES_DIR="${1:-docs/stories}"
MAPS_DIR="${2:-docs/story-maps}"

shopt -s nullglob

{
  # Stories — markdown YAML frontmatter.
  if [ -d "$STORIES_DIR" ]; then
    for f in "$STORIES_DIR"/*.md "$STORIES_DIR"/*/*.md; do
      [ "$(basename "$f")" = "README.md" ] && continue
      fm="$(awk 'NR==1 && $0 != "---" { exit } NR==1 { next } /^---[[:space:]]*$/ { exit } { print }' "$f")"
      printf '%s\n' "$fm" | grep -qiE '^human-oversight:[[:space:]]*confirmed[[:space:]]*$' && continue
      echo "$f"
    done
  fi
  # Story maps — HTML meta tag.
  if [ -d "$MAPS_DIR" ]; then
    for f in "$MAPS_DIR"/*.html "$MAPS_DIR"/*/*.html; do
      grep -qiE '<meta[^>]*name="human-oversight"[^>]*content="confirmed"' "$f" && continue
      echo "$f"
    done
  fi
} | sort

exit 0
