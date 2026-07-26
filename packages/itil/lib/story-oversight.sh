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
  grep -vE '^(human-oversight|oversight-hash|oversight-basis|status):|<meta[^>]*name="(human-oversight|oversight-hash|oversight-basis|status)"' "$1" \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g' \
    | shasum -a 256 | awk '{print $1}'
}

# Hash a story MAP's content while EXCLUDING the single-line card elements whose
# data-story-id is in the caller-supplied set (ADR-101 condition (a), map leg).
#
# ADR-095 requires story-map membership at capture, so authoring a story ALWAYS
# adds a card to its map — which, under ADR-090 drift-invalidation, re-opens the
# map's ratification by construction. Requiring a hash-matching map would make
# the AFK-accept carve-out unsatisfiable: capturing the story would break the
# very condition the story must satisfy.
#
# This COARSENS the drift trigger to a coherent edit-set — the remedy ADR-090's
# own Reassessment Criteria authorises — rather than dropping to write-once,
# which ADR-090 explicitly forbids. Any map edit OTHER than adding the named
# cards still drifts the hash, so the condition stays load-bearing.
oversight_content_hash_excluding_stories() {
  local f="$1"; shift
  local filtered id
  filtered="$(cat "$f")"
  for id in "$@"; do
    [ -n "$id" ] || continue
    # Anchored on the closing quote so STORY-05 cannot strip STORY-054's card.
    filtered="$(printf '%s\n' "$filtered" | grep -vF "data-story-id=\"${id}\"" || true)"
  done
  printf '%s\n' "$filtered" \
    | grep -vE '^(human-oversight|oversight-hash|oversight-basis|status):|<meta[^>]*name="(human-oversight|oversight-hash|oversight-basis|status)"' \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g' \
    | shasum -a 256 | awk '{print $1}'
}

# True (0) if this artefact's `confirmed` marker was written by the ADR-101 AFK
# pure-decomposition carve-out rather than by a human ratification event.
# BSD grep has no \s — use [[:space:]] (the P334 portability class).
oversight_is_pure_decomposition() {
  grep -qE '^oversight-basis:[[:space:]]*pure-decomposition([[:space:]]|$)' "$1" 2>/dev/null
}

# True (0) if the story DECLARES itself eligible for the ADR-101 carve-out.
# Unlike `oversight-basis:` (marker-adjacent, excluded from the hash), this is an
# AUTHORED claim and stays INSIDE the hash — editing it re-opens ratification,
# and it cannot be stripped to hide the story from the post-hoc drain.
oversight_declares_pure_decomposition() {
  grep -qE '^afk-accept:[[:space:]]*pure-decomposition([[:space:]]|$)' "$1" 2>/dev/null
}

# ADR-101 map leg. Satisfied when the map is fully ratified (card already present
# at ratification time), OR when it is `confirmed` and its stored hash matches the
# content hash with THIS story's card excluded (card added after ratification).
oversight_map_leg_ok() {
  local map="$1" story_id="$2"
  is_story_map_ratified "$map" && return 0
  oversight_is_confirmed "$map" || return 1
  [ "$(oversight_stored_hash "$map")" = "$(oversight_content_hash_excluding_stories "$map" "$story_id")" ]
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
