#!/usr/bin/env bats
# Behavioural-fixture coverage for packages/risk-scorer/scripts/drain-register-queue.sh
# per ADR-052 (behavioural tests default) and ADR-056 (Phase 2b drain contract).
#
# The drain script consumes .afk-run-state/risk-register-queue.jsonl (produced
# by risk-score-mark.sh per ADR-056 Phase 2a) and materialises register entries
# in docs/risks/. The script is invoked by consumer skills (this iter:
# /wr-itil:work-problems Step 6.4); subsequent iters wire additional consumers.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/risk-scorer/scripts/drain-register-queue.sh"
  SHIM="$REPO_ROOT/packages/risk-scorer/bin/wr-risk-scorer-drain-register-queue"
  WORK_DIR="$(mktemp -d)"
  cd "$WORK_DIR"
  # Minimal git setup — drain script does origin-max lookup via git ls-tree
  git init --quiet
  git config user.email "drain-test@example.com"
  git config user.name "Drain Test"
  git commit --quiet --allow-empty -m "init"
  # Seed README + a single R-file fixture matching the canonical .active.md
  # shape. P171 resolved 2026-05-31: drain script's vestigial TEMPLATE.md gate
  # was removed (it was a pre-wipe-direction residual). Canonical docs/risks/
  # has NO TEMPLATE.md per the 2026-05-04 user direction (commit 8edaf7b) +
  # the canonical .active.md suffix per commit 9b52610. Seeded R-file uses the
  # canonical shape; tests no longer synthesize a fixture-local TEMPLATE.md.
  mkdir -p docs/risks .afk-run-state
  cp "$REPO_ROOT/docs/risks/README.md" docs/risks/README.md
  cat > docs/risks/R001-confidential-info-leak-via-public-repo-push.active.md <<'R001_EOF'
# Risk R001: Confidential info leak via public repo push

**Status**: Active
**Category**: information-disclosure
**Identified**: 2026-04-17
**Owner**: maintainer

## Description

Test fixture for drain-register-queue dedupe path — slug
`confidential-info-leak-via-public-repo-push` matches an existing R-file
with `## Evidence Log` semantics.

## Evidence Log

- 2026-04-17: seeded fixture entry

## Change Log

- 2026-04-17: created (test fixture)
R001_EOF
  git add docs/risks
  git commit --quiet -m "seed risks"
}

teardown() {
  cd /
  rm -rf "$WORK_DIR"
}

@test "shim wrapper exists and is executable" {
  [ -x "$SHIM" ]
}

@test "shim resolves canonical script (not exit 127)" {
  run "$SHIM" "$WORK_DIR"
  [ "$status" -ne 127 ]
}

@test "empty queue → no-op, exit 0, no writes (ADR-056 idempotent)" {
  : > .afk-run-state/risk-register-queue.jsonl
  before_count=$(find docs/risks -name 'R*.active.md' 2>/dev/null | wc -l | tr -d ' ')
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=0$'
  echo "$output" | grep -q '^next_action=none$'
  after_count=$(find docs/risks -name 'R*.active.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "$before_count" = "$after_count" ]
}

@test "missing queue file → no-op, exit 0" {
  rm -f .afk-run-state/risk-register-queue.jsonl
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=0$'
}

@test "missing docs/risks/ → no-op, exit 0 (Phase 1 scaffold not yet fired)" {
  rm -rf docs/risks
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/x.md","reason_tag":"above-appetite-residual","risk_slug":"foo","slug_source":"agent","prefill":"prose"}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=0$'
}

@test "single hint, no existing match → creates R<NNN>-<slug>.active.md" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/2026-05-03T14-00-00-commit.md","reason_tag":"above-appetite-residual","risk_slug":"cumulative-residual-commit","slug_source":"agent","prefill":"Cumulative residual at commit hit High band."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=1$'
  echo "$output" | grep -q '^new_risks_created=1$'
  echo "$output" | grep -q '^next_action=commit-staged$'
  # R002 because R001 already exists in the seeded README
  [ -f docs/risks/R002-cumulative-residual-commit.active.md ]
  grep -q 'Status.*Active.*auto-scaffolded.*pending review' docs/risks/R002-cumulative-residual-commit.active.md
  grep -q 'Curation.*pending review' docs/risks/R002-cumulative-residual-commit.active.md
  grep -q 'not estimated.*no prior data' docs/risks/R002-cumulative-residual-commit.active.md
  grep -q 'Cumulative residual at commit hit High band' docs/risks/R002-cumulative-residual-commit.active.md
}

@test "single hint creates README Register table row (ADR-056 step 3d)" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/x.md","reason_tag":"above-appetite-residual","risk_slug":"my-test-risk","slug_source":"agent","prefill":"Test risk prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # README must contain a row for the new risk in the Register table
  grep -qE '\| \[R002\]\(R002-my-test-risk\.active\.md\) \|' docs/risks/README.md
  # Stub scoring renders as em-dash columns
  grep -qE 'R002.*my-test-risk.*\|.*—.*\|.*—.*\|.*pending' docs/risks/README.md
}

@test "multiple hints with same slug → one register file, multiple Evidence Log lines" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r1.md","reason_tag":"above-appetite-residual","risk_slug":"shared-slug","slug_source":"agent","prefill":"First mention."}
{"ts":"2026-05-03T14:01:00Z","session_id":"s1","report_path":".risk-reports/r2.md","reason_tag":"above-appetite-residual","risk_slug":"shared-slug","slug_source":"agent","prefill":"Second mention."}
{"ts":"2026-05-03T14:02:00Z","session_id":"s2","report_path":".risk-reports/r3.md","reason_tag":"above-appetite-residual","risk_slug":"shared-slug","slug_source":"agent","prefill":"Third mention."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=3$'
  echo "$output" | grep -q '^new_risks_created=1$'
  # Exactly one register file
  [ "$(find docs/risks -name 'R*-shared-slug.active.md' | wc -l | tr -d ' ')" = "1" ]
  # Evidence Log section cites all three reports
  grep -q '.risk-reports/r1.md' docs/risks/R*-shared-slug.active.md
  grep -q '.risk-reports/r2.md' docs/risks/R*-shared-slug.active.md
  grep -q '.risk-reports/r3.md' docs/risks/R*-shared-slug.active.md
}

@test "two distinct slugs in same queue → two register files with sequential IDs" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r1.md","reason_tag":"above-appetite-residual","risk_slug":"first-slug","slug_source":"agent","prefill":"First risk."}
{"ts":"2026-05-03T14:01:00Z","session_id":"s1","report_path":".risk-reports/r2.md","reason_tag":"confidentiality-disclosure","risk_slug":"second-slug","slug_source":"agent","prefill":"Second risk."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=2$'
  echo "$output" | grep -q '^new_risks_created=2$'
  [ -f docs/risks/R002-first-slug.active.md ]
  [ -f docs/risks/R003-second-slug.active.md ]
}

@test "existing match → appends Evidence Log only, no new file, no scoring change (ADR-056 step 3b)" {
  # Pre-seed an existing risk file with this slug
  cat > docs/risks/R042-known-risk.active.md <<'EOF'
# Risk R042: Known Risk

**Status**: Active
**Category**: operational
**Identified**: 2026-04-01
**Owner**: solo-developer
**Last reviewed**: 2026-04-01
**Next review**: 2026-10-01

## Description

Pre-existing curated risk.

## Inherent Risk

- **Impact**: 3 (Moderate)
- **Likelihood**: 2 (Unlikely)
- **Inherent Score**: 6
- **Inherent Band**: Medium

## Controls

- **control-x** — does the thing. Implemented in path/x.

## Residual Risk

- **Impact**: 2 (Minor)
- **Likelihood**: 2 (Unlikely)
- **Residual Score**: 4
- **Residual Band**: Low
- **Within appetite?**: Yes

## Treatment

Mitigate. Justified.

## Monitoring

- **Trigger to re-assess**: never
- **Metrics**: none

## Related

- Criteria: `RISK-POLICY.md`

## Change Log

- 2026-04-01: Initial identification.
EOF

  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/new-fire.md","reason_tag":"above-appetite-residual","risk_slug":"known-risk","slug_source":"agent","prefill":"Fired again."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=1$'
  echo "$output" | grep -q '^new_risks_created=0$'
  echo "$output" | grep -q '^evidence_appended=1$'
  # Existing file untouched on scoring lines
  grep -q 'Inherent Score.*: 6$' docs/risks/R042-known-risk.active.md
  grep -q 'Residual Score.*: 4$' docs/risks/R042-known-risk.active.md
  # Evidence Log section now exists
  grep -q '.risk-reports/new-fire.md' docs/risks/R042-known-risk.active.md
  # No R<NNN+1> file created
  [ ! -f docs/risks/R002-known-risk.active.md ]
}

@test "queue truncated on success" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r1.md","reason_tag":"above-appetite-residual","risk_slug":"truncate-test","slug_source":"agent","prefill":"prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # Queue file is empty after success
  [ ! -s .afk-run-state/risk-register-queue.jsonl ]
}

@test "queue NOT truncated on no-op (no docs/risks/ dir)" {
  rm -rf docs/risks
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r1.md","reason_tag":"above-appetite-residual","risk_slug":"preserve-on-skip","slug_source":"agent","prefill":"prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # Queue preserved when drain skips — Phase 1 scaffolding may land later
  [ -s .afk-run-state/risk-register-queue.jsonl ]
}

@test "stdout key=value shape (caller-parseable)" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r.md","reason_tag":"above-appetite-residual","risk_slug":"shape-test","slug_source":"agent","prefill":"prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # All four required keys present
  echo "$output" | grep -qE '^entries_drained=[0-9]+$'
  echo "$output" | grep -qE '^new_risks_created=[0-9]+$'
  echo "$output" | grep -qE '^evidence_appended=[0-9]+$'
  echo "$output" | grep -qE '^next_action=(commit-staged|none)$'
}

@test "files staged after successful drain (ready for caller commit)" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r.md","reason_tag":"above-appetite-residual","risk_slug":"stage-test","slug_source":"agent","prefill":"prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # Caller should be able to git commit immediately
  staged=$(git diff --cached --name-only)
  echo "$staged" | grep -q 'docs/risks/R002-stage-test.active.md'
  echo "$staged" | grep -q 'docs/risks/README.md'
}

@test "origin-max collision avoidance (ADR-019 ticket-creator dual-source ID)" {
  # Simulate origin/main having higher R-numbers than local. The drain script
  # MUST consult origin-max so parallel adopter sessions don't mint duplicate IDs.
  # We mock by creating a branch with R099 file then resetting local but keeping
  # the ref reachable as origin/main.
  cat > docs/risks/R099-future-risk.active.md <<'EOF'
# Risk R099: Future risk
EOF
  git add docs/risks/R099-future-risk.active.md
  git commit --quiet -m "high-id"
  git update-ref refs/remotes/origin/main HEAD
  git rm --quiet docs/risks/R099-future-risk.active.md
  git commit --quiet -m "remove from local"
  # Now local-max sees only R001 (from seeded README) but origin-max should see R099
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r.md","reason_tag":"above-appetite-residual","risk_slug":"collision-guard","slug_source":"agent","prefill":"prose."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  # Next ID must be R100, not R002
  [ -f docs/risks/R100-collision-guard.active.md ]
  [ ! -f docs/risks/R002-collision-guard.active.md ]
}

@test "malformed JSONL line skipped, valid lines processed" {
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
not-json-at-all
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/r.md","reason_tag":"above-appetite-residual","risk_slug":"good-line","slug_source":"agent","prefill":"valid prose."}
{"ts":"bad","incomplete":true}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^new_risks_created=1$'
  [ -f docs/risks/R002-good-line.active.md ]
}

@test "P309/P171 — three unrepresented slugs drain to three register files + queue truncated" {
  # P309 regression coverage (fold-fixed by P171, commit 9e91508).
  # Replays the original P309 observation: a 3-entry queue with three slugs
  # that have no matching docs/risks/ register file. Prior to the P171 fix,
  # this returned entries_drained=0 / new_risks_created=0 / next_action=none
  # AND did not truncate the queue — entries accumulated indefinitely off-
  # ledger. Post-fix, the drain MUST materialise all three register files,
  # truncate the queue, and emit next_action=commit-staged.
  rm -f docs/risks/TEMPLATE.md
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-24T10:00:00Z","session_id":"s1","report_path":".risk-reports/2026-05-24-r1.md","reason_tag":"above-appetite-residual","risk_slug":"p309-unrepresented-slug-a","slug_source":"agent","prefill":"First unrepresented slug — should mint a new register entry."}
{"ts":"2026-05-25T10:00:00Z","session_id":"s2","report_path":".risk-reports/2026-05-25-r2.md","reason_tag":"above-appetite-residual","risk_slug":"p309-unrepresented-slug-b","slug_source":"agent","prefill":"Second unrepresented slug — should mint a second new register entry."}
{"ts":"2026-05-25T11:00:00Z","session_id":"s2","report_path":".risk-reports/2026-05-25-r3.md","reason_tag":"above-appetite-residual","risk_slug":"p309-unrepresented-slug-c","slug_source":"agent","prefill":"Third unrepresented slug — should mint a third new register entry."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=3$'
  echo "$output" | grep -q '^new_risks_created=3$'
  echo "$output" | grep -q '^evidence_appended=0$'
  echo "$output" | grep -q '^next_action=commit-staged$'
  # Three register files materialised with sequential IDs (R002, R003, R004
  # because R001 is in the seeded README fixture).
  [ -f docs/risks/R002-p309-unrepresented-slug-a.active.md ]
  [ -f docs/risks/R003-p309-unrepresented-slug-b.active.md ]
  [ -f docs/risks/R004-p309-unrepresented-slug-c.active.md ]
  # Queue truncated — entries no longer accumulate off-ledger.
  [ ! -s .afk-run-state/risk-register-queue.jsonl ]
  # README Register table picks up all three new rows.
  grep -q 'R002-p309-unrepresented-slug-a' docs/risks/README.md
  grep -q 'R003-p309-unrepresented-slug-b' docs/risks/README.md
  grep -q 'R004-p309-unrepresented-slug-c' docs/risks/README.md
}

@test "drain succeeds against canonical (post-wipe) docs/risks/ with NO TEMPLATE.md (P171)" {
  # P171 regression coverage. The 2026-05-04 wipe direction (commit 8edaf7b)
  # removed TEMPLATE.md from canonical docs/risks/; commit 9b52610 then re-
  # canonicalized the R-file suffix to .active.md. The drain script previously
  # gated on TEMPLATE.md existence and would silent-no-op against the canonical
  # (TEMPLATE.md-absent) state. This test asserts the gate is gone: a queue with
  # one hint MUST materialize a register entry even without TEMPLATE.md.
  rm -f docs/risks/TEMPLATE.md
  cat > .afk-run-state/risk-register-queue.jsonl <<EOF
{"ts":"2026-05-03T14:00:00Z","session_id":"s1","report_path":".risk-reports/p171.md","reason_tag":"above-appetite-residual","risk_slug":"p171-canonical-fire","slug_source":"agent","prefill":"Canonical post-wipe drain works without TEMPLATE.md."}
EOF
  run bash "$SCRIPT" "$WORK_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^entries_drained=1$'
  echo "$output" | grep -q '^new_risks_created=1$'
  echo "$output" | grep -q '^next_action=commit-staged$'
  [ -f docs/risks/R002-p171-canonical-fire.active.md ]
}
