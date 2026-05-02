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
# Files at >= 2.0x the threshold also emit a second line that promotes
# ADR-040's reassessment trigger ("≥ 3 topic files exceed 2× the
# configured ceiling for ≥ 2 consecutive retro cycles") from
# policy-revisit-time to per-cycle enforcement on the same threshold:
#   MUST_SPLIT <basename> reason=<code>
#
# The MUST_SPLIT line is the "no defer" signal: run-retro Step 3 Tier 3
# silent-agent rotation is forced to pick split-by-subtopic /
# split-by-date for these files (the trim-noise / leave-as-is fall-
# throughs are not eligible). See P145.
#
# Output ordering (deterministic for stable retro-summary diffs):
#   1. All OVER lines, sorted by basename.
#   2. Then all MUST_SPLIT lines, sorted by basename.
#
# Output is empty (no lines) when no topic files exceed the threshold.
# README.md is excluded from the scan — it is Tier 2, not Tier 3.
#
# Read-only — does NOT mutate any briefing file. Rotation is surfaced
# to the user via run-retro Step 3.
#
# @problem P099 (initial OVER advisory)
# @problem P145 (MUST_SPLIT escalation — closes the defer-recurrence gap)
# @adr ADR-040 (Session-start briefing surface — Tier 3 budget; this
#   script promotes Tier 3 from informational to advisory enforcement;
#   MUST_SPLIT promotes the 2× reassessment trigger to per-cycle)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-013 (Rule 1 / Rule 6 — interactive vs AFK)
# @adr ADR-044 (Decision-delegation contract — MUST_SPLIT is framework-
#   resolved removal of the do-nothing options when ratio is decisive)
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

# Pass 1: emit OVER lines for every file at or above threshold.
# Track MUST_SPLIT candidates (ratio >= 2.0x) for pass 2.
declare -a must_split=()
for entry in "${sorted[@]}"; do
  base="${entry% *}"
  bytes="${entry##* }"
  if [ "$bytes" -ge "$THRESHOLD" ]; then
    echo "OVER $base bytes=$bytes threshold=$THRESHOLD"
    # Integer-arithmetic ratio test: bytes >= 2 * threshold.
    # Avoids float math; exact at the 2.0x boundary per ADR-040
    # reassessment trigger.
    if [ "$bytes" -ge "$(( THRESHOLD * 2 ))" ]; then
      must_split+=("$base")
    fi
  fi
done

# Pass 2: emit MUST_SPLIT lines (already sorted by pass-1 traversal order
# which is basename-sorted).
for base in "${must_split[@]}"; do
  echo "MUST_SPLIT $base reason=ratio-exceeds-2x"
done

exit 0
