#!/usr/bin/env bats
#
# packages/retrospective/scripts/test/check-tickets-deferred-cause.bats
#
# Behavioural tests for `check-tickets-deferred-cause.sh` — the
# Tickets Deferred cause-allowlist advisory script (P148). Mirrors
# the fixture-based test pattern of `check-ask-hygiene.bats`.
#
# Tests are behavioural per ADR-005 / ADR-037 / P081 — they exercise
# the script end-to-end against fixture retro summary directories
# and assert on stdout / stderr / exit shape. No structural greps of
# the script source itself.
#
# @problem P148 (Agent defers ticket creation — broadens Stage 1 fallback gate)
# @problem P081 (Structural-content tests are wasteful — behavioural preferred)
# @adr ADR-044 (Decision-Delegation Contract)
# @adr ADR-040 (Tier 3 advisory-not-fail-closed)
# @adr ADR-013 Rule 6 (non-interactive fail-safe)
# @adr ADR-005 / ADR-037 (Plugin testing strategy — behavioural tests)
# @jtbd JTBD-001 / JTBD-006 / JTBD-201

SCRIPT="${BATS_TEST_DIRNAME}/../check-tickets-deferred-cause.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ── Pre-checks ──────────────────────────────────────────────────────────────

@test "script file exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "missing retros dir exits 2 with error message on stderr" {
  run bash "$SCRIPT" "$TEST_DIR/does-not-exist"
  [ "$status" -eq 2 ]
  [[ "$output" == *"retros dir not found"* ]]
}

@test "empty retros dir exits 0 with empty stdout" {
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "default retros-dir argument is docs/retros (when omitted)" {
  cd "$TEST_DIR"
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" == *"docs/retros"* ]]
}

# ── No-defer steady state ───────────────────────────────────────────────────

@test "retro file with no Tickets Deferred section emits no output" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
## Session Retrospective

### Briefing Changes
- Added: foo

### Problems Created/Updated
- P148: opened

### No Action Needed
- learning captured
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Good fixture (skill_unavailable cause) ──────────────────────────────────

@test "good fixture: skill_unavailable cause → 0 violations" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
## Session Retrospective

### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| Polling regex deadlock observation | `skill_unavailable` | Step 2b detection |
| SIGTERM flush caveat | `skill_unavailable` | Step 4a verification |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred=2"* ]]
  [[ "$output" == *"with_valid_cause=2"* ]]
  [[ "$output" == *"violations=0"* ]]
}

# ── Bad fixture (session_pressure cause — the P148 anti-pattern) ────────────

@test "bad fixture: session_pressure cause → all entries are violations" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
## Session Retrospective

### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| Polling regex deadlock | `session_pressure` | Step 2b |
| SIGTERM flush caveat | `context_heavyweight` | Step 4a |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred=2"* ]]
  [[ "$output" == *"with_valid_cause=0"* ]]
  [[ "$output" == *"violations=2"* ]]
}

# ── Legacy fixture (no Cause column — pre-P148 retro shape) ─────────────────

@test "legacy fixture: no Cause column → all entries are violations" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
## Session Retrospective

### Tickets Deferred

| Observation | Citation |
|-------------|----------|
| Polling regex deadlock | Step 2b |
| SIGTERM flush caveat | Step 4a |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred=2"* ]]
  [[ "$output" == *"violations=2"* ]]
}

@test "legacy fixture exit code is 0 — advisory contract holds for AFK safety" {
  # JTBD-006 line 32 (extended AFK safety): legacy retros lacking the Cause
  # column would break AFK loops if exit code went non-zero. Fail-closed
  # escalation belongs at a future hook tier per P135 R6 trajectory, not
  # at the script.
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Citation |
|-------------|----------|
| obs1 | step1 |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
}

# ── Mixed fixture ───────────────────────────────────────────────────────────

@test "mixed fixture: one valid + one invalid → violations=1, with_valid_cause=1" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| Valid observation | `skill_unavailable` | Step 2b |
| Invalid observation | `session_pressure` | Step 4a |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred=2"* ]]
  [[ "$output" == *"with_valid_cause=1"* ]]
  [[ "$output" == *"violations=1"* ]]
}

# ── Empty Cause cell ────────────────────────────────────────────────────────

@test "empty Cause cell counts as a violation (cause-required invariant)" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| Observation with empty cause |   | Step 2b |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"violations=1"* ]]
}

# ── Format tolerance ────────────────────────────────────────────────────────

@test "Cause cell tolerates surrounding whitespace and bold markers" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| obs1 |    `skill_unavailable`    | Step 2b |
| obs2 | **skill_unavailable** | Step 4a |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deferred=2"* ]]
  [[ "$output" == *"with_valid_cause=2"* ]]
  [[ "$output" == *"violations=0"* ]]
}

@test "placeholder template row is skipped — not counted as a deferred entry" {
  # The retro summary template includes a placeholder example row in the
  # SKILL.md template (with `<one-line observation summary>` literal text).
  # When a retro is rendered with no real deferred entries, the template
  # row may persist; the script must NOT count it as a real deferred
  # observation.
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| <one-line observation summary> | `skill_unavailable` | <retro-step-citation> |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Multi-file behaviour ────────────────────────────────────────────────────

@test "multiple retro files emit per-file lines plus a TOTAL summary line" {
  cat > "$TEST_DIR/2026-04-25-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| good obs | `skill_unavailable` | Step 2b |
RETRO
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| bad obs | `session_pressure` | Step 4a |
RETRO
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RETRO 2026-04-25"* ]]
  [[ "$output" == *"RETRO 2026-04-29"* ]]
  [[ "$output" == *"TOTAL files=2 deferred=2 with_valid_cause=1 violations=1"* ]]
}

@test "files sorted oldest-first by date prefix" {
  for d in 27 25 26; do
    cat > "$TEST_DIR/2026-04-$d-retro.md" <<RETRO
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| obs$d | \`skill_unavailable\` | Step$d |
RETRO
  done
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  line1="${lines[0]}"
  line2="${lines[1]}"
  line3="${lines[2]}"
  [[ "$line1" == *"2026-04-25"* ]]
  [[ "$line2" == *"2026-04-26"* ]]
  [[ "$line3" == *"2026-04-27"* ]]
}

# ── File-type filtering ─────────────────────────────────────────────────────

@test "ask-hygiene trail files are skipped (not retro summaries)" {
  cat > "$TEST_DIR/2026-04-29-ask-hygiene.md" <<'TRAIL'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| should be ignored | `session_pressure` | irrelevant |
TRAIL
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "context-analysis files are skipped (not retro summaries)" {
  cat > "$TEST_DIR/2026-04-29-context-analysis.md" <<'CTX'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| should be ignored | `session_pressure` | irrelevant |
CTX
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "files without a YYYY-MM-DD date prefix are skipped" {
  cat > "$TEST_DIR/README.md" <<'RM'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| should be ignored | `session_pressure` | irrelevant |
RM
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Cross-shell portability (P124 / P133 lessons) ───────────────────────────

@test "script glob iteration uses portable for-loop existence check" {
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"*.md"* ]]
}

# ── Read-only contract ──────────────────────────────────────────────────────

@test "script is read-only — fixture tree unchanged after run" {
  cat > "$TEST_DIR/2026-04-29-retro.md" <<'RETRO'
### Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| obs1 | `skill_unavailable` | Step 2b |
RETRO
  pre_hash=$(find "$TEST_DIR" -type f -exec cksum {} \; 2>/dev/null | sort | cksum | awk '{print $1}')
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  post_hash=$(find "$TEST_DIR" -type f -exec cksum {} \; 2>/dev/null | sort | cksum | awk '{print $1}')
  [ "$pre_hash" = "$post_hash" ]
}
