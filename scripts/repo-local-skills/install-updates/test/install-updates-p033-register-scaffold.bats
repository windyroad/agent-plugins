#!/usr/bin/env bats

# P033 Phase 1b / ADR-047 behavioural-fixture test.
#
# Asserts the Step 6.5 "Scaffold governance artefacts (per-sibling)"
# contract against mock adopter fixtures. Mirrors the
# scaffold-intake-fixture.bats precedent: replays the documented bash
# steps from SKILL.md against an isolated tmp dir; asserts on observable
# file-system outcomes.
#
# Per ADR-052: behavioural test, not structural grep. Per
# feedback_behavioural_tests.md (P081): asserts files-that-appear /
# files-that-stay-the-same / no-overwrite, not SKILL.md prose content.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  TEMPLATE_DIR="$REPO_ROOT/scripts/repo-local-skills/install-updates/templates"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: replay the Step 6.5 trigger contract against a mock sibling.
# The trigger fires when RISK-POLICY.md is present AND docs/risks/ is
# absent. Per-file create-if-absent — never overwrite.
scaffold_register_if_eligible() {
  local sibling="$1"
  [ -f "$sibling/RISK-POLICY.md" ] || return 0
  mkdir -p "$sibling/docs/risks"
  if [ ! -f "$sibling/docs/risks/README.md" ]; then
    cp "$TEMPLATE_DIR/risk-register-README.md.tmpl" "$sibling/docs/risks/README.md"
  fi
  if [ ! -f "$sibling/docs/risks/TEMPLATE.md" ]; then
    cp "$TEMPLATE_DIR/risk-register-TEMPLATE.md.tmpl" "$sibling/docs/risks/TEMPLATE.md"
  fi
}

@test "ADR-047: templates dir exists at scripts/repo-local-skills/install-updates/templates/" {
  [ -d "$TEMPLATE_DIR" ]
}

@test "ADR-047: risk-register-README.md.tmpl ships with the skill" {
  [ -f "$TEMPLATE_DIR/risk-register-README.md.tmpl" ]
}

@test "ADR-047: risk-register-TEMPLATE.md.tmpl ships with the skill" {
  [ -f "$TEMPLATE_DIR/risk-register-TEMPLATE.md.tmpl" ]
}

@test "ADR-047: README template is adopter-flavoured (no R001 row, no Last reviewed date)" {
  # Adopter-flavour invariants: register table is empty (no example
  # entry); no this-repo-specific Last-reviewed timestamp leaks.
  run grep -F 'R001-confidential-info-leak' "$TEMPLATE_DIR/risk-register-README.md.tmpl"
  [ "$status" -ne 0 ]
  run grep -F 'Last reviewed: 2026' "$TEMPLATE_DIR/risk-register-README.md.tmpl"
  [ "$status" -ne 0 ]
}

@test "ADR-047: TEMPLATE.md template is verbatim copy of docs/risks/TEMPLATE.md" {
  diff "$REPO_ROOT/docs/risks/TEMPLATE.md" \
       "$TEMPLATE_DIR/risk-register-TEMPLATE.md.tmpl"
}

# --- Trigger condition: RISK-POLICY.md present AND docs/risks/ absent ---

@test "fixture: adopter with RISK-POLICY.md + no docs/risks/ — both files scaffolded" {
  mkdir -p sibling-a
  echo "# RISK-POLICY (mock)" > sibling-a/RISK-POLICY.md
  scaffold_register_if_eligible sibling-a
  [ -f sibling-a/docs/risks/README.md ]
  [ -f sibling-a/docs/risks/TEMPLATE.md ]
}

# --- Skip when adopter already has docs/risks/ populated ---

@test "fixture: adopter with docs/risks/ already populated — no overwrites" {
  mkdir -p sibling-b/docs/risks
  echo "# RISK-POLICY (mock)" > sibling-b/RISK-POLICY.md
  echo "ADOPTER-CUSTOMISED README" > sibling-b/docs/risks/README.md
  echo "ADOPTER-CUSTOMISED TEMPLATE" > sibling-b/docs/risks/TEMPLATE.md
  scaffold_register_if_eligible sibling-b
  # Both files should preserve the adopter's content verbatim.
  run cat sibling-b/docs/risks/README.md
  [ "$output" = "ADOPTER-CUSTOMISED README" ]
  run cat sibling-b/docs/risks/TEMPLATE.md
  [ "$output" = "ADOPTER-CUSTOMISED TEMPLATE" ]
}

# --- Skip when RISK-POLICY.md is absent ---

@test "fixture: adopter without RISK-POLICY.md — no scaffold attempted" {
  mkdir -p sibling-c
  scaffold_register_if_eligible sibling-c
  [ ! -d sibling-c/docs/risks ]
}

# --- Partial state: README present, TEMPLATE absent ---

@test "fixture: partial scaffold (README present, TEMPLATE absent) — only TEMPLATE written" {
  mkdir -p sibling-d/docs/risks
  echo "# RISK-POLICY (mock)" > sibling-d/RISK-POLICY.md
  echo "ADOPTER-CUSTOMISED README" > sibling-d/docs/risks/README.md
  scaffold_register_if_eligible sibling-d
  # README preserved verbatim, TEMPLATE created.
  run cat sibling-d/docs/risks/README.md
  [ "$output" = "ADOPTER-CUSTOMISED README" ]
  [ -f sibling-d/docs/risks/TEMPLATE.md ]
  # TEMPLATE matches source-of-truth.
  diff sibling-d/docs/risks/TEMPLATE.md "$TEMPLATE_DIR/risk-register-TEMPLATE.md.tmpl"
}

# --- Re-invocation idempotency: second pass produces no diff ---

@test "fixture: re-invocation idempotency (no diff on second pass)" {
  mkdir -p sibling-e
  echo "# RISK-POLICY (mock)" > sibling-e/RISK-POLICY.md
  scaffold_register_if_eligible sibling-e
  # Snapshot outside TEST_DIR (P127 — GNU cp won't copy into a child).
  SNAPSHOT_DIR=$(mktemp -d)
  cp -R sibling-e "$SNAPSHOT_DIR/sibling-e"
  scaffold_register_if_eligible sibling-e
  run diff -ru "$SNAPSHOT_DIR/sibling-e" sibling-e
  rm -rf "$SNAPSHOT_DIR"
  [ "$status" -eq 0 ]
}

# --- ISO clause mapping survives the adopter-flavour stripping ---

@test "fixture: scaffolded README cites ISO 31000 and ISO 27001 clauses" {
  mkdir -p sibling-f
  echo "# RISK-POLICY (mock)" > sibling-f/RISK-POLICY.md
  scaffold_register_if_eligible sibling-f
  # The ISO mapping is the load-bearing audit-trail purpose of the
  # scaffold per ADR-047 / P033 — must survive into adopter copies.
  run grep -F "ISO 31000" sibling-f/docs/risks/README.md
  [ "$status" -eq 0 ]
  run grep -F "ISO 27001" sibling-f/docs/risks/README.md
  [ "$status" -eq 0 ]
}
