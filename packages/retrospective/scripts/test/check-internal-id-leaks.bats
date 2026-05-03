#!/usr/bin/env bats

# Behavioural fixture for the internal-ID-leak advisory detector — per
# ADR-055 (Plugin-published artefacts use namespace-prefixed permalinks).
#
# Contract: `check-internal-id-leaks.sh [<root-dir>]` is a diagnose-only
# advisory script. It walks shipped-artefact surfaces under
# `<root-dir>/packages/*/` (default `<root-dir>` is `.`) and reports
# bare internal-ID tokens that lack the `WR-` namespace prefix.
#
# Surfaces scanned:
#   - packages/<plugin>/skills/<skill>/SKILL.md
#   - packages/<plugin>/agents/*.md
#   - packages/<plugin>/hooks/*.sh
#   - packages/<plugin>/CHANGELOG.md
#
# Bare tokens flagged (regex):
#   ADR-NNN  (3+ digits)
#   JTBD-NNN (3+ digits)
#   P-NNN or PNNN (3 digits — problem ticket form)
#
# Tokens that DO NOT trigger:
#   WR-ADR-NNN, WR-JTBD-NNN, WR-P-NNN, WR-PNNN  (namespace-prefixed)
#   docstring annotation lines beginning with `# @adr` / `# @jtbd` /
#     `# @problem` (maintainer-facing, never expanded into adopter context)
#   REFERENCE.md sibling files (lazy-loaded, maintainer-facing per ADR-054)
#
# Exit codes:
#   0 = always (advisory only — drift is signal, not failure)
#   2 = parse error (root dir missing or unreadable)
#
# Output format on drift (terse machine-readable per ADR-038):
#   OVER <plugin>/<file> bare_count=<N>
#
# Followed by a final summary line:
#   TOTAL packages=<N> with_leaks=<M> drift_instances=<K>
#
# Output is empty (no lines) when no shipped artefact carries bare tokens.
# Silent-on-pass per ADR-045 hook injection budget discipline.
#
# Read-only — does NOT mutate any artefact. Per ADR-052, this fixture is
# BEHAVIOURAL — it asserts script output on temp-fixture trees, NOT
# script source content. No greps of check-internal-id-leaks.sh source.
#
# @problem P137 (Plugin-published artefacts reference internal IDs that
#   adopter projects can't resolve)
# @adr ADR-055 (Plugin-published artefacts use namespace-prefixed
#   permalinks — strategy + advisory detector)
# @adr ADR-038 (Progressive disclosure — terse machine-readable signal)
# @adr ADR-045 (Hook injection budget — silent-on-pass)
# @adr ADR-052 (Behavioural-tests-default — fixture pattern)
# @adr ADR-005 (Plugin testing strategy)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just
#   Installed — semantic correctness axis of adopter-facing content)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-internal-id-leaks.sh"
  FIXTURE_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_ROOT"
}

# Helper: write a SKILL.md with given body content under fixture plugin.
# Uses %b to interpret \n in the body argument as a real newline so test
# fixtures can compose multi-line content inline.
write_skill() {
  local plugin="$1"
  local skill="$2"
  local body="$3"
  local skill_dir="$FIXTURE_ROOT/packages/$plugin/skills/$skill"
  mkdir -p "$skill_dir"
  printf '%b\n' "$body" > "$skill_dir/SKILL.md"
}

# Helper: write an agent file with given body.
write_agent() {
  local plugin="$1"
  local agent="$2"
  local body="$3"
  local agent_dir="$FIXTURE_ROOT/packages/$plugin/agents"
  mkdir -p "$agent_dir"
  printf '%b\n' "$body" > "$agent_dir/$agent.md"
}

# Helper: write a hook script with given body.
write_hook() {
  local plugin="$1"
  local hook="$2"
  local body="$3"
  local hook_dir="$FIXTURE_ROOT/packages/$plugin/hooks"
  mkdir -p "$hook_dir"
  printf '%b\n' "$body" > "$hook_dir/$hook.sh"
}

# Helper: write a CHANGELOG.md with given body.
write_changelog() {
  local plugin="$1"
  local body="$2"
  local plugin_dir="$FIXTURE_ROOT/packages/$plugin"
  mkdir -p "$plugin_dir"
  printf '%b\n' "$body" > "$plugin_dir/CHANGELOG.md"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-internal-id-leaks: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-internal-id-leaks: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Empty / clean trees ─────────────────────────────────────────────────────

@test "check-internal-id-leaks: empty tree produces no output and exits 0" {
  mkdir -p "$FIXTURE_ROOT/packages"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: clean SKILL.md (no IDs at all) produces no output" {
  write_skill "alpha" "clean" "# Skill\n\nThis skill has no references at all."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: SKILL.md with WR-prefixed refs only produces no output" {
  write_skill "alpha" "wr-only" "# Skill\n\nPer WR-ADR-014 and WR-JTBD-101 and WR-P137."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Bare-ID detection across surfaces ───────────────────────────────────────

@test "check-internal-id-leaks: bare ADR-NNN in SKILL.md is flagged" {
  write_skill "alpha" "leaky" "# Skill\n\nPer ADR-014 the workflow is..."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/skills/leaky/SKILL.md bare_count=[0-9]+"
}

@test "check-internal-id-leaks: bare JTBD-NNN in SKILL.md is flagged" {
  write_skill "alpha" "leaky" "# Skill\n\nServes JTBD-101 and JTBD-302."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/skills/leaky/SKILL.md bare_count=[0-9]+"
}

@test "check-internal-id-leaks: bare P-NNN in SKILL.md is flagged" {
  write_skill "alpha" "leaky" "# Skill\n\nCloses P137 and P078."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/skills/leaky/SKILL.md bare_count=[0-9]+"
}

@test "check-internal-id-leaks: bare IDs in agent file are flagged" {
  write_agent "beta" "specialist" "# Agent\n\nPer ADR-013 Rule 6 escalate."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER beta/agents/specialist.md bare_count=[0-9]+"
}

@test "check-internal-id-leaks: bare IDs in hook script body are flagged" {
  write_hook "gamma" "guard" "#!/usr/bin/env bash\n# This deny message points at ADR-014 and P137 from prose."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER gamma/hooks/guard.sh bare_count=[0-9]+"
}

@test "check-internal-id-leaks: bare IDs in CHANGELOG.md are flagged" {
  write_changelog "delta" "## 0.1.0\n\n- Per ADR-014 + P081 the new behaviour ships."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER delta/CHANGELOG.md bare_count=[0-9]+"
}

# ── Exclusions ──────────────────────────────────────────────────────────────

@test "check-internal-id-leaks: docstring @adr annotations on hook lines are NOT flagged" {
  write_hook "alpha" "annotated" "#!/usr/bin/env bash\n# @adr ADR-014 (commit discipline)\n# @jtbd JTBD-101\n# @problem P137"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: REFERENCE.md sibling files are NOT scanned" {
  local skill_dir="$FIXTURE_ROOT/packages/alpha/skills/with-ref"
  mkdir -p "$skill_dir"
  printf '# Skill\nClean body.\n' > "$skill_dir/SKILL.md"
  printf '# Reference\nADR-014 is fine here.\n' > "$skill_dir/REFERENCE.md"
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Counting + summary ──────────────────────────────────────────────────────

@test "check-internal-id-leaks: bare_count matches number of bare tokens in file" {
  write_skill "alpha" "trio" "# Skill\n\nADR-014 and JTBD-101 and P137 — three bare tokens."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^OVER alpha/skills/trio/SKILL.md bare_count=3$"
}

@test "check-internal-id-leaks: TOTAL summary line emitted on any drift" {
  write_skill "alpha" "leaky" "Per ADR-014 the workflow is."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TOTAL packages=1 with_leaks=1 drift_instances=1$"
}

@test "check-internal-id-leaks: TOTAL summary aggregates across files + packages" {
  write_skill "alpha" "leaky" "Per ADR-014."
  write_skill "alpha" "another" "JTBD-101."
  write_agent "beta" "specialist" "P137."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^TOTAL packages=2 with_leaks=3 drift_instances=3$"
}

@test "check-internal-id-leaks: no TOTAL line emitted when output is empty" {
  write_skill "alpha" "clean" "No bare references here."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Determinism ─────────────────────────────────────────────────────────────

@test "check-internal-id-leaks: OVER lines are sorted by package/file identifier" {
  write_skill "zeta" "z-skill" "ADR-014."
  write_skill "alpha" "a-skill" "ADR-014."
  write_skill "mu" "m-skill" "ADR-014."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  local first
  first=$(echo "$output" | grep '^OVER' | head -1)
  echo "$first" | grep -q "alpha/skills/a-skill/SKILL.md"
  local last
  last=$(echo "$output" | grep '^OVER' | tail -1)
  echo "$last" | grep -q "zeta/skills/z-skill/SKILL.md"
}

# ── Pre-check error path ────────────────────────────────────────────────────

@test "check-internal-id-leaks: missing root dir exits 2" {
  run "$SCRIPT" "/nonexistent/path/$$"
  [ "$status" -eq 2 ]
}

# ── Boundary tokens that must NOT match ─────────────────────────────────────

@test "check-internal-id-leaks: WR-prefixed token mid-sentence does not flag" {
  write_skill "alpha" "wr-mid" "Per WR-ADR-014 — clean."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: WR-prefixed JTBD does not flag" {
  write_skill "alpha" "wr-jtbd" "Serves WR-JTBD-302."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: standalone P3 (less than 3 digits) does not flag" {
  write_skill "alpha" "edge" "Phase P3 of the rollout."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check-internal-id-leaks: lowercase adr-014 does not flag (case-sensitive)" {
  write_skill "alpha" "lower" "in adr-014 prose context."
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
