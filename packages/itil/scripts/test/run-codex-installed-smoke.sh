#!/usr/bin/env bash
set -euo pipefail

PACKAGE="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'node "$PACKAGE/scripts/sync-codex-skills.mjs" --restore-pack >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

CODEX_BIN="${CODEX_BINARY:-$(command -v codex)}"
export CODEX_HOME="$TMP/codex-home"
mkdir -p "$CODEX_HOME" "$TMP/project"
git -C "$TMP/project" init -q
if [[ -f "$HOME/.codex/auth.json" ]]; then
  cp "$HOME/.codex/auth.json" "$CODEX_HOME/auth.json"
fi

npm pack "$PACKAGE" --pack-destination "$TMP" >/dev/null
TARBALL="$(find "$TMP" -maxdepth 1 -name '*.tgz' -print -quit)"
env CODEX_BINARY="$CODEX_BIN" npm exec --yes --package "$TARBALL" -- windyroad-itil --runtime codex --scope user >/dev/null

node -e 'require("node:fs").writeFileSync(process.argv[1], JSON.stringify({type:"object",additionalProperties:false,required:["usesNativeSubagents","usesNestedCodexExec","waitsForSameAgent","cancelsForSlowness"],properties:{usesNativeSubagents:{type:"boolean",const:true},usesNestedCodexExec:{type:"boolean",const:false},waitsForSameAgent:{type:"boolean",const:true},cancelsForSlowness:{type:"boolean",const:false}}}))' "$TMP/schema.json"

"$CODEX_BIN" exec --ephemeral --ignore-user-config --dangerously-bypass-hook-trust \
  --sandbox read-only --cd "$TMP/project" --output-schema "$TMP/schema.json" \
  --output-last-message "$TMP/result.json" \
  '$wr-itil:work-problems Read the installed skill only. Report whether it uses native Codex subagents, nested codex exec, waits for the same agent, or cancels an agent merely because it is slow. Make no changes.' >/dev/null

jq -e '.usesNativeSubagents == true and .usesNestedCodexExec == false and .waitsForSameAgent == true and .cancelsForSlowness == false' "$TMP/result.json" >/dev/null
printf 'Installed Codex ITIL smoke passed.\n'
