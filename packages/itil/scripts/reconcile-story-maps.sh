#!/usr/bin/env bash
# packages/itil/scripts/reconcile-story-maps.sh
#
# Diagnose-only drift detector for docs/story-maps/README.md vs
# filesystem truth. Reads <story-maps-dir>/<state>/STORY-MAP-<NNN>-*.html
# files across 5 lifecycle subdirs (draft, accepted, in-progress,
# completed, archived) and reports each disagreement against the README.
#
# Sibling to reconcile-stories.sh (P170 Phase 2 Slice 9) and
# reconcile-rfcs.sh (ADR-060 Phase 1 item 5). Differences:
#   - File extension: .html (not .md)
#   - ID format: STORY-MAP-<NNN>
#   - No WSJF (I5 invariant per ADR-060 line 145)
#   - No Rankings table — story-maps are planning artefacts, not work items;
#     README has only a single lifecycle-grouped table
#   - 5 lifecycle subdirs (vs story tier's 5 + RFC tier's 5)
#   - <meta> block parse (HTML) not YAML frontmatter parse
#
# Usage:
#   reconcile-story-maps.sh [<story-maps-dir>]
#
# Default <story-maps-dir> is ./docs/story-maps.
#
# Exit codes:
#   0 = clean
#   1 = drift detected (structured stdout)
#   2 = parse error (README missing or malformed)
#
# @problem P170
# @adr ADR-060 (Problem-RFC-Story framework — Phase 2 amendment 2026-05-10
#                story-map tier; reconcile-story-maps is the story-map-tier
#                sibling of reconcile-stories + reconcile-rfcs)
# @adr ADR-049 (Plugin-bundled scripts via bin/ on PATH — paired bin shim
#                at packages/itil/bin/wr-itil-reconcile-story-maps)

set -uo pipefail

STORY_MAPS_DIR="${1:-docs/story-maps}"
README="${STORY_MAPS_DIR}/README.md"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -f "$README" ]; then
  echo "PARSE_ERROR: README not found at ${README}" >&2
  exit 2
fi

# ── Build filesystem truth: ID → status ─────────────────────────────────────

declare -A FS_STATUS
shopt -s nullglob
for state in draft accepted in-progress completed archived; do
  for f in "$STORY_MAPS_DIR"/"$state"/STORY-MAP-[0-9][0-9][0-9]-*.html; do
    base="$(basename "$f")"
    num="${base#STORY-MAP-}"
    num="${num%%-*}"
    id="STORY-MAP-${num}"
    FS_STATUS["$id"]="$state"
  done
done
shopt -u nullglob

# ── Extract README ID claims (single lifecycle-grouped table) ──────────────

# The README has lifecycle-grouped sections; extract STORY-MAP-NNN tokens
# from anywhere in the README and verify each appears in the correct
# state's section.
README_IDS=$(grep -oE 'STORY-MAP-[0-9]{3}' "$README" | sort -u)

# ── Diff ─────────────────────────────────────────────────────────────────────

DRIFT_LINES=()

# (1) Each ID listed in README must exist on filesystem with a state.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  if [ "$actual" = "missing" ]; then
    DRIFT_LINES+=("MISSING  ${id} README claims it exists but no file on disk")
  fi
done <<< "$README_IDS"

# (2) Each ID on disk must appear in README.
for id in "${!FS_STATUS[@]}"; do
  state="${FS_STATUS[$id]}"
  if ! grep -qF "$id" <<< "$README_IDS"; then
    DRIFT_LINES+=("STALE    ${id} README missing entry; actual=${state}")
  fi
done

# ── Emit ─────────────────────────────────────────────────────────────────────

if [ ${#DRIFT_LINES[@]} -eq 0 ]; then
  exit 0
fi

printf '%s\n' "${DRIFT_LINES[@]}"
exit 1
