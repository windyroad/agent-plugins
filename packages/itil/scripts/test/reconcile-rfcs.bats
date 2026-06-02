#!/usr/bin/env bats

# @problem P170 — docs/rfcs/README.md needs a sibling drift-detector to
# reconcile-readme.sh once `/wr-itil:capture-rfc` and `/wr-itil:manage-rfc`
# start writing RFC files. P170 Slice 3 task B5.T6 ships this script;
# B5.T7 ships the `wr-itil-reconcile-rfcs` $PATH shim per ADR-049.
#
# Contract: `reconcile-rfcs.sh [<rfcs-dir>]` is a diagnose-only mechanical
# drift detector. It reads `<rfcs-dir>/RFC-<NNN>-*.<status>.md` files
# (default `docs/rfcs`), parses the WSJF Rankings + Verification Queue
# + Closed tables in `<rfcs-dir>/README.md`, and reports each
# disagreement between README claim and filesystem ground truth.
#
# Exit codes:
#   0 = clean (README matches filesystem for every parsed row)
#   1 = drift detected (structured diff to stdout, one row per drift)
#   2 = parse error (README missing or malformed beyond recovery)
#
# Drift line format per ADR-038 progressive-disclosure budget (≤150 bytes/row):
#   DRIFT    RFC-<NNN> wsjf-rankings: claims=open actual=<status>
#   MISSING  RFC-<NNN> wsjf-rankings: actual=<status>
#   STALE    RFC-<NNN> verification-queue: actual=<status>
#   MISMATCH RFC-<NNN> closed: actual=<status>
#
# Sibling to packages/itil/scripts/reconcile-readme.sh (P118) — same
# parse + diff structure applied at the RFC tier instead of the
# problems tier.
#
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes — RFC ranking
# integrity supports the capture-time decomposition surface)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — orchestrators
# composing with RFC-level WSJF rankings need them to match disk truth)
#
# Cross-reference:
#   P170: docs/problems/170-...open.md
#   ADR-060 (Problem-RFC-Story framework — Phase 1 item 5)
#   ADR-049 (Plugin script resolution via bin/ on PATH — paired bin shim)
#   ADR-005 — Plugin testing strategy (script-level bats governance)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/reconcile-rfcs.sh"
  FIXTURE_DIR="$(mktemp -d)"
  PROBLEMS_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_DIR" "$PROBLEMS_DIR"
}

# Helper: write a minimal valid RFC README to fixture dir.
write_minimal_readme() {
  local body="$1"
  cat > "$FIXTURE_DIR/README.md" <<EOF
# RFC Backlog

> Last reviewed: 2026-05-05

## Status

(intro)

## RFC Rankings

| WSJF | ID | Title | Severity | Status | Effort | Reported |
|------|-----|-------|----------|--------|--------|----------|
${body}

## Verification Queue

| ID | Title | Released | Verification check |
|----|-------|----------|--------------------|

## Closed

| ID | Title | Closed | Driving problems |
|----|-------|--------|------------------|
EOF
}

# Helper: write an RFC ticket file with the given status suffix.
# Optional 4th arg overrides the `problems:` list (default `[P168]`).
write_rfc() {
  local id="$1" slug="$2" status="$3"
  local problems="${4:-[P168]}"
  cat > "$FIXTURE_DIR/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
reported: 2026-05-05
decision-makers: [test]
problems: ${problems}
---

# RFC-${id}: ${slug}

stub
EOF
}

# Helper: write a problem ticket file with optional `## RFCs` table rows.
# Args: <pid-num> <slug> <status> <rfcs-rows-block>
# rfcs-rows-block is the markdown rows (already pipe-formatted) inserted under
# the `## RFCs` table header — pass an empty string to omit the section
# entirely (lazy-empty discipline per JTBD-101 atomic-fix-adopter friction guard).
write_problem() {
  local num="$1" slug="$2" status="$3" rfcs_rows="${4:-}"
  local file="$PROBLEMS_DIR/${num}-${slug}.${status}.md"
  cat > "$file" <<EOF
# Problem ${num}: ${slug}

**Status**: ${status}

## Description

stub

## Related

stub
EOF
  if [ -n "$rfcs_rows" ]; then
    cat >> "$file" <<EOF

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
${rfcs_rows}
EOF
  fi
}

# Helper: write a problem ticket under the per-state subdir layout per
# ADR-031 (state is the parent directory; filename has NO `.state.md` suffix).
# Args: <pid-num> <slug> <state> <rfcs-rows-block>
# Used to regression-test P312 — reconcile-rfcs reverse-trace must traverse
# docs/problems/<state>/<NNN>-*.md, not just flat docs/problems/<NNN>-*.<state>.md.
write_problem_subdir() {
  local num="$1" slug="$2" state="$3" rfcs_rows="${4:-}"
  mkdir -p "$PROBLEMS_DIR/$state"
  local file="$PROBLEMS_DIR/$state/${num}-${slug}.md"
  cat > "$file" <<EOF
# Problem ${num}: ${slug}

**Status**: ${state}

## Description

stub

## Related

stub
EOF
  if [ -n "$rfcs_rows" ]; then
    cat >> "$file" <<EOF

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
${rfcs_rows}
EOF
  fi
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "reconcile-rfcs: script exists" {
  [ -f "$SCRIPT" ]
}

@test "reconcile-rfcs: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Parse-error path ────────────────────────────────────────────────────────

@test "reconcile-rfcs: missing README → exit 2 (parse error)" {
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 2 ]
  [[ "$output" == *"PARSE_ERROR"* ]]
}

@test "reconcile-rfcs: README without RFC Rankings header → exit 2" {
  cat > "$FIXTURE_DIR/README.md" <<'EOF'
# RFC Backlog

(no Rankings section)
EOF
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 2 ]
}

# ── Clean path ──────────────────────────────────────────────────────────────

@test "reconcile-rfcs: empty filesystem + empty README → exit 0 (clean)" {
  write_minimal_readme ""
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "reconcile-rfcs: README and filesystem agree on one proposed RFC → exit 0" {
  write_rfc "001" "foo" "proposed"
  write_minimal_readme "| 1.5 | RFC-001 | foo | 3 Med | Proposed | M | 2026-05-05 |"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "reconcile-rfcs: accepted RFC matches Rankings (proposed/accepted/in-progress are all WSJF queue)" {
  write_rfc "002" "bar" "accepted"
  write_minimal_readme "| 2.0 | RFC-002 | bar | 4 High | Accepted | M | 2026-05-05 |"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "reconcile-rfcs: in-progress RFC matches Rankings" {
  write_rfc "003" "baz" "in-progress"
  write_minimal_readme "| 1.5 | RFC-003 | baz | 3 Med | In-Progress | M | 2026-05-05 |"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Drift paths ─────────────────────────────────────────────────────────────

@test "reconcile-rfcs: filesystem RFC missing from README → MISSING drift" {
  write_rfc "004" "qux" "proposed"
  write_minimal_readme ""
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING  RFC-004"* ]]
  [[ "$output" == *"actual=proposed"* ]]
}

@test "reconcile-rfcs: README claims RFC in Rankings but filesystem says verifying → DRIFT" {
  write_rfc "005" "blip" "verifying"
  write_minimal_readme "| 0 | RFC-005 | blip | 3 Med | Proposed | M | 2026-05-05 |"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"DRIFT    RFC-005"* ]]
  [[ "$output" == *"actual=verifying"* ]]
}

@test "reconcile-rfcs: verifying RFC missing from Verification Queue → MISSING in queue" {
  write_rfc "006" "ver" "verifying"
  write_minimal_readme ""
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING  RFC-006"* ]]
  [[ "$output" == *"verification-queue"* ]]
}

@test "reconcile-rfcs: closed RFC listed in Verification Queue → STALE" {
  write_rfc "007" "stale" "closed"
  cat > "$FIXTURE_DIR/README.md" <<'EOF'
# RFC Backlog

## RFC Rankings

| WSJF | ID | Title | Severity | Status | Effort | Reported |
|------|-----|-------|----------|--------|--------|----------|

## Verification Queue

| ID | Title | Released | Verification check |
|----|-------|----------|--------------------|
| RFC-007 | stale | 2026-05-05 | check |

## Closed

| ID | Title | Closed | Driving problems |
|----|-------|--------|------------------|
EOF
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"STALE    RFC-007"* ]]
  [[ "$output" == *"actual=closed"* ]]
}

@test "reconcile-rfcs: open-shape RFC listed in Closed section → MISMATCH" {
  write_rfc "008" "mis" "proposed"
  cat > "$FIXTURE_DIR/README.md" <<'EOF'
# RFC Backlog

## RFC Rankings

| WSJF | ID | Title | Severity | Status | Effort | Reported |
|------|-----|-------|----------|--------|--------|----------|
| 1.5 | RFC-008 | mis | 3 Med | Proposed | M | 2026-05-05 |

## Verification Queue

| ID | Title | Released | Verification check |
|----|-------|----------|--------------------|

## Closed

| ID | Title | Closed | Driving problems |
|----|-------|--------|------------------|
| RFC-008 | mis | 2026-05-05 | P168 |
EOF
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISMATCH RFC-008"* ]]
}

# ── Output format ───────────────────────────────────────────────────────────

@test "reconcile-rfcs: drift output is per-line and ≤150 bytes per line (ADR-038)" {
  write_rfc "010" "byte-budget-test-with-an-extra-long-slug-to-stress-row-width" "proposed"
  write_minimal_readme ""
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  while IFS= read -r line; do
    [ ${#line} -le 150 ] || { echo "row exceeds 150 bytes: '$line' (${#line} bytes)"; return 1; }
  done <<< "$output"
}

@test "reconcile-rfcs: stable sort order (deterministic for snapshot diffing)" {
  write_rfc "020" "second" "proposed"
  write_rfc "010" "first" "proposed"
  write_minimal_readme ""
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  # Both should appear; lower ID first per sort.
  first_line=$(echo "$output" | head -1)
  second_line=$(echo "$output" | sed -n '2p')
  [[ "$first_line" == *"RFC-010"* ]]
  [[ "$second_line" == *"RFC-020"* ]]
}

# ── Reverse-trace drift detection (B5.T8 — closes ADR-060 Confirmation criterion 3) ──
#
# Per architect Q5 verdict: when a problems-dir is provided as second positional
# arg, reconcile-rfcs.sh extends to detect drift in the `## RFCs` reverse-trace
# section on driving problem tickets. Three new drift conditions:
#
#   MISSING_REVERSE_TRACE  RFC-<NNN> in P<NNN> ## RFCs
#     RFC frontmatter `problems:` claims P<NNN> but P<NNN>'s `## RFCs` table
#     does not list RFC-<NNN>.
#
#   STALE_REVERSE_TRACE    RFC-<NNN> in P<NNN> ## RFCs
#     P<NNN>'s `## RFCs` table lists RFC-<NNN> but the RFC's frontmatter
#     `problems:` no longer claims P<NNN>.
#
#   STATUS_MISMATCH        RFC-<NNN> in P<NNN> ## RFCs claims=<X> actual=<Y>
#     P<NNN>'s `## RFCs` row claims status <X> but RFC's filesystem suffix is <Y>.
#
# Backward-compat: when no problems-dir arg is supplied (or the dir is absent),
# the script preserves the single-arg behaviour from B5.T6 (existing 18 cases
# above pass unchanged).

@test "reverse-trace: clean — RFC traces P, P has matching ## RFCs row → no drift" {
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  write_problem "168" "p168" "verifying" "| RFC-001 | accepted | foo |"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
}

@test "reverse-trace: MISSING_REVERSE_TRACE — RFC claims P, P has no ## RFCs section" {
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  write_problem "168" "p168" "verifying" ""
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING_REVERSE_TRACE"* ]]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

@test "reverse-trace: MISSING_REVERSE_TRACE — RFC claims P, P has ## RFCs but RFC absent from table" {
  write_rfc "001" "foo" "accepted"
  write_rfc "002" "bar" "proposed"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  # P168 has ## RFCs section listing RFC-002 but not RFC-001
  write_problem "168" "p168" "verifying" "| RFC-002 | proposed | bar |"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING_REVERSE_TRACE"* ]]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

@test "reverse-trace: STALE_REVERSE_TRACE — P lists RFC, RFC frontmatter no longer claims P" {
  # RFC-001 traces P169 only; P168's ## RFCs table still lists RFC-001
  write_rfc "001" "foo" "accepted" "[P169]"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  write_problem "168" "p168" "verifying" "| RFC-001 | accepted | foo |"
  write_problem "169" "p169" "open" "| RFC-001 | accepted | foo |"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"STALE_REVERSE_TRACE"* ]]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

@test "reverse-trace: STATUS_MISMATCH — P ## RFCs row claims status X but RFC suffix is Y" {
  write_rfc "001" "foo" "in-progress"
  write_minimal_readme "| 1.5 | RFC-001 | foo | 3 Med | In-Progress | M | 2026-05-05 |"
  # P168's ## RFCs table claims RFC-001 is `accepted` but the on-disk suffix is in-progress
  write_problem "168" "p168" "verifying" "| RFC-001 | accepted | foo |"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"STATUS_MISMATCH"* ]]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
  [[ "$output" == *"claims=accepted"* ]]
  [[ "$output" == *"actual=in-progress"* ]]
}

@test "reverse-trace: backward-compat — single-arg invocation skips reverse-trace check" {
  # No problems-dir → existing 18-case behaviour
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  run bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

@test "reverse-trace: problems-dir absent on disk → reverse-trace check skipped (warn-only)" {
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  rm -rf "$PROBLEMS_DIR"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  # absent problems-dir does not promote to drift; treat as backward-compat
  [ "$status" -eq 0 ]
}

@test "reverse-trace: RFC has no problems frontmatter → reverse-trace skipped for that RFC" {
  # Empty problems list; RFC-001 frontmatter has no claims to validate
  write_rfc "001" "foo" "accepted" "[]"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  write_problem "168" "p168" "verifying" ""
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
}

@test "reverse-trace: drift output is per-line and ≤150 bytes per line (ADR-038)" {
  write_rfc "001" "byte-budget-test-with-an-extra-long-slug-to-stress-row-width" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | byte-budget-test-with-an-extra-long-slug-to-stress-row-width | 3 Med | Accepted | M | 2026-05-05 |"
  write_problem "168" "p168" "verifying" ""
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  while IFS= read -r line; do
    [ ${#line} -le 150 ] || { echo "row exceeds 150 bytes: '$line' (${#line} bytes)"; return 1; }
  done <<< "$output"
}

# ── P312: per-state subdir reverse-trace (ADR-031 layout) ───────────────────
# Closes P312 — reconcile-rfcs reported spurious MISSING_REVERSE_TRACE for
# tickets that live under docs/problems/<state>/<NNN>-*.md because the
# reverse-trace pass only globbed the flat docs/problems/<NNN>-*.md layout.
# RFC-002-class dual-tolerant-glob fix mirroring the sibling already shipped
# in reconcile-readme.sh (P118).

@test "P312: reverse-trace clean when problem ticket lives in per-state subdir" {
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  # Ticket lives under docs/problems/verifying/168-p168.md (no .state suffix).
  write_problem_subdir "168" "p168" "verifying" "| RFC-001 | accepted | foo |"
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"MISSING_REVERSE_TRACE"* ]]
}

@test "P312: reverse-trace detects missing trace when problem ticket lives in per-state subdir" {
  write_rfc "001" "foo" "accepted"
  write_minimal_readme "| 2.0 | RFC-001 | foo | 3 Med | Accepted | M | 2026-05-05 |"
  # Subdir ticket WITHOUT a `## RFCs` section → MISSING_REVERSE_TRACE must fire.
  write_problem_subdir "168" "p168" "verifying" ""
  run bash "$SCRIPT" "$FIXTURE_DIR" "$PROBLEMS_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING_REVERSE_TRACE"* ]]
  [[ "$output" == *"RFC-001"* ]]
  [[ "$output" == *"P168"* ]]
}

# ── ADR-049 bin shim contract ───────────────────────────────────────────────

@test "wr-itil-reconcile-rfcs bin shim exists" {
  BIN_SHIM="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-reconcile-rfcs"
  [ -f "$BIN_SHIM" ]
}

@test "wr-itil-reconcile-rfcs bin shim is executable" {
  BIN_SHIM="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-reconcile-rfcs"
  [ -x "$BIN_SHIM" ]
}

@test "wr-itil-reconcile-rfcs bin shim dispatches to canonical script" {
  BIN_SHIM="$(cd "$SCRIPTS_DIR/../bin" && pwd)/wr-itil-reconcile-rfcs"
  write_minimal_readme ""
  run bash "$BIN_SHIM" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}
