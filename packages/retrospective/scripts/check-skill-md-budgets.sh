#!/usr/bin/env bash
# packages/retrospective/scripts/check-skill-md-budgets.sh
#
# Diagnose-only advisory script for SKILL.md byte budgets per ADR-054.
# Walks `<root-dir>/packages/*/skills/*/SKILL.md` and
# `<root-dir>/.claude/skills/*/SKILL.md`, measures byte size per file, and
# reports each SKILL.md exceeding the WARN threshold so retro Step 2b can
# surface the rotation candidate (interactive) or defer to retro summary
# (AFK).
#
# Usage:
#   check-skill-md-budgets.sh [<root-dir>]
#
# Default <root-dir> is `.`.
# Thresholds:
#   WARN ≥ SKILL_MD_WARN_BYTES (default 8192)
#   MUST_SPLIT ≥ SKILL_MD_MUST_SPLIT_BYTES (default 16384)
#
# Exit codes:
#   0 = always (advisory only — overflow is signal, not failure)
#   2 = parse error (root dir missing or unreadable)
#
# Output format on overflow (one line per file, terse machine-readable
# per ADR-038 progressive-disclosure budget):
#   OVER <plugin>/<skill> bytes=<N> threshold=<N>
#
# Files at >= MUST_SPLIT also emit a second line:
#   MUST_SPLIT <plugin>/<skill> reason=<code>
#
# This mirrors the OVER / MUST_SPLIT pair shape from `check-briefing-budgets.sh`
# (P099 / P145 / ADR-040) deliberately so adopters learn one concept across
# two surfaces.
#
# Output ordering (deterministic for stable retro-summary diffs):
#   1. All OVER lines, sorted by `<plugin>/<skill>` identifier.
#   2. Then all MUST_SPLIT lines, sorted by identifier.
#
# Output is empty (no lines) when no SKILL.md exceeds the WARN threshold.
# REFERENCE.md sibling files (per ADR-054) are excluded from the scan —
# they are intentionally lazy-loaded and not subject to the runtime budget.
#
# Read-only — does NOT mutate any SKILL.md file.
#
# @problem P097 (initial advisory — SKILL.md runtime budget surface)
# @adr ADR-054 (SKILL.md runtime budget policy — taxonomy + sibling pattern + budget)
# @adr ADR-040 (Session-start briefing surface — Tier 3 OVER / MUST_SPLIT vocabulary precedent)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-052 (Behavioural-tests-default — fixture is behavioural)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-001 / JTBD-006 / JTBD-101

set -uo pipefail

ROOT_DIR="${1:-.}"
WARN_BYTES="${SKILL_MD_WARN_BYTES:-8192}"
MUST_SPLIT_BYTES="${SKILL_MD_MUST_SPLIT_BYTES:-16384}"

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$ROOT_DIR" ]; then
  echo "check-skill-md-budgets: root dir not found: $ROOT_DIR" >&2
  exit 2
fi

# ── Scan ────────────────────────────────────────────────────────────────────
# Collect SKILL.md paths from two surfaces:
#   1. <root>/packages/*/skills/*/SKILL.md
#   2. <root>/.claude/skills/*/SKILL.md
# REFERENCE.md siblings are NOT scanned (per ADR-054).

shopt -s nullglob
plugin_skills=("$ROOT_DIR"/packages/*/skills/*/SKILL.md)
local_skills=("$ROOT_DIR"/.claude/skills/*/SKILL.md)
shopt -u nullglob

if [ "${#plugin_skills[@]}" -eq 0 ] && [ "${#local_skills[@]}" -eq 0 ]; then
  exit 0
fi

# Build (identifier, bytes) pairs.
# Identifier shape:
#   plugin-skill: <plugin>/<skill> (e.g. "itil/manage-problem")
#   project-local: .claude/<skill> (e.g. ".claude/install-updates")
declare -a entries=()
for path in "${plugin_skills[@]}"; do
  # Path shape: <root>/packages/<plugin>/skills/<skill>/SKILL.md
  skill_dir="$(dirname "$path")"
  skill="$(basename "$skill_dir")"
  plugin="$(basename "$(dirname "$(dirname "$skill_dir")")")"
  identifier="$plugin/$skill"
  bytes=$(wc -c < "$path" | tr -d ' ')
  entries+=("$identifier $bytes")
done
for path in "${local_skills[@]}"; do
  # Path shape: <root>/.claude/skills/<skill>/SKILL.md
  skill_dir="$(dirname "$path")"
  skill="$(basename "$skill_dir")"
  identifier=".claude/$skill"
  bytes=$(wc -c < "$path" | tr -d ' ')
  entries+=("$identifier $bytes")
done

if [ "${#entries[@]}" -eq 0 ]; then
  exit 0
fi

# Sort entries by identifier for deterministic output
IFS=$'\n' sorted=($(printf '%s\n' "${entries[@]}" | sort))
unset IFS

# Pass 1: emit OVER lines for every file at or above WARN threshold.
# Track MUST_SPLIT candidates (>= MUST_SPLIT_BYTES) for pass 2.
declare -a must_split=()
for entry in "${sorted[@]}"; do
  identifier="${entry% *}"
  bytes="${entry##* }"
  if [ "$bytes" -ge "$WARN_BYTES" ]; then
    echo "OVER $identifier bytes=$bytes threshold=$WARN_BYTES"
    if [ "$bytes" -ge "$MUST_SPLIT_BYTES" ]; then
      must_split+=("$identifier")
    fi
  fi
done

# Pass 2: emit MUST_SPLIT lines (already in basename-sorted order from pass 1).
for identifier in "${must_split[@]}"; do
  echo "MUST_SPLIT $identifier reason=ratio-exceeds-must-split"
done

exit 0
