#!/usr/bin/env bats
# Behavioural regression for the JTBD eval's authoritative inline output.
# The mock emits Claude stream-json so the real runner, parser, and cleanup
# execute without an LLM call (P324 / RFC-012 S1).

setup() {
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-agent-eval.sh"
  VERDICT_FILE="/tmp/jtbd-verdict"
  [ ! -e "$VERDICT_FILE" ]

  TMP="$(mktemp -d)"
  BIN="$TMP/bin"
  mkdir -p "$BIN"
  export PATH="$BIN:$PATH"
  export FAKE_CLAUDE_MODE=success
  export CLAUDE_CALLED="$TMP/claude-called"
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
assert sandbox["filesystem"]["allowWrite"] == ["//tmp/jtbd-verdict"]
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
case "$FAKE_CLAUDE_MODE" in
  nonzero)
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"JTBD Review: PASS"}]},"parent_tool_use_id":null}'
    printf 'PASS' > /tmp/jtbd-verdict
    exit 7
    ;;
  malformed)
    printf '%s\n' 'not-json'
    printf 'PASS' > /tmp/jtbd-verdict
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
    printf 'PASS' > /tmp/jtbd-verdict
    ;;
esac
MOCK
  chmod +x "$BIN/claude"
}

teardown() {
  rm -f "$VERDICT_FILE"
  rm -rf "$TMP"
}

@test "preserves an inline verdict from an earlier assistant turn" {
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 0 ]
  [[ "$output" == *"JTBD Review: PASS"* ]]
  [[ "$output" == *"Marker written."* ]]
  [ ! -e "$VERDICT_FILE" ]
}

@test "accepts the authoritative inline verdict when no subordinate marker is written" {
  export FAKE_CLAUDE_MODE=missing-marker
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 0 ]
  [[ "$output" == *"JTBD Review: PASS"* ]]
  [ ! -e "$VERDICT_FILE" ]
}

@test "refuses a pre-existing marker without overwriting it" {
  printf 'KEEP' > "$VERDICT_FILE"
  run bash "$DRIVER" "review fixture"
  [ "$status" -ne 0 ]
  [ "$(cat "$VERDICT_FILE")" = "KEEP" ]
  [ ! -e "$CLAUDE_CALLED" ]
}

@test "preserves Claude's non-zero status and cleans its marker" {
  export FAKE_CLAUDE_MODE=nonzero
  run bash "$DRIVER" "review fixture"
  [ "$status" -eq 7 ]
  [ ! -e "$VERDICT_FILE" ]
}

@test "fails on malformed stream JSON and cleans its marker" {
  export FAKE_CLAUDE_MODE=malformed
  run bash "$DRIVER" "review fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"malformed stream JSON"* ]]
  [ ! -e "$VERDICT_FILE" ]
}
