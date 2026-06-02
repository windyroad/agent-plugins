#!/usr/bin/env bash
# packages/itil/scripts/reconcile-rfcs.sh
#
# Diagnose-only drift detector for docs/rfcs/README.md vs filesystem
# truth. Reads <rfcs-dir>/RFC-<NNN>-*.<status>.md, parses the README's
# WSJF Rankings + Verification Queue + Closed tables, and reports each
# disagreement.
#
# Usage:
#   reconcile-rfcs.sh [<rfcs-dir> [<problems-dir>]]
#
# Default <rfcs-dir> is ./docs/rfcs.
# Default <problems-dir> is ./docs/problems (when supplied; absent dir
# silently skips the reverse-trace pass per backward-compat carve-out).
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
# Reverse-trace pass (B5.T8 — closes ADR-060 Confirmation criterion 3):
# When <problems-dir> is provided AND on disk, the reconciler also
# checks the auto-maintained `## RFCs` section on each problem ticket
# against the RFC frontmatter `problems:` claims. Three drift kinds:
#   MISSING_REVERSE_TRACE  RFC-<NNN> in P<NNN> ## RFCs
#     RFC's frontmatter claims P<NNN> but P<NNN>'s ## RFCs table does
#     not list RFC-<NNN>. Skill-side refresh contract was missed.
#   STALE_REVERSE_TRACE    RFC-<NNN> in P<NNN> ## RFCs
#     P<NNN>'s ## RFCs lists RFC-<NNN> but the RFC frontmatter no
#     longer claims P<NNN>. Re-trace bookkeeping was missed.
#   STATUS_MISMATCH        RFC-<NNN> in P<NNN> ## RFCs claims=<X> actual=<Y>
#     P<NNN>'s ## RFCs row claims status <X> but RFC's filesystem
#     suffix is <Y>. Status-column refresh contract was missed.
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
# Default PROBLEMS_DIR to the sibling of RFCS_DIR (so real-use
# `docs/rfcs` → `docs/problems`, and fixture-isolated test runs in
# `/tmp/X` → `/tmp/problems` which won't exist, gracefully skipping
# reverse-trace). Backward-compat: existing 18-case bats fixtures
# stay clean because `dirname /tmp/<rand>` = `/tmp`, never colliding
# with the real repo's `docs/problems`.
PROBLEMS_DIR="${2:-$(dirname "$RFCS_DIR")/problems}"
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

# ── Reverse-trace pass (B5.T8) ──────────────────────────────────────────────
# When PROBLEMS_DIR exists, validate that each problem ticket's auto-
# maintained `## RFCs` section agrees with the corresponding RFC
# frontmatter `problems:` claims (and vice-versa).

if [ -d "$PROBLEMS_DIR" ]; then
  # rfc_problems_claim["RFC-NNN"] = "P168 P169 ..."
  declare -A rfc_problems_claim
  shopt -s nullglob
  for f in "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.md; do
    base="$(basename "$f")"
    num="${base#RFC-}"
    num="${num%%-*}"
    rfc_id="RFC-${num}"
    # Parse YAML frontmatter `problems: [P168, P169]` (single line).
    raw=$(awk '/^problems:/ { print; exit }' "$f")
    # Strip everything except inside-brackets bare comma-separated content.
    inner=$(echo "$raw" | sed -E 's/^[[:space:]]*problems:[[:space:]]*\[//; s/\][[:space:]]*$//')
    # Tokenise on commas, normalise to bare P<NNN> tokens.
    pids=""
    if [ -n "$inner" ]; then
      while IFS= read -r tok; do
        tok=$(echo "$tok" | tr -d ' "'\''')
        case "$tok" in
          P[0-9][0-9][0-9]) pids="${pids:+$pids }$tok" ;;
        esac
      done <<< "$(echo "$inner" | tr ',' '\n')"
    fi
    rfc_problems_claim["$rfc_id"]="$pids"
  done
  shopt -u nullglob

  # problem_rfc_rows["P168 RFC-001"] = "<claimed-status>"
  # problem_rfc_ids["P168"] = "RFC-001 RFC-002 ..."
  declare -A problem_rfc_rows
  declare -A problem_rfc_ids
  # P312 / ADR-031: scan both flat docs/problems/<NNN>-*.md AND per-state
  # subdir docs/problems/<state>/<NNN>-*.md layouts so the reverse-trace
  # remains valid post-migration. Mirrors reconcile-readme.sh lines 74-110.
  shopt -s nullglob
  problem_files=( "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.md )
  for ticket_status in open known-error verifying closed parked; do
    problem_files+=( "$PROBLEMS_DIR"/"$ticket_status"/[0-9][0-9][0-9]-*.md )
  done
  shopt -u nullglob
  for pf in "${problem_files[@]}"; do
    pbase="$(basename "$pf")"
    pnum="${pbase%%-*}"
    pid="P${pnum}"
    # Locate `## RFCs` section start (if any).
    sec_start=$(awk 'BEGIN{flag=0} /^## RFCs[[:space:]]*$/ {print NR; exit}' "$pf")
    [ -z "$sec_start" ] && continue
    # Read until next `## ` header or EOF; extract `| RFC-NNN | <status> | ...|` rows.
    rfcs_in_p=""
    while IFS= read -r line; do
      case "$line" in
        \|*RFC-[0-9][0-9][0-9]*\|*)
          rid=$(echo "$line" | grep -oE 'RFC-[0-9]{3}' | head -1)
          claimed=$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); print $3}')
          [ -z "$rid" ] && continue
          problem_rfc_rows["${pid} ${rid}"]="$claimed"
          rfcs_in_p="${rfcs_in_p:+$rfcs_in_p }$rid"
          ;;
      esac
    done < <(awk -v start="$sec_start" 'NR>start { if (/^## /) exit; print }' "$pf")
    problem_rfc_ids["$pid"]="$rfcs_in_p"
  done

  # 1. MISSING_REVERSE_TRACE: RFC claims P, P does not list RFC.
  for rfc_id in "${!rfc_problems_claim[@]}"; do
    pids="${rfc_problems_claim[$rfc_id]}"
    [ -z "$pids" ] && continue
    for pid in $pids; do
      listed="${problem_rfc_ids[$pid]:-}"
      case " $listed " in
        *" $rfc_id "*) : ;;
        *)
          DRIFT_LINES+=("MISSING_REVERSE_TRACE  ${rfc_id} in ${pid} ## RFCs")
          ;;
      esac
    done
  done

  # 2. STALE_REVERSE_TRACE: P lists RFC, RFC frontmatter does not claim P.
  #    STATUS_MISMATCH: P's row claims status X but RFC suffix is Y.
  for pid in "${!problem_rfc_ids[@]}"; do
    rids="${problem_rfc_ids[$pid]}"
    [ -z "$rids" ] && continue
    for rid in $rids; do
      claimed_pids="${rfc_problems_claim[$rid]:-}"
      case " $claimed_pids " in
        *" $pid "*)
          # Status-mismatch check (only when reverse-trace is itself current).
          claimed_status="${problem_rfc_rows[${pid} ${rid}]:-}"
          actual_status="${FS_STATUS[$rid]:-missing}"
          if [ -n "$claimed_status" ] && [ "$claimed_status" != "$actual_status" ]; then
            DRIFT_LINES+=("STATUS_MISMATCH        ${rid} in ${pid} ## RFCs claims=${claimed_status} actual=${actual_status}")
          fi
          ;;
        *)
          DRIFT_LINES+=("STALE_REVERSE_TRACE    ${rid} in ${pid} ## RFCs")
          ;;
      esac
    done
  done
fi

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
