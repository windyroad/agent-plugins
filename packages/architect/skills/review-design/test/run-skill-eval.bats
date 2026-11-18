#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  DRIVER="$REPO_ROOT/packages/architect/skills/review-design/eval/run-skill-eval.sh"
  export CALLER_LAUNCH_MARKER="$BATS_TEST_TMPDIR/subject-launched"
  SHIM="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$SHIM"
  cat > "$SHIM/claude" <<'SHIM'
#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
Path(os.environ["CALLER_LAUNCH_MARKER"]).write_text("launched")
print(json.dumps(sys.argv[1:]))
SHIM
  chmod +x "$SHIM/claude"
}

@test "caller evaluator forwards only the literal scenario, excluding grading metadata" {
  local scenario=$'--scenario with a literal option prefix\nsecond line'
  run env PATH="$SHIM:$PATH" bash "$DRIVER" "$scenario" '{"assert":"private-grader-sentinel"}' 'provider-config-sentinel'
  [ "$status" -eq 0 ]
  python3 - "$output" "$scenario" <<'PYTHON'
import json, sys
args = json.loads(sys.argv[1])
assert args[:2] == ['-p', '--append-system-prompt'], args[:2]
assert len(args) == 5, 'unexpected arguments passed to the subject'
assert args[3:] == ['--', sys.argv[2]], 'scenario was not preserved literally'
assert 'private-grader-sentinel' not in args[2], 'metadata entered the skill instructions'
PYTHON
}

@test "caller evaluator rejects missing or empty scenarios before subject launch" {
  run env PATH="$SHIM:$PATH" bash "$DRIVER"
  [ "$status" -ne 0 ]
  [[ "$output" == *"prompt argument is required"* ]]
  [ ! -e "$CALLER_LAUNCH_MARKER" ]
  run env PATH="$SHIM:$PATH" bash "$DRIVER" '' 'private-grader-sentinel'
  [ "$status" -ne 0 ]
  [[ "$output" == *"prompt argument is required"* ]]
  [ ! -e "$CALLER_LAUNCH_MARKER" ]
}
