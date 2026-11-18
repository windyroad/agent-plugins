#!/usr/bin/env bash
# Canonical Architect qualification: full agent prompt, pinned declared profile.
# Model inheritance in the installed product is unchanged. This is dev tooling.
set -euo pipefail
umask 077
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD="$SCRIPT_DIR/../agent.md"
[[ -f "$AGENT_MD" ]] || { echo 'run-agent-eval.sh: agent.md missing' >&2; exit 2; }
PROMPT="${1:?prompt argument is required}"
MODEL="${WR_CLAUDE_EVAL_MODEL:-claude-opus-5-5}"
EFFORT="${WR_CLAUDE_EVAL_REASONING_EFFORT:-medium}"
ARTIFACT_ROOT="${ARCHITECT_EVAL_ARTIFACT_DIR:-$SCRIPT_DIR/../../../../docs/audits/agent-evals-workspace/architect-profiles}"
mkdir -p "$ARTIFACT_ROOT"
ARTIFACT_ROOT="$(cd "$ARTIFACT_ROOT" && pwd)"
CAPTURE="$(mktemp -d "$ARTIFACT_ROOT/review.XXXXXX")"
cp "$AGENT_MD" "$CAPTURE/agent.md"
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT
cp -R "$SCRIPT_DIR/fixtures/repo/." "$FIXTURE_ROOT/"
cd "$FIXTURE_ROOT"
set +e
claude -p --model "$MODEL" --effort "$EFFORT" --output-format json \
  --permission-mode dontAsk --tools 'Read,Glob,Grep' --allowedTools 'Read,Glob,Grep' \
  --setting-sources '' --settings '{"disableAllHooks":true}' --no-session-persistence \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  --system-prompt "$(cat "$CAPTURE/agent.md")" -- "$PROMPT" \
  </dev/null >"$CAPTURE/result.json" 2>"$CAPTURE/stderr.txt"
status=$?
set -e
printf '%s\n' "$status" >"$CAPTURE/exit-code"
cat "$CAPTURE/stderr.txt" >&2
if [[ "$status" -ne 0 ]]; then
  cat "$CAPTURE/result.json" >&2
  exit "$status"
fi
python3 "$SCRIPT_DIR/verify-claude-eval-profile.py" "$CAPTURE/result.json" \
  "$MODEL" "$EFFORT" "$CAPTURE/agent.md" "$CAPTURE/profile.json"
printf '\nARCHITECT_CLAUDE_EVAL_PROFILE: ' >&2
cat "$CAPTURE/profile.json" >&2
