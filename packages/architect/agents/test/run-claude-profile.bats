#!/usr/bin/env bats

setup() {
  export PYTHONDONTWRITEBYTECODE=1
  unset WR_CLAUDE_EVAL_MODEL WR_CLAUDE_EVAL_REASONING_EFFORT
  ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  DRIVER="$ROOT/packages/architect/agents/eval/run-agent-eval.sh"
  HELPER="$ROOT/packages/architect/agents/eval/verify-claude-eval-profile.py"
  export ARCHITECT_EVAL_ARTIFACT_DIR="$BATS_TEST_TMPDIR/captures"
  export CLI_ARGUMENTS="$BATS_TEST_TMPDIR/argv.json"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/claude" <<'SHIM'
#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
pathlib.Path(os.environ['CLI_ARGUMENTS']).write_text(json.dumps(args))
mode = os.environ.get('CLI_RESULT_MODE', 'valid')
if mode == 'error':
    print('fixture CLI error', file=sys.stderr)
    sys.exit(9)
model = args[args.index('--model') + 1]
usage = {model: {'contextWindow': 1000000}}
if mode == 'mismatch': usage = {'different-model': {'contextWindow': 1000000}}
if mode == 'ambiguous': usage['different-model'] = {'contextWindow': 1000000}
if mode == 'small-context': usage[model]['contextWindow'] = 200000
if mode == 'unknown-context': usage[model] = {}
print(json.dumps({'is_error': False, 'result': '**Architecture Review: PASS**', 'modelUsage': usage}))
SHIM
  chmod +x "$BATS_TEST_TMPDIR/bin/claude"
}

@test "canonical runner owns its profile despite the generic Sonnet setting and forwards only the scenario" {
  local scenario=$'--literal scenario\nsecond line'
  run env -u WR_CLAUDE_EVAL_MODEL -u WR_CLAUDE_EVAL_REASONING_EFFORT \
    PATH="$BATS_TEST_TMPDIR/bin:$PATH" AGENT_EVAL_MODEL=claude-sonnet-5 \
    "$DRIVER" "$scenario" 'private-grading-metadata'
  [ "$status" -eq 0 ]
  [[ "$output" == *'**Architecture Review: PASS**'* ]]
  python3 - "$CLI_ARGUMENTS" "$scenario" "$ROOT/packages/architect/agents/agent.md" <<'PY'
import json, pathlib, sys
args = json.loads(pathlib.Path(sys.argv[1]).read_text())
def value(flag): return args[args.index(flag) + 1]
assert value('--model') == 'claude-opus-5-5'
assert value('--effort') == 'medium'
assert value('--output-format') == 'json'
assert value('--setting-sources') == ''
assert json.loads(value('--settings'))['disableAllHooks'] is True
assert value('--tools') == 'Read,Glob,Grep'
assert value('--system-prompt') == pathlib.Path(sys.argv[3]).read_text().rstrip('\n')
assert args[-2:] == ['--', sys.argv[2]]
assert 'private-grading-metadata' not in args
PY
}

@test "canonical runner records exposed metadata and binds raw output, verdict and source" {
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" "$DRIVER" 'fixture'
  [ "$status" -eq 0 ]
  python3 - "$ARCHITECT_EVAL_ARTIFACT_DIR" "$ROOT/packages/architect/agents/agent.md" <<'PY'
import hashlib, json, pathlib, sys
capture, = pathlib.Path(sys.argv[1]).glob('review.*')
profile = json.loads((capture/'profile.json').read_text())
raw = (capture/'result.json').read_bytes()
assert profile['observed_model'] == 'claude-opus-5-5'
assert profile['exposed_context_window'] == 1000000
assert profile['requested_effort'] == 'medium'
assert profile['independently_observed_effort'] == 'not established'
assert profile['raw_sha256'] == hashlib.sha256(raw).hexdigest()
assert profile['verdict_sha256'] == hashlib.sha256(json.loads(raw)['result'].encode()).hexdigest()
assert profile['source_sha256'] == hashlib.sha256(pathlib.Path(sys.argv[2]).read_bytes()).hexdigest()
assert (capture/'agent.md').read_bytes() == pathlib.Path(sys.argv[2]).read_bytes()
PY
}

@test "canonical runner rejects mismatched, ambiguous and incompatible exposed context without a retry" {
  for mode in mismatch ambiguous small-context; do
    export ARCHITECT_EVAL_ARTIFACT_DIR="$BATS_TEST_TMPDIR/$mode"
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" CLI_RESULT_MODE="$mode" "$DRIVER" 'fixture'
    [ "$status" -ne 0 ]
    [[ "$output" != *'**Architecture Review: PASS**'* ]]
    [ "$(find "$ARCHITECT_EVAL_ARTIFACT_DIR" -name result.json | wc -l | tr -d ' ')" -eq 1 ]
    [ "$(find "$ARCHITECT_EVAL_ARTIFACT_DIR" -name profile.json | wc -l | tr -d ' ')" -eq 0 ]
  done
}

@test "canonical runner keeps missing context honestly unobserved" {
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" CLI_RESULT_MODE=unknown-context "$DRIVER" 'fixture'
  [ "$status" -eq 0 ]
  python3 - "$ARCHITECT_EVAL_ARTIFACT_DIR" <<'PY'
import json, pathlib, sys
profile, = pathlib.Path(sys.argv[1]).glob('review.*/profile.json')
assert json.loads(profile.read_text())['exposed_context_window'] == 'not exposed'
PY
}

@test "canonical runner propagates CLI failure diagnostics without fabricating a verdict" {
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" CLI_RESULT_MODE=error "$DRIVER" 'fixture'
  [ "$status" -eq 9 ]
  [ "$output" = 'fixture CLI error' ]
  [ "$(find "$ARCHITECT_EVAL_ARTIFACT_DIR" -name result.json | wc -l | tr -d ' ')" -eq 1 ]
  [ "$(find "$ARCHITECT_EVAL_ARTIFACT_DIR" -name profile.json | wc -l | tr -d ' ')" -eq 0 ]
}

@test "canonical metadata verifier rejects malformed and unsuccessful result objects" {
  python3 - "$HELPER" <<'PY'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location('profile', sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
valid = {'is_error':False, 'result':'PASS', 'modelUsage':{'model':{'contextWindow':1000000}}}
invalid = [None, {}, {**valid, 'is_error':True}, {**valid, 'result':''},
           {**valid, 'modelUsage':{}}, {**valid, 'modelUsage':{'model':{'contextWindow':True}}},
           {**valid, 'modelUsage':{'model':{'contextWindow':'1000000'}}}]
for record in invalid:
    try: m.verify(json.dumps(record).encode(), 'model', 'medium', b'fixture source')
    except (ValueError, TypeError): pass
    else: raise AssertionError('invalid metadata accepted: '+repr(record))
PY
}
