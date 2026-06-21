#!/usr/bin/env bats

# extract-risks-from-reports.sh — behavioural fixture per ADR-052.
# Walks .risk-reports/, parses RISK_REGISTER_HINT bullets per ADR-056,
# dedupes by slug, writes per-slug entries + README to docs/risks/.
#
# Tests are behavioural — replay the script against tmp-dir mock corpora,
# assert on observable filesystem outcomes (file presence, content shape,
# README rows). NO structural grep on script source.

setup() {
  ORIG_DIR="$PWD"
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SCRIPT="$REPO_ROOT/packages/risk-scorer/scripts/extract-risks-from-reports.sh"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  # All tests need RISK-POLICY.md to satisfy pre-condition
  echo "# Risk Policy" > RISK-POLICY.md
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# Pre-condition handling
# ──────────────────────────────────────────────────────────────────────────────

@test "fails with exit 1 when RISK-POLICY.md absent" {
  rm RISK-POLICY.md
  mkdir -p .risk-reports
  echo "report" > .risk-reports/r.md
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "fails with exit 1 when .risk-reports/ absent" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}

@test "fails with exit 1 when .risk-reports/ is empty" {
  mkdir -p .risk-reports
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Deterministic extraction (Phase 1)
# ──────────────────────────────────────────────────────────────────────────────

@test "extracts a single 3-column hint and writes one entry" {
  mkdir -p .risk-reports
  cat > .risk-reports/r1.md <<'EOF'
# Report

RISK_REGISTER_HINT:
- above-appetite-residual | example-risk-class | A description of the risk class
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -d docs/risks ]
  [ -f docs/risks/README.md ]
  ls docs/risks/R*-example-risk-class.active.md >/dev/null 2>&1
}

@test "dedupes 3 reports with same slug to one entry citing all 3 sources" {
  mkdir -p .risk-reports
  for i in 1 2 3; do
    cat > .risk-reports/r${i}.md <<EOF
RISK_REGISTER_HINT:
- above-appetite-residual | duplicated-class | Same risk surfaced ${i} times
EOF
  done
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  # Exactly one entry file
  count=$(ls docs/risks/R*-duplicated-class.active.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" = "1" ]
  # Source Evidence block lists all 3 reports
  entry=$(ls docs/risks/R*-duplicated-class.active.md)
  grep -q ".risk-reports/r1.md" "$entry"
  grep -q ".risk-reports/r2.md" "$entry"
  grep -q ".risk-reports/r3.md" "$entry"
}

@test "infers infosec category from confidentiality-disclosure reason-tag" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- confidentiality-disclosure | leak-shape | A confidentiality leak surfaced
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-leak-shape.active.md)
  grep -q "^\*\*Category\*\*: infosec" "$entry"
}

@test "infers operational category from above-appetite-residual reason-tag" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | ops-shape | An ops risk surfaced
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-ops-shape.active.md)
  grep -q "^\*\*Category\*\*: operational" "$entry"
}

@test "skips bullets with invalid reason-tag" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- not-a-real-tag | bogus-slug | Bogus prose
- above-appetite-residual | valid-slug | Valid prose
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  ! ls docs/risks/R*-bogus-slug.active.md 2>/dev/null
  ls docs/risks/R*-valid-slug.active.md >/dev/null 2>&1
}

# ──────────────────────────────────────────────────────────────────────────────
# Source Evidence block + ADR-026 sentinel
# ──────────────────────────────────────────────────────────────────────────────

@test "entry includes Source Evidence block with originating reports" {
  mkdir -p .risk-reports
  cat > .risk-reports/abc.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | citing-class | Cited risk
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-citing-class.active.md)
  grep -q "## Source Evidence" "$entry"
  grep -q ".risk-reports/abc.md" "$entry"
}

@test "ungrounded scoring fields use ADR-026 sentinel" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | sentinel-test | Sentinel check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-sentinel-test.active.md)
  grep -q "not estimated — no prior data" "$entry"
}

@test "Status field is auto-scaffolded pending review" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | status-test | Status check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-status-test.active.md)
  grep -q "Active (auto-scaffolded — pending review)" "$entry"
}

# ──────────────────────────────────────────────────────────────────────────────
# Recogniser-shape skeleton emission (P169 — bootstrap stops the bleeding)
# ──────────────────────────────────────────────────────────────────────────────
# Newly-scaffolded entries MUST carry a ## Recogniser section with the three
# sub-blocks awaiting curation, so new risks stop landing without the shape
# that the @windyroad/risk-scorer pipeline relies on for slug-token matching.

@test "scaffolded entry includes ## Recogniser section" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | recogniser-shape-test | Recogniser skeleton check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-recogniser-shape-test.active.md)
  grep -q "^## Recogniser" "$entry"
}

@test "scaffolded Recogniser block has Path-patterns / Diff-content / Anti-patterns sub-blocks" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | recogniser-subblock-test | Recogniser sub-block check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-recogniser-subblock-test.active.md)
  grep -q "Path patterns" "$entry"
  grep -q "Diff-content keywords" "$entry"
  grep -q "Anti-patterns" "$entry"
}

@test "scaffolded Recogniser sub-blocks carry pending-review placeholders" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | recogniser-pending-test | Recogniser pending check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-recogniser-pending-test.active.md)
  # The skeleton uses the same ADR-026-style "pending review" sentinel
  # so curators can grep for unfinished sections. Three pending-review
  # markers (one per sub-block: paths / keywords / anti-patterns).
  recog_lines=$(sed -n '/^## Recogniser/,/^## Inherent/p' "$entry" | grep -c "pending review" || true)
  [ "$recog_lines" -ge 3 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Idempotency / slug collision append
# ──────────────────────────────────────────────────────────────────────────────

@test "second run with same corpus appends to existing Source Evidence" {
  mkdir -p .risk-reports
  cat > .risk-reports/first.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | append-test | First sighting
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  entry=$(ls docs/risks/R*-append-test.active.md)
  # Add a second report with the same slug
  cat > .risk-reports/second.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | append-test | Second sighting
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  # Same entry file — no new R<NNN>
  count=$(ls docs/risks/R*-append-test.active.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" = "1" ]
  # Both reports cited
  grep -q "first.md" "$entry"
  grep -q "second.md" "$entry"
}

# ──────────────────────────────────────────────────────────────────────────────
# README generation
# ──────────────────────────────────────────────────────────────────────────────

@test "README is regenerated with Register table containing the new entry" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | readme-test | README inclusion check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f docs/risks/README.md ]
  grep -q "Risk Register" docs/risks/README.md
  grep -q "readme-test" docs/risks/README.md
  # README cites ADR-059
  grep -q "ADR-059" docs/risks/README.md
}

@test "README does NOT cite TEMPLATE.md (per user direction 2026-05-04)" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | nt | No TEMPLATE check
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -q "TEMPLATE.md" docs/risks/README.md
  ! [ -f docs/risks/TEMPLATE.md ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Dry-run mode
# ──────────────────────────────────────────────────────────────────────────────

@test "dry-run does not write any files" {
  mkdir -p .risk-reports
  cat > .risk-reports/r.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | dry-run-test | Dry-run check
EOF
  run "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  ! [ -d docs/risks ]
}

@test "dry-run reports hinted vs unhinted counts" {
  mkdir -p .risk-reports
  cat > .risk-reports/hinted.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | hinted | Hinted
EOF
  echo "no hint here" > .risk-reports/unhinted.md
  run "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"reports walked:          2"* ]]
  [[ "$output" == *"hinted (deterministic):  1"* ]]
  [[ "$output" == *"unhinted (Phase 2 todo): 1"* ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# --derived-slugs (Phase 2 input)
# ──────────────────────────────────────────────────────────────────────────────

@test "--derived-slugs adds entries from Phase 2 LLM-walk output" {
  mkdir -p .risk-reports
  echo "no hint" > .risk-reports/unhinted.md
  # Simulate Phase 2 LLM-walk producing a derived slug
  printf 'derived-slug\t1\tabove-appetite-residual\tDerived from LLM walk of unhinted.md\t.risk-reports/unhinted.md\n' > /tmp/derived.tsv
  run "$SCRIPT" --derived-slugs /tmp/derived.tsv
  [ "$status" -eq 0 ]
  ls docs/risks/R*-derived-slug.active.md >/dev/null 2>&1
  rm -f /tmp/derived.tsv
}

# ──────────────────────────────────────────────────────────────────────────────
# Octal-eval regression (P164 Phase 2 — #273 witness)
# ──────────────────────────────────────────────────────────────────────────────
# Bash arithmetic $(( ... )) parses a leading-zero operand as octal; 008/009 are
# invalid octal literals → `bash: 008: value too great for base`. The next-ID
# compute (LOCAL_MAX from zero-padded R<NNN> filenames) must force base-10 with
# 10#. Pre-seed an R008 entry so LOCAL_MAX="008" and assert the script allocates
# R009 cleanly without the octal error.

@test "allocates R009 cleanly when an R008 entry already exists (octal-eval regression, P164 Phase 2)" {
  mkdir -p docs/risks
  # Pre-existing zero-padded entry that drives LOCAL_MAX="008". Carries the
  # full field shape the README generator reads (Category/Status/Curation) so
  # the regression isolates the octal-eval boundary, not fixture malformation.
  cat > docs/risks/R008-pre-existing.active.md <<'EOF'
# Risk R008: Pre Existing
**Status**: Active
**Category**: operational
**Curation**: (human-curated)
EOF
  mkdir -p .risk-reports
  cat > .risk-reports/octal.md <<'EOF'
RISK_REGISTER_HINT:
- above-appetite-residual | octal-boundary-slug | New risk past the 008 boundary
EOF
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  # No octal-base error in output
  [[ "$output" != *"value too great for base"* ]]
  # New entry allocated as R009, not a corrupted/duplicate ID
  [ -f docs/risks/R009-octal-boundary-slug.active.md ]
}
