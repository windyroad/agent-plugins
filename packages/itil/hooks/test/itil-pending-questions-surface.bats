#!/usr/bin/env bats
# Behavioural fixtures for itil-pending-questions-surface.sh (P157).
#
# SessionStart hook that reads the AFK-loop-accumulated outstanding-questions
# JSONL queue at .afk-run-state/outstanding-questions.jsonl, ranks entries
# per ADR-044 6-class taxonomy, and emits an additionalContext directive on
# stdout for the agent to surface via AskUserQuestion (batched <=4).
#
# Per ADR-052 (behavioural-tests-default), these tests exercise the hook's
# observable stdout / exit-code behaviour against fixture queue files —
# NOT the prose contents of the script itself.
#
# Behavioural surfaces under test:
#   1. Silent-on-no-content per ADR-040 Mechanism step 1 — missing or empty
#      queue file produces zero stdout and exits 0.
#   2. Non-empty queue produces additionalContext naming the entries.
#   3. ADR-044 6-class precedence — when multiple categories present,
#      deviation-approval ranks first; correction-followup ranks last.
#   4. Deduplication — identical entries (same category + question + ticket_id)
#      collapse to one.
#   5. Batching directive — when N > 4, output names the AskUserQuestion
#      batched-call cap.
#   6. Cleanup directive — output instructs the agent to truncate resolved
#      entries from the queue file.
#   7. AFK-iter cross-context-leak prevention — WR_SUPPRESS_PENDING_QUESTIONS=1
#      env var forces silent exit even when queue is non-empty.
#
# @problem P157
# @jtbd JTBD-006 (progress backlog while AFK — surface accumulated questions
#                  on session resume)
# @jtbd JTBD-001 (enforce governance without slowing down — direction-class
#                  observations resolve before user begins foreground work)
# @jtbd JTBD-101 (extend the suite — sibling SessionStart hook reuses
#                  ADR-040 silent-on-no-content shape)
# @adr ADR-032 (governance skill invocation patterns — P157 amendment for
#                JSONL-queue SessionStart variant)
# @adr ADR-040 (session-start briefing surface — SessionStart precedent +
#                silent-on-no-content shape)
# @adr ADR-044 (decision-delegation contract — 6-class taxonomy precedence)
# @adr ADR-052 (behavioural-tests-default — these tests exercise hook
#                stdout / exit-code, not script prose)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK_SCRIPT="${REPO_ROOT}/packages/itil/hooks/itil-pending-questions-surface.sh"

  TMPROOT=$(mktemp -d)
  mkdir -p "$TMPROOT/.afk-run-state"
  QUEUE_FILE="$TMPROOT/.afk-run-state/outstanding-questions.jsonl"

  export CLAUDE_PROJECT_DIR="$TMPROOT"
  unset WR_SUPPRESS_PENDING_QUESTIONS
}

teardown() {
  rm -rf "$TMPROOT"
  unset CLAUDE_PROJECT_DIR WR_SUPPRESS_PENDING_QUESTIONS
}

# ---------------------------------------------------------------------------
# Existence — minimum surface required for hooks.json to wire it up.
# ---------------------------------------------------------------------------

@test "hook script exists and is executable" {
  [ -f "$HOOK_SCRIPT" ]
  [ -x "$HOOK_SCRIPT" ]
}

@test "hooks.json registers the SessionStart hook with matcher startup" {
  HOOKS_JSON="${REPO_ROOT}/packages/itil/hooks/hooks.json"
  run jq -r '.hooks.SessionStart[] | select(.matcher == "startup") | .hooks[].command' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'itil-pending-questions-surface.sh'
}

# ---------------------------------------------------------------------------
# Silent-on-no-content per ADR-040 Mechanism step 1.
# ---------------------------------------------------------------------------

@test "missing queue file: silent exit 0" {
  # No queue file at all (typical state for projects that have never run AFK).
  rm -f "$QUEUE_FILE"
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "empty queue file: silent exit 0" {
  : > "$QUEUE_FILE"
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "queue with only whitespace lines: silent exit 0" {
  printf '\n   \n\t\n' > "$QUEUE_FILE"
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Non-empty queue → additionalContext emitted.
# ---------------------------------------------------------------------------

@test "single entry: additionalContext names the question and ticket_id" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Pick A or B for the storage layer?","context":"iter1 P200","ticket_id":"P200"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'Pick A or B for the storage layer?'
  echo "$output" | grep -qF 'P200'
}

@test "single entry: output cites the queue file path so user can inspect" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q1","context":"c1","ticket_id":"P201"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF '.afk-run-state/outstanding-questions.jsonl'
}

# ---------------------------------------------------------------------------
# ADR-044 6-class precedence ordering.
# ---------------------------------------------------------------------------

@test "ranking: deviation-approval ranks first among mixed categories" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"correction-followup","question":"low-rank Q","context":"c","ticket_id":"P301"}
{"category":"direction","question":"mid-rank Q","context":"c","ticket_id":"P302"}
{"category":"deviation-approval","existing_decision":"ADR-001","contradicting_evidence":"ev","proposed_shape":"amend","rationale":"r","ticket_id":"P303"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  # The deviation-approval entry's rationale must appear before the direction Q
  # in the output (precedence: deviation-approval > direction > correction-followup).
  DEVIATION_LINE=$(echo "$output" | grep -n 'P303' | head -1 | cut -d: -f1)
  DIRECTION_LINE=$(echo "$output" | grep -n 'mid-rank Q' | head -1 | cut -d: -f1)
  CORRECTION_LINE=$(echo "$output" | grep -n 'low-rank Q' | head -1 | cut -d: -f1)
  [ -n "$DEVIATION_LINE" ]
  [ -n "$DIRECTION_LINE" ]
  [ -n "$CORRECTION_LINE" ]
  [ "$DEVIATION_LINE" -lt "$DIRECTION_LINE" ]
  [ "$DIRECTION_LINE" -lt "$CORRECTION_LINE" ]
}

@test "ranking: full 6-class precedence is deviation > direction > one-time > silent-framework > taste > correction" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"taste","question":"q-taste","context":"c","ticket_id":"P401"}
{"category":"correction-followup","question":"q-correction","context":"c","ticket_id":"P402"}
{"category":"silent-framework","question":"q-silent","context":"c","ticket_id":"P403"}
{"category":"one-time-override","question":"q-onetime","context":"c","ticket_id":"P404"}
{"category":"direction","question":"q-direction","context":"c","ticket_id":"P405"}
{"category":"deviation-approval","existing_decision":"ADR-X","contradicting_evidence":"ev","proposed_shape":"amend","rationale":"q-deviation","ticket_id":"P406"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  # Capture the line number of each category-tagged ticket marker; assert order.
  L1=$(echo "$output" | grep -n 'P406' | head -1 | cut -d: -f1)
  L2=$(echo "$output" | grep -n 'q-direction' | head -1 | cut -d: -f1)
  L3=$(echo "$output" | grep -n 'q-onetime' | head -1 | cut -d: -f1)
  L4=$(echo "$output" | grep -n 'q-silent' | head -1 | cut -d: -f1)
  L5=$(echo "$output" | grep -n 'q-taste' | head -1 | cut -d: -f1)
  L6=$(echo "$output" | grep -n 'q-correction' | head -1 | cut -d: -f1)
  [ "$L1" -lt "$L2" ]
  [ "$L2" -lt "$L3" ]
  [ "$L3" -lt "$L4" ]
  [ "$L4" -lt "$L5" ]
  [ "$L5" -lt "$L6" ]
}

# ---------------------------------------------------------------------------
# Deduplication of identical entries.
# ---------------------------------------------------------------------------

@test "dedup: identical entries (same category+question+ticket_id) collapse to one" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Same Q","context":"c","ticket_id":"P500"}
{"category":"direction","question":"Same Q","context":"c","ticket_id":"P500"}
{"category":"direction","question":"Same Q","context":"different-context-different-iter","ticket_id":"P500"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  # "Same Q" should appear exactly once in the output (after dedup).
  COUNT=$(echo "$output" | grep -cF 'Same Q')
  [ "$COUNT" -eq 1 ]
}

@test "dedup: different question text on same ticket survives as two entries" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Question one","context":"c","ticket_id":"P501"}
{"category":"direction","question":"Question two","context":"c","ticket_id":"P501"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'Question one'
  echo "$output" | grep -qF 'Question two'
}

# ---------------------------------------------------------------------------
# Batching directive — names the AskUserQuestion <=4 cap when N > 4.
# ---------------------------------------------------------------------------

@test "batching: output names AskUserQuestion when entries present" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q1","context":"c","ticket_id":"P600"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qiE 'AskUserQuestion'
}

@test "batching: directive cites the <=4-per-call cap" {
  # 5 entries should trigger the batching note since AskUserQuestion caps at 4.
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q1","context":"c","ticket_id":"P601"}
{"category":"direction","question":"Q2","context":"c","ticket_id":"P602"}
{"category":"direction","question":"Q3","context":"c","ticket_id":"P603"}
{"category":"direction","question":"Q4","context":"c","ticket_id":"P604"}
{"category":"direction","question":"Q5","context":"c","ticket_id":"P605"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '(<=|≤|max(imum)?[ -]?)4|four'
}

# ---------------------------------------------------------------------------
# Cleanup-on-resolve directive.
# ---------------------------------------------------------------------------

@test "cleanup: output instructs the agent to remove resolved entries from the queue" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q1","context":"c","ticket_id":"P700"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  # The cleanup directive must instruct removing resolved entries from the
  # queue file. Match on the load-bearing words rather than exact phrasing.
  echo "$output" | grep -qiE '(remove|delete|truncat|clear).*queue|outstanding-questions\.jsonl'
}

# ---------------------------------------------------------------------------
# AFK-iter cross-context-leak prevention (architect Note 2).
# ---------------------------------------------------------------------------

@test "WR_SUPPRESS_PENDING_QUESTIONS=1 forces silent exit even when queue non-empty" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q-should-not-leak","context":"c","ticket_id":"P800"}
JSONL
  export WR_SUPPRESS_PENDING_QUESTIONS=1
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "WR_SUPPRESS_PENDING_QUESTIONS=0 does NOT suppress (only =1 does)" {
  cat > "$QUEUE_FILE" <<'JSONL'
{"category":"direction","question":"Q-must-surface","context":"c","ticket_id":"P801"}
JSONL
  export WR_SUPPRESS_PENDING_QUESTIONS=0
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'Q-must-surface'
}

@test "work-problems Step 5 dispatch block exports WR_SUPPRESS_PENDING_QUESTIONS=1 before claude -p" {
  # The orchestrator MUST set WR_SUPPRESS_PENDING_QUESTIONS=1 before each
  # iter subprocess spawn so the queue does not surface inside iter contexts
  # (cross-context leak per ADR-032 line 127).
  WP_SKILL="${REPO_ROOT}/packages/itil/skills/work-problems/SKILL.md"
  [ -f "$WP_SKILL" ]
  # Find the export line; it must come before the "claude -p" dispatch line in
  # the same Step 5 dispatch block.
  EXPORT_LINE=$(grep -n 'export WR_SUPPRESS_PENDING_QUESTIONS=1' "$WP_SKILL" | head -1 | cut -d: -f1)
  CLAUDE_P_LINE=$(grep -n '^claude -p \\$' "$WP_SKILL" | head -1 | cut -d: -f1)
  [ -n "$EXPORT_LINE" ]
  [ -n "$CLAUDE_P_LINE" ]
  [ "$EXPORT_LINE" -lt "$CLAUDE_P_LINE" ]
}

# ---------------------------------------------------------------------------
# Malformed input — silent skip, do not crash the SessionStart hook chain.
# ---------------------------------------------------------------------------

@test "malformed JSON line: skipped silently, well-formed lines still surface" {
  cat > "$QUEUE_FILE" <<'JSONL'
{not valid json at all
{"category":"direction","question":"Valid Q","context":"c","ticket_id":"P900"}
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qF 'Valid Q'
}

@test "all-malformed queue: silent exit 0 (do not block session start)" {
  # Defensive — if the queue file is corrupted, the hook MUST NOT prevent
  # the session from starting. SessionStart hook failures cascade into
  # "session won't start" UX which is far worse than missing one surfacing.
  cat > "$QUEUE_FILE" <<'JSONL'
{not json
also not json
JSONL
  run "$HOOK_SCRIPT"
  [ "$status" -eq 0 ]
}
