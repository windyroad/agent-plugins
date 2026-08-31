#!/usr/bin/env bats
# Behavioural regression for the JTBD eval's authoritative inline output.
# The mock emits Claude stream-json so the real runner, parser, and cleanup
# execute without an LLM call (P324 / RFC-012 S1).

setup() {
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-agent-eval.sh"
  GLOBAL_VERDICT_FILE="/tmp/jtbd-verdict"
  GLOBAL_VERDICT_BEFORE="missing"
  if [ -e "$GLOBAL_VERDICT_FILE" ]; then
    GLOBAL_VERDICT_BEFORE="$(shasum -a 256 "$GLOBAL_VERDICT_FILE")"
  fi

  TMP="$(mktemp -d)"
  BIN="$TMP/bin"
  mkdir -p "$BIN"
  export PATH="$BIN:$PATH"
  export FAKE_CLAUDE_MODE=success
  export CLAUDE_CALLED="$TMP/claude-called"
  export EVAL_VERDICT_PATH_FILE="$TMP/eval-verdict-path"
  export EXPECTED_REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../../../.." && pwd -P)"

  cat > "$BIN/claude" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

touch "$CLAUDE_CALLED"
python3 - "$EXPECTED_REPO_ROOT" "$@" <<'PY'
import json
import os
import sys

repo_root = sys.argv[1]
args = sys.argv[2:]

def option(name):
    position = args.index(name)
    return args[position + 1]

assert option("--setting-sources") == ""
assert option("--tools") == "Read,Glob,Grep,Bash"
settings = json.loads(option("--settings"))
sandbox = settings["sandbox"]
assert sandbox["enabled"] is True
assert sandbox["failIfUnavailable"] is True
assert sandbox["autoAllowBashIfSandboxed"] is True
assert sandbox["allowUnsandboxedCommands"] is False
verdict_file = os.environ["JTBD_VERDICT_FILE"]
assert verdict_file != "/tmp/jtbd-verdict"
assert sandbox["filesystem"]["allowWrite"] == [
    "//" + os.path.realpath(verdict_file).lstrip("/")
]
assert sandbox["filesystem"]["denyWrite"] == [
    "//" + os.path.realpath(repo_root).lstrip("/")
]
for forbidden in (
    "--add-dir",
    "--dangerously-skip-permissions",
    "--allow-dangerously-skip-permissions",
    "--allowedTools",
    "--allowed-tools",
):
    assert all(
        argument != forbidden and not argument.startswith(forbidden + "=")
        for argument in args
    )
assert "bypassPermissions" not in args
assert not any(
    argument.startswith("--permission-mode=bypassPermissions")
    for argument in args
)
PY
printf '%s' "$JTBD_VERDICT_FILE" > "$EVAL_VERDICT_PATH_FILE"
case "$FAKE_CLAUDE_MODE" in
  nonzero)
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"JTBD Review: PASS"}]},"parent_tool_use_id":null}'
    printf 'PASS' > "$JTBD_VERDICT_FILE"
    exit 7
    ;;
  malformed)
    printf '%s\n' 'not-json'
    printf 'PASS' > "$JTBD_VERDICT_FILE"
    ;;
  missing-marker)
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"JTBD Review: PASS"}]},"parent_tool_use_id":null}'
    ;;
  success)
    printf '%s\n' \
      '{"type":"assistant","message":{"content":[{"type":"text","text":"JTBD Review: PASS\n\nAligned with JTBD-006."}]},"parent_tool_use_id":null}' \
      '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"tool-1","name":"Bash","input":{}}]},"parent_tool_use_id":null}' \
      '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tool-1","content":"ok"}]},"parent_tool_use_id":null}' \
      '{"type":"assistant","message":{"content":[{"type":"text","text":"Marker written."}]},"parent_tool_use_id":null}' \
      '{"type":"result","subtype":"success","result":"Marker written."}'
    printf 'PASS' > "$JTBD_VERDICT_FILE"
    ;;
esac
MOCK
  chmod +x "$BIN/claude"
}

teardown() {
  rm -rf "$TMP"
}

assert_eval_state_cleaned() {
  [ -s "$EVAL_VERDICT_PATH_FILE" ]
  [ ! -e "$(cat "$EVAL_VERDICT_PATH_FILE")" ]
  if [ "$GLOBAL_VERDICT_BEFORE" = "missing" ]; then
    [ ! -e "$GLOBAL_VERDICT_FILE" ]
  else
    [ "$(shasum -a 256 "$GLOBAL_VERDICT_FILE")" = "$GLOBAL_VERDICT_BEFORE" ]
  fi
}

@test "preserves an inline verdict from an earlier assistant turn" {
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 0 ]
  [[ "$output" == *"JTBD Review: PASS"* ]]
  [[ "$output" == *"Marker written."* ]]
  assert_eval_state_cleaned
}

@test "accepts the authoritative inline verdict when no subordinate marker is written" {
  export FAKE_CLAUDE_MODE=missing-marker
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 0 ]
  [[ "$output" == *"JTBD Review: PASS"* ]]
  assert_eval_state_cleaned
}

@test "uses an isolated verdict file without touching global hook state" {
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 0 ]
  [ -e "$CLAUDE_CALLED" ]
  assert_eval_state_cleaned
}

@test "preserves Claude's non-zero status and cleans its marker" {
  export FAKE_CLAUDE_MODE=nonzero
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 7 ]
  assert_eval_state_cleaned
}

@test "fails on malformed stream JSON and cleans its marker" {
  export FAKE_CLAUDE_MODE=malformed
  run bash "$DRIVER" "review fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"malformed stream JSON"* ]]
  assert_eval_state_cleaned
}
