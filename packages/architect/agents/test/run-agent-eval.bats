#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-agent-eval.sh"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/bin"
  export PATH="$TMP/bin:$PATH"

  cat > "$TMP/bin/claude" <<'MOCK'
#!/usr/bin/env bash
if [[ -n "${FAKE_CLAUDE_CAPTURE:-}" ]]; then
  python3 - "$@" <<'PY'
import json, os, pathlib, sys
p=pathlib.Path.cwd()
pathlib.Path(os.environ['FAKE_CLAUDE_CAPTURE']).write_text(json.dumps({'cwd':str(p),'args':sys.argv[1:],'ratified_fixture':(p/'docs/decisions/052-ratified-fixture.md').is_file(),'unratified_fixture':(p/'docs/decisions/074-unratified-fixture.proposed.md').is_file(),'ambient_project':(p/'CLAUDE.md').exists()}))
PY
fi
printf '%s\n' "${FAKE_CLAUDE_STDOUT:-Architecture Review: PASS}"
printf '%s\n' "${FAKE_CLAUDE_STDERR:-}" >&2
exit "${FAKE_CLAUDE_STATUS:-0}"
MOCK
  chmod +x "$TMP/bin/claude"
}

teardown() {
  rm -rf "$TMP"
}

@test "preserves Claude stdout when the provider fails" {
  export FAKE_CLAUDE_STDOUT="weekly limit"
  export FAKE_CLAUDE_STDERR="provider stderr"
  export FAKE_CLAUDE_STATUS=7

  run --separate-stderr "$DRIVER" "fixture"

  [ "$status" -eq 7 ]
  [ -z "$output" ]
  [[ "$stderr" == *"weekly limit"* ]]
  [[ "$stderr" == *"provider stderr"* ]]
}

@test "returns successful Claude output" {
  run --separate-stderr "$DRIVER" "fixture"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture Review: PASS"* ]]
  [ -z "$stderr" ]
}

@test "isolates fixture inspection and transports only the scenario with the production agent" {
  export FAKE_CLAUDE_CAPTURE="$TMP/capture.json"
  export AGENT_EVAL_MODEL="fixture-model"
  run "$DRIVER" 'self-contained schema scenario' 'provider metadata must stay out'
  [ "$status" -eq 0 ]
  python3 - "$FAKE_CLAUDE_CAPTURE" "${BATS_TEST_DIRNAME}/../agent.md" <<'PY'
import json,pathlib,sys
d=json.loads(pathlib.Path(sys.argv[1]).read_text());args=d['args']
def value(flag):return args[args.index(flag)+1]
assert d['ratified_fixture'] and d['unratified_fixture'] and not d['ambient_project']
assert value('--model')=='fixture-model'
assert value('--system-prompt')==pathlib.Path(sys.argv[2]).read_text().rstrip('\n')
assert value('--tools')=='Read,Glob,Grep'
assert value('--allowedTools')=='Read,Glob,Grep'
assert value('--setting-sources')==''
assert json.loads(value('--settings'))=={'disableAllHooks':True}
assert json.loads(value('--mcp-config'))=={'mcpServers':{}}
assert value('--permission-mode')=='dontAsk'
assert '--strict-mcp-config' in args and '--no-session-persistence' in args
assert args[-2:]==['--','self-contained schema scenario']
assert 'provider metadata must stay out' not in args
assert not pathlib.Path(d['cwd']).exists(), 'temporary fixture was not removed'
PY
}

@test "removes the temporary fixture while preserving a failed provider status" {
  export FAKE_CLAUDE_CAPTURE="$TMP/capture.json"
  export FAKE_CLAUDE_STATUS=9
  run "$DRIVER" 'scenario'
  [ "$status" -eq 9 ]
  python3 - "$FAKE_CLAUDE_CAPTURE" <<'PY'
import json,pathlib,sys
d=json.loads(pathlib.Path(sys.argv[1]).read_text())
assert d['ratified_fixture']
assert not pathlib.Path(d['cwd']).exists()
PY
}
