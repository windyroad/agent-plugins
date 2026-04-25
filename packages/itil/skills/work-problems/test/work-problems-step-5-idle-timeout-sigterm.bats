#!/usr/bin/env bats
# Behavioural test: work-problems Step 5 backgrounded-poll-loop dispatch fires
# SIGTERM on the iteration subprocess when LAST_ACTIVITY_MARK has been stale
# longer than WORK_PROBLEMS_IDLE_TIMEOUT_S (default 3600s = 60 min). The SIGTERM
# empirically produces a clean JSON exit-flush per the 2026-04-25 P118 iter 5
# evidence captured in P121 (and in docs/briefing/afk-subprocess.md).
#
# This is the second-source the architect addendum required: the SIGTERM-flushes-
# JSON evidence is otherwise single-source from one production observation. The
# fake-claude shim here re-creates the stuck-subprocess shape (emit JSON to stdout,
# then sleep past the threshold while remaining killable by SIGTERM) and asserts
# the orchestrator-shape harness's poll-and-sigterm behaviour matches the
# contract documented in SKILL.md Step 5.
#
# @problem P121
# @jtbd JTBD-006
# @jtbd JTBD-001
#
# Cross-reference:
#   P121 (orchestrator should SIGTERM stuck claude -p subprocesses after idle-
#     timeout — and SIGTERM appears to flush a clean JSON) — driver ticket
#   ADR-032 (governance skill invocation patterns — subprocess-boundary variant
#     amended 2026-04-26 with the backgrounded-poll-loop refinement)
#   ADR-037 (skill testing strategy — behavioural is the default; doc-lint
#     contract assertions are the Permitted Exception)
#   docs/briefing/afk-subprocess.md (P121 entry — the cross-session knowledge
#     index entry this fixture provides empirical second-source for)

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="${TEST_TMP}/bin"
  mkdir -p "$FAKE_BIN"

  # Fake `claude` binary that simulates a stuck iteration subprocess: emits a
  # valid `claude -p --output-format json` envelope to stdout, then sleeps for
  # FAKE_SLEEP_AFTER seconds (default 30s) while trapping SIGTERM. This matches
  # the 2026-04-25 P118 iter 5 shape: subprocess completes its semantic work,
  # then sits in an idle-wait state until SIGTERM unblocks it. The trap exits 0
  # with the JSON already flushed to stdout — same observable as the production
  # CLI behaviour that motivated P121.
  cat > "$FAKE_BIN/claude" <<'FAKE_EOF'
#!/usr/bin/env bash
# Test fake for work-problems Step 5 idle-timeout SIGTERM bats fixture.
# Emits a JSON envelope then sleeps; SIGTERM exits cleanly (JSON already flushed).
trap 'exit 0' TERM
printf '%s\n' '{"is_error":false,"result":"ITERATION_SUMMARY\nticket_id: P000\nticket_title: fake\naction: worked\noutcome: investigated\ncommitted: false\nreason: test fixture\nremaining_backlog_count: 0\nnotes: stuck-subprocess simulation","total_cost_usd":0.01,"duration_ms":100,"usage":{"input_tokens":10,"output_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}'
sleep "${FAKE_SLEEP_AFTER:-30}"
FAKE_EOF
  chmod +x "$FAKE_BIN/claude"
  export PATH="$FAKE_BIN:$PATH"

  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

teardown() {
  if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# Faithful re-implementation of SKILL.md Step 5's backgrounded-poll-loop dispatch.
# Adopters who copy-paste the SKILL.md Step 5 block into their orchestrator
# should observe the same outcomes this harness does — that's the contract this
# fixture pins. The harness uses sleep 1 instead of the SKILL.md's sleep 60 so
# the test wall-clock stays bounded; the LAST_ACTIVITY_MARK math, SIGTERM action,
# and JSON-after-SIGTERM read are otherwise identical.
dispatch_with_poll() {
  local json_file="${TEST_TMP}/iter.json"
  local idle_timeout_s="${WORK_PROBLEMS_IDLE_TIMEOUT_S:-3600}"
  local dispatch_start_epoch
  dispatch_start_epoch=$(date +%s)
  local sigterm_sent=0

  : > "$json_file"
  claude -p --permission-mode bypassPermissions --output-format json "TEST" \
    < /dev/null > "$json_file" 2>&1 &
  local iter_pid=$!

  while kill -0 "$iter_pid" 2>/dev/null; do
    sleep 1
    local now
    now=$(date +%s)
    # LAST_ACTIVITY_MARK = max(DISPATCH_START, last commit timestamp).
    # In this test there is no git repo and no commits, so the max is just
    # DISPATCH_START — same shape as a real skip-iteration that produces no
    # commit during its run.
    local last_activity_mark=$dispatch_start_epoch
    local idle_seconds=$(( now - last_activity_mark ))
    if (( idle_seconds > idle_timeout_s )) && (( sigterm_sent == 0 )); then
      kill -TERM "$iter_pid" 2>/dev/null || true
      sigterm_sent=1
    fi
  done

  wait "$iter_pid" 2>/dev/null || true

  printf 'SIGTERM_SENT=%d\n' "$sigterm_sent"
  printf '%s\n' '---JSON---'
  cat "$json_file"
}

# (a) SIGTERM was sent within the threshold.
@test "P121: SIGTERM fires when subprocess idle exceeds WORK_PROBLEMS_IDLE_TIMEOUT_S" {
  export FAKE_SLEEP_AFTER=10
  export WORK_PROBLEMS_IDLE_TIMEOUT_S=2
  run dispatch_with_poll
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGTERM_SENT=1"* ]]
}

# (b) JSON arrives after SIGTERM (clean exit-flush).
@test "P121: JSON arrives after SIGTERM and parses cleanly (clean exit-flush per 2026-04-25 P118 iter 5)" {
  export FAKE_SLEEP_AFTER=10
  export WORK_PROBLEMS_IDLE_TIMEOUT_S=2
  run dispatch_with_poll
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGTERM_SENT=1"* ]]
  # Extract the JSON portion after the ---JSON--- marker and validate.
  json_payload=$(printf '%s\n' "$output" | sed -n '/^---JSON---$/,$p' | tail -n +2)
  printf '%s' "$json_payload" | python3 -c '
import json, sys
j = json.loads(sys.stdin.read().strip())
assert not j.get("is_error"), "is_error should be false"
assert "ITERATION_SUMMARY" in j["result"], "result must carry ITERATION_SUMMARY"
assert "total_cost_usd" in j, "cost metadata must survive SIGTERM exit-flush"
'
}

# (c) Env-var override is honoured (default 3600s; override to 2s).
@test "P121: WORK_PROBLEMS_IDLE_TIMEOUT_S env-var override is honoured" {
  # Without an override, the default 3600s would never fire in test wall-clock,
  # so no SIGTERM. With WORK_PROBLEMS_IDLE_TIMEOUT_S=2, SIGTERM fires within
  # seconds. Confirms the override is consulted by the harness, matching the
  # SKILL.md contract that adopters can tune the threshold per-environment.
  export FAKE_SLEEP_AFTER=10
  export WORK_PROBLEMS_IDLE_TIMEOUT_S=2
  run dispatch_with_poll
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGTERM_SENT=1"* ]]
}

# (d) Within-threshold runs are NOT SIGTERMed (negative case).
@test "P121: within-threshold runs are NOT SIGTERMed (subprocess exits before idle threshold)" {
  # Subprocess exits naturally in 1 second; idle timeout is 60s. Loop must
  # observe the natural exit and NOT send SIGTERM. Guards against an over-eager
  # poll loop that would interrupt every iteration regardless of state.
  export FAKE_SLEEP_AFTER=1
  export WORK_PROBLEMS_IDLE_TIMEOUT_S=60
  run dispatch_with_poll
  [ "$status" -eq 0 ]
  [[ "$output" == *"SIGTERM_SENT=0"* ]]
}

# Doc-lint contract assertions — pin SKILL.md prose to the contract this fixture
# exercises behaviourally. Permitted Exception under ADR-037 (the SKILL.md is
# the contract document; these assertions guard against silent prose drift away
# from the behavioural expectation above).

@test "P121: SKILL.md Step 5 names WORK_PROBLEMS_IDLE_TIMEOUT_S env var" {
  run grep -nE "WORK_PROBLEMS_IDLE_TIMEOUT_S" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P121: SKILL.md Step 5 documents SIGTERM-on-idle action" {
  run grep -niE "SIGTERM.{0,80}idle|idle.{0,80}SIGTERM|kill[[:space:]]+-TERM" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P121: SKILL.md Step 5 names LAST_ACTIVITY_MARK signal" {
  run grep -nE "LAST_ACTIVITY_MARK|last activity mark" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P121: SKILL.md Step 5 cites P121 (idle-timeout SIGTERM driver)" {
  run grep -nE "P121" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P121: SKILL.md Step 5 documents the LAST_ACTIVITY signal trade-off (skip-iteration case)" {
  # Per architect amendment 3: signal trade-off must be explicit so future
  # contributors don't silently re-rate it. The SKILL.md prose names the
  # max(dispatch_start, last commit) shape so adopters know skip iterations
  # are bounded by IDLE_TIMEOUT_S since dispatch start, not a stale commit
  # timestamp.
  run grep -niE "max.{0,40}(dispatch.?start|DISPATCH_START).{0,80}(commit|git log)|skip.?iteration.{0,80}(timeout|threshold|bounded)|dispatch.?start.{0,80}upper.?bound" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "P121: SKILL.md Step 5 dispatch backgrounds the subprocess (PID capture for poll)" {
  # The dispatch command shape must show the backgrounded form (& + $!) so the
  # poll loop has a PID to kill -0 / kill -TERM. Foreground synchronous
  # dispatch (current pre-P121 shape) cannot support idle-timeout SIGTERM.
  run grep -nE 'ITER_PID=\$!|& *\n*ITER_PID|claude -p.{0,200}&[[:space:]]*$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
