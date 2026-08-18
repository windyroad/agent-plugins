#!/usr/bin/env bats

setup() {
  unset CODEX_THREAD_ID
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMP="$(mktemp -d)"
}

@test "agent scope selects project or user directory" {
  mkdir -p "$TMP/project"
  (cd "$TMP/project" && node "$PACKAGE/scripts/codex-agent.mjs" --scope project >/dev/null)
  [ -f "$TMP/project/.codex/agents/wr-architect-agent.toml" ]

  CODEX_HOME="$TMP/home" node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  [ -f "$TMP/home/agents/wr-architect-agent.toml" ]
}

@test "SessionStart repairs only Codex user registration" {
  CODEX_HOME="$TMP/claude-home" node "$PACKAGE/scripts/codex-agent.mjs" --session-start
  [ ! -d "$TMP/claude-home/agents" ]

  run env CODEX_THREAD_ID=test CODEX_HOME="$TMP/codex-home" node "$PACKAGE/scripts/codex-agent.mjs" --session-start
  [ "$status" -eq 0 ]
  [[ "$output" == *"restart Codex"* ]]
  [ -f "$TMP/codex-home/agents/wr-architect-agent.toml" ]

  run env CODEX_THREAD_ID=test CODEX_HOME="$TMP/codex-home" node "$PACKAGE/scripts/codex-agent.mjs" --session-start
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "default installer remains Claude-only" {
  run node "$PACKAGE/bin/install.mjs" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude plugin marketplace add"* ]]
  [[ "$output" != *"codex plugin marketplace add"* ]]
}

@test "packed installer registers plugin and exact agent in isolated Codex home" {
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]
  export CODEX_HOME="$TMP/codex-installed"
  run npm exec --yes --package "$TMP"/*.tgz -- windyroad-architect --runtime codex --scope user
  [ "$status" -eq 0 ]
  [ -f "$CODEX_HOME/agents/wr-architect-agent.toml" ]
  run codex plugin list
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-architect@windyroad-architect-local"* ]]
}

teardown() {
  node "$PACKAGE/scripts/sync-codex-skills.mjs" --restore-pack >/dev/null 2>&1 || true
  rm -rf "$TMP"
}

@test "npm pack emits Codex skills and restores Claude sources" {
  before="$(shasum -a 256 "$PACKAGE"/skills/*/SKILL.md)"
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]
  [ "$before" = "$(shasum -a 256 "$PACKAGE"/skills/*/SKILL.md)" ]

  tar -xzf "$TMP"/*.tgz -C "$TMP"
  run grep -F 'bash "<architect-plugin-root>/scripts/generate-decisions-compendium.sh"' "$TMP/package/skills/review-decisions/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F 'use `request_user_input`' "$TMP/package/skills/review-decisions/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F 'wr-architect-generate-decisions-compendium' "$TMP/package/skills/review-decisions/SKILL.md"
  [ "$status" -ne 0 ]
  run grep -F 'packages/architect/' "$TMP/package/skills/create-adr/SKILL.md"
  [ "$status" -ne 0 ]
  run grep -F 'the Needs-Direction handoff rule' "$TMP/package/skills/create-adr/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -E '\b(The the|the the|inverse-the)\b' "$TMP/package/skills/create-adr/SKILL.md"
  [ "$status" -ne 0 ]
  run env ARCHITECT_PACKAGE_ROOT="$(cd "$TMP/package" && pwd -P)" bats "$PACKAGE/hooks/test/architect-hook-dispatch.bats"
  [ "$status" -eq 0 ]
}

@test "Codex agent install is exact, owned, and removable" {
  export CODEX_HOME="$TMP/codex"
  run node "$PACKAGE/scripts/codex-agent.mjs" --scope user
  [ "$status" -eq 0 ]
  target="$CODEX_HOME/agents/wr-architect-agent.toml"
  grep -Fq 'name = "wr-architect:agent"' "$target"

  printf '# user managed\n' > "$target"
  node "$PACKAGE/scripts/codex-agent.mjs" --scope user >/dev/null
  [ "$(cat "$target")" = "# user managed" ]

  node "$PACKAGE/scripts/codex-agent.mjs" --scope user --uninstall
  [ -e "$target" ]
}
