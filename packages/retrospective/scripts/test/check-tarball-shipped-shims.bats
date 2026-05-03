#!/usr/bin/env bats

# Behavioural fixture for the tarball-shipped-shims advisory detector — per
# WR-P154 (P137 namespace-prefix detector must run against npm pack output
# not source tree) and the WR-ADR-049 / WR-ADR-052 / WR-ADR-055 cluster.
#
# Contract: `check-tarball-shipped-shims.sh [<root-dir>]` is a diagnose-only
# advisory script. It walks workspaces under `<root-dir>/packages/*/`, runs
# `npm pack --dry-run --json` per workspace to enumerate the file set that
# ships, then asserts that every WR-ADR-049-grammar bin shim
# (`bin/wr-<plugin>-<name>`) in the tarball has its `exec`'d
# `scripts/<name>.sh` target also in the tarball.
#
# Surface: shipped publish-manifest integrity for bin/scripts/ shim
# resolvability — different correctness axis than check-internal-id-leaks.sh
# (which measures source-tree namespace-prefix drift).
#
# WR-ADR-049-grammar shims that this script considers:
#   bin/wr-<plugin>-<name>
# Non-grammar bins (e.g. `bin/install.mjs`, `bin/check-deps.sh`,
# `bin/windyroad-<plugin>` legacy installers) are skipped — they don't
# follow the script-resolution-via-bin-on-PATH ADR-049 contract this
# script enforces.
#
# Exit codes:
#   0 = always (advisory only — drift is signal, not failure)
#   2 = parse error (root dir missing/unreadable, or npm unavailable)
#
# Output format on drift (terse machine-readable per WR-ADR-038):
#   TARBALL_DRIFT package=<name> shim=<bin/wr-...> target=<scripts/...> tarball-status=missing
#
# Followed by a final summary line (always emitted when any drift exists):
#   TOTAL packages=<N> with_drift=<M> missing_targets=<K>
#
# Output is empty (no lines) when no shipped artefact carries broken
# shims — silent-on-pass per WR-ADR-045 hook injection budget.
#
# Output ordering (deterministic for stable retro-summary diffs):
#   TARBALL_DRIFT lines sorted by `<package>/<shim>` identifier.
#   TOTAL line last.
#
# Read-only — does NOT mutate any artefact. Per WR-ADR-052, this fixture
# is BEHAVIOURAL — it asserts script output on temp-fixture trees, NOT
# script source content. No greps of check-tarball-shipped-shims.sh source.
#
# @problem P154 (P137 namespace-prefix detector must run against
#   npm pack output not source tree)
# @problem P140 (Step 6.5 fix-and-continue — same prevention surface)
# @adr ADR-049 (Plugin script resolution via bin/ on PATH)
# @adr ADR-038 (Progressive disclosure — terse machine-readable signal)
# @adr ADR-045 (Hook injection budget — silent-on-pass)
# @adr ADR-052 (Behavioural-tests-default — fixture pattern)
# @adr ADR-055 (Plugin-published namespace-prefixed permalinks —
#   sibling adopter-context decision)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just
#   Installed — executable correctness axis of adopter-facing content)
# @jtbd JTBD-101 (Extend the Suite with New Plugins — secondary
#   plugin-developer feedback surface)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-tarball-shipped-shims.sh"
  FIXTURE_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_ROOT"
}

# Helper: write a workspace package.json with a controlled `files` array.
# Args: <plugin> <files-json-array>
# Example: write_package_json alpha '["bin/", "scripts/"]'
write_package_json() {
  local plugin="$1"
  local files="$2"
  local plugin_dir="$FIXTURE_ROOT/packages/$plugin"
  mkdir -p "$plugin_dir"
  cat > "$plugin_dir/package.json" <<EOF
{
  "name": "@test/$plugin",
  "version": "0.1.0",
  "files": $files
}
EOF
}

# Helper: write an WR-ADR-049-grammar bin shim that exec-s a scripts/ target.
# Args: <plugin> <name>  (shim becomes bin/wr-<plugin>-<name>, exec-s ../scripts/<name>.sh)
write_adr049_shim() {
  local plugin="$1"
  local name="$2"
  local bin_dir="$FIXTURE_ROOT/packages/$plugin/bin"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/wr-$plugin-$name" <<EOF
#!/usr/bin/env bash
exec "\$(dirname "\$0")/../scripts/$name.sh" "\$@"
EOF
  chmod +x "$bin_dir/wr-$plugin-$name"
}

# Helper: write a script body matching the shim's exec target.
write_script() {
  local plugin="$1"
  local name="$2"
  local script_dir="$FIXTURE_ROOT/packages/$plugin/scripts"
  mkdir -p "$script_dir"
  cat > "$script_dir/$name.sh" <<'EOF'
#!/usr/bin/env bash
echo "fixture script body"
EOF
  chmod +x "$script_dir/$name.sh"
}

# Helper: write a non-WR-ADR-049-grammar bin entry (e.g. legacy installer).
# These should be silently ignored by the script.
write_non_grammar_bin() {
  local plugin="$1"
  local name="$2"
  local bin_dir="$FIXTURE_ROOT/packages/$plugin/bin"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/$name" <<'EOF'
#!/usr/bin/env bash
echo "legacy installer"
EOF
  chmod +x "$bin_dir/$name"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-tarball-shipped-shims: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-tarball-shipped-shims: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Empty / clean trees ─────────────────────────────────────────────────────

@test "check-tarball-shipped-shims: empty tree (no packages dir) produces no output and exits 0" {
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-tarball-shipped-shims: packages dir with no workspaces produces no output and exits 0" {
  mkdir -p "$FIXTURE_ROOT/packages"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-tarball-shipped-shims: workspace with no WR-ADR-049 shims produces no output" {
  write_package_json "alpha" '["bin/"]'
  write_non_grammar_bin "alpha" "windyroad-alpha"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-tarball-shipped-shims: clean workspace (shim + target both ship) produces no output" {
  write_package_json "alpha" '["bin/", "scripts/"]'
  write_adr049_shim "alpha" "good"
  write_script "alpha" "good"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Drift detection — the iter-20 P033 sibling-finding shape ────────────────

@test "check-tarball-shipped-shims: shim present in tarball, target NOT in tarball — flagged" {
  # The canonical broken shape: scripts/ exists on disk, shim references it,
  # but package.json#files omits scripts/ so the target isn't shipped.
  write_package_json "alpha" '["bin/"]'
  write_adr049_shim "alpha" "broken"
  write_script "alpha" "broken"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TARBALL_DRIFT package=@test/alpha shim=bin/wr-alpha-broken target=scripts/broken.sh tarball-status=missing$"
}

@test "check-tarball-shipped-shims: TOTAL summary emitted on any drift" {
  write_package_json "alpha" '["bin/"]'
  write_adr049_shim "alpha" "broken"
  write_script "alpha" "broken"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TOTAL packages=1 with_drift=1 missing_targets=1$"
}

@test "check-tarball-shipped-shims: multiple shims in one workspace — each missing target flagged" {
  write_package_json "alpha" '["bin/"]'
  write_adr049_shim "alpha" "alpha-one"
  write_script "alpha" "alpha-one"
  write_adr049_shim "alpha" "alpha-two"
  write_script "alpha" "alpha-two"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TARBALL_DRIFT package=@test/alpha shim=bin/wr-alpha-alpha-one target=scripts/alpha-one.sh tarball-status=missing$"
  echo "$output" | grep -E "^TARBALL_DRIFT package=@test/alpha shim=bin/wr-alpha-alpha-two target=scripts/alpha-two.sh tarball-status=missing$"
  echo "$output" | grep -E "^TOTAL packages=1 with_drift=1 missing_targets=2$"
}

@test "check-tarball-shipped-shims: drift across multiple packages aggregates correctly" {
  write_package_json "alpha" '["bin/"]'
  write_adr049_shim "alpha" "a-broken"
  write_script "alpha" "a-broken"
  write_package_json "beta" '["bin/"]'
  write_adr049_shim "beta" "b-broken"
  write_script "beta" "b-broken"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TOTAL packages=2 with_drift=2 missing_targets=2$"
}

# ── Mixed clean + drift workspaces ──────────────────────────────────────────

@test "check-tarball-shipped-shims: clean workspace + broken workspace — only broken flagged, TOTAL counts only with_drift" {
  write_package_json "alpha" '["bin/", "scripts/"]'
  write_adr049_shim "alpha" "good"
  write_script "alpha" "good"
  write_package_json "beta" '["bin/"]'
  write_adr049_shim "beta" "broken"
  write_script "beta" "broken"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "alpha"
  echo "$output" | grep -E "^TARBALL_DRIFT package=@test/beta shim=bin/wr-beta-broken target=scripts/broken.sh tarball-status=missing$"
  echo "$output" | grep -E "^TOTAL packages=1 with_drift=1 missing_targets=1$"
}

# ── Determinism ─────────────────────────────────────────────────────────────

@test "check-tarball-shipped-shims: TARBALL_DRIFT lines sorted deterministically by package/shim" {
  write_package_json "zeta" '["bin/"]'
  write_adr049_shim "zeta" "z-shim"
  write_script "zeta" "z-shim"
  write_package_json "alpha" '["bin/"]'
  write_adr049_shim "alpha" "a-shim"
  write_script "alpha" "a-shim"
  write_package_json "mu" '["bin/"]'
  write_adr049_shim "mu" "m-shim"
  write_script "mu" "m-shim"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  local first
  first=$(echo "$output" | grep '^TARBALL_DRIFT' | head -1)
  echo "$first" | grep -q "package=@test/alpha"
  local last
  last=$(echo "$output" | grep '^TARBALL_DRIFT' | tail -1)
  echo "$last" | grep -q "package=@test/zeta"
}

# ── Mixed grammar — non-WR-ADR-049 bins ignored ─────────────────────────────

@test "check-tarball-shipped-shims: legacy bin (non-WR-ADR-049 grammar) alongside grammar shim — only grammar shim checked" {
  write_package_json "alpha" '["bin/"]'
  write_non_grammar_bin "alpha" "windyroad-alpha"
  write_adr049_shim "alpha" "broken"
  write_script "alpha" "broken"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "windyroad-alpha"
  echo "$output" | grep -E "^TARBALL_DRIFT package=@test/alpha shim=bin/wr-alpha-broken target=scripts/broken.sh tarball-status=missing$"
}

# ── Pre-check error path ────────────────────────────────────────────────────

@test "check-tarball-shipped-shims: missing root dir exits 2" {
  run "$SCRIPT" "/nonexistent/path/$$"
  [ "$status" -eq 2 ]
}

# ── Silent-on-pass invariant ────────────────────────────────────────────────

@test "check-tarball-shipped-shims: no TOTAL line emitted when output is empty" {
  write_package_json "alpha" '["bin/", "scripts/"]'
  write_adr049_shim "alpha" "good"
  write_script "alpha" "good"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
