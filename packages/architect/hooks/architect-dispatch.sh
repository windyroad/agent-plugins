#!/bin/bash
# Fan out architect hooks from one registered hook per lifecycle event.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVENT="${1:-}"
INPUT="$(cat)"

tool_name() {
  printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true
}

run_gate() {
  local output status
  local child="$1"
  shift
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$child" "$@")"
  status=$?
  [ -z "$output" ] || printf '%s\n' "$output"
  [ "$status" -eq 0 ] || exit "$status"
  [ -z "$output" ] || exit 0
}

run_side_effect() {
  local output status
  local child="$1"
  shift
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$child" "$@")"
  status=$?
  [ -z "$output" ] || printf '%s\n' "$output"
  return "$status"
}

case "$EVENT" in
  session-start)
    agent_output="$(printf '%s' "$INPUT" | node "$SCRIPT_DIR/../scripts/codex-agent.mjs" --session-start)"
    nudge_output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/architect-oversight-nudge.sh")"
    if [ -n "${CODEX_THREAD_ID:-}" ]; then
      AGENT_OUTPUT="$agent_output" NUDGE_OUTPUT="$nudge_output" python3 -c '
import json, os
messages = []
try:
    message = json.loads(os.environ["AGENT_OUTPUT"]).get("systemMessage", "")
except (json.JSONDecodeError, AttributeError):
    message = os.environ["AGENT_OUTPUT"]
if message:
    messages.append(message)
if os.environ["NUDGE_OUTPUT"]:
    messages.append(os.environ["NUDGE_OUTPUT"])
if messages:
    print(json.dumps({"systemMessage": "\n".join(messages)}))
'
    else
      [ -z "$agent_output" ] || printf '%s\n' "$agent_output"
      [ -z "$nudge_output" ] || printf '%s\n' "$nudge_output"
    fi
    ;;
  user-prompt)
    detect_output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/architect-detect.sh")"
    stale_output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/staleness-check.sh")"
    [ -z "$detect_output" ] || printf '%s\n' "$detect_output"
    [ -z "$stale_output" ] || printf '%s\n' "$stale_output"
    ;;
  pre-tool)
    case "$(tool_name)" in
      Edit|Write)
        run_gate architect-enforce-edit.sh
        run_gate architect-oversight-marker-discipline.sh
        ;;
      ExitPlanMode)
        run_gate architect-plan-enforce.sh
        ;;
      Bash)
        run_gate architect-readme-pairing-check.sh
        run_gate bash-write-dispatch.sh \
          "$SCRIPT_DIR/architect-enforce-edit.sh" \
          "$SCRIPT_DIR/architect-oversight-marker-discipline.sh"
        ;;
    esac
    ;;
  post-tool)
    case "$(tool_name)" in
      Agent)
        run_side_effect architect-mark-reviewed.sh || true
        run_side_effect architect-slide-marker.sh || true
        ;;
      collaborationspawn_agent|collaborationinterrupt_agent|spawn_agent|close_agent|multi_agent_v1__spawn_agent|multi_agent_v1__close_agent)
        printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
        ;;
      Edit|Write)
        run_side_effect architect-refresh-hash.sh || true
        run_side_effect architect-compendium-update-entry.sh || true
        ;;
      Bash)
        run_side_effect architect-slide-marker.sh || true
        run_side_effect bash-write-dispatch.sh --all \
          "$SCRIPT_DIR/architect-refresh-hash.sh" \
          "$SCRIPT_DIR/architect-compendium-update-entry.sh" || true
        ;;
      Skill)
        run_side_effect architect-slide-marker.sh || true
        ;;
    esac
    ;;
esac
