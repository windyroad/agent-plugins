#!/usr/bin/env bash
# packages/retrospective/scripts/check-tickets-deferred-cause.sh
#
# Diagnose-only advisory script for Step 4b Stage 1's "Tickets Deferred"
# fallback (P148). Walks docs/retros/*.md retro summary files, parses the
# `### Tickets Deferred` table in each, and counts entries whose `Cause`
# column is not in the allowlist `{skill_unavailable}`. Emits one line
# per retro file plus a trailing TOTAL summary line.
#
# Exit code is always 0 — the script is advisory per ADR-040
# declarative-first / ADR-013 Rule 6 fail-safe. Violation count is
# emitted as data on stdout; downstream consumers (retro summary
# rendering, future enforcement-hook escalation per P135 R6 trajectory)
# decide whether to act on the count.
#
# Usage:
#   check-tickets-deferred-cause.sh [<retros-dir>]
#
# Default <retros-dir> is ./docs/retros.
#
# Exit codes:
#   0 = always (advisory only — count is signal, not failure)
#   2 = parse error (retros dir missing or unreadable)
#
# Output format (one line per retro file with a Tickets Deferred section,
# oldest first by date prefix):
#   RETRO <YYYY-MM-DD> file=<basename> deferred=<N> with_valid_cause=<M> violations=<K>
#
# Plus a trailing TOTAL line summarising the window:
#   TOTAL files=<N> deferred=<N> with_valid_cause=<M> violations=<K>
#
# Output is empty (no lines) when no retro files contain a Tickets
# Deferred section — this is the expected steady state when Stage 1
# ticketing is firing as designed.
#
# Tickets Deferred table shape (per run-retro SKILL.md Step 5 template):
#
#   ### Tickets Deferred
#
#   | Observation | Cause | Citation |
#   |-------------|-------|----------|
#   | <text> | `skill_unavailable` | <text> |
#
# The script tolerates:
#   - Cause values wrapped in backticks or bold markers
#   - Missing Cause column entirely (treated as a violation)
#   - Out-of-allowlist cause values (treated as a violation)
#   - Empty Cause cell (treated as a violation)
#
# Read-only — does NOT mutate any retro file.
#
# @problem P148 (Agent defers ticket creation — broadens Stage 1 fallback gate)
# @problem P145 (Sibling defer-pattern at Tier 3 rotation — same class of behaviour)
# @adr ADR-044 (Decision-Delegation Contract — framework-resolution boundary)
# @adr ADR-040 (Tier 3 advisory-not-fail-closed — declarative-first precedent)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — advisory script never blocks AFK)
# @adr ADR-005 / ADR-037 (Plugin testing strategy — behavioural tests)
# @jtbd JTBD-001 (enforce governance without slowing down)
# @jtbd JTBD-006 (progress backlog while AFK — anti-defer is the load-bearing job)
# @jtbd JTBD-201 (audit trail for AI-assisted work — Cause field IS the audit trail)

set -uo pipefail

RETROS_DIR="${1:-docs/retros}"

# Allowlist — single source of truth for valid Cause values. The
# allowlist intentionally has ONE entry. Adding entries requires a
# matching SKILL.md AFK-branch update (and ideally a sibling ADR).
ALLOWLIST_CAUSES=("skill_unavailable")

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$RETROS_DIR" ]; then
  echo "check-tickets-deferred-cause: retros dir not found: $RETROS_DIR" >&2
  exit 2
fi

# ── Scan ────────────────────────────────────────────────────────────────────
# Iterate retro summary files at the top level of RETROS_DIR. Skip
# ask-hygiene trail files (those are check-ask-hygiene.sh's surface);
# skip context-analysis files. Glob expansion uses a portable for-loop
# (P124 lesson — `shopt -s nullglob` is bash-only).

retro_files=()
for path in "$RETROS_DIR"/*.md; do
  [ -e "$path" ] || continue
  # Skip non-summary files
  basename="$(basename "$path")"
  case "$basename" in
    *-ask-hygiene.md) continue ;;
    *-context-analysis.md) continue ;;
    *)
      # Only consider files whose basename starts with a YYYY-MM-DD date prefix
      if [[ "$basename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        retro_files+=("$path")
      fi
      ;;
  esac
done

if [ "${#retro_files[@]}" -eq 0 ]; then
  exit 0
fi

# Sort by basename date prefix, oldest first
IFS=$'\n' sorted_files=($(printf '%s\n' "${retro_files[@]}" | sort))
unset IFS

# ── Helpers ─────────────────────────────────────────────────────────────────

extract_date() {
  local basename
  basename="$(basename "$1")"
  # Take the leading YYYY-MM-DD prefix
  echo "${basename:0:10}"
}

# Determine if a cause value is in the allowlist
is_valid_cause() {
  local raw="$1"
  # Strip backticks, bold asterisks, and surrounding whitespace
  local cleaned
  cleaned=$(echo "$raw" | sed 's/`//g' | sed 's/\*\*//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  if [ -z "$cleaned" ]; then
    return 1
  fi
  for allowed in "${ALLOWLIST_CAUSES[@]}"; do
    if [ "$cleaned" = "$allowed" ]; then
      return 0
    fi
  done
  return 1
}

# Parse a single retro file's Tickets Deferred section. Sets the global
# variables `parsed_deferred`, `parsed_valid`, `parsed_violations` for
# the caller to read.
parse_retro_file() {
  local path="$1"
  parsed_deferred=0
  parsed_valid=0
  parsed_violations=0

  # Extract the lines between `### Tickets Deferred` and the next `###`
  # heading (or EOF). awk's range pattern handles this idiomatically.
  local section
  section=$(awk '
    /^### Tickets Deferred[[:space:]]*$/ { in_section=1; next }
    in_section && /^### / { in_section=0 }
    in_section { print }
  ' "$path")

  if [ -z "$section" ]; then
    return 0
  fi

  # Walk the table rows. A table row starts with `|`, has at least 3
  # cells, and is not the header or separator row.
  while IFS= read -r line; do
    # Skip blank lines, prose, and non-table content
    [[ "$line" =~ ^\| ]] || continue
    # Skip the separator row (cells of dashes)
    [[ "$line" =~ ^\|[[:space:]]*-+[[:space:]]*\| ]] && continue
    # Skip the header row — detected by literal "Observation" in cell 1
    if [[ "$line" =~ ^\|[[:space:]]*Observation[[:space:]]*\| ]]; then
      continue
    fi
    # Skip the placeholder example row — detected by `<one-line` template marker
    if [[ "$line" =~ \<one-line\ observation\ summary\> ]]; then
      continue
    fi

    parsed_deferred=$(( parsed_deferred + 1 ))

    # Split the row into cells. The first cell is empty (leading `|`).
    # Use a perl-free awk split on `|`.
    local cause_cell
    cause_cell=$(echo "$line" | awk -F'|' '{print $3}')

    if [ -z "$cause_cell" ]; then
      # No Cause column at all — violation
      parsed_violations=$(( parsed_violations + 1 ))
      continue
    fi

    if is_valid_cause "$cause_cell"; then
      parsed_valid=$(( parsed_valid + 1 ))
    else
      parsed_violations=$(( parsed_violations + 1 ))
    fi
  done <<< "$section"
}

# ── Emit per-file lines ─────────────────────────────────────────────────────

total_files=0
total_deferred=0
total_valid=0
total_violations=0

for path in "${sorted_files[@]}"; do
  parse_retro_file "$path"
  if [ "$parsed_deferred" -eq 0 ]; then
    continue
  fi
  date=$(extract_date "$path")
  basename="$(basename "$path")"
  echo "RETRO $date file=$basename deferred=$parsed_deferred with_valid_cause=$parsed_valid violations=$parsed_violations"
  total_files=$(( total_files + 1 ))
  total_deferred=$(( total_deferred + parsed_deferred ))
  total_valid=$(( total_valid + parsed_valid ))
  total_violations=$(( total_violations + parsed_violations ))
done

# Emit TOTAL line when at least one file contributed
if [ "$total_files" -gt 0 ]; then
  echo "TOTAL files=$total_files deferred=$total_deferred with_valid_cause=$total_valid violations=$total_violations"
fi

exit 0
