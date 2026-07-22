#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
PROMPT="${1:-}"
[ -n "$PROMPT" ] || { echo "prompt argument is required" >&2; exit 2; }

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_CODEX_HOME"' EXIT
chmod 700 "$TMP_CODEX_HOME"
export CODEX_HOME="$TMP_CODEX_HOME"

# Exercise real plugin discovery and telemetry without letting live quota
# pacing delay the evaluator itself.
printf '{"max_sleep_s":0}\n' > "$CODEX_HOME/cruise.config.json"

if [ -f "${SOURCE_CODEX_HOME}/auth.json" ]; then
  cp "${SOURCE_CODEX_HOME}/auth.json" "$CODEX_HOME/auth.json"
  chmod 600 "$CODEX_HOME/auth.json"
fi

codex plugin marketplace add "$REPO_ROOT/packages/cruise" >/dev/null
codex plugin add wr-cruise@windyroad-local >/dev/null

if [[ "$PROMPT" == *'[STALE_FIXTURE]'* ]]; then
  printf '{"source":"codex-app-server","five_used_pct":0,"five_resets_at":0,"week_used_pct":10,"week_resets_at":0,"written_at":1}\n' > "$CODEX_HOME/quota-state.json"
  touch -t 202001010000 "$CODEX_HOME/quota-state.json"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$CODEX_HOME/codex-unavailable"
  chmod +x "$CODEX_HOME/codex-unavailable"
  export CODEX_BINARY="$CODEX_HOME/codex-unavailable"
  export WR_CRUISE_CODEX_BINARY_ONLY=1
fi

exec codex exec \
  --ephemeral \
  --cd "$REPO_ROOT" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  "Invoke the installed wr-cruise status skill and follow its instructions exactly. ${PROMPT}"
