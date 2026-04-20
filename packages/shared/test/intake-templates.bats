#!/usr/bin/env bats

# P066: intake templates must be problem-first, not bug/feature-split.
# This project practises ITIL problem management, so the intake template
# shape must mirror the problem-ticket structure and let triage -- not the
# reporter -- decide whether a report is a defect, a missing capability,
# or something else.
#
# Structural doc-lint (Permitted Exception per ADR-005): asserts file
# presence/absence and fixed string markers, not behaviour.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  TEMPLATE_DIR="$REPO_ROOT/.github/ISSUE_TEMPLATE"
}

@test "intake: problem-report.yml exists" {
  [ -f "$TEMPLATE_DIR/problem-report.yml" ]
}

@test "intake: bug-report.yml has been removed" {
  [ ! -f "$TEMPLATE_DIR/bug-report.yml" ]
}

@test "intake: feature-request.yml has been removed" {
  [ ! -f "$TEMPLATE_DIR/feature-request.yml" ]
}

@test "intake: problem-report.yml uses [problem] title prefix" {
  run grep -F 'title: "[problem] "' "$TEMPLATE_DIR/problem-report.yml"
  [ "$status" -eq 0 ]
}

@test "intake: problem-report.yml applies problem + needs-triage labels" {
  run grep -F 'labels: ["problem", "needs-triage"]' "$TEMPLATE_DIR/problem-report.yml"
  [ "$status" -eq 0 ]
}

@test "intake: problem-report.yml mirrors problem-ticket sections (Description, Symptoms, Workaround, Environment, Evidence)" {
  for section in Description Symptoms Workaround Environment Evidence; do
    run grep -F "label: $section" "$TEMPLATE_DIR/problem-report.yml"
    [ "$status" -eq 0 ]
  done
}

@test "intake: config.yml no longer enumerates the tracker as 'bugs and feature requests only'" {
  run grep -F 'bugs and feature requests only' "$TEMPLATE_DIR/config.yml"
  [ "$status" -ne 0 ]
}

@test "intake: config.yml retains the Discussions contact link" {
  run grep -F 'github.com/windyroad/agent-plugins/discussions' "$TEMPLATE_DIR/config.yml"
  [ "$status" -eq 0 ]
}

@test "intake: config.yml retains the Security Advisories contact link" {
  run grep -F 'security/advisories/new' "$TEMPLATE_DIR/config.yml"
  [ "$status" -eq 0 ]
}

@test "intake: SUPPORT.md references 'Report a problem' rather than 'Bug reports' / 'Feature requests'" {
  run grep -F 'Report a problem' "$REPO_ROOT/SUPPORT.md"
  [ "$status" -eq 0 ]
  run grep -E '^## Bug reports' "$REPO_ROOT/SUPPORT.md"
  [ "$status" -ne 0 ]
  run grep -E '^## Feature requests' "$REPO_ROOT/SUPPORT.md"
  [ "$status" -ne 0 ]
}

@test "intake: CONTRIBUTING.md no longer opens with 'Bugs and feature requests'" {
  run grep -F '**Bugs and feature requests**' "$REPO_ROOT/CONTRIBUTING.md"
  [ "$status" -ne 0 ]
  run grep -F '**Problems**' "$REPO_ROOT/CONTRIBUTING.md"
  [ "$status" -eq 0 ]
}
