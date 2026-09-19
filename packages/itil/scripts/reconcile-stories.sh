#!/usr/bin/env bash
# packages/itil/scripts/reconcile-stories.sh
#
# Diagnose-only drift detector for docs/stories/README.md vs filesystem
# truth. Reads <stories-dir>/<state>/STORY-<NNN>-*.md (per-state subdirs:
# draft, accepted, in-progress, done, archived), parses the README's
# Story Rankings + Done tables, and reports each disagreement.
#
# Usage:
#   reconcile-stories.sh [<stories-dir> [<problems-dir> [<rfcs-dir> [<jtbd-dir> [<story-maps-dir>]]]]]
#
# Defaults:
#   <stories-dir>   = ./docs/stories
#   <problems-dir>  = ./docs/problems (when supplied + on disk; reverse trace)
#   <rfcs-dir>      = ./docs/rfcs (when supplied + on disk; reverse trace)
#   <jtbd-dir>      = ./docs/jtbd (when supplied + on disk; reverse trace)
#   <story-maps-dir> = ./docs/story-maps (row-backed RFC resolution)
#
# Exit codes:
#   0 = clean (README matches filesystem)
#   1 = drift detected (structured diff to stdout)
#   2 = parse error (README missing or malformed)
#
# Output format on drift (one line per drift entry, ≤ 150 bytes per
# ADR-038 progressive-disclosure budget):
#   DRIFT    STORY-<NNN> rankings: claims=<status> actual=<status>
#   STALE    STORY-<NNN> rankings: actual=<status>
#   MISMATCH STORY-<NNN> done: actual=<status>
#
# Reverse-trace pass (P170 Phase 2 Slice 9 — closes ADR-060 line 270):
# When <problems-dir> / <rfcs-dir> / <jtbd-dir> are provided AND on
# disk, the reconciler also checks the auto-maintained `## Stories`
# section on each parent artefact against the story frontmatter's
# `problems:` / `rfcs:` / `jtbd:` claims. Three drift kinds per parent
# tier:
#   MISSING_REVERSE_TRACE  STORY-<NNN> in <PARENT-ID> ## Stories
#     Story's frontmatter claims <PARENT-ID> but parent's ## Stories
#     table does not list STORY-<NNN>. Skill-side refresh contract
#     was missed.
#
# WHICH POPULATION THE RFC LEG COVERS (P472 / STORY-099). On the problems
# and jtbd legs every story that names the parent is checked. On the rfcs leg
# only APPROVED stories are, because ADR-090 as amended by ADR-103 forbids an
# RFC from referencing a story whose story map is not ratified: for such a
# story the `## Stories` row is CORRECTLY absent, and demanding it reported
# correct work as drift — a finding no compliant action could ever clear,
# since satisfying it meant breaking the rule it existed to protect.
#
# Approval reaches a story through its MAP (ADR-103), so `story_is_approved`
# is the predicate. A `human-oversight:` field left on a story file is legacy
# and is deliberately ignored; reading one would revive the second approval
# surface ADR-103 deleted.
#
# The release-row leg below is NOT gated. ADR-095 compels a story card onto
# the map at capture and ADR-103 took cards out of the fingerprint basis, so
# a card's absence from its row is never correct.
#
# Every run of the rfcs leg says on STDERR how many pairs it checked and how
# many it skipped, split by reason, so a reader of an exit-0 clean result can
# tell "checked and clean" from "skipped because out of scope". Two of the
# three skip reasons are corpus defects, not correct absences, and are
# counted apart: a story that names NO map (ADR-095), and a story naming a
# map id that resolves to zero or to several files. Folding either into the
# correct-absence bucket would be this ticket's own failure in the other
# direction. STDOUT stays drift-lines-only — /wr-itil:reconcile-stories
# redirects it to a file and parses it line by line.
#
# Read-only — does NOT mutate the README. The /wr-itil:manage-story skill
# (P170 Phase 2 Slice 8) applies edits with narrative-aware preservation;
# this script's only job is to report ground truth.
#
# Sibling to packages/itil/scripts/reconcile-rfcs.sh (ADR-060 Phase 1
# item 5) and reconcile-readme.sh (P118 / ADR-014): same parse + diff
# structure, applied at the story tier instead of the RFC / problem
# tier. Differences from reconcile-rfcs:
#   - Filename pattern: <state>/STORY-NNN-*.md (5 states: draft, accepted,
#     in-progress, done, archived) — per-state subdir layout (NOT
#     dual-tolerant flat — story tier is post-RFC-002, native-subdir)
#   - ID format: STORY-<NNN>
#   - No WSJF column (I11 invariant per ADR-060 line 253)
#   - Story Rankings covers draft/accepted/in-progress (story dev queue)
#   - Done covers done (matches RFC closed semantics)
#   - No Verification Queue (stories don't have a verifying status —
#     done is end-of-lifecycle for stories per ADR-060)
#   - No Parked tier (stories don't have a Parked status; only Problems do)
#
# @problem P170
# @adr ADR-060 (Problem-RFC-Story framework — Phase 2 amendment 2026-05-10
#                 story tier; reconcile-stories is the story-tier sibling
#                 of reconcile-rfcs)
# @adr ADR-049 (Plugin script resolution via bin/ on PATH — paired bin shim
#                at packages/itil/bin/wr-itil-reconcile-stories)

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# Adopter-safe: source the shared lazy-fingerprint lib RELATIVE TO THIS SCRIPT
# (P317), matching check-rfc-stories-ratified.sh. `story_is_approved` and its
# two accessors are the ONE definition of story ratification; this script adds
# no second one.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "reconcile-stories: cannot locate lib dir" >&2; exit 2; }
# shellcheck source=../lib/story-oversight.sh
source "$LIB/story-oversight.sh"

STORIES_DIR="${1:-docs/stories}"
PROBLEMS_DIR="${2:-$(dirname "$STORIES_DIR")/problems}"
RFCS_DIR="${3:-$(dirname "$STORIES_DIR")/rfcs}"
JTBD_DIR="${4:-$(dirname "$STORIES_DIR")/jtbd}"
MAPS_DIR="${5:-$(dirname "$STORIES_DIR")/story-maps}"
README="${STORIES_DIR}/README.md"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -f "$README" ]; then
  echo "PARSE_ERROR: README not found at ${README}" >&2
  exit 2
fi

if ! grep -q '^## Story Rankings' "$README"; then
  echo "PARSE_ERROR: '## Story Rankings' header missing in ${README}" >&2
  exit 2
fi

# ── Build filesystem truth: ID → status ─────────────────────────────────────

declare -A FS_STATUS
shopt -s nullglob
for state in draft accepted in-progress done archived; do
  for f in "$STORIES_DIR"/"$state"/STORY-[0-9][0-9][0-9]-*.md; do
    base="$(basename "$f")"
    num="${base#STORY-}"
    num="${num%%-*}"
    id="STORY-${num}"
    FS_STATUS["$id"]="$state"
  done
done
shopt -u nullglob

# ── Parse README sections into ID buckets ───────────────────────────────────

RANKINGS_START=$(grep -nE '^## Story Rankings' "$README" | head -1 | cut -d: -f1)
DONE_START=$(grep -n '^## Done' "$README" | head -1 | cut -d: -f1)
END_LINE=$(wc -l < "$README")

RANKINGS_END=${DONE_START:-$END_LINE}
DONE_END=$END_LINE

extract_section_ids() {
  local start="$1" end="$2"
  [ -z "$start" ] && return 0
  sed -n "${start},${end}p" "$README" \
    | grep -oE '\| *STORY-[0-9]{3} *\|' \
    | grep -oE 'STORY-[0-9]{3}' \
    | sort -u
}

README_RANKINGS_IDS="$(extract_section_ids "$RANKINGS_START" "$RANKINGS_END")"
README_DONE_IDS="$(extract_section_ids "$DONE_START" "$DONE_END")"

# ── Diff ─────────────────────────────────────────────────────────────────────

DRIFT_LINES=()

# (1) Each ID listed in Story Rankings must be draft / accepted /
#     in-progress on disk. Other statuses (done / archived) → drift.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    draft|accepted|in-progress)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("DRIFT    ${id} rankings: claims=active actual=${actual}")
      ;;
  esac
done <<< "$README_RANKINGS_IDS"

# (2) Each ID listed in Done section must be done on disk.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    done)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("MISMATCH ${id} done: actual=${actual}")
      ;;
  esac
done <<< "$README_DONE_IDS"

# (3) Each ID on disk in draft/accepted/in-progress must appear in
#     Story Rankings. Each done on disk must appear in Done.
for id in "${!FS_STATUS[@]}"; do
  state="${FS_STATUS[$id]}"
  case "$state" in
    draft|accepted|in-progress)
      if ! grep -qF "$id" <<< "$README_RANKINGS_IDS"; then
        DRIFT_LINES+=("STALE    ${id} rankings: actual=${state}")
      fi
      ;;
    done)
      if ! grep -qF "$id" <<< "$README_DONE_IDS"; then
        DRIFT_LINES+=("STALE    ${id} done: actual=done")
      fi
      ;;
    archived)
      : # archived stories are intentionally hidden from both tables
      ;;
  esac
done

# ── Reverse-trace pass — story frontmatter ↔ parent ## Stories section ─────

# RFC-leg population accounting. Counted per (story, markdown-RFC) pair.
RFC_MD_CHECKED=0
RFC_MD_SKIP_UNRATIFIED=0
RFC_MD_SKIP_NO_MAP=0
RFC_MD_SKIP_UNRESOLVED_MAP=0
declare -A MAP_RATIFIED_MEMO

# Classify a story for the ADR-090 RFC-markdown rule. Sets RFC_MD_BUCKET to one
# of: approved | unratified | no-map | unresolved-map.
#
# Sets a global rather than echoing so the memo survives: a $(...) call runs in a
# subshell and every MAP_RATIFIED_MEMO write inside one is discarded, which would
# re-hash the same handful of maps once per claim.
#
# `story_is_approved` is false for three different reasons and only ONE of them
# is a correct absence, so this asks the lib's accessors directly instead of
# taking the verdict alone.
_rfc_md_bucket() {
  local sf="$1" ids id m verdict
  RFC_MD_BUCKET=approved
  ids="$(story_declared_maps "$sf")"
  if [ -z "$ids" ]; then RFC_MD_BUCKET=no-map; return 0; fi
  for id in $ids; do
    if ! m="$(story_map_file "$id" "$MAPS_DIR")"; then
      RFC_MD_BUCKET=unresolved-map; return 0
    fi
    verdict="${MAP_RATIFIED_MEMO[$m]:-}"
    if [ -z "$verdict" ]; then
      if is_story_map_ratified "$m"; then verdict=yes; else verdict=no; fi
      MAP_RATIFIED_MEMO["$m"]="$verdict"
    fi
    if [ "$verdict" != yes ]; then RFC_MD_BUCKET=unratified; return 0; fi
  done
  return 0
}

reverse_trace_pass() {
  local parent_dir="$1" parent_kind="$2" parent_id_pattern="$3"
  local -a matches=()
  local pfile row_json
  [ ! -d "$parent_dir" ] && return 0

  shopt -s nullglob globstar
  # Extract frontmatter trace claims from each story and verify parents
  # carry the matching ## Stories row.
  for sf in "$STORIES_DIR"/*/STORY-[0-9][0-9][0-9]-*.md; do
    sbase="$(basename "$sf")"
    snum="${sbase#STORY-}"; snum="${snum%%-*}"
    sid="STORY-${snum}"
    sstatus="${FS_STATUS[$sid]:-missing}"

    # Parse the frontmatter parent list ($parent_kind = problems|rfcs|jtbd)
    parent_claims=$(awk -v k="^${parent_kind}:" '$0 ~ k {gsub(/[][]/,""); gsub(/,/," "); for(i=2;i<=NF;i++)print $i; exit}' "$sf")
    for pid in $parent_claims; do
      # Resolve parent file under parent_dir
      matches=()
      case "$parent_kind" in
        problems)
          pnum="${pid#P}"
          matches=("$parent_dir"/${pnum}-*.md "$parent_dir"/*/${pnum}-*.md)
          ;;
        rfcs)
          matches=("$parent_dir"/${pid}-*.md)
          ;;
        jtbd)
          matches=("$parent_dir"/*/${pid}-*.md)
          ;;
        *) matches=() ;;
      esac
      pfile="${matches[0]:-}"

      # ADR-103: a release row may be the RFC, so no markdown parent exists.
      # In that case the map row itself is the reverse trace and must contain
      # this story. Query the canonical map island rather than scraping HTML.
      if [ "$parent_kind" = rfcs ] && [ -z "$pfile" ]; then
        row_json=$("$HERE/story-map-query.sh" find-rfc "$pid" --maps-dir "$MAPS_DIR" 2>/dev/null || true)
        if [ -z "$row_json" ] || [ "$row_json" = "[]" ]; then
          DRIFT_LINES+=("UNRESOLVED_RFC_TRACE ${sid} claims=${pid}")
        elif ! grep -qF "\"${sid}\"" <<< "$row_json"; then
          DRIFT_LINES+=("MISSING_REVERSE_TRACE ${sid} in ${pid} release row")
        fi
        continue
      fi

      [ -z "$pfile" ] && continue

      # ADR-090 / ADR-103: an RFC references only approved stories, so an
      # unapproved story's absence from this section is correct, not drift.
      # Only the markdown-RFC leg is narrowed — the release-row branch above
      # has already returned.
      if [ "$parent_kind" = rfcs ]; then
        _rfc_md_bucket "$sf"
        case "$RFC_MD_BUCKET" in
          approved)       RFC_MD_CHECKED=$((RFC_MD_CHECKED + 1)) ;;
          unratified)     RFC_MD_SKIP_UNRATIFIED=$((RFC_MD_SKIP_UNRATIFIED + 1)); continue ;;
          no-map)         RFC_MD_SKIP_NO_MAP=$((RFC_MD_SKIP_NO_MAP + 1)); continue ;;
          unresolved-map) RFC_MD_SKIP_UNRESOLVED_MAP=$((RFC_MD_SKIP_UNRESOLVED_MAP + 1)); continue ;;
        esac
      fi

      # Check parent's ## Stories section contains this story's ID
      if ! awk '/^## Stories/{flag=1; next} /^## /{flag=0} flag{print}' "$pfile" | grep -qF "$sid"; then
        DRIFT_LINES+=("MISSING_REVERSE_TRACE ${sid} in ${pid} ## Stories")
      fi
    done
  done
  shopt -u nullglob globstar
}

reverse_trace_pass "$PROBLEMS_DIR" "problems" "P[0-9]{3}"
reverse_trace_pass "$RFCS_DIR" "rfcs" "RFC-[0-9]{3}"
reverse_trace_pass "$JTBD_DIR" "jtbd" "JTBD-[0-9]{3}"

# ── Say which population the RFC leg checked ────────────────────────────────
#
# On stderr, so stdout stays drift-lines-only for the skill's line-by-line
# parse. Printed whether or not there is drift: a clean result that never says
# what it covered is the same defect this leg was narrowed to fix. Skip lines
# are suppressed at zero — the checked-of-total line already carries that.

if [ -d "$RFCS_DIR" ]; then
  rfc_md_total=$(( RFC_MD_CHECKED + RFC_MD_SKIP_UNRATIFIED + RFC_MD_SKIP_NO_MAP + RFC_MD_SKIP_UNRESOLVED_MAP ))
  echo "reconcile-stories: RFC ## Stories reverse trace checked ${RFC_MD_CHECKED} of ${rfc_md_total} story/RFC pairs." >&2
  [ "$RFC_MD_SKIP_UNRATIFIED" -gt 0 ] && \
    echo "reconcile-stories:   ${RFC_MD_SKIP_UNRATIFIED} skipped because the story's map is not ratified, so the row is correctly absent." >&2
  [ "$RFC_MD_SKIP_NO_MAP" -gt 0 ] && \
    echo "reconcile-stories:   ${RFC_MD_SKIP_NO_MAP} skipped because the story names no story map at all; that is a corpus defect, not a correct absence." >&2
  [ "$RFC_MD_SKIP_UNRESOLVED_MAP" -gt 0 ] && \
    echo "reconcile-stories:   ${RFC_MD_SKIP_UNRESOLVED_MAP} skipped because the story names a map id that does not resolve to exactly one file; also a corpus defect." >&2
fi

# ── Emit ─────────────────────────────────────────────────────────────────────

if [ ${#DRIFT_LINES[@]} -eq 0 ]; then
  exit 0
fi

printf '%s\n' "${DRIFT_LINES[@]}"
exit 1
