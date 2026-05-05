#!/usr/bin/env bash
# packages/itil/scripts/reconcile-rfcs.sh
#
# Diagnose-only drift detector for docs/rfcs/README.md vs filesystem
# truth. Reads <rfcs-dir>/RFC-<NNN>-*.<status>.md, parses the README's
# WSJF Rankings + Verification Queue + Closed tables, and reports each
# disagreement.
#
# Usage:
#   reconcile-rfcs.sh [<rfcs-dir>]
#
# Default <rfcs-dir> is ./docs/rfcs.
#
# Exit codes:
#   0 = clean (README matches filesystem)
#   1 = drift detected (structured diff to stdout)
#   2 = parse error (README missing or malformed)
#
# Output format on drift (one line per drift entry, ≤ 150 bytes per
# ADR-038 progressive-disclosure budget):
#   DRIFT    RFC-<NNN> wsjf-rankings: claims=<status> actual=<status>
#   MISSING  RFC-<NNN> wsjf-rankings: actual=<status>
#   STALE    RFC-<NNN> verification-queue: actual=<status>
#   MISMATCH RFC-<NNN> closed: actual=<status>
#
# Read-only — does NOT mutate the README. The /wr-itil:manage-rfc skill
# applies edits with narrative-aware preservation; this script's only
# job is to report ground truth.
#
# Sibling to packages/itil/scripts/reconcile-readme.sh (P118 / ADR-014):
# same parse + diff structure, applied at the RFC tier instead of the
# problems tier. Differences:
#   - Filename pattern: RFC-NNN-*.<status>.md (5 statuses: proposed,
#     accepted, in-progress, verifying, closed)
#   - ID format: RFC-<NNN> (vs P<NNN>)
#   - WSJF Rankings covers proposed/accepted/in-progress (RFC dev-work
#     queue per ADR-060 § Decisions Resolved — RFC-level WSJF, Phase 1)
#   - Verification Queue covers verifying (matches problem tier)
#   - Closed covers closed
#   - No Parked tier (RFCs don't have a Parked status per ADR-060;
#     only Problems do)
#
# @problem P170
# @adr ADR-060 (Problem-RFC-Story framework — Phase 1 item 5)
# @adr ADR-049 (Plugin script resolution via bin/ on PATH — paired bin shim)

set -uo pipefail

RFCS_DIR="${1:-docs/rfcs}"
README="${RFCS_DIR}/README.md"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -f "$README" ]; then
  echo "PARSE_ERROR: README not found at ${README}" >&2
  exit 2
fi

if ! grep -q '^## RFC Rankings\|^## WSJF Rankings' "$README"; then
  echo "PARSE_ERROR: '## RFC Rankings' or '## WSJF Rankings' header missing in ${README}" >&2
  exit 2
fi

# ── Build filesystem truth: ID → status ─────────────────────────────────────

declare -A FS_STATUS
shopt -s nullglob
for f in "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.proposed.md \
         "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.accepted.md \
         "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.in-progress.md \
         "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.verifying.md \
         "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.closed.md; do
  base="$(basename "$f")"
  # Extract NNN from RFC-NNN-...
  num="${base#RFC-}"
  num="${num%%-*}"
  id="RFC-${num}"
  case "$base" in
    *.proposed.md)     ticket_status="proposed" ;;
    *.accepted.md)     ticket_status="accepted" ;;
    *.in-progress.md)  ticket_status="in-progress" ;;
    *.verifying.md)    ticket_status="verifying" ;;
    *.closed.md)       ticket_status="closed" ;;
    *)                 continue ;;
  esac
  FS_STATUS["$id"]="$ticket_status"
done
shopt -u nullglob

# ── Parse README sections into ID buckets ───────────────────────────────────

# Accept either '## RFC Rankings' (this README's heading) or
# '## WSJF Rankings' (problems-tier-style heading) — the structural test
# is "is there a ranking section?" not "is the heading word-for-word".
WSJF_START=$(grep -nE '^## (RFC Rankings|WSJF Rankings)' "$README" | head -1 | cut -d: -f1)
VQ_START=$(grep -n '^## Verification Queue' "$README" | head -1 | cut -d: -f1)
CLOSED_START=$(grep -n '^## Closed' "$README" | head -1 | cut -d: -f1)
END_LINE=$(wc -l < "$README")

WSJF_END=${VQ_START:-${CLOSED_START:-$END_LINE}}
VQ_END=${CLOSED_START:-$END_LINE}
CLOSED_END=$END_LINE

extract_section_ids() {
  local start="$1" end="$2"
  [ -z "$start" ] && return 0
  sed -n "${start},${end}p" "$README" \
    | grep -oE '\| *RFC-[0-9]{3} *\|' \
    | grep -oE 'RFC-[0-9]{3}' \
    | sort -u
}

README_WSJF_IDS="$(extract_section_ids "$WSJF_START" "$WSJF_END")"
README_VQ_IDS="$(extract_section_ids "$VQ_START" "$VQ_END")"
README_CLOSED_IDS="$(extract_section_ids "$CLOSED_START" "$CLOSED_END")"

# ── Diff ─────────────────────────────────────────────────────────────────────

DRIFT_LINES=()

# (1) Each ID listed in RFC Rankings must be proposed/accepted/in-progress
#     on disk. Other statuses (verifying/closed) → drift.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    proposed|accepted|in-progress)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("DRIFT    ${id} wsjf-rankings: claims=open actual=${actual}")
      ;;
  esac
done <<< "$README_WSJF_IDS"

# (2) Each ID listed in Verification Queue must be verifying on disk.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    verifying)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("STALE    ${id} verification-queue: actual=${actual}")
      ;;
  esac
done <<< "$README_VQ_IDS"

# (3) Each ID listed in Closed section must be closed on disk.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    closed)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("MISMATCH ${id} closed: actual=${actual}")
      ;;
  esac
done <<< "$README_CLOSED_IDS"

# (4) Each filesystem RFC must appear in the right README section.
declare -A IN_WSJF
while read -r id; do
  [ -z "$id" ] && continue
  IN_WSJF["$id"]=1
done <<< "$README_WSJF_IDS"

declare -A IN_VQ
while read -r id; do
  [ -z "$id" ] && continue
  IN_VQ["$id"]=1
done <<< "$README_VQ_IDS"

for id in "${!FS_STATUS[@]}"; do
  ticket_status="${FS_STATUS[$id]}"
  case "$ticket_status" in
    proposed|accepted|in-progress)
      if [ -z "${IN_WSJF[$id]:-}" ]; then
        DRIFT_LINES+=("MISSING  ${id} wsjf-rankings: actual=${ticket_status}")
      fi
      ;;
    verifying)
      if [ -z "${IN_VQ[$id]:-}" ]; then
        DRIFT_LINES+=("MISSING  ${id} verification-queue: actual=${ticket_status}")
      fi
      ;;
    # closed: Closed section is curated narrative; absence is soft
    # drift not flagged at this layer (mirrors reconcile-readme).
  esac
done

# ── Report ──────────────────────────────────────────────────────────────────

if [ ${#DRIFT_LINES[@]} -eq 0 ]; then
  exit 0
fi

IFS=$'\n' sorted=($(printf '%s\n' "${DRIFT_LINES[@]}" | sort))
unset IFS
for line in "${sorted[@]}"; do
  printf '%s\n' "$line"
done
exit 1
