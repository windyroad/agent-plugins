#!/usr/bin/env bats

setup() {
  HOOK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$TMPDIR"
  SESSION="parent-session"
  TARGET="/root/external-comms"
  KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  PIPELINE_REPO="$TMP/assessed"
  OTHER_REPO="$TMP/completion"
  git init -q "$PIPELINE_REPO"
  git init -q "$OTHER_REPO"
  printf 'same\n' > "$PIPELINE_REPO/state"
  printf 'same\n' > "$OTHER_REPO/state"
  git -C "$PIPELINE_REPO" add state
  git -C "$OTHER_REPO" add state
  git -C "$PIPELINE_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
  git -C "$OTHER_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
  printf '# Risk Policy\n\n## Risk Appetite\n\n**Threshold: 5 (Low)**\n' > "$PIPELINE_REPO/RISK-POLICY.md"
}

teardown() {
  rm -rf "$TMP"
}

dispatch() {
  printf '%s' "$1" | "$HOOK_DIR/risk-scorer-dispatch.sh" post-tool
}

dispatch_subagent_stop() {
  printf '%s' "$1" | "$HOOK_DIR/risk-scorer-dispatch.sh" subagent-stop
}

spawn_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationspawn_agent","tool_input":{"agent_type":"%s"},"tool_response":"{\\"task_name\\":\\"%s\\"}"}' \
    "$SESSION" "$TMP" "${1:-wr-risk-scorer:external-comms}" "$TARGET"
}

current_spawn_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__spawn_agent","tool_input":{"agent_type":"%s"},"tool_response":{"agent_id":"%s"}}' \
    "$SESSION" "$TMP" "${1:-wr-risk-scorer:external-comms}" "$TARGET"
}

direct_spawn_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"spawn_agent","tool_input":{"agent_type":"%s"},"tool_response":{"task_name":"%s"}}' \
    "$SESSION" "$TMP" "${1:-wr-risk-scorer:external-comms}" "$TARGET"
}

close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationinterrupt_agent","tool_input":{"target":"%s"},"tool_response":"{\\"previous_status\\":{\\"completed\\":\\"EXTERNAL_COMMS_RISK_VERDICT: PASS\\\\nEXTERNAL_COMMS_RISK_KEY: %s\\"}}"}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

current_close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"EXTERNAL_COMMS_RISK_VERDICT: PASS\\nEXTERNAL_COMMS_RISK_KEY: %s"}}}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

current_pipeline_wait_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__wait_agent","tool_input":{"targets":["%s"]},"tool_response":{"status":{"%s":{"completed":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}},"timed_out":false}}' \
    "$SESSION" "$OTHER_REPO" "$TARGET" "$TARGET" "$PIPELINE_REPO"
}

current_pipeline_close_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"multi_agent_v1__close_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}}}' \
    "$SESSION" "$OTHER_REPO" "$TARGET" "$PIPELINE_REPO"
}

direct_pipeline_interrupt_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"interrupt_agent","tool_input":{"target":"%s"},"tool_response":{"previous_status":{"completed":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}}}' \
    "$SESSION" "$OTHER_REPO" "$TARGET" "$PIPELINE_REPO"
}

current_empty_wait_input() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"collaborationwait_agent","tool_input":{"timeout_ms":3600000},"tool_response":"{\"message\":\"Wait completed.\",\"timed_out\":false}"}' \
    "$SESSION" "$TMP"
}

subagent_stop_input() {
  printf '{"hook_event_name":"SubagentStop","session_id":"%s","cwd":"%s","agent_id":"%s","agent_type":"wr-risk-scorer:external-comms","last_assistant_message":"EXTERNAL_COMMS_RISK_VERDICT: PASS\\nEXTERNAL_COMMS_RISK_KEY: %s"}' \
    "$SESSION" "$TMP" "$TARGET" "$KEY"
}

pipeline_subagent_stop_input() {
  printf '{"hook_event_name":"SubagentStop","session_id":"%s","cwd":"%s","agent_id":"%s","agent_type":"wr-risk-scorer:pipeline","last_assistant_message":"RISK_SCORES: commit=%s push=%s release=%s\\nRISK_CWD: %s"}' \
    "${1:-child-session}" "$OTHER_REPO" "${2:-child-agent}" "${3:-4}" "${3:-4}" "${3:-4}" "$PIPELINE_REPO"
}

parent_bash_input() {
  printf '{"hook_event_name":"PreToolUse","session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"cwd":"%s","command":"git commit --dry-run"}}' \
    "$SESSION" "$PIPELINE_REPO" "$PIPELINE_REPO"
}

parent_prompt_input() {
  printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","cwd":"%s","prompt":"continue"}' \
    "$SESSION" "$PIPELINE_REPO"
}

dispatch_pretool() {
  printf '%s' "$1" | "$HOOK_DIR/risk-scorer-dispatch.sh" pre-tool
}

@test "desktop SubagentStop marks completion before agent close" {
  dispatch "$(current_spawn_input)"
  dispatch_subagent_stop "$(subagent_stop_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
  [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' | wc -l | tr -d ' ')" = "1" ]

  dispatch "$(current_close_input)"
  [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' | wc -l | tr -d ' ')" = "1" ]
}

@test "desktop pipeline SubagentStop hands a checkout-bound receipt to the parent without spawn state" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  diagnostic="$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).outcome' "$diagnostic")" = "receipt-written" ]
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$diagnostic")" = "checkout-bound-receipt" ]
  [ "$(stat -f '%Lp' "$diagnostic" 2>/dev/null || stat -c '%a' "$diagnostic")" = "600" ]
  run grep -F "$PIPELINE_REPO" "$diagnostic"
  [ "$status" -ne 0 ]
  run grep -F "child-session" "$diagnostic"
  [ "$status" -ne 0 ]
  run grep -F "child-agent" "$diagnostic"
  [ "$status" -ne 0 ]
  [ ! -e "$TMPDIR/claude-risk-$SESSION/commit" ]

  run dispatch_pretool "$(parent_bash_input)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  rdir="$TMPDIR/claude-risk-$SESSION"
  [ "$(cat "$rdir/commit")" = "4" ]
  expected_hash="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && "$HOOK_DIR/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
  expected_checkout="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && _checkout_id)"
  [ "$(cat "$rdir/state-hash")" = "$expected_hash" ]
  [ "$(cat "$rdir/checkout-id")" = "$expected_checkout" ]
  [ ! -e "$TMPDIR/claude-risk-child-session/commit" ]
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
  run grep -R "$PIPELINE_REPO" "$PIPELINE_REPO/.risk-reports"
  [ "$status" -ne 0 ]

  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  dispatch_pretool "$(parent_bash_input)"
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
}

@test "a distinct completion from the same agent supersedes an unchanged checkout score" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input child-one agent-one 3)"
  dispatch_subagent_stop "$(pipeline_subagent_stop_input child-one agent-one 4)"
  dispatch_pretool "$(parent_bash_input)"
  [ "$(cat "$TMPDIR/claude-risk-$SESSION/commit")" = "4" ]
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name '*.done' ! -name '*.claim' ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "0" ]
}

@test "duplicate delivery of the same completion writes one receipt" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name '*.done' ! -name '*.claim' ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "1" ]
}

@test "desktop pipeline SubagentStop records a privacy-safe rejection reason" {
  input="$(pipeline_subagent_stop_input | node -e 'let s=""; process.stdin.on("data", c => s += c); process.stdin.on("end", () => { const value = JSON.parse(s); delete value.last_assistant_message; process.stdout.write(JSON.stringify(value)); });')"
  dispatch_subagent_stop "$input"

  diagnostic="$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).outcome' "$diagnostic")" = "rejected" ]
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$diagnostic")" = "missing-output" ]
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).fields.last_assistant_message' "$diagnostic")" = "absent" ]
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "0" ]
}

@test "desktop pipeline SubagentStop records malformed JSON without leaking it" {
  dispatch_subagent_stop '{"secret":"do-not-retain"'

  diagnostic="$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$diagnostic")" = "malformed-json" ]
  run grep -F "do-not-retain" "$diagnostic"
  [ "$status" -ne 0 ]
}

@test "desktop pipeline SubagentStop records an invalid session id" {
  invalid="$(pipeline_subagent_stop_input | sed 's/child-session/invalid session/')"
  dispatch_subagent_stop "$invalid"

  diagnostic="$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$diagnostic")" = "invalid-session-id" ]
}

@test "Codex parent prompt imports a completed child receipt" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  run bash -c 'printf "%s" "$1" | "$2" user-prompt' _ "$(parent_prompt_input)" "$HOOK_DIR/risk-scorer-dispatch.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TMPDIR/claude-risk-$SESSION/commit")" = "4" ]
}

@test "imported score retains the original assessment timestamp" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  pending="$(find "$TMPDIR/claude-risk-pending" -type f ! -name '*.done' ! -name '*.claim' ! -name 'subagent-stop-diagnostic.json' -print -quit)"
  assessed_seconds="$(node -e 'console.log(Math.floor(JSON.parse(require("fs").readFileSync(process.argv[1])).createdAt / 1000))' "$pending")"
  sleep 1
  printf '%s' "$(parent_bash_input)" | "$HOOK_DIR/risk-pending-receipt.sh"
  born_seconds="$(source "$HOOK_DIR/lib/gate-helpers.sh" && _mtime "$TMPDIR/claude-risk-$SESSION/commit-born")"
  [ "$born_seconds" = "$assessed_seconds" ]
}

@test "ordinary imported score does not renew an unrelated bypass marker" {
  rdir="$TMPDIR/claude-risk-$SESSION"
  mkdir -p "$rdir"
  touch -t 200001010000 "$rdir/incident-release"
  before="$(source "$HOOK_DIR/lib/gate-helpers.sh" && _mtime "$rdir/incident-release")"
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  printf '%s' "$(parent_bash_input)" | "$HOOK_DIR/risk-pending-receipt.sh"
  after="$(source "$HOOK_DIR/lib/gate-helpers.sh" && _mtime "$rdir/incident-release")"
  [ "$after" = "$before" ]
}

@test "pending pipeline receipt rejects checkout drift" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  printf 'drift\n' >> "$PIPELINE_REPO/state"
  printf '%s' "$(parent_bash_input)" | "$HOOK_DIR/risk-pending-receipt.sh"
  [ ! -e "$TMPDIR/claude-risk-$SESSION/commit" ]
}

@test "pending pipeline receipt rejects malformed completion" {
  malformed="$(pipeline_subagent_stop_input | sed 's#RISK_CWD: [^\"]*#RISK_CWD: relative/path#')"
  dispatch_subagent_stop "$malformed"
  printf '%s' "$(parent_bash_input)" | "$HOOK_DIR/risk-pending-receipt.sh"
  [ ! -e "$TMPDIR/claude-risk-$SESSION/commit" ]
}

@test "expired consumed receipt permits rescoring the unchanged checkout" {
  dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  printf '%s' "$(parent_bash_input)" | "$HOOK_DIR/risk-pending-receipt.sh"
  done_receipt="$(find "$TMPDIR/claude-risk-pending" -name '*.done' -print -quit)"
  touch -t 200001010000 "$done_receipt"

  RISK_TTL=1 dispatch_subagent_stop "$(pipeline_subagent_stop_input)"
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name '*.done' ! -name '*.claim' ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "1" ]
}

@test "Codex completion bridge marks the exact risk agent when it closes" {
  dispatch "$(spawn_input)"
  dispatch "$(close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
  run find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.claim' -print -quit
  [ -z "$output" ]
  run find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*.done' -print -quit
  [ -n "$output" ]
}

@test "Codex completion bridge supports current agent ids and tool names" {
  dispatch "$(current_spawn_input)"
  dispatch "$(current_close_input)"

  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "direct Codex interrupt_agent completion persists the assessed checkout" {
  dispatch "$(direct_spawn_input wr-risk-scorer:pipeline)"
  dispatch "$(direct_pipeline_interrupt_input)"

  rdir="$TMPDIR/claude-risk-$SESSION"
  [ "$(cat "$rdir/commit")" = "4" ]
  expected_checkout="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && _checkout_id)"
  completion_checkout="$(cd "$OTHER_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && _checkout_id)"
  [ "$(cat "$rdir/checkout-id")" = "$expected_checkout" ]
  [ "$expected_checkout" != "$completion_checkout" ]
  [ ! -e "$OTHER_REPO/.risk-reports" ]
}

@test "PostToolUse routes direct Codex interrupt_agent completions" {
  run node -e '
    const hooks = require(process.argv[1]).hooks.PostToolUse;
    if (!hooks.some(({ matcher }) => matcher.split("|").includes("interrupt_agent"))) process.exit(1);
  ' "$HOOK_DIR/hooks.json"
  [ "$status" -eq 0 ]
}

@test "current wait response stays inert until completed-agent close" {
  dispatch "$(spawn_input)"
  dispatch "$(current_empty_wait_input)"
  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]

  dispatch "$(close_input)"
  [ -f "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "wait_agent completion refreshes a stale pipeline score exactly once" {
  rdir="$TMPDIR/claude-risk-$SESSION"
  mkdir -p "$rdir"
  printf '9' > "$rdir/commit"

  dispatch "$(current_spawn_input wr-risk-scorer:pipeline)"
  dispatch "$(current_pipeline_wait_input)"

  [ "$(cat "$rdir/commit")" = "4" ]
  [ "$(cat "$rdir/push")" = "4" ]
  [ "$(cat "$rdir/release")" = "4" ]
  expected="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && "$HOOK_DIR/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
  completion_hash="$(cd "$OTHER_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && "$HOOK_DIR/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
  [ "$(cat "$rdir/state-hash")" = "$expected" ]
  [ "$expected" = "$completion_hash" ]
  expected_checkout="$(cd "$PIPELINE_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && _checkout_id)"
  completion_checkout="$(cd "$OTHER_REPO" && source "$HOOK_DIR/lib/gate-helpers.sh" && _checkout_id)"
  [ "$(cat "$rdir/checkout-id")" = "$expected_checkout" ]
  [ "$expected_checkout" != "$completion_checkout" ]
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
  [ ! -e "$OTHER_REPO/.risk-reports" ]
  run grep -R "$PIPELINE_REPO" "$PIPELINE_REPO/.risk-reports"
  [ "$status" -ne 0 ]

  dispatch "$(current_pipeline_close_input)"
  [ "$(find "$PIPELINE_REPO/.risk-reports" -type f -name '*-commit.md' | wc -l | tr -d ' ')" = "1" ]
}

@test "pipeline completion rejects invalid assessed roots and remains retryable" {
  dispatch "$(current_spawn_input wr-risk-scorer:pipeline)"
  mkdir "$PIPELINE_REPO/subdir"

  for invalid_root in relative/path "$PIPELINE_REPO/subdir"; do
    invalid="$(current_pipeline_close_input | sed "s#RISK_CWD: $PIPELINE_REPO#RISK_CWD: $invalid_root#")"
    run dispatch "$invalid"
    [ "$status" -ne 0 ]
    [ ! -e "$TMPDIR/claude-risk-$SESSION/commit" ]
    [ "$(find "$TMPDIR/claude-risk-$SESSION" -name 'codex-agent-*' ! -name '*.claim' ! -name '*.done' | wc -l | tr -d ' ')" = "1" ]
  done

  dispatch "$(current_pipeline_close_input)"
  [ "$(cat "$TMPDIR/claude-risk-$SESSION/commit")" = "4" ]
}

@test "a reused target cannot retain a stale risk-agent role" {
  dispatch "$(current_spawn_input)"
  dispatch "$(current_spawn_input default)"
  dispatch "$(current_close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "Codex completion bridge ignores a non-risk agent" {
  dispatch "$(spawn_input default)"
  dispatch "$(close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}

@test "Codex completion bridge ignores a close without a matching spawn" {
  dispatch "$(close_input)"

  [ ! -e "$TMPDIR/claude-risk-$SESSION/external-comms-risk-reviewed-$KEY" ]
}
