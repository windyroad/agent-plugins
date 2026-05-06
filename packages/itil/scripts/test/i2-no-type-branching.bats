#!/usr/bin/env bats

# @problem P170 — Slice 4 B7.T4 (item 8d): I2 (uniform problem
# ontology) load-bearing behavioural enforcement. ADR-060 architect
# finding 2: "I2 needs load-bearing behavioural test, not prose
# prohibition" — without this test ADR-060 ships I2 in name only.
#
# Contract: the type-tag is a CLASSIFICATION facet, never a workflow
# split. No skill or supporting script branches on the `type` field.
# This test asserts the property behaviourally for the pure-bash
# supporting-script surface — for each script that reads problem-
# ticket frontmatter, observable outputs (stdout / exit code / file
# mutations) are isomorphic across two synthetic ticket-set variants
# (one `type: technical`, one `type: user-business`).
#
# Coverage SCOPE — pure-bash supporting scripts only:
#   - `reconcile-readme.sh`
#   - `update-problem-rfcs-section.sh`
#   - `classify-readme-drift.sh`
#   - `reconcile-rfcs.sh`
#   - `migrate-problems-add-type.sh` (idempotency on already-migrated
#     tickets, regardless of type value)
#
# Coverage GAP — agent-driven SKILL.md surface:
#   The SKILL.md files (`/wr-itil:capture-problem`,
#   `/wr-itil:manage-problem`, `/wr-itil:work-problems`,
#   `/wr-itil:review-problems`, `/wr-itil:transition-problem(s)`) are
#   agent-driven instructions, not scripts. Behaviourally testing them
#   requires invoking each skill against two type-variant ticket sets
#   and asserting observable agent action is isomorphic — that
#   primitive does not yet exist. **Tracked as P176** (agent-side I2
#   coverage gap; descendant of P012 skill testing harness scope).
#   Per ADR-052 § Surface 2 (in-file justification with cited harness-
#   gap ticket): the deferral is named, ticketed, audit-trailed — NOT
#   silent.
#
# P081 protection: this test is behavioural per ADR-052 (observable
# input → output assertions on script invocations). It does NOT grep
# SKILL.md / agent.md content for `type` token references — that
# would be the structural-test-disguised-as-behavioural anti-pattern
# P081 forbids.
#
# @adr ADR-060 (Phase 1 invariant I2; architect finding 2 + finding 10
#   item 8d; Confirmation criterion 8)
# @adr ADR-051 (load-bearing-from-the-start — I2 ships at the same
#   time as the type-tag, NOT later by graceful drift)
# @adr ADR-052 (behavioural-bats default; § Surface 2 escape-hatch
#   for the agent-side coverage gap)
# @adr ADR-014 (single-purpose; one mechanical invariant guard)
# @problem P081 (no structural grep on SKILL.md content — protects
#   against quick-fix workarounds that would re-introduce drift)
# @problem P176 (agent-side I2 coverage gap follow-up — covers what
#   this bats explicitly does not)
# @jtbd JTBD-001 (extended scope: multi-commit coordinated-change
#   governance at the change-set level — this test gates a CLASS of
#   future changes, not just a single edit)
# @jtbd JTBD-008 (decompose-fix-into-coordinated-changes — preserves
#   uniform mechanism across the type facet)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TECH_DIR="$(mktemp -d)"
  USER_DIR="$(mktemp -d)"
  RFCS_TECH="$(mktemp -d)"
  RFCS_USER="$(mktemp -d)"
}

teardown() {
  rm -rf "$TECH_DIR" "$USER_DIR" "$RFCS_TECH" "$RFCS_USER"
}

# Build twin ticket-set fixtures: identical content except for the
# `**Type**:` field value. Three tickets per fixture (Open / Verifying
# / Closed) so each script's branching surface gets exercised.
build_twin_fixtures() {
  for type_pair in "technical:$TECH_DIR" "user-business:$USER_DIR"; do
    typev="${type_pair%%:*}"
    dir="${type_pair##*:}"
    cat > "$dir/100-foo.open.md" <<EOF
# Problem 100: Foo

**Status**: Open
**WSJF**: 5.0
**Type**: ${typev}

## Description

stub

## Related

stub
EOF
    cat > "$dir/101-bar.verifying.md" <<EOF
# Problem 101: Bar

**Status**: Verification Pending
**WSJF**: 0
**Type**: ${typev}

## Description

stub
EOF
    cat > "$dir/102-baz.closed.md" <<EOF
# Problem 102: Baz

**Status**: Closed
**Type**: ${typev}

## Description

stub
EOF
  done

  for type_pair in "technical:$TECH_DIR" "user-business:$USER_DIR"; do
    dir="${type_pair##*:}"
    cat > "$dir/README.md" <<'EOF'
# Problem Backlog

> Last reviewed: 2026-01-01.

## WSJF Rankings

| WSJF | ID | Title | Severity | Status | Effort |
|------|-----|-------|----------|--------|--------|
| 5.0 | P100 | Foo | 12 High | Open | M |

## Verification Queue

| ID | Title | Released | Likely verified? |
|----|-------|----------|------------------|
| P101 | Bar | 2026-01-01 | no (0 days) |

## Closed

| ID | Title | Closed |
|----|-------|--------|
| P102 | Baz | 2026-01-01 |
EOF
  done
}

# Build twin RFC-set fixtures alongside the problem fixtures, so
# `update-problem-rfcs-section.sh` and `reconcile-rfcs.sh` get exercised
# on traced-RFCs across both type variants.
build_twin_rfc_fixtures() {
  for type_pair in "technical:$RFCS_TECH" "user-business:$RFCS_USER"; do
    dir="${type_pair##*:}"
    cat > "$dir/RFC-001-foo.accepted.md" <<EOF
---
status: accepted
rfc-id: foo
reported: 2026-01-01
decision-makers: [test]
problems: [P100]
---

# RFC-001: foo

stub
EOF
    cat > "$dir/README.md" <<'EOF'
# RFC Backlog

## WSJF Rankings

| WSJF | ID | Title | Status |
|------|-----|-------|--------|
| 5.0 | RFC-001 | foo | accepted |

## Verification Queue

| ID | Title | Released | Likely verified? |
|----|-------|----------|------------------|

## Closed

| ID | Title | Closed |
|----|-------|--------|
EOF
  done
}

# Strip `**Type**:` lines and `type:` YAML lines from a stream so
# isomorphism comparison ignores the SOLE legitimate point of
# differentiation. Anything else differing between the two variants
# is an I2 violation.
strip_type_lines() {
  grep -v -E '^(\*\*Type\*\*:|type: )' || true
}

# Diff two files modulo type lines; expect empty diff (= isomorphic).
assert_isomorphic_files() {
  local a="$1" b="$2"
  diff <(strip_type_lines < "$a") <(strip_type_lines < "$b")
}

# ── reconcile-readme.sh: exit code + stdout invariant across types ───────────

@test "I2: reconcile-readme.sh exits identically across type variants" {
  build_twin_fixtures
  set +e
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$TECH_DIR" > /tmp/i2-rrt-tech.out 2>&1
  ec_tech=$?
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$USER_DIR" > /tmp/i2-rrt-user.out 2>&1
  ec_user=$?
  set -e
  [ "$ec_tech" = "$ec_user" ]
}

@test "I2: reconcile-readme.sh stdout isomorphic modulo type field" {
  build_twin_fixtures
  set +e
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$TECH_DIR" > /tmp/i2-rrs-tech.out 2>&1 || true
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$USER_DIR" > /tmp/i2-rrs-user.out 2>&1 || true
  set -e
  assert_isomorphic_files /tmp/i2-rrs-tech.out /tmp/i2-rrs-user.out
}

# ── update-problem-rfcs-section.sh: file mutation invariant across types ─────

@test "I2: update-problem-rfcs-section.sh mutates ticket files identically across type variants" {
  build_twin_fixtures
  build_twin_rfc_fixtures
  bash "$SCRIPTS_DIR/update-problem-rfcs-section.sh" \
    "$TECH_DIR/100-foo.open.md" "$RFCS_TECH"
  bash "$SCRIPTS_DIR/update-problem-rfcs-section.sh" \
    "$USER_DIR/100-foo.open.md" "$RFCS_USER"
  assert_isomorphic_files \
    "$TECH_DIR/100-foo.open.md" \
    "$USER_DIR/100-foo.open.md"
}

@test "I2: update-problem-rfcs-section.sh produces same ## RFCs section regardless of type" {
  build_twin_fixtures
  build_twin_rfc_fixtures
  bash "$SCRIPTS_DIR/update-problem-rfcs-section.sh" \
    "$TECH_DIR/100-foo.open.md" "$RFCS_TECH"
  bash "$SCRIPTS_DIR/update-problem-rfcs-section.sh" \
    "$USER_DIR/100-foo.open.md" "$RFCS_USER"
  # Both files now carry the SAME ## RFCs table row.
  grep -q '| RFC-001 | accepted | foo |' "$TECH_DIR/100-foo.open.md"
  grep -q '| RFC-001 | accepted | foo |' "$USER_DIR/100-foo.open.md"
}

# ── classify-readme-drift.sh: exit code + stdout invariant across types ──────

@test "I2: classify-readme-drift.sh exits identically across type variants" {
  build_twin_fixtures
  # Manufacture a drift output file (the script reads stdout from
  # reconcile-readme; here we build a minimal canned drift line).
  drift_in="$(mktemp)"
  echo "DRIFT P100 wsjf-rankings: claims=open actual=open" > "$drift_in"
  set +e
  bash "$SCRIPTS_DIR/classify-readme-drift.sh" "$drift_in" "$TECH_DIR" > /tmp/i2-cdt-tech.out 2>&1
  ec_tech=$?
  bash "$SCRIPTS_DIR/classify-readme-drift.sh" "$drift_in" "$USER_DIR" > /tmp/i2-cdt-user.out 2>&1
  ec_user=$?
  set -e
  rm -f "$drift_in"
  [ "$ec_tech" = "$ec_user" ]
  assert_isomorphic_files /tmp/i2-cdt-tech.out /tmp/i2-cdt-user.out
}

# ── reconcile-rfcs.sh: exit code + stdout invariant across types ─────────────

@test "I2: reconcile-rfcs.sh exits identically across problem-type variants" {
  build_twin_fixtures
  build_twin_rfc_fixtures
  set +e
  bash "$SCRIPTS_DIR/reconcile-rfcs.sh" "$RFCS_TECH" "$TECH_DIR" > /tmp/i2-rrf-tech.out 2>&1
  ec_tech=$?
  bash "$SCRIPTS_DIR/reconcile-rfcs.sh" "$RFCS_USER" "$USER_DIR" > /tmp/i2-rrf-user.out 2>&1
  ec_user=$?
  set -e
  [ "$ec_tech" = "$ec_user" ]
  assert_isomorphic_files /tmp/i2-rrf-tech.out /tmp/i2-rrf-user.out
}

# ── migrate-problems-add-type.sh: idempotency invariant across both type values ──

@test "I2: migrate-problems-add-type.sh is no-op on already-typed tickets, both type values" {
  build_twin_fixtures
  hash_tech_before=$(shasum "$TECH_DIR"/*.md | shasum | cut -d' ' -f1)
  hash_user_before=$(shasum "$USER_DIR"/*.md | shasum | cut -d' ' -f1)
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" --apply "$TECH_DIR"
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" --apply "$USER_DIR"
  hash_tech_after=$(shasum "$TECH_DIR"/*.md | shasum | cut -d' ' -f1)
  hash_user_after=$(shasum "$USER_DIR"/*.md | shasum | cut -d' ' -f1)
  [ "$hash_tech_before" = "$hash_tech_after" ]
  [ "$hash_user_before" = "$hash_user_after" ]
}

@test "I2: migrate-problems-add-type.sh diagnose-mode exit code identical across type variants" {
  build_twin_fixtures
  set +e
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" "$TECH_DIR" > /tmp/i2-mig-tech.out 2>&1
  ec_tech=$?
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" "$USER_DIR" > /tmp/i2-mig-user.out 2>&1
  ec_user=$?
  set -e
  [ "$ec_tech" = "$ec_user" ]
  assert_isomorphic_files /tmp/i2-mig-tech.out /tmp/i2-mig-user.out
}

# ── Cross-script invariant: full-pipeline behaviour identical across types ───

@test "I2: full diagnose pipeline (migrate diagnose + reconcile-readme) invariant across types" {
  build_twin_fixtures
  set +e
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" "$TECH_DIR" > /tmp/i2-pipe-tech-mig.out 2>&1
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$TECH_DIR" > /tmp/i2-pipe-tech-rec.out 2>&1
  bash "$SCRIPTS_DIR/migrate-problems-add-type.sh" "$USER_DIR" > /tmp/i2-pipe-user-mig.out 2>&1
  bash "$SCRIPTS_DIR/reconcile-readme.sh" "$USER_DIR" > /tmp/i2-pipe-user-rec.out 2>&1
  set -e
  assert_isomorphic_files /tmp/i2-pipe-tech-mig.out /tmp/i2-pipe-user-mig.out
  assert_isomorphic_files /tmp/i2-pipe-tech-rec.out /tmp/i2-pipe-user-rec.out
}
