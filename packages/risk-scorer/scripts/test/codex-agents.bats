#!/usr/bin/env bats

setup() {
  unset CODEX_THREAD_ID
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/codex-agents.mjs"
  SKILL_SYNC="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/sync-codex-skills.mjs"
  TMP="$(mktemp -d)"
  TARGET="$TMP/agents"
}

@test "packed Codex skill keeps YAML frontmatter first" {
  pkg="$TMP/package"
  mkdir -p "$pkg/scripts" "$pkg/skills/demo"
  cp "$SKILL_SYNC" "$pkg/scripts/sync-codex-skills.mjs"
  printf '%s\n' '---' 'name: demo' 'description: Demo' '---' 'Use AskUserQuestion.' > "$pkg/skills/demo/SKILL.md"

  node "$pkg/scripts/sync-codex-skills.mjs" --pack >/dev/null
  [ "$(head -1 "$pkg/skills/demo/SKILL.md")" = "---" ]
  grep -q "Generated from packages/risk-scorer" "$pkg/skills/demo/SKILL.md"
  grep -q "request_user_input" "$pkg/skills/demo/SKILL.md"
  grep -q 'close that completed agent once' "$pkg/skills/demo/SKILL.md"
  grep -q 'Do not parse transcripts or launch nested `codex exec`' "$pkg/skills/demo/SKILL.md"
}

teardown() {
  rm -rf "$TMP"
}

@test "generator installs all six exact Codex agent identities" {
  run node "$SCRIPT" --target "$TARGET"
  [ "$status" -eq 0 ]
  [ "$(find "$TARGET" -type f -name '*.toml' | wc -l | tr -d ' ')" -eq 6 ]
  for mode in pipeline plan wip policy external-comms inbound-report; do
    grep -q "^name = \"wr-risk-scorer:${mode}\"$" "$TARGET/wr-risk-scorer-${mode}.toml"
  done
  grep -q "EXTERNAL_COMMS_RISK_KEY:" "$TARGET/wr-risk-scorer-external-comms.toml"
  grep -q "endpoint pipeline scorer" "$TARGET/wr-risk-scorer-pipeline.toml"
  grep -q 'not invoke the `wr-risk-scorer:pipeline` skill' "$TARGET/wr-risk-scorer-pipeline.toml"
  grep -q 'wr-risk-scorer:pipeline' "$TARGET/wr-risk-scorer-pipeline.toml"
  grep -q 'workdir` alone may be hidden' "$TARGET/wr-risk-scorer-pipeline.toml"
  ! grep -q "Codex completion marker compatibility" "$TARGET/wr-risk-scorer-policy.toml"
}

@test "generator is idempotent and check detects drift" {
  node "$SCRIPT" --target "$TARGET" >/dev/null
  run node "$SCRIPT" --target "$TARGET"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 updated, 6 current, 0 preserved"* ]]

  printf '\n# drift\n' >> "$TARGET/wr-risk-scorer-external-comms.toml"
  run node "$SCRIPT" --target "$TARGET" --check
  [ "$status" -ne 0 ]
}

@test "SessionStart repair runs only under Codex" {
  CODEX_HOME="$TMP/codex-home" node "$SCRIPT" --session-start
  [ ! -d "$TMP/codex-home/agents" ]

  run env CODEX_THREAD_ID=test CODEX_HOME="$TMP/codex-home" node "$SCRIPT" --session-start
  [ "$status" -eq 0 ]
  [[ "$output" == *"restart Codex"* ]]
  [ -f "$TMP/codex-home/agents/wr-risk-scorer-external-comms.toml" ]

  run env CODEX_THREAD_ID=test CODEX_HOME="$TMP/codex-home" node "$SCRIPT" --session-start
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Codex-shaped SessionStart emits JSON restart context" {
  run bash -c 'printf '\''%s'\'' '\''{"model":"gpt-test"}'\'' | CODEX_THREAD_ID=codex-test CODEX_HOME="$1" node "$2" --session-start' _ "$TMP/codex-json-home" "$SCRIPT"
  [ "$status" -eq 0 ]
  run jq -er '.systemMessage | contains("restart Codex")' <<< "$output"
  [ "$status" -eq 0 ]
}

@test "Claude-shaped SessionStart never installs Codex agents" {
  run bash -c 'printf '\''%s'\'' '\''{"hook_event_name":"SessionStart","model":"claude-opus-4"}'\'' | env -u CODEX_THREAD_ID CODEX_HOME="$1" node "$2" --session-start' _ "$TMP/claude-home" "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -d "$TMP/claude-home/agents" ]
}

@test "uninstall removes owned files and preserves modified ownership" {
  node "$SCRIPT" --target "$TARGET" >/dev/null
  printf '\n# user edit\n' >> "$TARGET/wr-risk-scorer-external-comms.toml"

  run node "$SCRIPT" --target "$TARGET" --uninstall
  [ "$status" -eq 0 ]
  [[ "$output" == *"5 removed"* ]]
  [ -f "$TARGET/wr-risk-scorer-external-comms.toml" ]
  [ ! -f "$TARGET/wr-risk-scorer-policy.toml" ]
}

@test "install preserves unmarked collisions and modified generated files" {
  mkdir -p "$TARGET"
  printf 'name = "user-owned"\n' > "$TARGET/wr-risk-scorer-policy.toml"
  node "$SCRIPT" --target "$TARGET" >/dev/null
  printf '\n# user edit\n' >> "$TARGET/wr-risk-scorer-external-comms.toml"

  run node "$SCRIPT" --target "$TARGET"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 preserved"* ]]
  grep -q 'name = "user-owned"' "$TARGET/wr-risk-scorer-policy.toml"
  grep -q '# user edit' "$TARGET/wr-risk-scorer-external-comms.toml"
}

@test "scope selects project or user agent directory" {
  mkdir -p "$TMP/project"
  (cd "$TMP/project" && node "$SCRIPT" --scope project >/dev/null)
  [ -f "$TMP/project/.codex/agents/wr-risk-scorer-policy.toml" ]

  CODEX_HOME="$TMP/home" node "$SCRIPT" --scope user >/dev/null
  [ -f "$TMP/home/agents/wr-risk-scorer-policy.toml" ]
}
