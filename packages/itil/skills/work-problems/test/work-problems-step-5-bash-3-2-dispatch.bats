#!/usr/bin/env bats

# @problem P428
# @jtbd JTBD-006

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="$TEST_TMP/bin"
  mkdir -p "$FAKE_BIN"

  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="$SKILL_DIR/SKILL.md"

  cat > "$FAKE_BIN/wr-itil-resolve-governance-plugin-dirs" <<'FAKE_EOF'
#!/usr/bin/env bash
printf '%s\n' --plugin-dir '/tmp/plugin one' --plugin-dir /tmp/plugin-two
FAKE_EOF

  cat > "$FAKE_BIN/claude" <<'FAKE_EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGS_FILE"
printf '%s\n' '{"is_error":false,"result":"ok"}'
FAKE_EOF

  chmod +x "$FAKE_BIN/claude" "$FAKE_BIN/wr-itil-resolve-governance-plugin-dirs"
  export PATH="$FAKE_BIN:$PATH"
  export FAKE_ARGS_FILE="$TEST_TMP/args"
}

teardown() {
  rm -rf "$TEST_TMP"
}

extract_dispatch_start() {
  awk '
    /^\*\*Dispatch command shape/ { found = 1 }
    found && /^```bash$/ { code = 1; next }
    code { print }
    code && /^ITER_PID=\$!$/ { exit }
  ' "$SKILL_FILE"
}

@test "Step 5 dispatch runs under macOS Bash 3.2 with its prompt and every plugin-dir argument" {
  dispatch="$TEST_TMP/dispatch.sh"
  extract_dispatch_start > "$dispatch"
  printf '%s\n' 'wait "$ITER_PID"' >> "$dispatch"

  run /bin/bash "$dispatch"

  [ "$status" -eq 0 ]
  [ "$(sed -n '1p' "$FAKE_ARGS_FILE")" = "-p" ]
  grep -Fx -- '--plugin-dir' "$FAKE_ARGS_FILE"
  grep -Fx -- '/tmp/plugin one' "$FAKE_ARGS_FILE"
  grep -Fx -- '/tmp/plugin-two' "$FAKE_ARGS_FILE"
  grep -F '<iteration prompt body' "$FAKE_ARGS_FILE"
}
