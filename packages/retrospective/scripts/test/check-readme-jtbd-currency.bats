#!/usr/bin/env bats
#
# packages/retrospective/scripts/test/check-readme-jtbd-currency.bats
#
# Behavioural tests for `check-readme-jtbd-currency.sh` — the JTBD-anchored
# README drift advisory (ADR-051 / P152 Phase 1). Mirrors the fixture-based
# pattern of sibling detectors (`check-tickets-deferred-cause.bats`,
# `check-briefing-budgets.bats`, `check-ask-hygiene.bats`).
#
# Tests are behavioural per ADR-005 / ADR-037 / P081 — they exercise the
# script end-to-end against fixture packages/ + docs/jtbd/ trees and assert
# on stdout / exit code shape. No structural greps of the script source.
#
# @problem P152 (No pressure or nudge for documentation currency)
# @problem P081 (Structural-content tests are wasteful — behavioural preferred)
# @adr ADR-051 (JTBD-anchored README rule with declarative drift advisory)
# @adr ADR-013 Rule 6 (non-interactive fail-safe)
# @adr ADR-005 / ADR-037 (Plugin testing strategy — behavioural tests)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just Installed)
# @jtbd JTBD-007 (Keep Plugins Current Across Projects — currency expansion)

SCRIPT="${BATS_TEST_DIRNAME}/../check-readme-jtbd-currency.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  PKG_DIR="$TEST_DIR/packages"
  JTBD_DIR="$TEST_DIR/docs/jtbd"
  mkdir -p "$PKG_DIR" "$JTBD_DIR/plugin-user" "$JTBD_DIR/solo-developer"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Helper: write a synthetic plugin layout into PKG_DIR
make_plugin() {
  local name="$1"
  local readme_content="$2"
  mkdir -p "$PKG_DIR/$name"
  printf '%s\n' "$readme_content" > "$PKG_DIR/$name/README.md"
}

# Helper: write a synthetic JTBD job file into JTBD_DIR
make_jtbd() {
  local persona="$1"
  local id="$2"
  local slug="$3"
  local status="$4"
  mkdir -p "$JTBD_DIR/$persona"
  cat > "$JTBD_DIR/$persona/$id-$slug.$status.md" <<EOF
---
status: $status
job-id: $slug
persona: $persona
date-created: 2026-05-03
---

# $id: stub job for fixture
EOF
}

# ── Pre-checks ──────────────────────────────────────────────────────────────

@test "script file exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "missing packages dir exits 2 with error message on stderr" {
  run bash "$SCRIPT" "$TEST_DIR/does-not-exist" "$JTBD_DIR"
  [ "$status" -eq 2 ]
  [[ "$output" == *"packages dir not found"* ]]
}

@test "missing jtbd dir exits 2 with error message on stderr" {
  run bash "$SCRIPT" "$PKG_DIR" "$TEST_DIR/does-not-exist"
  [ "$status" -eq 2 ]
  [[ "$output" == *"jtbd dir not found"* ]]
}

@test "empty packages dir exits 0 with empty stdout" {
  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Drift fixture: README has no JTBD citation ──────────────────────────────

@test "drift fixture: README with no JTBD-NNN cite emits has_jtbd_anchor=no + missing-jtbd-section drift hint" {
  make_plugin "stub" "# @windyroad/stub
This README documents nothing about JTBD."
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"has_jtbd_anchor=no"* ]]
  [[ "$output" == *"cited_jobs=0"* ]]
  [[ "$output" == *"drift_hints="*"missing-jtbd-section"* ]]
  [[ "$output" == *"TOTAL packages=1 with_jtbd=0 drift_instances=1"* ]]
}

# ── Clean fixture: README cites a current JTBD ID ───────────────────────────

@test "clean fixture: README citing a resolving JTBD-NNN emits has_jtbd_anchor=yes with empty drift_hints" {
  make_plugin "stub" "# @windyroad/stub
This plugin serves JTBD-302 and JTBD-007."
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"
  make_jtbd "solo-developer" "JTBD-007" "keep-plugins-current" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"has_jtbd_anchor=yes"* ]]
  [[ "$output" == *"cited_jobs=2"* ]]
  [[ "$output" == *"known_jobs=2"* ]]
  [[ "$output" == *"drift_hints="$'\n'* || "$output" == *"drift_hints= "* || "$output" == *"drift_hints="*$'\n'* ]]
  [[ "$output" == *"TOTAL packages=1 with_jtbd=1 drift_instances=0"* ]]
}

# ── Stale-ID fixture: cited JTBD does not resolve ───────────────────────────

@test "stale-ID fixture: README citing JTBD-NNN with no resolving file emits stale-jtbd-citation hint" {
  make_plugin "stub" "# @windyroad/stub
This plugin serves JTBD-999 (which doesn't exist)."
  # No JTBD-999 file; only JTBD-302 exists in the fixture
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"has_jtbd_anchor=yes"* ]]
  [[ "$output" == *"cited_jobs=1"* ]]
  [[ "$output" == *"known_jobs=0"* ]]
  [[ "$output" == *"stale-jtbd-citation"* ]]
  [[ "$output" == *"TOTAL packages=1 with_jtbd=1 drift_instances=1"* ]]
}

# ── Deprecated-only fixture: cited JTBD resolves only to deprecated ─────────

@test "deprecated-only fixture: cited JTBD resolves to .deprecated.md emits deprecated-jtbd-citation hint" {
  make_plugin "stub" "# @windyroad/stub
This plugin serves JTBD-888."
  make_jtbd "plugin-user" "JTBD-888" "old-job" "deprecated"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"has_jtbd_anchor=yes"* ]]
  [[ "$output" == *"cited_jobs=1"* ]]
  [[ "$output" == *"known_jobs=1"* ]]
  [[ "$output" == *"deprecated-jtbd-citation"* ]]
  [[ "$output" == *"drift_instances=1"* ]]
}

# ── Skill-inventory-drift fixture ───────────────────────────────────────────

@test "skill-inventory-drift fixture: skills/ directory not named in README emits skill-inventory-drift hint" {
  mkdir -p "$PKG_DIR/stub/skills/orphan-widget"
  printf '%s\n' "# @windyroad/stub
This plugin serves JTBD-302." > "$PKG_DIR/stub/README.md"
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"skill-inventory-drift"* ]]
  [[ "$output" == *"drift_instances=1"* ]]
}

@test "skill-inventory-drift NOT flagged when skills/ directories are all named in README" {
  mkdir -p "$PKG_DIR/stub/skills/manage-secret"
  printf '%s\n' "# @windyroad/stub
This plugin serves JTBD-302 via the manage-secret skill." > "$PKG_DIR/stub/README.md"
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" != *"skill-inventory-drift"* ]]
}

# ── Multi-package aggregation ───────────────────────────────────────────────

@test "multi-package aggregation: emits one README line per package + TOTAL summary" {
  make_plugin "alpha" "# alpha
Serves JTBD-302."
  make_plugin "bravo" "# bravo
No anchor here."
  make_plugin "charlie" "# charlie
Serves JTBD-302 and JTBD-007."
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"
  make_jtbd "solo-developer" "JTBD-007" "keep-plugins-current" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=alpha"* ]]
  [[ "$output" == *"package=bravo"* ]]
  [[ "$output" == *"package=charlie"* ]]
  # bravo has missing-jtbd-section, alpha + charlie are clean
  [[ "$output" == *"TOTAL packages=3 with_jtbd=2 drift_instances=1"* ]]
}

# ── Package without README is skipped ───────────────────────────────────────

@test "package without README.md is silently skipped" {
  mkdir -p "$PKG_DIR/no-readme"
  make_plugin "with-readme" "# with-readme
Serves JTBD-302."
  make_jtbd "plugin-user" "JTBD-302" "trust-readme" "proposed"

  run bash "$SCRIPT" "$PKG_DIR" "$JTBD_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"package=no-readme"* ]]
  [[ "$output" == *"package=with-readme"* ]]
  [[ "$output" == *"TOTAL packages=1"* ]]
}
