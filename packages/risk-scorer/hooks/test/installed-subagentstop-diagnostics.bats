#!/usr/bin/env bats

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMP="$(mktemp -d)"
  export TMPDIR="$TMP/runtime"
  mkdir -p "$TMPDIR" "$TMP/packed" "$TMP/repo"
  git -C "$TMP/repo" init -q
  printf 'same\n' > "$TMP/repo/state"
  git -C "$TMP/repo" add state
  git -C "$TMP/repo" -c user.name=test -c user.email=test@example.com commit -qm initial
  printf '# Risk Policy\n\n## Risk Appetite\n\n**Threshold: 5 (Low)**\n' > "$TMP/repo/RISK-POLICY.md"

  npm pack "$PACKAGE" --pack-destination "$TMP" >/dev/null
  tar -xzf "$TMP"/*.tgz -C "$TMP/packed" --strip-components=1
  DISPATCH="$TMP/packed/hooks/risk-scorer-dispatch.sh"
  DIAGNOSTIC="$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json"
}

teardown() {
  rm -rf "$TMP"
}

dispatch() {
  printf '%s' "$1" | "$DISPATCH" subagent-stop
}

input() {
  printf '{"hook_event_name":"SubagentStop","session_id":"child-session","cwd":"%s","agent_id":"child-agent","agent_type":"wr-risk-scorer:pipeline","last_assistant_message":"RISK_SCORES: commit=4 push=4 release=4\\nRISK_CWD: %s"}' \
    "$TMP/repo" "$TMP/repo"
}

@test "packed SubagentStop bridge writes privacy-safe diagnostics and one receipt" {
  dispatch "$(input)"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).outcome' "$DIAGNOSTIC")" = "receipt-written" ]
  [ "$(stat -f '%Lp' "$DIAGNOSTIC" 2>/dev/null || stat -c '%a' "$DIAGNOSTIC")" = "600" ]
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "1" ]

  dispatch "$(input)"
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$DIAGNOSTIC")" = "fresh-receipt-exists" ]
  [ "$(find "$TMPDIR/claude-risk-pending" -type f ! -name 'subagent-stop-diagnostic.json' | wc -l | tr -d ' ')" = "1" ]

  dispatch '{"hook_event_name":"SubagentStop","session_id":"private-session","agent_id":"private-agent","agent_type":"wr-risk-scorer:pipeline"}'
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$DIAGNOSTIC")" = "missing-output" ]

  dispatch '{"secret":"do-not-retain"'
  [ "$(node -p 'JSON.parse(require("fs").readFileSync(process.argv[1])).reason' "$DIAGNOSTIC")" = "malformed-json" ]
  run grep -E "child-session|child-agent|private-session|private-agent|do-not-retain|$TMP/repo" "$DIAGNOSTIC"
  [ "$status" -ne 0 ]
}
