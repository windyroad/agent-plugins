#!/usr/bin/env bats

# @problem P097 — SKILL.md files mix runtime-necessary steps with maintainer-
#   facing rationale, bloating every skill invocation. ADR-054 codifies the
#   classification taxonomy ([runtime] / [reference] / [deprecated]), the
#   sibling REFERENCE.md lazy-load pattern, and the byte budgets (WARN ≥
#   8192, MUST_SPLIT ≥ 16384). This bats fixture covers the advisory
#   detector script that surfaces SKILL.md files exceeding the budget.
#
# Contract: `check-skill-md-budgets.sh [<root-dir>]` is a diagnose-only
# advisory script. It walks `<root-dir>/packages/*/skills/*/SKILL.md` and
# `<root-dir>/.claude/skills/*/SKILL.md` (default `<root-dir>` is `.`),
# measures byte size per file, and reports each SKILL.md whose size is at
# or above the WARN threshold (default 8192 bytes, overridable via
# SKILL_MD_WARN_BYTES env var).
#
# Exit codes:
#   0 = always (advisory only — overflow is signal, not failure)
#   2 = parse error (root dir missing or unreadable)
#
# Output format on overflow (one line per file, terse machine-readable
# per ADR-038 progressive-disclosure budget):
#   OVER <plugin>/<skill> bytes=<N> threshold=<N>
#
# Files at >= MUST_SPLIT (default 16384, overridable via SKILL_MD_MUST_SPLIT_BYTES)
# also emit a second line:
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
# Read-only — does NOT mutate any SKILL.md file. Extraction priority is
# surfaced to the maintainer; rotation is opportunistic per ADR-052
# migration shape.
#
# This fixture is BEHAVIOURAL per ADR-052 — it asserts script output on
# temp-fixture skill trees, NOT script source content. No greps of
# check-skill-md-budgets.sh source.
#
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — solo dev;
#   read-only, no interactive friction on the happy path)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK-safe advisory)
# @jtbd JTBD-101 (Extend the Suite with Clear Patterns — reusable
#   advisory-script + bats + ADR-amendment shape for context-budget surfaces)
#
# Cross-reference:
#   P097: docs/problems/097-skill-md-runtime-size-mixes-policy-with-runtime-steps.*.md
#   ADR-054 — SKILL.md runtime budget policy (taxonomy + sibling pattern + budget)
#   ADR-040 — Session-start briefing surface (Tier 3 OVER / MUST_SPLIT precedent)
#   ADR-038 — Progressive disclosure (per-row byte budget on diff output)
#   ADR-052 — Behavioural-tests-default (this fixture's pattern)
#   ADR-005 — Plugin testing strategy (script-level bats governance)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-skill-md-budgets.sh"
  FIXTURE_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_ROOT"
}

# Helper: write a SKILL.md with N bytes of body content under a fixture
# plugin/skill path. Creates the directory tree as needed.
write_skill() {
  local plugin="$1"
  local skill="$2"
  local target_bytes="$3"
  local skill_dir="$FIXTURE_ROOT/packages/$plugin/skills/$skill"
  mkdir -p "$skill_dir"
  local path="$skill_dir/SKILL.md"
  : > "$path"
  printf '# Skill\n\n' >> "$path"
  local header_size
  header_size=$(wc -c < "$path" | tr -d ' ')
  local body_target=$(( target_bytes - header_size ))
  if [ "$body_target" -gt 0 ]; then
    local line="- step text padded out to a known length for byte-budget testing.    "
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

# Helper: write a project-local SKILL.md under .claude/skills/<skill>/SKILL.md
# (the project-local skill surface, in scope per ADR-054 §Phase 1 deliverable).
write_local_skill() {
  local skill="$1"
  local target_bytes="$2"
  local skill_dir="$FIXTURE_ROOT/.claude/skills/$skill"
  mkdir -p "$skill_dir"
  local path="$skill_dir/SKILL.md"
  : > "$path"
  printf '# Skill\n\n' >> "$path"
  local header_size
  header_size=$(wc -c < "$path" | tr -d ' ')
  local body_target=$(( target_bytes - header_size ))
  if [ "$body_target" -gt 0 ]; then
    local line="- step text padded out to a known length for byte-budget testing.    "
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

@test "check-skill-md-budgets: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-skill-md-budgets: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Default-threshold behaviour (WARN 8192, MUST_SPLIT 16384) ───────────────

@test "check-skill-md-budgets: empty tree produces no output and exits 0" {
  mkdir -p "$FIXTURE_ROOT/packages"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-skill-md-budgets: all skills under WARN produces no output" {
  write_skill "alpha" "small" 1024
  write_skill "beta" "medium" 4096
  write_skill "gamma" "near-warn" 7000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-skill-md-budgets: skill at WARN band emits OVER line with bytes + threshold" {
  write_skill "alpha" "warn-band" 10000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/warn-band bytes=[0-9]+ threshold=8192$"
}

@test "check-skill-md-budgets: skill exactly at WARN threshold emits OVER (>= boundary)" {
  local skill_dir="$FIXTURE_ROOT/packages/alpha/skills/edge"
  mkdir -p "$skill_dir"
  printf '%.0s.' $(seq 1 8192) > "$skill_dir/SKILL.md"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/edge bytes=8192 threshold=8192$"
}

@test "check-skill-md-budgets: skill at WARN band but under MUST_SPLIT emits OVER only (no MUST_SPLIT)" {
  write_skill "alpha" "warn-only" 12000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/warn-only bytes=[0-9]+ threshold=8192"
  ! echo "$output" | grep -q "MUST_SPLIT"
}

@test "check-skill-md-budgets: skill at exactly MUST_SPLIT emits OVER + MUST_SPLIT" {
  local skill_dir="$FIXTURE_ROOT/packages/alpha/skills/exactly-must-split"
  mkdir -p "$skill_dir"
  printf '%.0s.' $(seq 1 16384) > "$skill_dir/SKILL.md"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/exactly-must-split bytes=16384 threshold=8192"
  echo "$output" | grep -E "^MUST_SPLIT alpha/exactly-must-split reason=ratio-exceeds-must-split$"
}

@test "check-skill-md-budgets: skill well over MUST_SPLIT emits both lines" {
  write_skill "alpha" "very-bloated" 80000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/very-bloated bytes=[0-9]+ threshold=8192"
  echo "$output" | grep -E "^MUST_SPLIT alpha/very-bloated reason=ratio-exceeds-must-split$"
}

@test "check-skill-md-budgets: only over-threshold skills appear in output" {
  write_skill "alpha" "under" 2000
  write_skill "beta" "over-warn" 10000
  write_skill "gamma" "over-must-split" 20000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER beta/over-warn bytes=[0-9]+ threshold=8192"
  echo "$output" | grep -E "^OVER gamma/over-must-split bytes=[0-9]+ threshold=8192"
  ! echo "$output" | grep -q "alpha/under"
}

# ── Sibling REFERENCE.md exclusion (ADR-054) ────────────────────────────────

@test "check-skill-md-budgets: REFERENCE.md sibling is excluded from the scan" {
  write_skill "alpha" "with-ref" 1000
  # Write a bloated REFERENCE.md that would otherwise trip MUST_SPLIT
  printf '%.0s.' $(seq 1 50000) > "$FIXTURE_ROOT/packages/alpha/skills/with-ref/REFERENCE.md"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # No output — only SKILL.md is measured, not REFERENCE.md
  [ -z "$output" ]
}

# ── Project-local .claude/skills discovery ──────────────────────────────────

@test "check-skill-md-budgets: .claude/skills/* SKILL.md files are scanned" {
  write_local_skill "install-updates" 12000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # The project-local prefix is .claude in the identifier
  echo "$output" | grep -E "^OVER .claude/install-updates bytes=[0-9]+ threshold=8192"
}

@test "check-skill-md-budgets: project-local + plugin-skill outputs both appear" {
  write_skill "alpha" "plugin-skill" 10000
  write_local_skill "local-skill" 12000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER .claude/local-skill"
  echo "$output" | grep -E "^OVER alpha/plugin-skill"
}

# ── Configurable thresholds via env vars ────────────────────────────────────

@test "check-skill-md-budgets: SKILL_MD_WARN_BYTES env var overrides default" {
  write_skill "alpha" "small-by-default" 4096
  # Default 8192: no output. With env var 2000: over threshold.
  SKILL_MD_WARN_BYTES=2000 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/small-by-default bytes=[0-9]+ threshold=2000"
}

@test "check-skill-md-budgets: SKILL_MD_MUST_SPLIT_BYTES env var overrides default" {
  write_skill "alpha" "moderate" 9000
  # Default WARN 8192: emits OVER. Default MUST_SPLIT 16384: no MUST_SPLIT.
  # With MUST_SPLIT override 8500: should emit MUST_SPLIT too.
  SKILL_MD_MUST_SPLIT_BYTES=8500 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/moderate"
  echo "$output" | grep -E "^MUST_SPLIT alpha/moderate reason=ratio-exceeds-must-split$"
}

@test "check-skill-md-budgets: env var threshold of 0 emits every skill (sanity)" {
  write_skill "alpha" "tiny-one" 100
  write_skill "beta" "tiny-two" 200
  SKILL_MD_WARN_BYTES=0 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OVER alpha/tiny-one"
  echo "$output" | grep -q "OVER beta/tiny-two"
}

# ── Argument and error handling ─────────────────────────────────────────────

@test "check-skill-md-budgets: defaults to current directory when no arg provided" {
  cd "$FIXTURE_ROOT"
  write_skill "alpha" "default-arg" 12000
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/default-arg bytes=[0-9]+ threshold=8192"
}

@test "check-skill-md-budgets: missing root dir exits 2 with parse error on stderr" {
  run "$SCRIPT" "$FIXTURE_ROOT/does-not-exist"
  [ "$status" -eq 2 ]
  echo "$output" | grep -iE "not found|missing|does not exist"
}

@test "check-skill-md-budgets: ignores non-SKILL.md files in skill dirs" {
  local skill_dir="$FIXTURE_ROOT/packages/alpha/skills/with-extras"
  mkdir -p "$skill_dir"
  # Bloated non-SKILL.md files should not trip the scan
  printf '%.0s.' $(seq 1 50000) > "$skill_dir/NOTES.md"
  printf '%.0s.' $(seq 1 50000) > "$skill_dir/scratch.txt"
  # Small SKILL.md under threshold
  printf '%.0s.' $(seq 1 1000) > "$skill_dir/SKILL.md"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Output stability ────────────────────────────────────────────────────────

@test "check-skill-md-budgets: output is sorted by identifier for stable diffs" {
  write_skill "zeta" "one" 10000
  write_skill "alpha" "one" 10000
  write_skill "middle" "one" 10000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  first_line=$(echo "$output" | head -1)
  last_line=$(echo "$output" | tail -1)
  echo "$first_line" | grep -q "alpha/one"
  echo "$last_line" | grep -q "zeta/one"
}

@test "check-skill-md-budgets: mixed OVER + MUST_SPLIT output uses block ordering" {
  # Three OVER files; two of them also MUST_SPLIT. Output must be
  # deterministic so retro summary diffs stay stable across cycles.
  # Contract: OVER block (sorted by identifier) followed by MUST_SPLIT
  # block (sorted by identifier).
  write_skill "zeta" "over-only" 10000
  write_skill "alpha" "must-split" 20000
  write_skill "middle" "must-split" 25000
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # Three OVER lines — alpha first, middle next, zeta last
  over_lines=$(echo "$output" | grep "^OVER ")
  [ "$(echo "$over_lines" | wc -l | tr -d ' ')" = "3" ]
  echo "$over_lines" | sed -n '1p' | grep -q "alpha/must-split"
  echo "$over_lines" | sed -n '2p' | grep -q "middle/must-split"
  echo "$over_lines" | sed -n '3p' | grep -q "zeta/over-only"
  # Two MUST_SPLIT lines — alpha first, middle second; zeta-over-only NOT present
  must_lines=$(echo "$output" | grep "^MUST_SPLIT ")
  [ "$(echo "$must_lines" | wc -l | tr -d ' ')" = "2" ]
  echo "$must_lines" | sed -n '1p' | grep -q "alpha/must-split"
  echo "$must_lines" | sed -n '2p' | grep -q "middle/must-split"
  ! echo "$must_lines" | grep -q "zeta/over-only"
  # All OVER lines come before any MUST_SPLIT line (block ordering)
  first_must_line_no=$(echo "$output" | grep -n "^MUST_SPLIT " | head -1 | cut -d: -f1)
  last_over_line_no=$(echo "$output" | grep -n "^OVER " | tail -1 | cut -d: -f1)
  [ "$last_over_line_no" -lt "$first_must_line_no" ]
}
