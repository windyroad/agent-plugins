#!/usr/bin/env bats

# P234 Phase 1: itil-fictional-defer-detect.sh PostToolUse:Write|Edit
# hook detects "fictional defer" rationales in `docs/retros/*.md` writes
# — defer-rationale phrases (`next retro`, `next session`, `defer
# pending`, `defer with cause:`, `deferred per`) that lack a
# SCHEDULED-FUTURE-SURFACE citation in surrounding context.
#
# Detection signal (per ticket Investigation Task 2 two-axis test):
#   1. tool_name is Write OR Edit AND file_path matches docs/retros/*.md
#   2. Written file contains a defer-rationale phrase (case-insensitive)
#   3. Within +/-5 lines of the match there is NO citation of a
#      SCHEDULED-FUTURE-SURFACE (ticket ID P\d{3} / STORY-\d{3} / R\d{3},
#      skill invocation /wr-[a-z-]+:[a-z-]+, hook script path .sh, CI
#      workflow path .github/workflows/, dated ADR ADR-\d{3} ... YYYY-MM-DD)
#   4. Match is NOT on the exception allowlist (e.g. `deferred per Branch B`).
#
# When all four hold, the hook emits a stderr advisory citing P234 + the
# SCHEDULED-FUTURE-SURFACE definition. Advisory only — never blocks
# (exit 0 always). Mirrors the itil-rfc-trailer-advisory.sh PostToolUse
# precedent (stderr + exit 0) and the itil-mid-loop-ask-detect.sh
# detection-pattern precedent (per-surface configuration at top).
#
# Per ADR-005 / ADR-052 — bats live under packages/<plugin>/hooks/test/
# and assert on emitted stderr text, not source-content. Per P081 — no
# source-grep on hook text.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-fictional-defer-detect.sh"
  TMPDIR_="$(mktemp -d)"
  RETRO_DIR="$TMPDIR_/docs/retros"
  mkdir -p "$RETRO_DIR"
  RETRO_FILE="$RETRO_DIR/2026-05-17-session-3.md"
}

teardown() {
  rm -rf "$TMPDIR_"
}

# Helper: emit PostToolUse stdin payload for a Write tool call.
emit_write_payload() {
  local file_path="$1"
  jq -n --arg p "$file_path" '{
    session_id: "fictional-defer-test",
    tool_name: "Write",
    tool_input: { file_path: $p, content: "(content already on disk)" },
    tool_response: { success: true }
  }'
}

# Helper: emit PostToolUse stdin payload for an Edit tool call.
emit_edit_payload() {
  local file_path="$1"
  jq -n --arg p "$file_path" '{
    session_id: "fictional-defer-test",
    tool_name: "Edit",
    tool_input: { file_path: $p, old_string: "x", new_string: "y" },
    tool_response: { success: true }
  }'
}

run_hook_with_write() {
  emit_write_payload "$RETRO_FILE" | bash "$HOOK"
}

run_hook_with_edit() {
  emit_edit_payload "$RETRO_FILE" | bash "$HOOK"
}

# --- Positive detection: fictional defer ---

@test "detect: defer-to-next-retro with no scheduled-future-surface emits advisory" {
  # Faithful reproduction of the P234 worked-example fictional-defer
  # class — the defer-rationale prose carries no SCHEDULED-FUTURE-
  # SURFACE citation; no ticket ID, no skill invocation, no dated ADR
  # appears in the +/-5 line window around the defer phrase.
  cat > "$RETRO_FILE" <<'EOF'
# Session 3 Retro

## Signal-vs-Noise Pass

Deferred this retro per session-length constraint (16+ briefing
entries across 13 topic files would require ~30 min of per-entry
scoring). Next retro should run a full pass.
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"P234"* ]] || [[ "$output" == *"P234"* ]]
}

@test "detect: deferred-pending-design-judgement with no scheduled-future-surface emits advisory" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 4 Retro

## Topic File Rotation Candidates

| File | Action |
|------|--------|
| governance-workflow.md | deferred pending design judgement (cascade case) |
| hooks-and-gates.md | deferred pending complexity review |
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"P234"* ]] || [[ "$output" == *"P234"* ]]
}

@test "detect: defer-with-cause-context-budget with no surface emits advisory" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 5 Retro

## Codification Candidates

Deferred with cause: context budget pressure. Next session should
revisit when fresh context is available.
EOF
  run run_hook_with_edit
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"P234"* ]] || [[ "$output" == *"P234"* ]]
}

# --- Negative paths: legitimate citations (silent exit) ---

@test "allow: defer citing P-ticket within +/-5 lines exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 3 Retro

## Signal-vs-Noise Pass

Deferred per [[P235]] (briefing SVN backlog: 146 entries across 17
topic files). Next retro will surface P235 if it has been promoted
to actionable.
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

@test "allow: defer citing skill invocation within +/-5 lines exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 4 Retro

## Tickets Deferred

Deferred pending /wr-itil:work-problems Step 6.5 above-appetite
release-loop check.
EOF
  run run_hook_with_edit
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

@test "allow: defer citing hook script path within +/-5 lines exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 5 Retro

## Codification Candidates

Defer pending packages/itil/hooks/itil-fictional-defer-detect.sh
extension to also cover the assistant-output review channel.
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

@test "allow: defer citing dated ADR within +/-5 lines exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 6 Retro

## Codification Candidates

Deferred pending ADR-044 confirmation criterion 3 graduation
(2026-05-25). Reassess after the criterion lands.
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

# --- Exception allowlist ---

@test "allow: deferred-per-Branch-B allowlist phrase exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 3 Retro

## Topic File Rotation Candidates

| File | Action |
|------|--------|
| governance-workflow.md (ratio 1.5x) | leave-as-is — deferred per Branch B |
| hooks-and-gates.md (ratio 1.3x) | leave-as-is — deferred per Branch B |
EOF
  run run_hook_with_write
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

# --- Path / tool short-circuits ---

@test "allow: tool_name != Write/Edit exits silent" {
  cat > "$RETRO_FILE" <<'EOF'
Deferred this retro per session-length constraint. Next retro should run.
EOF
  payload=$(jq -n --arg p "$RETRO_FILE" '{
    session_id: "x",
    tool_name: "Bash",
    tool_input: { command: "ls" },
    tool_response: { stdout: "" }
  }')
  run bash -c "echo '$payload' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

@test "allow: file_path outside docs/retros/ exits silent" {
  OTHER="$TMPDIR_/docs/problems/foo.md"
  mkdir -p "$(dirname "$OTHER")"
  cat > "$OTHER" <<'EOF'
Deferred this retro per session-length constraint. Next retro should run a full pass.
EOF
  payload=$(jq -n --arg p "$OTHER" '{
    session_id: "x",
    tool_name: "Write",
    tool_input: { file_path: $p, content: "" },
    tool_response: { success: true }
  }')
  run bash -c "echo '$payload' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

@test "allow: missing file_path exits silent" {
  payload=$(jq -n '{
    session_id: "x",
    tool_name: "Write",
    tool_input: {},
    tool_response: { success: true }
  }')
  run bash -c "echo '$payload' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

# --- Crash safety ---

@test "allow: malformed JSON input does not crash the hook" {
  run bash -c "echo 'not-json' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  # Either silent OR a single advisory — but never a non-zero exit.
}

@test "allow: non-existent retro file exits silent" {
  GHOST="$TMPDIR_/docs/retros/does-not-exist.md"
  payload=$(jq -n --arg p "$GHOST" '{
    session_id: "x",
    tool_name: "Write",
    tool_input: { file_path: $p, content: "" },
    tool_response: { success: true }
  }')
  run bash -c "echo '$payload' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$stderr" != *"P234"* ]]
  [[ "$output" != *"P234"* ]]
}

# --- Advisory budget per ADR-045 ---

@test "advisory output stays under ADR-045 1000-byte honour-system ceiling" {
  cat > "$RETRO_FILE" <<'EOF'
# Session 3 Retro

## Signal-vs-Noise Pass

Deferred this retro per session-length constraint. Next retro
should run a full pass.
EOF
  emit_write_payload "$RETRO_FILE" > "$TMPDIR_/payload.json"
  # Capture combined stdout+stderr; advisory channel is stderr per
  # PostToolUse precedent (itil-rfc-trailer-advisory.sh).
  combined=$(bash "$HOOK" < "$TMPDIR_/payload.json" 2>&1)
  [ -n "$combined" ]
  [ "${#combined}" -lt 1000 ]
}
