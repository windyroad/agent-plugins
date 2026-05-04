#!/usr/bin/env bats

# P168 / ADR-059 install-updates Step 6.5.1 bootstrap auto-trigger contract.
#
# Asserts the Step 6.5.1 trigger contract against mock adopter fixtures.
# Mirrors the install-updates-p033-register-scaffold.bats precedent: replays
# the documented bash function from SKILL.md against an isolated tmp dir;
# asserts on observable trigger output.
#
# Per ADR-052: behavioural fixture, not structural grep. Per
# feedback_behavioural_tests.md (P081): asserts function-output-given-state,
# not SKILL.md prose content. The trigger function `bootstrap_register_if_eligible`
# returns a deterministic decision string per state combination (no-policy,
# no-scaffold, catalog-populated, no-reports, bootstrap-eligible) — that's
# the observable behaviour this test exercises.

setup() {
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: inline the Step 6.5.1 bootstrap trigger function from SKILL.md.
# Mirrors the install-updates-p033-register-scaffold.bats precedent of
# inlining `scaffold_register_if_eligible` for behavioural fixture testing.
bootstrap_register_if_eligible() {
  local target="$1"
  [ -f "$target/RISK-POLICY.md" ] || { echo "no-policy"; return 0; }
  [ -d "$target/docs/risks" ] || { echo "no-scaffold"; return 0; }
  if ls "$target/docs/risks/"R*-*.active.md >/dev/null 2>&1; then
    echo "catalog-populated"
    return 0
  fi
  if ! ls "$target/.risk-reports/"*.md >/dev/null 2>&1; then
    echo "no-reports"
    return 0
  fi
  echo "bootstrap-eligible"
  return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# Trigger contract: 5 outcomes per state combination
# ──────────────────────────────────────────────────────────────────────────────

@test "no-policy when RISK-POLICY.md absent" {
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "no-policy" ]
}

@test "no-scaffold when docs/risks/ directory absent" {
  mkdir -p sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "no-scaffold" ]
}

@test "catalog-populated when docs/risks/ has R*-*.active.md entries" {
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  touch sibling/docs/risks/R001-existing-risk.active.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "catalog-populated" ]
}

@test "no-reports when .risk-reports/ is empty" {
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "no-reports" ]
}

@test "no-reports when .risk-reports/ directory absent" {
  mkdir -p sibling/docs/risks
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "no-reports" ]
}

@test "bootstrap-eligible when all preconditions met" {
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "bootstrap-eligible" ]
}

@test "bootstrap-eligible when .risk-reports/ has multiple files" {
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  for d in 2026-04-01 2026-04-15 2026-05-04; do
    touch "sibling/.risk-reports/${d}-commit.md"
  done
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "bootstrap-eligible" ]
}

@test "scaffold-only state (README+TEMPLATE no R-files) qualifies as bootstrap-eligible" {
  # The "catalog is empty" semantic: README.md and TEMPLATE.md present but no
  # R*-*.active.md files. This is the post-scaffold-pre-bootstrap state per
  # ADR-047 Phase 1 + ADR-059 Phase 3 sequencing.
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "bootstrap-eligible" ]
}

@test "any single R*.active.md flips to catalog-populated (idempotent re-run protection)" {
  # Once at least one bootstrap-derived entry exists, re-running install-updates
  # must NOT re-fire the bootstrap. New-class detection then flows through
  # ADR-056 hint-and-drain, NOT through this trigger.
  mkdir -p sibling/docs/risks sibling/.risk-reports
  touch sibling/RISK-POLICY.md
  touch sibling/docs/risks/README.md sibling/docs/risks/TEMPLATE.md
  touch sibling/docs/risks/R042-some-bootstrap-derived.active.md
  touch sibling/.risk-reports/2026-05-04-commit.md
  run bootstrap_register_if_eligible sibling
  [ "$status" -eq 0 ]
  [ "$output" = "catalog-populated" ]
}

@test "exit code is 0 in all decision branches (skill-friendly)" {
  # Function MUST return 0 in every decision branch — the decision is encoded
  # in stdout, not exit code. Step 6.5.1 inherits the install-updates script's
  # error-handling discipline; non-zero would propagate as a fatal error.
  for state in no-policy no-scaffold catalog-populated no-reports bootstrap-eligible; do
    rm -rf sibling
    case "$state" in
      no-policy)
        mkdir -p sibling/docs/risks sibling/.risk-reports
        touch sibling/.risk-reports/2026-05-04-commit.md
        ;;
      no-scaffold)
        mkdir -p sibling/.risk-reports
        touch sibling/RISK-POLICY.md
        touch sibling/.risk-reports/2026-05-04-commit.md
        ;;
      catalog-populated)
        mkdir -p sibling/docs/risks sibling/.risk-reports
        touch sibling/RISK-POLICY.md
        touch sibling/docs/risks/R001.active.md
        touch sibling/.risk-reports/2026-05-04-commit.md
        ;;
      no-reports)
        mkdir -p sibling/docs/risks
        touch sibling/RISK-POLICY.md
        ;;
      bootstrap-eligible)
        mkdir -p sibling/docs/risks sibling/.risk-reports
        touch sibling/RISK-POLICY.md
        touch sibling/.risk-reports/2026-05-04-commit.md
        ;;
    esac
    run bootstrap_register_if_eligible sibling
    [ "$status" -eq 0 ]
  done
}
