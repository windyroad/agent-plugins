#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
PROMPT="${1:-}"
[ -n "$PROMPT" ] || { echo "prompt argument is required" >&2; exit 2; }

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME="$(mktemp -d)"
TMP_PACK_DIR="$(mktemp -d)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$TMP_CODEX_HOME" "$TMP_PACK_DIR" "$FIXTURE"' EXIT
chmod 700 "$TMP_CODEX_HOME"
export CODEX_HOME="$TMP_CODEX_HOME"

if [ -f "$SOURCE_CODEX_HOME/auth.json" ]; then
  cp "$SOURCE_CODEX_HOME/auth.json" "$CODEX_HOME/auth.json"
  chmod 600 "$CODEX_HOME/auth.json"
fi

printf '%s\n' '# Parcel Status' '' 'A CLI that turns parcel scan events into current delivery status.' > "$FIXTURE/README.md"
printf '%s\n' '{"name":"parcel-status","type":"module","scripts":{"test":"node --test"}}' > "$FIXTURE/package.json"
printf '%s\n' 'export function currentStatus(events) { return events.at(-1)?.status ?? "unknown"; }' > "$FIXTURE/index.js"

npm pack "$REPO_ROOT/packages/wardley" --pack-destination "$TMP_PACK_DIR" >/dev/null
NPM_SPEC="$(find "$TMP_PACK_DIR" -maxdepth 1 -name '*.tgz' -print -quit)"
CODEX_BINARY="${CODEX_BINARY:-$(command -v codex)}" npm exec --yes --package "$NPM_SPEC" -- windyroad-wardley --runtime codex --scope user >/dev/null

codex exec \
  --ephemeral \
  --skip-git-repo-check \
  --cd "$FIXTURE" \
  -c 'approval_policy="never"' \
  --sandbox workspace-write \
  --dangerously-bypass-hook-trust \
  "Invoke the installed wr-wardley generate skill and follow it exactly. ${PROMPT}" </dev/null

for artifact in wardley-map.owm wardley-map.svg wardley-map.png wardley-map.md; do
  test -s "$FIXTURE/docs/$artifact"
done
printf 'WARDLEY_EVAL_ARTIFACTS: wardley-map.owm wardley-map.svg wardley-map.png wardley-map.md\n'
