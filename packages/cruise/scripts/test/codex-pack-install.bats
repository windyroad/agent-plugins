#!/usr/bin/env bats

setup() {
  PACKAGE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMP="$(mktemp -d)"
  export CODEX_HOME="$TMP/codex-home"
}

@test "packed installer stages scoped npm path before Codex marketplace registration" {
  run npm pack "$PACKAGE" --pack-destination "$TMP"
  [ "$status" -eq 0 ]

  scoped="$TMP/node_modules/@windyroad/cruise"
  mkdir -p "$scoped"
  tar -xzf "$TMP"/*.tgz -C "$scoped" --strip-components=1
  version="$(node -p "require('$scoped/package.json').version")"

  run node "$scoped/bin/install.mjs" --runtime codex --scope user
  [ "$status" -eq 0 ]
  [ -f "$CODEX_HOME/.tmp/marketplaces/wr-cruise-$version/package.json" ]

  run codex plugin list
  [ "$status" -eq 0 ]
  [[ "$output" == *"wr-cruise@windyroad-local"* ]]
  [[ "$output" == *"$version"* ]]
}

teardown() {
  rm -rf "$TMP"
}
