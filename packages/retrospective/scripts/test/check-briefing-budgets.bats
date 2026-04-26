#!/usr/bin/env bats

# @problem P099 — docs/briefing/<topic>.md (Tier 3 of ADR-040) accumulates
# without rotation. ADR-040 names a 2-5 KB / topic ceiling but the budget
# was informational only. P099 promotes Tier 3 to advisory enforcement: a
# read-only diagnostic script surfaces topic files over the configured
# ceiling so run-retro Step 3 can route them through the rotation
# AskUserQuestion (interactive) or defer to the retro summary (AFK).
#
# Contract: `check-briefing-budgets.sh [<briefing-dir>]` is a diagnose-only
# advisory script. It walks `<briefing-dir>/<topic>.md` files (default
# `docs/briefing`), measures byte size per file, and reports each topic
# file whose size is at or above the threshold (default 5120 bytes,
# overridable via BRIEFING_TIER3_MAX_BYTES env var).
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
# The script is read-only — it does NOT mutate any briefing file.
# Rotation candidates are surfaced to the user via run-retro Step 3
# (AskUserQuestion interactive path or retro-summary AFK fallback).
#
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK-safe advisory)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — read-only,
#   no interactive friction on the happy path; cost amortised across
#   every subsequent topic-file load)
# @jtbd JTBD-101 (Extend the Suite with Clear Patterns — reusable
#   advisory-script + bats + ADR-amendment shape for accumulator surfaces)
#
# Cross-reference:
#   P099: docs/problems/099-briefing-md-grows-unbounded-via-run-retro-appends-violating-progressive-disclosure.open.md
#   ADR-040 — Session-start briefing surface (Tier 3 budget; this script
#     promotes Tier 3 from informational to advisory enforcement)
#   ADR-038 — Progressive disclosure (per-row byte budget on diff output)
#   ADR-013 Rule 1 / Rule 6 — interactive AskUserQuestion path / AFK fallback
#   ADR-005 — Plugin testing strategy (script-level bats governance)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-briefing-budgets.sh"
  FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# Helper: write a markdown file with N bytes of body content. The header
# adds a small constant overhead; body fills to roughly the requested
# size so the total file size approximates the requested target.
write_briefing_entry() {
  local path="$1"
  local target_bytes="$2"
  : > "$path"
  printf '# Topic\n\n' >> "$path"
  local header_size=$(wc -c < "$path" | tr -d ' ')
  local body_target=$(( target_bytes - header_size ))
  if [ "$body_target" -gt 0 ]; then
    # Repeated 80-byte line keeps things readable
    local line="- entry text padded out to a known length for byte-budget testing.   "
    local line_size=${#line}
    line+=$'\n'
    local line_count=$(( (body_target + line_size) / (line_size + 1) ))
    local i=0
    while [ "$i" -lt "$line_count" ]; do
      printf '%s' "$line" >> "$path"
      i=$(( i + 1 ))
    done
  fi
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-briefing-budgets: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-briefing-budgets: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Default-threshold behaviour (5120 bytes per ADR-040 Tier 3 ceiling) ─────

@test "check-briefing-budgets: empty briefing dir produces no output and exits 0" {
  mkdir -p "$FIXTURE_DIR/briefing"
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-briefing-budgets: all files under threshold produces no output" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/small-topic.md" 1024
  write_briefing_entry "$FIXTURE_DIR/briefing/medium-topic.md" 3000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-briefing-budgets: file over threshold emits OVER line with bytes + threshold" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/bloated-topic.md" 10000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER bloated-topic.md bytes=[0-9]+ threshold=5120$"
}

@test "check-briefing-budgets: file exactly at threshold emits OVER (>= boundary)" {
  mkdir -p "$FIXTURE_DIR/briefing"
  # Create a file exactly 5120 bytes
  printf '%.0s.' $(seq 1 5120) > "$FIXTURE_DIR/briefing/edge.md"
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER edge.md bytes=5120 threshold=5120$"
}

@test "check-briefing-budgets: only over-threshold files appear in output" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/under.md" 2000
  write_briefing_entry "$FIXTURE_DIR/briefing/over-one.md" 8000
  write_briefing_entry "$FIXTURE_DIR/briefing/over-two.md" 12000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  # Both over-files present
  echo "$output" | grep -E "^OVER over-one.md bytes=[0-9]+ threshold=5120$"
  echo "$output" | grep -E "^OVER over-two.md bytes=[0-9]+ threshold=5120$"
  # Under-file absent
  ! echo "$output" | grep -q "under.md"
}

@test "check-briefing-budgets: README.md is excluded from the scan (Tier 2 not Tier 3)" {
  mkdir -p "$FIXTURE_DIR/briefing"
  # Bloated README that would otherwise trip the threshold
  write_briefing_entry "$FIXTURE_DIR/briefing/README.md" 20000
  write_briefing_entry "$FIXTURE_DIR/briefing/topic.md" 3000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Configurable threshold via env var ──────────────────────────────────────

@test "check-briefing-budgets: BRIEFING_TIER3_MAX_BYTES env var overrides default" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/topic.md" 3000
  # Default 5120: under threshold, no output. With env var set to 2000:
  # over threshold, expect OVER line.
  BRIEFING_TIER3_MAX_BYTES=2000 run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER topic.md bytes=[0-9]+ threshold=2000$"
}

@test "check-briefing-budgets: env var threshold of 0 emits every file (sanity)" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/a.md" 100
  write_briefing_entry "$FIXTURE_DIR/briefing/b.md" 200
  BRIEFING_TIER3_MAX_BYTES=0 run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OVER a.md "
  echo "$output" | grep -q "OVER b.md "
}

# ── Argument and error handling ─────────────────────────────────────────────

@test "check-briefing-budgets: defaults to docs/briefing when no arg provided" {
  cd "$FIXTURE_DIR"
  mkdir -p docs/briefing
  write_briefing_entry "docs/briefing/big.md" 10000
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER big.md bytes=[0-9]+ threshold=5120$"
}

@test "check-briefing-budgets: missing briefing dir exits 2 with parse error on stderr" {
  run "$SCRIPT" "$FIXTURE_DIR/does-not-exist"
  [ "$status" -eq 2 ]
  echo "$output" | grep -iE "not found|missing|does not exist"
}

@test "check-briefing-budgets: ignores non-markdown files in the briefing dir" {
  mkdir -p "$FIXTURE_DIR/briefing"
  # Bloated non-markdown (e.g. a stray log) should not trip the scan
  printf '%.0s.' $(seq 1 20000) > "$FIXTURE_DIR/briefing/stray.txt"
  write_briefing_entry "$FIXTURE_DIR/briefing/topic.md" 1000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Output stability ────────────────────────────────────────────────────────

@test "check-briefing-budgets: output is sorted by filename for stable diffs" {
  mkdir -p "$FIXTURE_DIR/briefing"
  write_briefing_entry "$FIXTURE_DIR/briefing/zebra.md" 8000
  write_briefing_entry "$FIXTURE_DIR/briefing/alpha.md" 8000
  write_briefing_entry "$FIXTURE_DIR/briefing/middle.md" 8000
  run "$SCRIPT" "$FIXTURE_DIR/briefing"
  [ "$status" -eq 0 ]
  # First line is alpha, last is zebra
  first_line=$(echo "$output" | head -1)
  last_line=$(echo "$output" | tail -1)
  echo "$first_line" | grep -q "alpha.md"
  echo "$last_line" | grep -q "zebra.md"
}
