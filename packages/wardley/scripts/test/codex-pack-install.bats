#!/usr/bin/env bats

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  REPO_ROOT="$(cd "$PACKAGE/../.." && pwd)"
  TMP="$(mktemp -d)"
  export CODEX_HOME="$TMP/codex-home"
}

teardown() {
  rm -rf "$TMP"
}

@test "default installer remains Claude-only" {
  run node "$PACKAGE/bin/install.mjs" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude plugin marketplace add"* ]]
  [[ "$output" != *"codex plugin marketplace add"* ]]
}

@test "packed installer stages and registers the Wardley Codex plugin" {
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]
  tarball="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
  version="$(node -p "require('$PACKAGE/package.json').version")"

  run tar -tzf "$tarball"
  [ "$status" -eq 0 ]
  [[ "$output" == *"package/.codex-plugin/plugin.json"* ]]
  [[ "$output" == *"package/.agents/plugins/marketplace.json"* ]]
  [[ "$output" == *"package/skills/generate/agents/openai.yaml"* ]]
  [[ "$output" != *"package/skills/generate/eval/"* ]]

  run env CODEX_BINARY="$(command -v codex)" npm exec --yes --package "$tarball" -- windyroad-wardley --runtime codex --scope user
  [ "$status" -eq 0 ]
  [ -f "$CODEX_HOME/.tmp/marketplaces/wr-wardley-$version/package.json" ]

  run codex plugin list
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-wardley@windyroad-wardley-local"* ]]
  [[ "$output" == *"$version"* ]]
}

@test "repo-local marketplace exposes Wardley for dogfooding" {
  run node -e '
    const marketplace = require(process.argv[1]);
    const plugin = marketplace.plugins.find(({ name }) => name === "wr-wardley");
    if (plugin?.source?.path !== "./packages/wardley") process.exit(1);
  ' "$REPO_ROOT/.agents/plugins/marketplace.json"
  [ "$status" -eq 0 ]
}
