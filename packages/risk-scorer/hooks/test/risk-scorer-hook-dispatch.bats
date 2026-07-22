#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOKS="$REPO_ROOT/packages/risk-scorer/hooks"
}

@test "hooks.json registers four command hooks" {
  run python3 - "$HOOKS/hooks.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
print(sum(len(entry["hooks"]) for entries in data["hooks"].values() for entry in entries))
PY
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}

@test "dispatcher is registered for session, prompt, pre-tool, and post-tool events" {
  run grep -n "risk-scorer-dispatch.sh session-start" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "risk-scorer-dispatch.sh user-prompt" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "risk-scorer-dispatch.sh pre-tool" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "risk-scorer-dispatch.sh post-tool" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "multi_agent_v1__wait_agent" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
}

@test "dispatcher combines Codex SessionStart repair and scaffold messages" {
  local dir input
  dir="$(mktemp -d)"
  mkdir -p "$dir/project"
  printf 'placeholder policy\n' > "$dir/project/RISK-POLICY.md"
  input='{"model":"gpt-test"}'

  run env CODEX_THREAD_ID=codex-test CODEX_HOME="$dir/codex" CLAUDE_PROJECT_DIR="$dir/project" \
    bash "$HOOKS/risk-scorer-dispatch.sh" session-start <<< "$input"
  rm -rf "$dir"

  [ "$status" -eq 0 ]
  run jq -er '.systemMessage | contains("Codex agents installed") and contains("bootstrap-catalog")' <<< "$output"
  [ "$status" -eq 0 ]
}

@test "dispatcher preserves Codex scaffold nudge when agent repair fails" {
  local dir input
  dir="$(mktemp -d)"
  printf 'placeholder policy\n' > "$dir/RISK-POLICY.md"
  input='{"model":"gpt-test"}'

  run env CODEX_THREAD_ID=codex-test CODEX_HOME=/dev/null CLAUDE_PROJECT_DIR="$dir" \
    bash "$HOOKS/risk-scorer-dispatch.sh" session-start <<< "$input"
  rm -rf "$dir"

  [ "$status" -eq 0 ]
  run jq -er '.systemMessage | contains("agent repair failed") and contains("bootstrap-catalog")' <<< "$output"
  [ "$status" -eq 0 ]
}

@test "dispatcher routes Write through the secret leak gate" {
  local fake_key input
  fake_key="AKIA""ABCDEFGHIJKLMNOP"
  input="$(python3 - "$fake_key" <<'PY'
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "session_id": "dispatch-test",
    "tool_input": {"file_path": "src/example.txt", "content": sys.argv[1]},
}))
PY
)"

  run bash "$HOOKS/risk-scorer-dispatch.sh" pre-tool <<<"$input"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"AWS access key"* ]]
}

@test "dispatcher routes PostToolUse Write through the WIP nudge" {
  local dir input orig
  dir="$(mktemp -d)"
  orig="$PWD"
  mkdir -p "$dir/repo" "$dir/tmp"
  cd "$dir/repo"
  git init -q
  git config user.email test@example.com
  git config user.name "Test User"
  printf 'base\n' > base.txt
  git add base.txt
  git commit -q -m initial
  mkdir -p src
  printf 'one\n' > src/one.txt
  printf 'two\n' > src/two.txt
  printf 'three\n' > src/three.txt
  input="$(python3 - <<'PY'
import json
print(json.dumps({
    "tool_name": "Write",
    "session_id": "dispatch-wip",
    "tool_input": {"file_path": "src/three.txt"},
}))
PY
)"
  run env TMPDIR="$dir/tmp" bash "$HOOKS/risk-scorer-dispatch.sh" post-tool <<<"$input"
  cd "$orig"
  rm -rf "$dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Batching risk rising"* ]]
}
