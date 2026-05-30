#!/usr/bin/env bats

# @problem P263 — CI pre-publish manifest-validity gate. Adds the
#                 `claude plugin validate` (non-strict) loop ADR-063
#                 §Confirmation #11 names as the post-bats coverage
#                 layer that catches P258-class manifest breakages
#                 (recognised top-level key with wrong-typed content)
#                 without rejecting the ADR-063 `maturity:` safe-
#                 extension pattern that --strict would reject.
#
# Contract: `plugin-validate-ci-gate.sh` (invoked via ADR-049 shim
# `wr-itil-plugin-validate-ci-gate`) walks every
# `packages/*/.claude-plugin/plugin.json` in CWD, invokes `claude
# plugin validate <plugin_dir>` (NON-strict) per plugin, and exits
# non-zero if ANY plugin's manifest fails validation. The loop does
# NOT short-circuit on first failure — every plugin is exercised so
# the CI failure surfaces every defect at once.
#
# Behavioural test strategy (ADR-052): a programmable stub `claude`
# on PATH simulates `claude plugin validate`. The stub exits 1 when
# the manifest carries a top-level `hooks:` key whose body holds a
# `schema_version` sub-key (the P258 reproduction class — recognised
# key, wrong-typed content); exits 0 otherwise (including the ADR-063
# top-level `maturity:` safe-extension shape — unrecognised key, warn-
# only under non-strict). The stub captures the load-bearing
# behavioural contract of `claude plugin validate` non-strict for
# the two manifest shapes P263's design tension turns on. The real
# CLI is exercised at the CI workflow layer (`.github/workflows/
# ci.yml`) — split per ADR-052 (bats covers script-owned loop +
# failure-aggregation behaviour with a faithful test double; CI
# exercises the real CLI surface end-to-end).
#
# @adr ADR-063 Amendment 2026-05-18 §Confirmation #11 (the gate
#               criterion this script satisfies)
# @adr ADR-049 (bin/ on PATH shim — `wr-itil-plugin-validate-ci-gate`)
# @adr ADR-052 (Behavioural tests default — stub-claude faithfully
#               models the validator's non-strict exit contract for
#               the two manifest shapes P263 turns on)
# @adr ADR-014 (single-commit grain — script + shim + bats + CI +
#               ADR amendment + changeset land together)
# @adr ADR-022 (KE WSJF multiplier — informs prioritisation)
# @jtbd JTBD-101 (Extend the Suite with New Plugins — primary
#                 alignment; named Desired Outcome at L19 strengthened
#                 by this gate)
# @jtbd JTBD-202 (Pre-Flight Governance Checks Before Release —
#                 secondary alignment; gate fires in Quality Gates job)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/plugin-validate-ci-gate.sh"
  SHIM="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-plugin-validate-ci-gate"
  FIXTURE_DIR="$(mktemp -d)"
  STUB_DIR="$FIXTURE_DIR/stub-bin"
  mkdir -p "$STUB_DIR"
  cd "$FIXTURE_DIR"
  mkdir -p packages
  write_stub_claude
  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  cd /
  rm -rf "$FIXTURE_DIR"
}

# Programmable stub for `claude plugin validate <plugin_dir>`. Faithful
# model of the non-strict exit contract for the two manifest shapes
# P263 turns on:
#   - Top-level `hooks:` carrying a `schema_version` sub-key (the P258
#     reproduction — recognised key with wrong-typed content) → exit 1.
#   - Anything else (including ADR-063 top-level `maturity:` safe-
#     extension shape, where `maturity:` is unrecognised → warn-only
#     under non-strict) → exit 0.
write_stub_claude() {
  cat > "$STUB_DIR/claude" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "plugin" && "$2" == "validate" ]] || { echo "stub: unsupported args $*" >&2; exit 2; }
plugin_dir="$3"
manifest="$plugin_dir/.claude-plugin/plugin.json"
[ -f "$manifest" ] || { echo "stub: manifest not found at $manifest" >&2; exit 1; }
# Detect P258 reproduction: top-level "hooks": { ... "schema_version": ... }
if python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    m = json.load(f)
for key in ('hooks', 'skills', 'agents', 'commands'):
    v = m.get(key)
    if isinstance(v, dict):
        for sub in v.values():
            if isinstance(sub, dict) and 'schema_version' in sub:
                sys.exit(1)
sys.exit(0)
" "$manifest"; then
  echo "stub: $plugin_dir OK"
  exit 0
else
  echo "stub: $plugin_dir Validation errors: hooks: Invalid input" >&2
  exit 1
fi
STUB
  chmod +x "$STUB_DIR/claude"
}

# Helper: write a synthetic plugin manifest at packages/<name>/.claude-plugin/plugin.json
write_plugin() {
  local name="$1"
  local body="$2"
  mkdir -p "packages/$name/.claude-plugin"
  printf '%s\n' "$body" > "packages/$name/.claude-plugin/plugin.json"
}

# ── Existence / executable ──────────────────────────────────────────────────

@test "plugin-validate-ci-gate: canonical script exists" {
  [ -f "$SCRIPT" ]
}

@test "plugin-validate-ci-gate: canonical script is executable" {
  [ -x "$SCRIPT" ]
}

@test "plugin-validate-ci-gate: ADR-049 shim exists" {
  [ -f "$SHIM" ]
}

@test "plugin-validate-ci-gate: ADR-049 shim is executable" {
  [ -x "$SHIM" ]
}

@test "plugin-validate-ci-gate: shim is thin (single exec line to canonical body)" {
  grep -qE '^exec .*plugin-validate-ci-gate\.sh' "$SHIM"
}

# ── Fixture A: positive — ADR-063 safe-extension shape passes ───────────────

@test "plugin-validate-ci-gate: ADR-063 maturity: top-level safe-extension shape → exit 0" {
  write_plugin "alpha" '{
  "name": "alpha",
  "version": "1.0.0",
  "description": "test plugin",
  "maturity": {
    "schema_version": "2.0",
    "band": "Experimental"
  }
}'

  run "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "plugin-validate-ci-gate: multiple plugins all ADR-063-shaped → exit 0" {
  write_plugin "alpha" '{"name":"alpha","version":"1.0.0","description":"t","maturity":{"schema_version":"2.0","band":"Experimental"}}'
  write_plugin "beta"  '{"name":"beta","version":"1.0.0","description":"t","maturity":{"schema_version":"2.0","band":"Stable"}}'
  write_plugin "gamma" '{"name":"gamma","version":"1.0.0","description":"t"}'

  run "$SCRIPT"
  [ "$status" -eq 0 ]
}

# ── Fixture B: negative — P258 reproduction shape fails ─────────────────────

@test "plugin-validate-ci-gate: P258 reproduction (top-level hooks: with schema_version) → exit 1" {
  write_plugin "broken" '{
  "name": "broken",
  "version": "1.0.0",
  "description": "test plugin with P258 mistake",
  "hooks": {
    "some-hook": {
      "schema_version": "1.0",
      "band": "Experimental"
    }
  }
}'

  run "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "plugin-validate-ci-gate: mixed pass/fail loops every plugin (no short-circuit) → exit 1" {
  write_plugin "alpha"  '{"name":"alpha","version":"1.0.0","description":"t","maturity":{"schema_version":"2.0","band":"Experimental"}}'
  write_plugin "broken" '{"name":"broken","version":"1.0.0","description":"t","hooks":{"h":{"schema_version":"1.0","band":"Experimental"}}}'
  write_plugin "gamma"  '{"name":"gamma","version":"1.0.0","description":"t"}'

  run "$SCRIPT"
  [ "$status" -ne 0 ]
  # All three plugins must be exercised — no short-circuit on first failure.
  echo "$output" | grep -q "alpha"
  echo "$output" | grep -q "broken"
  echo "$output" | grep -q "gamma"
}

# ── No-plugins case (CI is always run against the monorepo tree, but the
#    fail-safe matters for adopter-tree invocation per ADR-049 portability).

@test "plugin-validate-ci-gate: no plugins under packages/ → exit 0 (nothing to validate)" {
  # No packages/<name>/.claude-plugin/plugin.json written.
  run "$SCRIPT"
  [ "$status" -eq 0 ]
}

# ── Shim PATH-resolution behaviour (ADR-049 contract) ──────────────────────

@test "plugin-validate-ci-gate: invoking shim runs the canonical body" {
  write_plugin "alpha" '{"name":"alpha","version":"1.0.0","description":"t","maturity":{"schema_version":"2.0","band":"Experimental"}}'

  run "$SHIM"
  [ "$status" -eq 0 ]
}
