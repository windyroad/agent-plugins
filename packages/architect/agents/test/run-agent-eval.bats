#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  DRIVER="${BATS_TEST_DIRNAME}/../eval/run-agent-eval.sh"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/bin"
  export PATH="$TMP/bin:$PATH"

  cat > "$TMP/bin/claude" <<'MOCK'
#!/usr/bin/env bash
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
