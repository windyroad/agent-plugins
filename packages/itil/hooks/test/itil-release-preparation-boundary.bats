#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  PLUGIN_ROOT="$REPO_ROOT/packages/itil"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init --quiet -b main
  git config user.email test@example.com
  git config user.name Test
  printf 'seed\n' > seed.txt
  git add seed.txt
  git -c commit.gpgsign=false commit --quiet -m initial
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

assert_registered_hooks_allow_without_changeset() {
  local path="$1" command output payload
  mkdir -p "$(dirname "$path")"
  printf 'implementation\n' > "$path"
  git add "$path"
  payload='{"tool_name":"Bash","tool_input":{"command":"git commit -m implementation"}}'

  output="$({
    while IFS= read -r command; do
      command="${command//'${CLAUDE_PLUGIN_ROOT}'/$PLUGIN_ROOT}"
      printf '%s' "$payload" | bash -c "$command"
    done < <(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[].command' "$PLUGIN_ROOT/hooks/hooks.json")
  } 2>&1)"
  [[ "$output" != *"P141 changeset discipline"* ]]

  output="$(printf '%s' "$payload" | bash "$PLUGIN_ROOT/hooks/itil-codex-dispatch.sh" pre-tool 2>&1)"
  [[ "$output" != *"P141 changeset discipline"* ]]
}

@test "registered ITIL hooks allow a Windy Road implementation commit without release metadata" {
  assert_registered_hooks_allow_without_changeset packages/itil/skills/example/SKILL.md
}

@test "registered ITIL hooks allow an adopter implementation commit without release metadata" {
  assert_registered_hooks_allow_without_changeset packages/core/src/push-and-watch.test.ts
}

@test "packed ITIL plugin allows both implementation commits without release metadata" {
  local tarball
  tarball="$(npm pack "$PLUGIN_ROOT" --pack-destination "$TEST_DIR" --silent)"
  mkdir "$TEST_DIR/packed"
  tar -xzf "$TEST_DIR/$tarball" -C "$TEST_DIR/packed"
  PLUGIN_ROOT="$TEST_DIR/packed/package"

  assert_registered_hooks_allow_without_changeset packages/itil/skills/example/SKILL.md
  assert_registered_hooks_allow_without_changeset packages/core/src/push-and-watch.test.ts
}
