#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/packs"
  cat > "$BATS_TEST_TMPDIR/bin/codex" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo "codex-test"; exit 0; fi
printf '%s\n' "$*" >> "$CODEX_HOME/codex-calls"
exit 0
SH
  chmod +x "$BATS_TEST_TMPDIR/bin/codex"
}

@test "remaining packages pack and stage exact Codex plugin versions" {
  for package in c4 connect jtbd retrospective style-guide tdd voice-tone; do
    local version tarball staged
    version="$(jq -r .version "$REPO_ROOT/packages/$package/package.json")"
    run npm pack "$REPO_ROOT/packages/$package" --pack-destination "$BATS_TEST_TMPDIR/packs"
    [ "$status" -eq 0 ]
    tarball="$BATS_TEST_TMPDIR/packs/windyroad-$package-$version.tgz"
    [ -f "$tarball" ]

    export CODEX_HOME="$BATS_TEST_TMPDIR/codex-$package"
    mkdir -p "$CODEX_HOME"
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" npm exec --yes --package "$tarball" -- "windyroad-$package" --runtime codex --scope user
    [ "$status" -eq 0 ]

    staged="$CODEX_HOME/.tmp/marketplaces/wr-$package-$version"
    [ "$(jq -r .version "$staged/.codex-plugin/plugin.json")" = "$version" ]
    [ -f "$staged/.agents/plugins/marketplace.json" ]
    [ -n "$(find "$staged/skills" -name SKILL.md -print -quit)" ]
    grep -Fxq "plugin marketplace add $staged" "$CODEX_HOME/codex-calls"
    grep -Fxq "plugin add wr-$package@windyroad-$package-local" "$CODEX_HOME/codex-calls"
  done

  [ -f "$BATS_TEST_TMPDIR/codex-jtbd/agents/wr-jtbd-agent.toml" ]
  [ -f "$BATS_TEST_TMPDIR/codex-style-guide/agents/wr-style-guide-agent.toml" ]
  [ -f "$BATS_TEST_TMPDIR/codex-tdd/agents/wr-tdd-review-test.toml" ]
  [ -f "$BATS_TEST_TMPDIR/codex-voice-tone/agents/wr-voice-tone-external-comms.toml" ]
}

@test "Codex hook adapter translates apply_patch and native subagent inputs" {
  local version tarball extracted adapter
  version="$(jq -r .version "$REPO_ROOT/packages/jtbd/package.json")"
  run npm pack "$REPO_ROOT/packages/jtbd" --pack-destination "$BATS_TEST_TMPDIR/packs"
  [ "$status" -eq 0 ]
  tarball="$BATS_TEST_TMPDIR/packs/windyroad-jtbd-$version.tgz"
  extracted="$BATS_TEST_TMPDIR/extracted-jtbd"
  mkdir -p "$extracted"
  tar -xzf "$tarball" -C "$extracted"
  adapter="$extracted/package/hooks-codex/codex-adapter.sh"
  [ -f "$adapter" ]
  local target="$BATS_TEST_TMPDIR/capture.sh"
  cat > "$target" <<'SH'
#!/usr/bin/env bash
jq -r '[.tool_name, (.tool_input.file_path // ""), (.tool_input.subagent_type // ""), (.tool_input.prompt // "")] | @tsv' >> "$CAPTURE"
SH
  chmod +x "$target"
  export CAPTURE="$BATS_TEST_TMPDIR/captured"

  run bash "$adapter" "$target" <<'JSON'
{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: one.md\n*** Add File: two.md\n*** End Patch"}}
JSON
  [ "$status" -eq 0 ]
  grep -Fxq $'Edit\tone.md\t\t' "$CAPTURE"
  grep -Fxq $'Edit\ttwo.md\t\t' "$CAPTURE"

  run bash "$adapter" "$target" <<'JSON'
{"tool_name":"spawn_agent","tool_input":{"agent_type":"wr-jtbd:agent","message":"review this"}}
JSON
  [ "$status" -eq 0 ]
  grep -Fxq $'Agent\t\twr-jtbd:agent\treview this' "$CAPTURE"
}

@test "Codex agent install preserves user-managed and modified generated files" {
  local version tarball agent
  version="$(jq -r .version "$REPO_ROOT/packages/tdd/package.json")"
  run npm pack "$REPO_ROOT/packages/tdd" --pack-destination "$BATS_TEST_TMPDIR/packs"
  [ "$status" -eq 0 ]
  tarball="$BATS_TEST_TMPDIR/packs/windyroad-tdd-$version.tgz"
  export CODEX_HOME="$BATS_TEST_TMPDIR/codex-tdd-ownership"
  agent="$CODEX_HOME/agents/wr-tdd-review-test.toml"
  mkdir -p "$(dirname "$agent")"
  printf 'name = "user-owned"\n' > "$agent"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" npm exec --yes --package "$tarball" -- windyroad-tdd --runtime codex --scope user
  [ "$status" -eq 0 ]
  grep -Fxq 'name = "user-owned"' "$agent"

  rm "$agent"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" npm exec --yes --package "$tarball" -- windyroad-tdd --update --runtime codex --scope user
  [ "$status" -eq 0 ]
  printf '\n# user edit\n' >> "$agent"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" npm exec --yes --package "$tarball" -- windyroad-tdd --update --runtime codex --scope user
  [ "$status" -eq 0 ]
  grep -Fxq '# user edit' "$agent"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" npm exec --yes --package "$tarball" -- windyroad-tdd --uninstall --runtime codex --scope user
  [ "$status" -eq 0 ]
  grep -Fxq '# user edit' "$agent"
}
