#!/usr/bin/env bats

setup() {
  TMP=$(mktemp -d)
  BIN="$TMP/bin"
  mkdir -p "$BIN"
  SCRIPT="$BATS_TEST_DIRNAME/../../../scripts/run-agent-evals-ci.sh"
}

teardown() {
  rm -rf "$TMP"
}

write_claude() {
  cat > "$BIN/claude" <<EOF
#!/bin/bash
printf '%s\n' "$1"
exit "$2"
EOF
  chmod +x "$BIN/claude"
}

write_npm() {
  cat > "$BIN/npm" <<EOF
#!/bin/bash
touch "$TMP/npm-called"
exit "$1"
EOF
  chmod +x "$BIN/npm"
}

@test "quota-only probe skips evals with a warning" {
  write_claude "You've hit your weekly limit · resets Aug 15, 5am (UTC)" 1
  write_npm 9

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"::warning::Claude subscription quota is exhausted"* ]]
  [ ! -e "$TMP/npm-called" ]
}

@test "quota-only probe accepts a reset time without a date" {
  write_claude "You've hit your weekly limit · resets 5am (UTC)" 1
  write_npm 9

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"::warning::Claude subscription quota is exhausted"* ]]
  [ ! -e "$TMP/npm-called" ]
}

@test "ordinary probe failure remains blocking" {
  write_claude "Authentication failed" 7
  write_npm 0

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 7 ]
  [[ "$output" == *"Authentication failed"* ]]
  [ ! -e "$TMP/npm-called" ]
}

@test "mixed quota and ordinary failure remains blocking" {
  write_claude $'You\'ve hit your weekly limit\nAuthentication failed' 7
  write_npm 0

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 7 ]
  [[ "$output" == *"Authentication failed"* ]]
  [ ! -e "$TMP/npm-called" ]
}

@test "same-line quota and ordinary failure remains blocking" {
  write_claude "You've hit your weekly limit · Authentication failed" 7
  write_npm 0

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 7 ]
  [[ "$output" == *"Authentication failed"* ]]
  [ ! -e "$TMP/npm-called" ]
}

@test "available probe delegates to evals and preserves their status" {
  write_claude "available" 0
  write_npm 9

  run env PATH="$BIN:$PATH" "$SCRIPT"

  [ "$status" -eq 9 ]
  [ -e "$TMP/npm-called" ]
}
