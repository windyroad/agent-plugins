#!/usr/bin/env bats
setup() {
 ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
 PROJECT=$(mktemp -d)
 SESSION="fail-open-$$-$BATS_TEST_NUMBER"
 mkdir -p "$PROJECT/docs/decisions" "$PROJECT/docs/jtbd"
 printf '# Policy\n' > "$PROJECT/docs/STYLE-GUIDE.md"
 git -C "$PROJECT" init -q
 echo fixture > "$PROJECT/app.js"
 git -C "$PROJECT" add app.js
 git -C "$PROJECT" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture
 export CLAUDE_PROJECT_DIR="$PROJECT"
 cd "$PROJECT"
}
teardown() { rm -rf "$PROJECT"; }
@test "architecture missing approval allows with advisory" {
 run bash "$ROOT/packages/architect/hooks/architect-enforce-edit.sh" <<<"{\"session_id\":\"$SESSION\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$PROJECT/app.js\"}}"
 [ "$status" -eq 0 ]
 [[ "$output" != *'"deny"'* ]]
 [[ "$output" == *'unavailable'* ]]
}
@test "generic review gates allow unverifiable receipts" {
 for pkg in jtbd style-guide voice-tone; do
  run bash -c 'source "$1"; check_review_gate "$2" "$3" "$4"' _ "$ROOT/packages/$pkg/hooks/lib/review-gate.sh" "$SESSION" "$pkg" "$PROJECT/docs/STYLE-GUIDE.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'unavailable'* ]]
 done
}
@test "risk missing score allows without synthesizing assessment" {
 run bash -c 'source "$1"; check_risk_gate "$2" commit' _ "$ROOT/packages/risk-scorer/hooks/lib/risk-gate.sh" "$SESSION"
 [ "$status" -eq 0 ]
 [[ "$output" == *'unavailable'* ]]
}
@test "unavailable gh permits CI lookup with advisory" {
 mkdir "$PROJECT/bin"
 printf '#!/bin/sh\nexit 127\n' > "$PROJECT/bin/gh"
 chmod +x "$PROJECT/bin/gh"
 PATH="$PROJECT/bin:$PATH" run bash -c 'source "$1"; check_ci_status "$2" push' _ "$ROOT/packages/risk-scorer/hooks/lib/risk-gate.sh" "$SESSION"
 [ "$status" -eq 0 ]
 [[ "$output" == *'unavailable'* ]]
}
@test "malformed architecture input fails open" {
 run bash "$ROOT/packages/architect/hooks/architect-enforce-edit.sh" <<<'{broken'
 [ "$status" -eq 0 ]
 [[ "$output" != *'"deny"'* ]]
 [[ "$output" == *'unavailable'* ]]
}

fixture() {
 printf '%s\n' '#!/bin/sh' "echo '$2'" "exit $3" > "$1"
 chmod +x "$1"
}
@test "dispatcher advisory does not suppress later policy denial" {
 mkdir -p "$PROJECT/hooks"
 cp "$ROOT/packages/architect/hooks/architect-dispatch.sh" "$PROJECT/hooks/"
 printf '' > "$PROJECT/hooks/codex-agent-completion.mjs"
 fixture "$PROJECT/hooks/architect-enforce-edit.sh" '{"systemMessage":"receipt unavailable"}' 0
 fixture "$PROJECT/hooks/architect-oversight-marker-discipline.sh" '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"known policy failure"}}' 0
 run bash "$PROJECT/hooks/architect-dispatch.sh" pre-tool <<<'{"tool_name":"Edit"}'
 [[ "$output" == *'known policy failure'* ]]
}
@test "dispatcher drops partial denial from crashed evaluator" {
 mkdir -p "$PROJECT/hooks"
 cp "$ROOT/packages/architect/hooks/architect-dispatch.sh" "$PROJECT/hooks/"
 printf '' > "$PROJECT/hooks/codex-agent-completion.mjs"
 fixture "$PROJECT/hooks/architect-enforce-edit.sh" '{"hookSpecificOutput":{"permissionDecision":"deny"}}' 1
 fixture "$PROJECT/hooks/architect-oversight-marker-discipline.sh" '' 0
 run bash "$PROJECT/hooks/architect-dispatch.sh" pre-tool <<<'{"tool_name":"Edit"}'
 [ "$status" -eq 0 ]
 [[ "$output" != *'"deny"'* ]]
 [[ "$output" == *'unavailable'* ]]
}

@test "architecture expired receipt allows with advisory" {
 run bash -c 'source "$1"; touch "/tmp/architect-reviewed-$2"; ARCHITECT_TTL=0 check_architect_gate "$2"; rc=$?; rm -f "/tmp/architect-reviewed-$2"; exit "$rc"' _ "$ROOT/packages/architect/hooks/lib/architect-gate.sh" "$SESSION"
 [ "$status" -eq 0 ]
 [[ "$output" == *'expired'* ]]
}
@test "valid current above-appetite risk remains enforcing" {
 run bash -c 'source "$1"; RDIR="$3"; _risk_dir() { printf "%s/receipt\n" "$PWD"; }; mkdir -p "$RDIR"; _checkout_id > "$RDIR/checkout-id"; echo 25 > "$RDIR/commit"; check_risk_gate "$2" commit' _ "$ROOT/packages/risk-scorer/hooks/lib/risk-gate.sh" "$SESSION" "$PROJECT/receipt"
 [ "$status" -ne 0 ]
}
@test "generated adapter accumulates advisories for multiple writes as valid JSON" {
 node "$ROOT/scripts/sync-codex-plugin-surfaces.mjs" jtbd --build >/dev/null
 fixture "$PROJECT/child" '{"systemMessage":"unavailable"}' 0
 run bash "$ROOT/packages/jtbd/hooks-codex/codex-adapter.sh" "$PROJECT/child" <<<'{"tool_name":"apply_patch","tool_input":{"command":"*** Update File: a.js\n*** Update File: b.js"}}'
 [ "$status" -eq 0 ]
 run jq -e '.systemMessage | contains("unavailable")' <<<"$output"
 [ "$status" -eq 0 ]
 node "$ROOT/scripts/sync-codex-plugin-surfaces.mjs" jtbd --clean >/dev/null
}

@test "dispatcher emits one valid denial after earlier advisory in same child" {
 mkdir -p "$PROJECT/hooks"
 cp "$ROOT/packages/architect/hooks/architect-dispatch.sh" "$PROJECT/hooks/"
 printf '' > "$PROJECT/hooks/codex-agent-completion.mjs"
 fixture "$PROJECT/hooks/architect-enforce-edit.sh" '{"systemMessage":"unavailable"}
{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"above appetite"}}' 0
 fixture "$PROJECT/hooks/architect-oversight-marker-discipline.sh" '' 0
 run bash "$PROJECT/hooks/architect-dispatch.sh" pre-tool <<<'{"tool_name":"Edit"}'
 [ "$status" -eq 0 ]
 run jq -es 'length == 1 and .[0].hookSpecificOutput.permissionDecision == "deny"' <<<"$output"
 [ "$status" -eq 0 ]
}
@test "dispatcher malformed successful output becomes advisory" {
 mkdir -p "$PROJECT/hooks"
 cp "$ROOT/packages/architect/hooks/architect-dispatch.sh" "$PROJECT/hooks/"
 printf '' > "$PROJECT/hooks/codex-agent-completion.mjs"
 fixture "$PROJECT/hooks/architect-enforce-edit.sh" '{malformed' 0
 fixture "$PROJECT/hooks/architect-oversight-marker-discipline.sh" '' 0
 run bash "$PROJECT/hooks/architect-dispatch.sh" pre-tool <<<'{"tool_name":"Edit"}'
 [ "$status" -eq 0 ]
 [[ "$output" == *'unavailable'* ]]
}

@test "risk malformed input permits action with unavailable warning" {
 run bash "$ROOT/packages/risk-scorer/hooks/risk-score-commit-gate.sh" <<<'{broken'
 [ "$status" -eq 0 ]
 [[ "$output" == *'unavailable'* ]]
 [[ "$output" != *'"deny"'* ]]
}
