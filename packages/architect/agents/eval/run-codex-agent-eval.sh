#!/usr/bin/env bash
# Codex promptfoo exec-provider driver for the generated wr-architect agent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
# Later exec-provider arguments contain metadata, including grading assertions.
PROMPT="${1:-}"
AGENT_NAME="wr-architect:agent"
EVAL_MODEL="${WR_CODEX_EVAL_MODEL:-gpt-6.1-sol}"
EVAL_EFFORT="${WR_CODEX_EVAL_REASONING_EFFORT:-medium}"

if [[ "$PROMPT" == "[COG_A11Y]"* ]]; then
  AGENT_NAME="wr-architect-cog-a11y"
  PROMPT="${PROMPT#\[COG_A11Y\]}"
fi

if [[ -z "$PROMPT" ]]; then
  echo "run-codex-agent-eval.sh: prompt argument is required" >&2
  exit 2
fi

SOURCE_CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
TMP_CODEX_HOME=""
TMP_PACK_DIR="$(mktemp -d)"
TMP_REPO="$(mktemp -d)"

cleanup() {
  [[ -z "$TMP_CODEX_HOME" ]] || rm -rf "$TMP_CODEX_HOME"
  rm -rf "$TMP_PACK_DIR" "$TMP_REPO"
}
trap cleanup EXIT

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

npm pack "$REPO_ROOT/packages/architect" --pack-destination "$TMP_PACK_DIR" >/dev/null
NPM_SPEC="$(find "$TMP_PACK_DIR" -maxdepth 1 -type f -name '*.tgz' -print -quit)"
CODEX_BINARY="${CODEX_BINARY:-$(command -v codex)}" npm exec --yes --package "$NPM_SPEC" -- windyroad-architect --runtime codex --scope user >/dev/null
test -f "$CODEX_HOME/agents/wr-architect-agent.toml"
test -f "$CODEX_HOME/agents/wr-architect-cog-a11y.toml"
cp -R "$SCRIPT_DIR/fixtures/repo/." "$TMP_REPO/"
git -C "$TMP_REPO" init --quiet

set +e
codex exec \
  --model "$EVAL_MODEL" \
  -c "model_reasoning_effort=\"$EVAL_EFFORT\"" \
  --json --output-last-message "$TMP_PACK_DIR/review-output.txt" \
  --cd "$TMP_REPO" \
  -c 'approval_policy="never"' \
  --sandbox read-only \
  --dangerously-bypass-hook-trust \
  "Spawn the installed custom collaborator agent named ${AGENT_NAME}. Wait for it and close that same agent. Do not substitute another agent or perform the review inline. Return the collaborator's final output verbatim without adding a verdict label or summary.

${PROMPT}" </dev/null > "$TMP_PACK_DIR/review-events.jsonl"
CODEX_STATUS=$?
set -e

# Keep runtime records only in the isolated home long enough to verify the
# actual reviewer child. Requested flags and parent launch headers are not proof.
set +e
python3 "$SCRIPT_DIR/verify-codex-eval-profile.py" \
  "$CODEX_HOME" "$TMP_PACK_DIR/review-events.jsonl" \
  "$TMP_PACK_DIR/review-output.txt" "$EVAL_MODEL" "$EVAL_EFFORT" \
  "$AGENT_NAME" "$CODEX_STATUS" > "$TMP_PACK_DIR/review-profile.json"
PROFILE_STATUS=$?
set -e
if [[ -n "${WR_CODEX_EVAL_PROFILE_MANIFEST:-}" ]]; then
  cp "$TMP_PACK_DIR/review-profile.json" "$WR_CODEX_EVAL_PROFILE_MANIFEST"
fi
printf 'ARCHITECT_CODEX_EVAL_PROFILE: ' >&2
cat "$TMP_PACK_DIR/review-profile.json" >&2
[[ ! -f "$TMP_PACK_DIR/review-output.txt" ]] || cat "$TMP_PACK_DIR/review-output.txt"
[[ "$CODEX_STATUS" -eq 0 ]] || exit "$CODEX_STATUS"
[[ "$PROFILE_STATUS" -eq 0 ]] || exit "$PROFILE_STATUS"

[[ ! -e "$TMP_REPO/forbidden.txt" ]] || {
  echo "run-codex-agent-eval.sh: reviewer changed the read-only fixture" >&2
  exit 3
}
