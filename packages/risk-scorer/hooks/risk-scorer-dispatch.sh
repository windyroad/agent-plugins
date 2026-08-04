#!/bin/bash
# Fan out risk-scorer hooks from one registered hook per event.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVENT="${1:-}"
INPUT="$(cat)"

run_hook() {
  local output
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$1")"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
    exit 0
  fi
}

tool_name() {
  printf '%s' "$INPUT" | python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_name") or ""))' 2>/dev/null || true
}

case "$EVENT" in
  session-start)
    if ! AGENT_OUTPUT="$(printf '%s' "$INPUT" | node "$SCRIPT_DIR/../scripts/codex-agents.mjs" --session-start 2>/dev/null)"; then
      AGENT_OUTPUT='{"systemMessage":"wr-risk-scorer: Codex agent repair failed; reinstall the plugin."}'
    fi
    if ! NUDGE_OUTPUT="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/risk-scorer-scaffold-nudge.sh" 2>/dev/null)"; then
      NUDGE_OUTPUT=""
    fi
    if [ -n "${CODEX_THREAD_ID:-}" ]; then
      AGENT_OUTPUT="$AGENT_OUTPUT" NUDGE_OUTPUT="$NUDGE_OUTPUT" python3 -c '
import json, os
messages = []
for name in ("AGENT_OUTPUT", "NUDGE_OUTPUT"):
    try:
        message = json.loads(os.environ[name]).get("systemMessage", "")
    except (json.JSONDecodeError, AttributeError):
        message = ""
    if message:
        messages.append(message)
if messages:
    print(json.dumps({"systemMessage": "\n".join(messages)}))
'
    else
      [ -z "$NUDGE_OUTPUT" ] || printf '%s\n' "$NUDGE_OUTPUT"
    fi
    ;;
  user-prompt)
    run_hook risk-score.sh
    run_hook staleness-check.sh
    ;;
  pre-tool)
    case "$(tool_name)" in
      Edit|Write)
        run_hook secret-leak-gate.sh
        run_hook wip-risk-gate.sh
        run_hook external-comms-gate.sh
        run_hook risk-policy-enforce-edit.sh
        ;;
      Bash)
        run_hook git-push-gate.sh
        run_hook risk-score-commit-gate.sh
        run_hook external-comms-gate.sh
        ;;
      ExitPlanMode)
        run_hook risk-score-plan-enforce.sh
        ;;
      EnterPlanMode)
        run_hook plan-risk-guidance.sh
        ;;
    esac
    ;;
  post-tool)
    case "$(tool_name)" in
      Agent)
        run_hook risk-score-mark.sh
        run_hook risk-slide-marker.sh
        ;;
      collaborationspawn_agent|collaborationwait_agent|collaborationinterrupt_agent|spawn_agent|wait_agent|close_agent|multi_agent_v1__spawn_agent|multi_agent_v1__wait_agent|multi_agent_v1__close_agent)
        printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
        ;;
      Bash)
        run_hook risk-hash-refresh.sh
        run_hook risk-slide-marker.sh
        ;;
      Edit|Write)
        run_hook wip-risk-mark.sh
        ;;
      Skill)
        run_hook risk-slide-marker.sh
        ;;
    esac
    ;;
  subagent-stop)
    printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
    ;;
  *)
    exit 0
    ;;
esac
