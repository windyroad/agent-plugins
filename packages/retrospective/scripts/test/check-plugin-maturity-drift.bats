#!/usr/bin/env bats

# @problem P238 — Phase 3b drift detector behavioural confirmation.
# @problem P087 — parent: plugin maturity battle-hardening signal.
# @problem P152 — sibling drift-detector pattern (JTBD-currency).
#
# Contract under test:
# `packages/retrospective/scripts/check-plugin-maturity-drift.sh` is an
# advisory drift detector. It compares each plugin's rendered README
# maturity badge against the canonical `plugin.json` `maturity:` field
# and emits NDJSON-per-drift signals to stdout. Exit code 0 always per
# ADR-013 Rule 6 — drift is data, not failure.
#
# Drift classes:
#   missing-badge      — plugin.json has maturity but README has no badge
#   stale-band         — badge band mismatches canonical record
#   orphan-badge       — README has badge but plugin.json has no maturity
#   anti-pattern-section — README has standalone ## Maturity section
#   anti-pattern-url   — README has shields.io / SVG badge URL
#
# @adr ADR-063 (Plugin maturity presentation layer — Phase 3b contract)
# @adr ADR-051 (Sibling drift-detector pattern — `check-readme-jtbd-currency.sh`)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — exit 0 always)
# @adr ADR-049 (Shim grammar — `wr-retrospective-check-plugin-maturity-drift` on $PATH)
# @adr ADR-052 (Behavioural tests default)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-plugin-maturity-drift.sh"
  FIXTURE_DIR="$(mktemp -d)"
  PROJECT_ROOT="$FIXTURE_DIR/project"
  PKG_DIR="$PROJECT_ROOT/packages"
  mkdir -p "$PKG_DIR"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# Helper: write a synthetic plugin layout with plugin.json + README.md
make_plugin() {
  local name="$1"
  local plugin_json="$2"
  local readme="$3"
  local pkg="$PKG_DIR/$name"
  mkdir -p "$pkg/.claude-plugin"
  printf '%s\n' "$plugin_json" > "$pkg/.claude-plugin/plugin.json"
  printf '%s\n' "$readme" > "$pkg/README.md"
}

# ── Pre-checks ──────────────────────────────────────────────────────────────

@test "script file exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "missing packages dir exits 2 with error message on stderr" {
  run bash "$SCRIPT" "$FIXTURE_DIR/does-not-exist"
  [ "$status" -eq 2 ]
  [[ "$output" == *"packages dir not found"* ]]
}

@test "empty packages dir exits 0 with empty stdout" {
  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"TOTAL"* ]] || [ -z "$output" ]
}

# ── Clean fixture: badge matches plugin.json record ─────────────────────────

@test "clean fixture: matching badge + record emits no drift hints" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.*

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"drift_hints="* ]]
  [[ "$output" != *"stale-band"* ]]
  [[ "$output" != *"missing-badge"* ]]
}

# ── Stale-band fixture: badge != canonical record ───────────────────────────

@test "stale-band fixture: README badge band mismatches plugin.json record" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Beta"}}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.*

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"stale-band"* ]]
}

# ── Missing-badge fixture: plugin.json has maturity, README has no badge ────

@test "missing-badge fixture: plugin.json has maturity but README has no badge" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/stub

**Stub plugin description.**

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"missing-badge"* ]]
}

# ── Orphan-badge fixture: README has badge, plugin.json has no maturity ─────

@test "orphan-badge fixture: README badge present but plugin.json lacks maturity field" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub"}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.*

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"orphan-badge"* ]]
}

# ── Anti-pattern: standalone ## Maturity section ────────────────────────────

@test "anti-pattern: standalone ## Maturity section emits anti-pattern-section hint" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.*

## Maturity

Alpha band.

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"anti-pattern-section"* ]]
}

# ── Anti-pattern: shields.io URL ────────────────────────────────────────────

@test "anti-pattern: shields.io URL emits anti-pattern-url hint" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.* ![Maturity](https://img.shields.io/badge/maturity-alpha-orange)

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=stub"* ]]
  [[ "$output" == *"anti-pattern-url"* ]]
}

# ── TOTAL summary line ──────────────────────────────────────────────────────

@test "multi-plugin aggregation: emits TOTAL summary with drift count" {
  make_plugin "alpha" '{"name":"wr-alpha","version":"0.1.0","description":"Alpha","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/alpha

**Alpha plugin.** *Maturity: Alpha.*

## Skills
"
  make_plugin "bravo" '{"name":"wr-bravo","version":"0.1.0","description":"Bravo","maturity":{"schema_version":"1.0","band":"Beta"}}' \
"# @windyroad/bravo

**Bravo plugin.**

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package=alpha"* ]]
  [[ "$output" == *"package=bravo"* ]]
  [[ "$output" == *"TOTAL packages=2"* ]]
  [[ "$output" == *"drift_instances=1"* ]]
}

# ── Exit-0-always invariant ─────────────────────────────────────────────────

@test "exit-0-always: even with multiple drift entries, exit code is 0" {
  make_plugin "alpha" '{"name":"wr-alpha","version":"0.1.0","description":"Alpha","maturity":{"schema_version":"1.0","band":"Beta"}}' \
"# @windyroad/alpha

**Alpha plugin.** *Maturity: Alpha.*

## Skills
"
  make_plugin "bravo" '{"name":"wr-bravo","version":"0.1.0","description":"Bravo","maturity":{"schema_version":"1.0","band":"Stable"}}' \
"# @windyroad/bravo

**Bravo plugin.**

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
}

# ── Package without README is silently skipped ──────────────────────────────

@test "package without README.md is silently skipped" {
  local pkg="$PKG_DIR/no-readme"
  mkdir -p "$pkg/.claude-plugin"
  echo '{"name":"wr-no-readme","version":"0.1.0","description":"No README","maturity":{"schema_version":"1.0","band":"Alpha"}}' > "$pkg/.claude-plugin/plugin.json"

  make_plugin "with-readme" '{"name":"wr-with-readme","version":"0.1.0","description":"With README","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/with-readme

**With README.** *Maturity: Alpha.*
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"package=no-readme"* ]]
  [[ "$output" == *"package=with-readme"* ]]
}

# ── No-network primitive: ADR-035 privacy posture ───────────────────────────

@test "ADR-035: script body invokes no network primitive" {
  run grep -E "(curl|wget|nc -|netcat|ssh |scp |rsync|http\.client|urllib|requests)" "$SCRIPT"
  [ "$status" -ne 0 ]
}

# ── NDJSON output: per-line shape parseable as structured signal ────────────

@test "NDJSON output: each README line follows package=<name> <key>=<value> shape" {
  make_plugin "stub" '{"name":"wr-stub","version":"0.1.0","description":"Stub","maturity":{"schema_version":"1.0","band":"Alpha"}}' \
"# @windyroad/stub

**Stub plugin description.** *Maturity: Alpha.*

## Skills
"

  run bash "$SCRIPT" "$PKG_DIR"
  [ "$status" -eq 0 ]
  # Per-package README line is space-separated key=value tokens
  [[ "$output" == *"README package=stub"* ]]
  [[ "$output" == *"badge_band="* ]]
  [[ "$output" == *"record_band="* ]]
}
