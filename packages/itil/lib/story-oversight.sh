#!/usr/bin/env bash
# story-oversight.sh — ADR-090 lazy-fingerprint ratification helpers.
#
# Shared by detect-unratified-stories-maps.sh, check-rfc-stories-ratified.sh, and
# mark-story-oversight-confirmed.sh so all three agree on ONE hash definition
# (if they diverged, a freshly-ratified artefact would read as drifted forever).
#
# A story/map is RATIFIED when it carries a `confirmed` human-oversight marker
# AND a stored oversight-hash that matches a fresh hash of its content-minus-
# marker. Any content edit changes the hash → the artefact reads as drifted /
# unratified until re-ratified. This is ADR-090's drift-invalidation (ADR-009
# drift lineage, NOT ADR-066 write-once) — the same hash-the-artefact pattern
# the external-comms gate uses.
#
# Sourced, not executed. Requires `shasum` (BSD + coreutils both ship it).

# Stable hash of the artefact's content EXCLUDING the two marker lines, so
# writing/updating the marker is idempotent w.r.t. the hash. Covers both
# encodings in one filter:
#   - markdown: `human-oversight:` / `oversight-hash:` frontmatter lines
#   - HTML:     <meta name="human-oversight" ...> / <meta name="oversight-hash" ...>
oversight_content_hash() {
  # Exclude the marker + lifecycle-`status` lines, and normalize lifecycle-PROGRESS
  # state — acceptance-criterion checkbox ticks and slice `data-status` — so that
  # ONLY a SUBSTANCE change re-opens ratification. Ticking a criterion or advancing
  # status/slice-progress is progress, not a change to what the user ratified; the
  # value statement, criterion TEXT, and structure still drift the hash.
  grep -vE '^(human-oversight|oversight-hash|status):|<meta[^>]*name="(human-oversight|oversight-hash|status)"' "$1" \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g' \
    | shasum -a 256 | awk '{print $1}'
}

# Echo the stored oversight-hash (md frontmatter OR HTML meta), empty if none.
oversight_stored_hash() {
  local h
  h="$(grep -oE '^oversight-hash:[[:space:]]*[a-f0-9]{64}' "$1" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)"
  [ -z "$h" ] && h="$(grep -oE '<meta[^>]*name="oversight-hash"[^>]*content="[a-f0-9]{64}"' "$1" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)"
  printf '%s' "$h"
}

# True (0) if the file carries a `confirmed` human-oversight marker (md or HTML).
oversight_is_confirmed() {
  grep -qiE '^human-oversight:[[:space:]]*confirmed([[:space:]]|$)' "$1" && return 0
  grep -qiE '<meta[^>]*name="human-oversight"[^>]*content="confirmed"' "$1" && return 0
  return 1
}

# True (0) if RATIFIED: confirmed AND a stored hash that matches current content.
# A confirmed marker with NO stored hash (legacy hand-ratified) is NOT ratified —
# it must be re-ratified once to gain its fingerprint.
is_story_map_ratified() {
  local f="$1" stored
  oversight_is_confirmed "$f" || return 1
  stored="$(oversight_stored_hash "$f")"
  [ -z "$stored" ] && return 1
  [ "$stored" = "$(oversight_content_hash "$f")" ]
}
