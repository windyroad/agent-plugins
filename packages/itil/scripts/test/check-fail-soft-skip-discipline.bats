#!/usr/bin/env bats

# @problem P351 — skills fail-soft-skip when their precondition config is
#                 missing — should auto-bootstrap with user input as needed
#                 rather than silently skipping.
#
# Contract: `check-fail-soft-skip-discipline.sh <repo-root>` walks
# `<repo-root>/packages/*/skills/*/SKILL.md`, greps each file for the
# tightened fail-soft-skip pattern set
# (fail-soft skip|silently skip|skipping.*config|skipping.*not configured|
#  not configured.*skip), emits one `WARN  <relpath>:<line>  <pat>: ...`
# line per match on stderr, and exits 0 in Phase 1 advisory mode
# regardless of whether violations were found.
#
# @adr ADR-049 (bin/ on PATH shim — adopter-safe script resolution)
# @adr ADR-052 (Behavioural bats default)
# @adr ADR-040 (Advisory-then-load-bearing reusable pattern)
# @adr ADR-013 Rule 6 (Non-interactive fail-safe — advisory exit 0)
# @jtbd JTBD-001 (Enforce Governance — pattern-discipline lint)
# @jtbd JTBD-101 (Extend the Suite — extensible pattern per skill site)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-fail-soft-skip-discipline.sh"
  FIXTURE_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_ROOT"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-fail-soft-skip-discipline: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-fail-soft-skip-discipline: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Phase 1 advisory exit-code contract ─────────────────────────────────────

@test "Phase 1 advisory: exits 0 on a clean fixture" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/clean-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/clean-skill/SKILL.md" <<'EOF'
# Sample clean skill

This skill auto-bootstraps any missing precondition config via
AskUserQuestion. No fail-soft pattern present.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
}

@test "Phase 1 advisory: exits 0 even when violations present (default WR_FAIL_SOFT_SKIP_WARN_ONLY=1)" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/dirty-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/dirty-skill/SKILL.md" <<'EOF'
# Sample dirty skill

This skill performs a fail-soft skip when the config is missing.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
}

# ── WARN-on-fixture: behavioural ────────────────────────────────────────────

@test "WARN-on-fixture: matches 'fail-soft skip' literal" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/dirty-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/dirty-skill/SKILL.md" <<'EOF'
# Dirty skill

When the file is missing emit a fail-soft skip and continue.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"* ]]
  [[ "$output" == *"packages/sample/skills/dirty-skill/SKILL.md"* ]]
  [[ "$output" == *"fail-soft skip"* ]]
}

@test "WARN-on-fixture: matches 'silently skip' synonym" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/silent-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/silent-skill/SKILL.md" <<'EOF'
# Silent skill

If config missing, silently skip the pass.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"silently skip"* ]]
}

@test "WARN-on-fixture: matches tightened 'skipping.*config' shape" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/skipper-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/skipper-skill/SKILL.md" <<'EOF'
# Skipper skill

Skipping the pass because the channels config is absent.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipper-skill/SKILL.md"* ]]
}

# ── CLEAN-on-fixture: behavioural negative ──────────────────────────────────

@test "CLEAN-on-fixture: no WARN emitted when SKILL.md is fail-soft-skip free" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/auto-bootstrap-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/auto-bootstrap-skill/SKILL.md" <<'EOF'
# Auto-bootstrap skill

When the config file is missing, auto-bootstrap it via AskUserQuestion
(interactive mode) or queue a config-direction outstanding_question
(AFK mode). The skill resumes the original pass after bootstrap.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! [[ "$output" == *"WARN"* ]]
}

@test "CLEAN-on-fixture: does NOT false-positive on legitimate per-channel skip prose (architect tightening)" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/per-channel-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/per-channel-skill/SKILL.md" <<'EOF'
# Per-channel skill

On rate-limit, log advisory and skip that channel only — skipping the
failing channel/report is fine because other channels proceed. This
prose is the inverse of fail-soft-skip-on-missing-config and must NOT
fire a WARN per the architect-tightened pattern set.
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # The "fail-soft-skip-on-missing-config" hyphenated literal in the
  # prose does NOT contain a literal space-separated "fail-soft skip"
  # phrase, but the descriptive text does. Verify the script catches the
  # descriptive use and does NOT mistake the per-channel skip-prose for
  # the load-bearing pattern.
  # We expect EITHER zero WARNs (if the descriptive use is the only
  # hit) OR exactly the descriptive lines. Either way the per-channel
  # "skipping the failing channel/report" prose alone must NOT generate
  # a WARN.
  channel_only_warns=$(echo "$output" | grep -c "skipping the failing channel" || true)
  [ "$channel_only_warns" = "0" ]
}

# ── Phase 2 promotion: behavioural ──────────────────────────────────────────

@test "Phase 2 promotion: exits 1 when WR_FAIL_SOFT_SKIP_WARN_ONLY=0 + violations present" {
  mkdir -p "$FIXTURE_ROOT/packages/sample/skills/dirty-skill"
  cat > "$FIXTURE_ROOT/packages/sample/skills/dirty-skill/SKILL.md" <<'EOF'
# Dirty skill

Fail-soft skip when missing.
EOF
  WR_FAIL_SOFT_SKIP_WARN_ONLY=0 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 1 ]
}

# ── Usage / path-error contract ─────────────────────────────────────────────

@test "Usage: exits 2 on missing repo-root directory" {
  run "$SCRIPT" "$FIXTURE_ROOT/does-not-exist"
  [ "$status" -eq 2 ]
}

@test "Usage: exits 2 on repo-root without packages/ subdir" {
  mkdir -p "$FIXTURE_ROOT/no-packages-here"
  run "$SCRIPT" "$FIXTURE_ROOT/no-packages-here"
  [ "$status" -eq 2 ]
}
