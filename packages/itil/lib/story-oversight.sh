#!/usr/bin/env bash
# story-oversight.sh — ADR-090 lazy-fingerprint ratification helpers.
#
# Shared by detect-unratified-stories-maps.sh, check-rfc-stories-ratified.sh, and
# mark-story-oversight-confirmed.sh so all three agree on ONE hash definition
# (if they diverged, a freshly-ratified artefact would read as drifted forever).
#
# A story MAP is RATIFIED when it carries a `confirmed` human-oversight marker
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
#   - ADR-102 data island: the same fields as JSON keys, `"humanOversight":` /
#     `"oversightHash":` / `"oversightDate":` / `"oversightNote":`. Since ADR-102
#     scopes a map's hash to the island, the marker now lives INSIDE the hashed
#     region — so without this third spelling, ratifying a map mutated the very
#     bytes it was fingerprinting and the stored hash could never match. Every
#     map would have read as drifted the instant it was ratified.
# THE single definition of what the fingerprint ignores. Reads stdin, writes the
# normalised stream. Both hash functions route through this and neither carries
# its own copy — that duplication is why the P474 `**Status**:` mirror had to be
# removed from two places and why a third copy could have been missed entirely
# (RFC-059 / STORY-055).
#
# Excludes the marker lines plus the lifecycle `status` key in both encodings, and
# normalises lifecycle PROGRESS — acceptance-criterion ticks and slice
# `data-status` — so ONLY a SUBSTANCE change re-opens ratification. Ticking a
# criterion or advancing status is progress, not a revision of what the human
# ratified; the value statement, criterion TEXT and structure all still drift.
#
# Editing this filter changes ADR-090's Decision Outcome, not merely a mechanism.
# It is the surface the 2026-07-03 narrowing changed while going unrecorded for
# three weeks; a change here needs an ADR-090 amendment. The pattern is a
# LITERAL on purpose: built from a variable, an expansion that ever yielded empty
# would make `grep -vE ''` suppress every line and hash the empty stream to a
# constant, after which one artefact's stored hash would validate against ANY
# content — and `itil-no-implement-draft-gate` sources this lib under
# `2>/dev/null || exit 0`, so that failure would remove the gate silently.
_oversight_filter() {
  grep -vE '^(human-oversight|oversight-hash|oversight-basis|status):|<meta[^>]*name="(human-oversight|oversight-hash|oversight-basis|status)"|^[[:space:]]*"(humanOversight|oversightHash|oversightBasis|oversightDate|oversightNote|status)"[[:space:]]*:' \
    | sed -E 's/- \[[ xX]\]/- [ ]/g; s/data-status="[^"]*"/data-status=""/g'
}

# The excluded key set, readable by tests and the corpus lint. Kept in agreement
# with the literal above by a bidirectional test rather than by construction, for
# the reason in that comment. One key per line.
oversight_excluded_keys() {
  printf '%s\n' human-oversight oversight-hash oversight-basis status
}

# The MAP-SUBSTANCE key set: the island keys a story map's ratification hangs on.
#
# Editing this set — here or in the SUBSTANCE tuple below — changes ADR-090's
# Decision Outcome as amended by ADR-103, not merely a mechanism. It IS the drift
# trigger. A change here needs an ADR-090 amendment, and the bidirectional test
# will NOT catch that: it asserts the accessor and the tuple agree, so it passes
# whenever both move together, which is the shape of exactly that edit. The
# sibling notice on _oversight_filter says the same thing for the same reason.
#
# SCOPE: island keys only. Unlike oversight_excluded_keys, which strips keys from
# every artefact in three encodings, this set is meaningless for anything with no
# island — stories and pre-ADR-102 maps fall through to whole-file bytes. The two
# are not complements; `excluded ∪ substance` is not the key space.
#
# THIS IS THE ONLY ENUMERATION. Six documents used to restate it (ADR-090,
# ADR-103, ADR-105, capture-story-map, and manage-story-map twice) and by
# 2026-08-08 it had drifted in both directions at once: the ADRs still named
# `lead` and `traceProse`, dead the day before, while manage-story-map had lost
# `storyMapId` and `secondaryPersona`, both live. The prose now states the rule
# and points here — which is what the excluded-key set has always done, and it
# has never drifted.
#
# Consumers DERIVE from this rather than restating it, the way the corpus lint
# derives its pattern from oversight_excluded_keys. A consumer that hardcodes the
# list starts a seventh enumeration.
oversight_map_substance_keys() {
  printf '%s\n' storyMapId title persona secondaryPersona traces backbone caption
}

# Emit the bytes a fingerprint should cover.
#
# For a story map under ADR-102 that is the DATA ISLAND alone, not the whole
# file: the grid, the <style> block and the <meta> block are all generated from
# the island, so hashing the whole file would let a template change regenerate
# every map, drift every stored fingerprint, and silently revoke ratification
# across the corpus (ADR-090's marker is drift-invalidated). A presentation
# change must never revoke a substance approval.
#
# Anything with no island — stories (.md), and maps predating ADR-102 — falls
# through to whole-file bytes, so the story leg and the legacy corpus are
# untouched.
_oversight_hashable() {
  local f="$1"
  if grep -qF '<script id="story-map-data"' "$f" 2>/dev/null; then
    # ADR-103: the fingerprint covers SUBSTANCE only — the map's identity and
    # prose, its traces, and its backbone (the activity columns). Releases and
    # the cards in them are SCHEDULING: drawing a row, or putting a story in
    # one, is not a revision of what a human approved.
    #
    # This is what retires the ADR-101 carve-out. That existed because
    # capturing a story onto its map drifted the map's hash, which broke the
    # very condition the story had to satisfy. With cards outside the basis,
    # the drift never happens and the carve-out has nothing to carve.
    #
    # NOT a sed range and not a JS reimplementation — see the awk note below
    # and story-map-query.sh's header.
    awk '
      !inside && index($0, "<script id=\"story-map-data\"") { inside=1; next }
      inside && index($0, "</script>") { exit }
      inside { print }
    ' "$f" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read().replace("\\u003c", "<"))
except Exception:
    sys.exit(0)          # unparseable island → empty basis, reads as drifted
# Only keys PRESENT in the island are included, so a key listed here that no
# map carries contributes nothing — which is why `lead` and `traceProse` could
# be removed on 2026-08-08 without moving a single stored hash. They had left
# the format the day before and were a live re-introduction vector: a field
# nothing documents would still have been ratification-bearing.
SUBSTANCE = ("storyMapId", "title", "persona", "secondaryPersona",
             "traces", "backbone", "caption")
print(json.dumps({k: d[k] for k in SUBSTANCE if k in d}, sort_keys=True, indent=2))
'
  else
    cat "$f"
  fi
}

oversight_content_hash() {
  # Input path: bytes are fed to the filter directly, so trailing blank lines
  # are PRESERVED. Deliberately NOT unified with the map variant below — see the
  # note there. Changing this changes every stored fingerprint.
  _oversight_hashable "$1" | _oversight_filter | shasum -a 256 | awk '{print $1}'
}

# ADR-103 retired the ADR-101 AFK pure-decomposition carve-out and its map leg.
# The carve-out existed because ADR-095 compels a card onto the map at capture,
# which under ADR-090 drift-invalidation re-opened the map's ratification by
# construction — the condition a story had to satisfy was broken by authoring the
# story. ADR-103 took cards out of the fingerprint basis entirely, so that no
# longer happens and there is nothing left to exclude. Removed with it:
# oversight_content_hash_excluding_stories, oversight_map_leg_ok,
# oversight_is_pure_decomposition, oversight_declares_pure_decomposition.

# Echo the stored oversight-hash, empty if none. Three spellings carry the same
# fact: md frontmatter, an HTML <meta>, and — for an ADR-102 map — the data
# island, which is where mark-story-oversight-confirmed actually writes. The
# island MUST be read here: the <meta> is a projection the renderer regenerates
# from it, so a map marked but not yet re-rendered would otherwise read as
# unratified the instant it was ratified.
oversight_stored_hash() {
  local h
  h="$(grep -oE '^oversight-hash:[[:space:]]*[a-f0-9]{64}' "$1" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)"
  [ -z "$h" ] && h="$(grep -oE '<meta[^>]*name="oversight-hash"[^>]*content="[a-f0-9]{64}"' "$1" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)"
  [ -z "$h" ] && h="$(grep -oE '"oversightHash"[[:space:]]*:[[:space:]]*"[a-f0-9]{64}"' "$1" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)"
  printf '%s' "$h"
}

# True (0) if the file carries a `confirmed` human-oversight marker (md or HTML).
oversight_is_confirmed() {
  grep -qiE '^human-oversight:[[:space:]]*confirmed([[:space:]]|$)' "$1" && return 0
  grep -qiE '<meta[^>]*name="human-oversight"[^>]*content="confirmed"' "$1" && return 0
  # ADR-102 island spelling — see oversight_stored_hash for why this is load-bearing.
  grep -qiE '"humanOversight"[[:space:]]*:[[:space:]]*"confirmed"' "$1" && return 0
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

# Is this STORY approved? ADR-103 made the story map the approval surface, and a
# story carries no oversight marker of its own — not even one saying it inherits.
# A story is approved exactly when every map it names is ratified.
#
# Any `human-oversight:` line left on a story is legacy and is IGNORED here. It
# is not consulted as a fallback: a story-level marker that could still approve a
# story on an unratified map would keep alive the second approval surface this
# decision removed, and the drain would never finish.
#
# A story naming no map is NOT approved — otherwise dropping the `story-maps:`
# field would be a way to self-approve.
story_is_approved() {
  local story="$1" maps_root="${2:-docs/story-maps}" line ids id f found=0

  # `story-maps:` in inline `[A, B]` or block `- A` form.
  line="$(awk '/^story-maps:/{print; exit}' "$story")"
  ids="$(printf '%s' "$line" | grep -oE 'STORY-MAP-[0-9]+' || true)"
  [ -n "$ids" ] || ids="$(awk '/^story-maps:/{g=1;next} g&&/^[[:space:]]*-/{print} g&&/^[^[:space:]-]/{exit}' "$story" \
    | grep -oE 'STORY-MAP-[0-9]+' || true)"

  for id in $ids; do
    # Exactly one file must match under a lifecycle directory. This USED to be
    # `ls ... | head -1`, which arbitrary-picks when an id resolves in more than
    # one of them — silently, and in the permissive direction: the one branch in
    # this predicate that could grant an approval nobody gave. Which copy wins is
    # just glob sort order, so whether it lands on the live map or a stale one is
    # luck. An ambiguous id is a corpus defect; deny and let it surface.
    #
    # Known gap, pre-existing and unreachable today (no map sits at the top
    # level of docs/story-maps/): the detector walks BOTH "$MAPS_DIR"/*.html and
    # "$MAPS_DIR"/*/*.html, so a top-level map is visible to it but invisible
    # here, and a story naming one would read unapproved forever.
    #
    # No `shopt nullglob` here on purpose. This function is sourced, so toggling
    # it would mutate the CALLER's shell — and one caller
    # (detect-unratified-stories-maps.sh) sets nullglob once at the top and
    # relies on it for a later glob. The `-e` test does the same job locally: an
    # unmatched glob stays literal, and a literal path does not exist.
    local cand n=0 m=""
    for cand in "$maps_root"/*/"${id}"-*.html; do
      [ -e "$cand" ] || continue
      n=$((n + 1)); m="$cand"
    done
    [ "$n" -eq 1 ] || return 1
    is_story_map_ratified "$m" || return 1
    found=1
  done
  [ "$found" = 1 ]
}
