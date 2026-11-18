#!/usr/bin/env bats

setup() {
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-codex-agent-eval.sh"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/bin"
  export PATH="$TMP/bin:$PATH"
  export WR_CODEX_EVAL_CODEX_HOME="$TMP/codex-home"
  export CAPTURE_CODEX_ARGS="$TMP/args"
  cat > "$TMP/bin/npm" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == pack ]]; then
  while [[ "$1" != --pack-destination ]]; do shift; done
  touch "$2/fixture.tgz"
else
  mkdir -p "$CODEX_HOME/agents"
  touch "$CODEX_HOME/agents/wr-architect-agent.toml" "$CODEX_HOME/agents/wr-architect-cog-a11y.toml"
fi
MOCK
  cat > "$TMP/bin/codex" <<'MOCK'
#!/usr/bin/env bash
printf '%s\0' "$@" > "$CAPTURE_CODEX_ARGS"
printf 'Architecture Review: PASS\n'
MOCK
  chmod +x "$TMP/bin/npm" "$TMP/bin/codex"
}

teardown() {
  rm -rf "$TMP"
}

@test "Codex review receives the scenario without provider metadata" {
  run bash "$DRIVER" 'original scenario' 'SECRET GRADER METADATA'
  [ "$status" -eq 0 ]
  python3 - "$CAPTURE_CODEX_ARGS" <<'PY'
from pathlib import Path
import sys
args=Path(sys.argv[1]).read_bytes().decode().split('\0')[:-1]
assert args[0]=='exec'
assert args[-1].endswith('\n\noriginal scenario')
assert 'SECRET GRADER METADATA' not in '\n'.join(args)
assert 'named wr-architect:agent' in args[-1]
assert not Path(args[args.index('--cd')+1]).exists()
PY
}

@test "Codex review keeps cognitive dispatch and strips its selector prefix" {
  run bash "$DRIVER" '[COG_A11Y]cognitive scenario' 'SECRET GRADER METADATA'
  [ "$status" -eq 0 ]
  python3 - "$CAPTURE_CODEX_ARGS" <<'PY'
from pathlib import Path
import sys
prompt=Path(sys.argv[1]).read_bytes().decode().split('\0')[-2]
assert 'named wr-architect-cog-a11y' in prompt
assert prompt.endswith('\n\ncognitive scenario')
assert '[COG_A11Y]' not in prompt and 'SECRET GRADER METADATA' not in prompt
PY
}

@test "Codex review rejects an empty scenario even if metadata follows" {
  run bash "$DRIVER" '' 'SECRET GRADER METADATA'
  [ "$status" -eq 2 ]
  [[ "$output" == *'prompt argument is required'* ]]
  [ ! -e "$CAPTURE_CODEX_ARGS" ]
}
