#!/usr/bin/env bats

# tdd-review: structural-permitted (justification: P012 skill testing
#   harness scope is open; no behavioural alternative for YAML-form intake
#   template structural assertions today. The whole-file annotation covers
#   the P066 problem-first invariants AND the P128 consolidated-Versions
#   schema assertions added 2026-05-03.)
#
# P066: intake templates must be problem-first, not bug/feature-split.
# This project practises ITIL problem management, so the intake template
# shape must mirror the problem-ticket structure and let triage -- not the
# reporter -- decide whether a report is a defect, a missing capability,
# or something else.
#
# P128 (2026-05-03, ADR-033 amendment): the freeform Environment textarea
# is replaced with five structured `input` fields (Local plugin, Upstream
# package, Claude Code CLI, Node, OS) so inbound and outbound shapes match.
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

@test "intake: problem-report.yml mirrors problem-ticket sections (Description, Symptoms, Workaround, Evidence)" {
  # Per the P128 amendment 2026-05-03 (ADR-033 amendment), the freeform
  # `Environment` section is decomposed into five structured `input` fields
  # — see the dedicated Versions-schema test below. The other section labels
  # remain in lockstep with the problem-ticket structure.
  for section in Description Symptoms Workaround Evidence; do
    run grep -F "label: $section" "$TEMPLATE_DIR/problem-report.yml"
    [ "$status" -eq 0 ]
  done
}

@test "intake: problem-report.yml carries the consolidated Versions schema (P128, ADR-033 amendment 2026-05-03)" {
  # Five-field structured-input schema replacing the old freeform Environment
  # textarea. Symmetry with `## Versions` in `/wr-itil:report-upstream`'s
  # structured default body — what the suite ships out, the suite accepts in.
  for label in 'Local plugin version' 'Upstream package version' 'Claude Code CLI version' 'Node version' 'Operating system'; do
    run grep -F "label: $label" "$TEMPLATE_DIR/problem-report.yml"
    [ "$status" -eq 0 ] || {
      echo "missing P128 Versions-schema label: $label"
      return 1
    }
  done

  # The freeform Environment textarea must be gone — its replacement is the
  # structured five-input schema above.
  run grep -F 'label: Environment' "$TEMPLATE_DIR/problem-report.yml"
  [ "$status" -ne 0 ]
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
