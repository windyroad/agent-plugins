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

@test "dispatcher is registered for prompt, pre-tool, and post-tool events" {
  run grep -n "risk-scorer-dispatch.sh user-prompt" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "risk-scorer-dispatch.sh pre-tool" "$HOOKS/hooks.json"
  [ "$status" -eq 0 ]
  run grep -n "risk-scorer-dispatch.sh post-tool" "$HOOKS/hooks.json"
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
