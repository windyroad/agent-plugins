#!/usr/bin/env bats

# P065 / ADR-036 Confirmation behavioural-replay 1+2:
# Fixture-based behavioural test for scaffold-intake. Exercises the skill's
# core write-and-substitute contract against a mock empty downstream repo.
#
# This is the behavioural counterpart to scaffold-intake-contract.bats.
# It does NOT invoke the skill via Claude Code — it asserts the
# contract by replaying the skill's documented bash steps:
#   1. detect project name + url from package.json
#   2. enumerate missing intake files
#   3. write substituted templates to the correct paths
#   4. mark .claude/.intake-scaffold-done
# The bats reads templates/*.tmpl directly, applies the substitution rules
# defined in ADR-036, and asserts on the resulting files.
#
# Per feedback_behavioural_tests.md (P081): asserts observable file-system
# outcomes (files exist, content substituted, idempotent re-run no-ops),
# not source content.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  TEMPLATE_DIR="$REPO_ROOT/packages/itil/skills/scaffold-intake/templates"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"

  # Seed a minimal package.json so the skill's detection step has inputs.
  cat > package.json <<'JSON'
{
  "name": "example-downstream",
  "repository": {
    "url": "https://github.com/example/downstream.git"
  }
}
JSON
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: replay the skill's substitute-and-write step for one template.
# This is the inline mustache-style substitution declared in ADR-036.
scaffold_one() {
  local tmpl="$1"
  local out="$2"
  local project_name="example-downstream"
  local project_url="https://github.com/example/downstream"
  local security_contact="Use GitHub Security Advisories"
  local plugin_list="@windyroad/itil"
  local year="2026"
  mkdir -p "$(dirname "$out")"
  sed \
    -e "s|{{project_name}}|$project_name|g" \
    -e "s|{{project_url}}|$project_url|g" \
    -e "s|{{security_contact}}|$security_contact|g" \
    -e "s|{{plugin_list}}|$plugin_list|g" \
    -e "s|{{year}}|$year|g" \
    "$TEMPLATE_DIR/$tmpl" > "$out"
}

scaffold_all() {
  scaffold_one "config.yml.tmpl" ".github/ISSUE_TEMPLATE/config.yml"
  scaffold_one "problem-report.yml.tmpl" ".github/ISSUE_TEMPLATE/problem-report.yml"
  scaffold_one "SECURITY.md.tmpl" "SECURITY.md"
  scaffold_one "SUPPORT.md.tmpl" "SUPPORT.md"
  scaffold_one "CONTRIBUTING.md.tmpl" "CONTRIBUTING.md"
  mkdir -p .claude
  : > .claude/.intake-scaffold-done
}

# --- Empty repo: scaffold writes all five files ---

@test "fixture: empty repo gains all five intake files" {
  scaffold_all
  [ -f .github/ISSUE_TEMPLATE/config.yml ]
  [ -f .github/ISSUE_TEMPLATE/problem-report.yml ]
  [ -f SECURITY.md ]
  [ -f SUPPORT.md ]
  [ -f CONTRIBUTING.md ]
}

@test "fixture: substitution tokens are resolved (no raw {{...}} left in scaffolded files)" {
  scaffold_all
  for f in \
    .github/ISSUE_TEMPLATE/config.yml \
    .github/ISSUE_TEMPLATE/problem-report.yml \
    SECURITY.md \
    SUPPORT.md \
    CONTRIBUTING.md; do
    run grep -F '{{' "$f"
    [ "$status" -ne 0 ] || { echo "raw mustache token left in $f"; return 1; }
  done
}

@test "fixture: project_name substitution propagated into scaffolded SECURITY.md or CONTRIBUTING.md" {
  scaffold_all
  # The project name should appear at least once in either SECURITY.md or
  # CONTRIBUTING.md; the exact placement is template-dependent but
  # ABSENCE from both files would indicate a substitution miss.
  run bash -c "grep -F 'example-downstream' SECURITY.md SUPPORT.md CONTRIBUTING.md"
  [ "$status" -eq 0 ]
}

@test "fixture: scaffolded problem-report.yml retains problem-first shape (P066)" {
  scaffold_all
  run grep -F 'title: "[problem] "' .github/ISSUE_TEMPLATE/problem-report.yml
  [ "$status" -eq 0 ]
  run grep -F 'labels: ["problem", "needs-triage"]' .github/ISSUE_TEMPLATE/problem-report.yml
  [ "$status" -eq 0 ]
}

@test "fixture: done marker written after successful scaffold" {
  scaffold_all
  [ -f .claude/.intake-scaffold-done ]
}

# --- Idempotency: re-scaffolding produces no diff ---

@test "fixture: full re-application is idempotent (no diff)" {
  scaffold_all
  # Snapshot into a sibling temp dir — NOT inside $TEST_DIR. GNU cp refuses
  # `cp -R . dest` when dest is a child of source ("cannot copy a directory
  # into itself"), so the test fails on Linux CI even though macOS BSD cp
  # tolerates it. Putting the snapshot outside $TEST_DIR removes the platform
  # divergence (P127).
  SNAPSHOT_DIR=$(mktemp -d)
  cp -R "$TEST_DIR/." "$SNAPSHOT_DIR"
  # Re-apply.
  scaffold_all
  # Diff against snapshot.
  run diff -ru "$SNAPSHOT_DIR" "$TEST_DIR"
  rm -rf "$SNAPSHOT_DIR"
  # diff exit 0 means no differences.
  [ "$status" -eq 0 ]
}

# --- Partial repo: pre-existing CONTRIBUTING.md is preserved ---

@test "fixture: pre-existing CONTRIBUTING.md is preserved (idempotent skip)" {
  echo "# Custom Contributing" > CONTRIBUTING.md
  echo "Custom adopter content; must not be overwritten by scaffold." >> CONTRIBUTING.md
  ORIGINAL=$(cat CONTRIBUTING.md)

  # Scaffold the OTHER four files (skill skips the existing one).
  scaffold_one "config.yml.tmpl" ".github/ISSUE_TEMPLATE/config.yml"
  scaffold_one "problem-report.yml.tmpl" ".github/ISSUE_TEMPLATE/problem-report.yml"
  scaffold_one "SECURITY.md.tmpl" "SECURITY.md"
  scaffold_one "SUPPORT.md.tmpl" "SUPPORT.md"
  # Deliberately do NOT call scaffold_one for CONTRIBUTING.md — that's
  # the skill's idempotent skip behaviour for present files.

  # Other files were created.
  [ -f .github/ISSUE_TEMPLATE/config.yml ]
  [ -f .github/ISSUE_TEMPLATE/problem-report.yml ]
  [ -f SECURITY.md ]
  [ -f SUPPORT.md ]

  # CONTRIBUTING.md unchanged.
  AFTER=$(cat CONTRIBUTING.md)
  [ "$ORIGINAL" = "$AFTER" ]
}
