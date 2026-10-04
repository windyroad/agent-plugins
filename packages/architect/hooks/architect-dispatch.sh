#!/bin/bash
# Fan out architect hooks from one registered hook per lifecycle event.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVENT="${1:-}"
INPUT="$(cat)"

tool_name() {
  printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true
}

ADVISORIES=""
collect_gate_output() {
  local output="$1" parsed
  [ -n "$output" ] || return 0
  if ! parsed="$(printf '%s' "$output" | jq -cs '
    if any(.[]; .hookSpecificOutput.permissionDecision == "deny")
    then map(select(.hookSpecificOutput.permissionDecision == "deny"))[0]
    else {systemMessage: map(.systemMessage // .hookSpecificOutput.permissionDecisionReason // "Governance evidence unavailable; action permitted.") | join("\n")} end' 2>/dev/null)"; then
    parsed='{"systemMessage":"Governance evidence unavailable: malformed evaluator output; action permitted."}'
  fi
  if printf '%s' "$parsed" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    printf '%s\n' "$parsed"
    exit 0
  fi
  ADVISORIES="$ADVISORIES
$parsed"
}
flush_advisories() {
  [ -n "$ADVISORIES" ] || return 0
  printf '%s' "$ADVISORIES" | jq -s '{systemMessage: map(.systemMessage // .hookSpecificOutput.permissionDecisionReason // "Governance evidence unavailable; action permitted.") | join("\n")}'
}
run_gate() {
  local output status child="$1"
  shift
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$child" "$@" 2>/dev/null)"
  status=$?
  if [ "$status" -ne 0 ]; then
    collect_gate_output '{"systemMessage":"Governance evaluator unavailable; action permitted. A crashed hook output was discarded."}'
    return 0
  fi
  collect_gate_output "$output"
}

run_side_effect() {
  local output status
  local child="$1"
  shift
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$child" "$@" 2>/dev/null)"
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
    printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
    detect_output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/architect-detect.sh")"
    stale_output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/staleness-check.sh")"
    [ -z "$detect_output" ] || printf '%s\n' "$detect_output"
    [ -z "$stale_output" ] || printf '%s\n' "$stale_output"
    ;;
  subagent-start|subagent-stop)
    printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
    ;;
  pre-tool)
    printf '%s' "$INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs"
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
      collaboration.spawn_agent|collaboration.wait_agent|collaboration.interrupt_agent|collaborationspawn_agent|collaborationwait_agent|collaborationinterrupt_agent|spawn_agent|wait_agent|interrupt_agent|close_agent|multi_agent_v1__spawn_agent|multi_agent_v1__wait_agent|multi_agent_v1__close_agent)
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

[ "$EVENT" != pre-tool ] || flush_advisories
