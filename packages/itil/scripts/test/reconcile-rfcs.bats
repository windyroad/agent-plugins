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
}

teardown() {
  rm -rf "$FIXTURE_DIR"
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
write_rfc() {
  local id="$1" slug="$2" status="$3"
  cat > "$FIXTURE_DIR/RFC-${id}-${slug}.${status}.md" <<EOF
---
status: ${status}
rfc-id: ${slug}
reported: 2026-05-05
decision-makers: [test]
problems: [P168]
---

# RFC-${id}: ${slug}

stub
EOF
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
