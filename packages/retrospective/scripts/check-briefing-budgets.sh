#!/usr/bin/env bash
# packages/retrospective/scripts/check-briefing-budgets.sh
#
# Diagnose-only advisory script for the docs/briefing/ tree (Tier 3 of
# ADR-040). Walks <briefing-dir>/<topic>.md files, measures byte size
# per file, and reports each topic file at or above the configured
# threshold so run-retro Step 3 can route them through the rotation
# AskUserQuestion (interactive) or defer to the retro summary (AFK).
#
# Usage:
#   check-briefing-budgets.sh [<briefing-dir>]
#
# Default <briefing-dir> is ./docs/briefing.
# Threshold is read from BRIEFING_TIER3_MAX_BYTES (default 5120 — the
# upper bound of ADR-040's stated "2-5 KB / topic" Tier 3 envelope).
#
# Exit codes:
#   0 = always (advisory only — overflow is signal, not failure)
#   2 = parse error (briefing dir missing or unreadable)
#
# Output format on overflow (one line per file, terse machine-readable
# per ADR-038 progressive-disclosure budget):
#   OVER <basename> bytes=<N> threshold=<N>
#
# Output is empty (no lines) when no topic files exceed the threshold.
# README.md is excluded from the scan — it is Tier 2, not Tier 3.
#
# Read-only — does NOT mutate any briefing file. Rotation is surfaced
# to the user via run-retro Step 3.
#
# @problem P099
# @adr ADR-040 (Session-start briefing surface — Tier 3 budget; this
#   script promotes Tier 3 from informational to advisory enforcement)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-013 (Rule 1 / Rule 6 — interactive vs AFK)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-001 / JTBD-006 / JTBD-101

set -uo pipefail

BRIEFING_DIR="${1:-docs/briefing}"
THRESHOLD="${BRIEFING_TIER3_MAX_BYTES:-5120}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$BRIEFING_DIR" ]; then
  echo "check-briefing-budgets: briefing dir not found: $BRIEFING_DIR" >&2
  exit 2
fi

# ── Scan ────────────────────────────────────────────────────────────────────
# Iterate markdown files at the top level of BRIEFING_DIR (not recursive).
# Sort by basename for stable diff output (per bats fixture contract).

shopt -s nullglob
files=("$BRIEFING_DIR"/*.md)
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

# Build (basename, bytes) pairs sorted by basename.
declare -a entries=()
for path in "${files[@]}"; do
  base="$(basename "$path")"
  # README.md is the Tier 2 index, not a Tier 3 topic file.
  if [ "$base" = "README.md" ]; then
    continue
  fi
  bytes=$(wc -c < "$path" | tr -d ' ')
  entries+=("$base $bytes")
done

# Sort entries by basename
IFS=$'\n' sorted=($(printf '%s\n' "${entries[@]}" | sort))
unset IFS

for entry in "${sorted[@]}"; do
  base="${entry% *}"
  bytes="${entry##* }"
  if [ "$bytes" -ge "$THRESHOLD" ]; then
    echo "OVER $base bytes=$bytes threshold=$THRESHOLD"
  fi
done

exit 0
