#!/usr/bin/env bats

# @problem P310 — RFCs carry independent decisions invisible to the ADR-066
#   human-oversight net. ADR-070 closes the blind spot; this lint enforces it.
# @adr ADR-070 (RFCs hold no independent decisions — the invariant under test)
# @adr ADR-052 (behavioural-tests-default — this is an artefact-state behavioural
#   assertion: it RUNS the checker against fixture RFC corpora + the real corpus
#   and asserts the verdict (exit code + output). It does NOT structurally grep
#   the checker's own source, the SKILL.md, or any agent prose — that would be
#   the P081 structural-test-disguised-as-behavioural anti-pattern.)
# @adr ADR-071 (every fix via RFC — composes; the lint guards the RFC corpus)
#
# Contract under test (ADR-070 § Confirmation): no RFC body in docs/rfcs/
# contains a "Considered Options / Alternatives Rejected" HEADING block
# without a matching `adrs:` frontmatter reference. The detector targets a
# markdown heading, never a prose mention of the phrase.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/itil/scripts/check-rfc-rejected-alternatives.sh"
  FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ── Fixture helper: write an RFC file with given adrs-line + body ────────────
write_rfc() {
  local name="$1" adrs_line="$2" body="$3"
  cat > "$FIXTURE_DIR/$name" <<EOF
---
status: accepted
rfc-id: ${name%.md}
problems: [P999]
$adrs_line
stories: []
---

# ${name%.md}: fixture

## Summary

A fixture RFC.

$body
EOF
}

@test "violation: rejected-alternatives heading block WITH empty adrs: -> exit 1 + VIOLATION" {
  write_rfc "RFC-901-bad.md" "adrs: []" $'## Considered Options / Alternatives Rejected\n\n- F1 alternative rejected: foo.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"VIOLATION"* ]]
  [[ "$output" == *"RFC-901-bad.md"* ]]
}

@test "allowed: rejected-alternatives heading block WITH a matching adrs: reference -> exit 0 (clean)" {
  write_rfc "RFC-902-homed.md" "adrs: [ADR-072, ADR-073]" $'## Considered Options / Alternatives Rejected\n\n- The contested choice is recorded in ADR-072; this block references it.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

@test "clean: no rejected-alternatives block, empty adrs: -> exit 0" {
  write_rfc "RFC-903-scope.md" "adrs: []" $'## Scope\n\nPure scope + decomposition + traces. No decisions here.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

@test "prose mention (not a heading) of the phrase does NOT trigger -> exit 0" {
  # Guards the RFC-005 retrofit-banner false positive: a blockquote/prose line
  # mentioning the struck section must not be flagged.
  write_rfc "RFC-904-retrofit.md" "adrs: []" $'> Retrofitted: this RFC originally carried a "Considered Options / Alternatives Rejected" section, now struck per ADR-070.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

@test "variant heading 'Alternatives Rejected' WITH empty adrs: -> exit 1" {
  write_rfc "RFC-905-variant.md" "adrs: []" $'### Alternatives Rejected\n\n- rejected: bar.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"RFC-905-variant.md"* ]]
}

@test "mixed corpus: one violation among clean RFCs -> exit 1, names only the offender" {
  write_rfc "RFC-906-ok.md" "adrs: [ADR-001]" $'## Considered Options\n\n- references ADR-001.'
  write_rfc "RFC-907-bad.md" "adrs: []" $'## Considered Options\n\n- no adr.'
  write_rfc "RFC-908-scope.md" "adrs: []" $'## Scope\n\nclean.'
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"RFC-907-bad.md"* ]]
  [[ "$output" != *"RFC-906-ok.md"* ]]
  [[ "$output" != *"RFC-908-scope.md"* ]]
}

@test "non-existent directory -> exit 2 (usage error)" {
  run bash "$SCRIPT" "$FIXTURE_DIR/does-not-exist"
  [ "$status" -eq 2 ]
}

@test "dogfood: the real docs/rfcs/ corpus is clean -> exit 0" {
  run bash "$SCRIPT" "$REPO_ROOT/docs/rfcs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}
