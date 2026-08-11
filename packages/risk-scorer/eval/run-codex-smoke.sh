#!/usr/bin/env bash
# Pack and install wr-risk-scorer for Codex in an isolated CODEX_HOME, then
# prove exact-agent discovery plus the external-comms completion marker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME=""
TMP_PACK_DIR=""
TMP_FIXTURE_DIR=""
CODEX_BIN="${CODEX_BINARY:-}"

cleanup() {
  [[ -z "$TMP_CODEX_HOME" ]] || rm -rf "$TMP_CODEX_HOME"
  [[ -z "$TMP_PACK_DIR" ]] || rm -rf "$TMP_PACK_DIR"
  [[ -z "$TMP_FIXTURE_DIR" ]] || rm -rf "$TMP_FIXTURE_DIR"
}
trap cleanup EXIT

if [[ -z "$CODEX_BIN" ]]; then
  if [[ -x /Applications/ChatGPT.app/Contents/Resources/codex ]]; then
    CODEX_BIN=/Applications/ChatGPT.app/Contents/Resources/codex
  else
    CODEX_BIN="$(command -v codex)"
  fi
fi

if [[ -n "${WR_CODEX_EVAL_CODEX_HOME:-}" ]]; then
  export CODEX_HOME="$WR_CODEX_EVAL_CODEX_HOME"
  mkdir -p "$CODEX_HOME"
else
  TMP_CODEX_HOME="$(mktemp -d)"
  chmod 700 "$TMP_CODEX_HOME"
  export CODEX_HOME="$TMP_CODEX_HOME"
  if [[ -f "${SOURCE_CODEX_HOME}/auth.json" ]]; then
    cp "${SOURCE_CODEX_HOME}/auth.json" "$CODEX_HOME/auth.json"
    chmod 600 "$CODEX_HOME/auth.json"
  fi
  if [[ "${WR_CODEX_EVAL_COPY_CONFIG:-0}" == "1" && -f "${SOURCE_CODEX_HOME}/config.toml" ]]; then
    cp "${SOURCE_CODEX_HOME}/config.toml" "$CODEX_HOME/config.toml"
    chmod 600 "$CODEX_HOME/config.toml"
  fi
fi

export TMPDIR="${WR_CODEX_EVAL_TMPDIR:-$CODEX_HOME/tmp}"
mkdir -p "$TMPDIR"

if [[ -n "${WR_RISK_SCORER_NPM_SPEC:-}" ]]; then
  NPM_SPEC="$WR_RISK_SCORER_NPM_SPEC"
else
  TMP_PACK_DIR="$(mktemp -d)"
  npm pack "$REPO_ROOT/packages/risk-scorer" --pack-destination "$TMP_PACK_DIR" >/dev/null
  NPM_SPEC="$(find "$TMP_PACK_DIR" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
  [[ -n "$NPM_SPEC" ]]
fi
CODEX_BINARY="$CODEX_BIN" npm exec --yes --package "$NPM_SPEC" -- windyroad-risk-scorer --runtime codex --scope user >/dev/null

for mode in pipeline plan wip policy external-comms inbound-report; do
  test -f "$CODEX_HOME/agents/wr-risk-scorer-${mode}.toml"
done
CODEX_HOME="$CODEX_HOME" "$CODEX_BIN" plugin list | grep -q 'wr-risk-scorer@windyroad-risk-scorer-local'

run_codex() {
  local cwd="$1"
  shift
  "$CODEX_BIN" exec \
    --cd "$cwd" \
    -c 'approval_policy="never"' \
    --sandbox read-only \
    --dangerously-bypass-hook-trust \
    "$1"
}

TMP_FIXTURE_DIR="$(mktemp -d)"
ASSESSED_REPO="$TMP_FIXTURE_DIR/assessed"
COMPLETION_REPO="$TMP_FIXTURE_DIR/completion"
mkdir -p "$ASSESSED_REPO" "$COMPLETION_REPO"
git init -q "$ASSESSED_REPO"
git init -q "$COMPLETION_REPO"
printf 'same\n' > "$ASSESSED_REPO/state"
printf 'same\n' > "$COMPLETION_REPO/state"
git -C "$ASSESSED_REPO" add state
git -C "$COMPLETION_REPO" add state
git -C "$ASSESSED_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial
git -C "$COMPLETION_REPO" -c user.name=test -c user.email=test@example.com commit -qm initial

MARKER_DRAFT="Codex packaged external communications marker smoke test."
MARKER_KEY="$(MARKER_DRAFT="$MARKER_DRAFT" python3 - <<'PY'
import hashlib, os
draft = os.environ["MARKER_DRAFT"]
print(hashlib.sha256((draft + "\nchangeset-author").encode()).hexdigest())
PY
)"
run_codex "$COMPLETION_REPO" "Use the exact custom agent wr-risk-scorer:external-comms synchronously without full-history fork. Send it exactly this structured review request:
SURFACE: changeset-author
DESTINATION: npm public registry
<draft>
${MARKER_DRAFT}
</draft>
Wait for it to finish, then close that completed agent once and return the reviewer verdict and key verbatim. Do not compute the verdict yourself or inspect any transcript."

find "$TMPDIR" -type f -name "external-comms-risk-reviewed-${MARKER_KEY}" -print -quit | grep -q .

PIPELINE_TMP="$(mktemp -d "$TMPDIR/pipeline-cwd.XXXXXX")"
TMPDIR="$PIPELINE_TMP" run_codex "$COMPLETION_REPO" "Use the exact custom agent wr-risk-scorer:pipeline synchronously without full-history fork. Send it exactly this scoring request and treat the supplied fixture scores as authoritative:
RISK_CWD: ${ASSESSED_REPO}
POLICY_THRESHOLD: 5
Commit, push, and release residual risk are each 4/25. Return the required structured score output. Wait for it to finish, then close that completed agent once. Do not compute the scores yourself or inspect any transcript."

STATE_HASH="$(find "$PIPELINE_TMP" -type f -name state-hash -print -quit)"
[[ -n "$STATE_HASH" ]]
expected="$(cd "$ASSESSED_REPO" && source "$REPO_ROOT/packages/risk-scorer/hooks/lib/gate-helpers.sh" && "$REPO_ROOT/packages/risk-scorer/hooks/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
completion_hash="$(cd "$COMPLETION_REPO" && source "$REPO_ROOT/packages/risk-scorer/hooks/lib/gate-helpers.sh" && "$REPO_ROOT/packages/risk-scorer/hooks/lib/pipeline-state.sh" --hash-inputs | _hashcmd | cut -d' ' -f1)"
[[ "$(cat "$STATE_HASH")" = "$expected" ]]
[[ "$expected" = "$completion_hash" ]]
CHECKOUT_ID="$(find "$PIPELINE_TMP" -type f -name checkout-id -print -quit)"
[[ -n "$CHECKOUT_ID" ]]
expected_checkout="$(cd "$ASSESSED_REPO" && source "$REPO_ROOT/packages/risk-scorer/hooks/lib/gate-helpers.sh" && _checkout_id)"
completion_checkout="$(cd "$COMPLETION_REPO" && source "$REPO_ROOT/packages/risk-scorer/hooks/lib/gate-helpers.sh" && _checkout_id)"
[[ "$(cat "$CHECKOUT_ID")" = "$expected_checkout" ]]
[[ "$expected_checkout" != "$completion_checkout" ]]
find "$ASSESSED_REPO/.risk-reports" -type f -name '*-commit.md' -print -quit | grep -q .
[[ ! -e "$COMPLETION_REPO/.risk-reports" ]]
! grep -R "$ASSESSED_REPO" "$ASSESSED_REPO/.risk-reports"
