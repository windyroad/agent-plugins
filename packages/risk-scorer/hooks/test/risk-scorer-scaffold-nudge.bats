#!/usr/bin/env bats

# ADR-047 Amendment 2026-06-08 (P297): risk-scorer-scaffold-nudge.sh
# (SessionStart) emits a one-line nudge when RISK-POLICY.md exists but the
# docs/risks/ standing-risk register directory is missing, is silent
# otherwise, and self-suppresses under the AFK guard
# (WR_SUPPRESS_OVERSIGHT_NUDGE=1 per ADR-068) so the interactive
# scaffold-confirm never fires into an absent-user iteration (JTBD-006).
#
# P375 (2026-06-27): once docs/risks/ exists, the hook no longer goes
# silent — it counts entries still carrying the `**Curation**: pending
# review` marker and re-surfaces the count every session so the
# pending-review backlog self-surfaces (class-B) instead of rotting
# silently once stubs exist (the audit's "one step short of the jtbd
# pattern" gap).
#
# P379 (2026-06-28): inverse predicate of the register-missing arm — when
# RISK-POLICY.md is ABSENT ENTIRELY the hook nudges the adopter to author
# one via /wr-risk-scorer:update-policy (the gates otherwise run at the
# default appetite silently). Same AFK-suppress envelope (ADR-068).
# Behavioural — exercises the hook against fixture trees and asserts on stdout.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh"
  PLUGIN_ROOT="$REPO_ROOT/packages/risk-scorer"
  DIR="$(mktemp -d)"
  # Hermeticity (P391): the AFK work-problems orchestrator exports
  # WR_SUPPRESS_OVERSIGHT_NUDGE=1, which the hook self-suppresses on. Unset it so
  # nudge-emitting tests assert real behaviour; guard-specific tests set it
  # per-invocation via `run env WR_SUPPRESS_OVERSIGHT_NUDGE=...`.
  unset WR_SUPPRESS_OVERSIGHT_NUDGE
}

teardown() {
  rm -rf "$DIR"
}

@test "emits a scaffold nudge when RISK-POLICY.md exists and docs/risks/ is missing" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RISK-POLICY.md present but docs/risks/ is missing"* ]]
  [[ "$output" == *"/wr-risk-scorer:bootstrap-catalog"* ]]
}

@test "silent when RISK-POLICY.md exists and docs/risks/ exists but is empty" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  mkdir -p "$DIR/docs/risks"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when docs/risks/ exists with entries but none are pending review" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  mkdir -p "$DIR/docs/risks"
  printf '# R001\n**Curation**: curated\n' > "$DIR/docs/risks/R001-foo.active.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "surfaces a pending-review count when entries carry the curation marker (P375 self-surfacing)" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  mkdir -p "$DIR/docs/risks"
  printf '# R001\n**Curation**: pending review (auto-scaffolded 2026-06-17)\n' > "$DIR/docs/risks/R001-foo.active.md"
  printf '# R002\n**Curation**: pending review\n' > "$DIR/docs/risks/R002-bar.active.md"
  printf '# R003\n**Curation**: curated\n' > "$DIR/docs/risks/R003-baz.active.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 standing-risk entries are pending review"* ]]
  [[ "$output" == *"docs/risks/"* ]]
}

@test "singular phrasing when exactly one entry is pending review" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  mkdir -p "$DIR/docs/risks"
  printf '# R001\n**Curation**: pending review\n' > "$DIR/docs/risks/R001-foo.active.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 standing-risk entry is pending review"* ]]
}

@test "AFK guard suppresses the pending-review nudge too" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  mkdir -p "$DIR/docs/risks"
  printf '# R001\n**Curation**: pending review\n' > "$DIR/docs/risks/R001-foo.active.md"
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=1 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits a policy-authoring nudge when RISK-POLICY.md is absent (P379 inverse predicate)" {
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No RISK-POLICY.md"* ]]
  [[ "$output" == *"/wr-risk-scorer:update-policy"* ]]
}

@test "policy-absent nudge fires even when docs/risks/ exists (policy-absence wins, P379)" {
  mkdir -p "$DIR/docs/risks"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No RISK-POLICY.md"* ]]
  [[ "$output" == *"/wr-risk-scorer:update-policy"* ]]
}

@test "AFK guard suppresses the policy-absent nudge too (P379)" {
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=1 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "AFK guard WR_SUPPRESS_OVERSIGHT_NUDGE=1 suppresses the nudge entirely" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=1 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard value other than 1 does not suppress" {
  printf 'placeholder policy\n' > "$DIR/RISK-POLICY.md"
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=0 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"docs/risks/ is missing"* ]]
}

@test "silent when CLAUDE_PROJECT_DIR points at a non-existent path" {
  run env CLAUDE_PROJECT_DIR="$DIR/nonexistent" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
