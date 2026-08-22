#!/usr/bin/env bash
# Fan out ITIL hooks from one trusted Codex hook per lifecycle event.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENT="${1:-}"
INPUT="$(cat)"
INPUT="$(printf '%s' "$INPUT" | CODEX_THREAD_ID="${CODEX_THREAD_ID:-}" python3 -c '
import json, os, sys
try:
    value = json.load(sys.stdin)
except (json.JSONDecodeError, TypeError):
    value = {}
value.setdefault("session_id", os.environ.get("CODEX_THREAD_ID", ""))
value.setdefault("cwd", os.getcwd())
value.setdefault("tool_input", {})
print(json.dumps(value))
')"
OUTPUTS=()

run_hook() {
  local output
  output="$(printf '%s' "$INPUT" | "$SCRIPT_DIR/$1" 2>&1 || true)"
  if [ -n "$output" ]; then
    OUTPUTS+=("$(printf '%s\n' "$output" | sed 's/AskUserQuestion/request_user_input/g; s#\.claude/#.codex/#g; s/CLAUDE\.md/AGENTS.md/g')")
  fi
}

emit_outputs() {
  [ "${#OUTPUTS[@]}" -gt 0 ] || return 0
  printf '%s\0' "${OUTPUTS[@]}" | EVENT="$EVENT" python3 -c '
import json, os, sys

messages, reasons, stops = [], [], []
for raw in sys.stdin.buffer.read().decode().split("\0"):
    if not raw:
        continue
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        messages.append(raw)
        continue
    if value.get("systemMessage"):
        messages.append(value["systemMessage"])
    if value.get("stopReason"):
        stops.append(value["stopReason"])
    specific = value.get("hookSpecificOutput") or {}
    if specific.get("permissionDecision") == "deny":
        reasons.append(specific.get("permissionDecisionReason") or "Denied by ITIL policy")
    if specific.get("additionalContext"):
        messages.append(specific["additionalContext"])

if reasons:
    names = {"pre-tool": "PreToolUse", "post-tool": "PostToolUse"}
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": names.get(os.environ.get("EVENT"), "PreToolUse"),
        "permissionDecision": "deny",
        "permissionDecisionReason": "\n".join(reasons + messages),
    }}))
elif stops:
    print(json.dumps({"stopReason": "\n".join(stops + messages)}))
elif messages:
    print(json.dumps({"systemMessage": "\n".join(messages)}))
'
}

tool_name() {
  printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name") or "")' 2>/dev/null || true
}

input_field() {
  printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get(sys.argv[1]) or "")' "$1" 2>/dev/null || true
}

work_problems_marker() {
  local session_id digest
  session_id="$(input_field session_id)"
  [ -n "$session_id" ] || session_id="${CODEX_THREAD_ID:-unknown}"
  digest="$(printf '%s' "$session_id" | shasum -a 256 | awk '{print $1}')"
  printf '%s/wr-itil-codex-work-problems-%s' "${TMPDIR:-/tmp}" "$digest"
}

check_codex_dependencies() {
  local installed
  command -v codex >/dev/null 2>&1 || return 0
  installed="$(codex plugin list 2>/dev/null)" || return 0
  [[ "$installed" == *"wr-risk-scorer@"* ]] || OUTPUTS+=("$(jq -n '{systemMessage:"WR ITIL requires wr-risk-scorer for governed commit, push, and release assessment. Install @windyroad/risk-scorer for Codex."}')")
}

case "$EVENT" in
  session-start)
    AGENT_OUTPUT="$(printf '%s' "$INPUT" | node "$SCRIPT_DIR/../scripts/codex-agent.mjs" --session-start 2>/dev/null || true)"
    [ -z "$AGENT_OUTPUT" ] || OUTPUTS+=("$AGENT_OUTPUT")
    check_codex_dependencies
    run_hook itil-pending-questions-surface.sh
    run_hook itil-rfc-oversight-nudge.sh
    run_hook itil-story-mirror-migration-nudge.sh
    ;;
  user-prompt)
    PROMPT="$(input_field prompt)"
    [[ "$PROMPT" == *"wr-itil:work-problems"* ]] && : > "$(work_problems_marker)"
    run_hook itil-assistant-output-gate.sh
    run_hook itil-correction-detect.sh
    run_hook staleness-check.sh
    ;;
  pre-tool)
    run_hook itil-runtime-sid-marker.sh
    case "$(tool_name)" in
      Write)
        run_hook manage-problem-enforce-create.sh
        run_hook itil-claude-space-protection.sh
        ;;
      Edit)
        run_hook itil-claude-space-protection.sh
        ;;
      Bash)
        run_hook p057-staging-trap-detect.sh
        run_hook itil-no-implement-draft-gate.sh
        run_hook itil-bash-polling-antipattern-detect.sh
        run_hook pre-publish-intake-gate.sh
        run_hook itil-changeset-discipline.sh
        run_hook itil-readme-refresh-discipline.sh
        ;;
      request_user_input|AskUserQuestion)
        if [ -f "$(work_problems_marker)" ]; then
          OUTPUTS+=("$(jq -n '{systemMessage:"MID-LOOP ASK DETECTED: request_user_input fired during wr-itil:work-problems. Use it only at a documented halt point; otherwise queue the question and continue with other actionable work."}')")
        fi
        ;;
    esac
    ;;
  post-tool)
    case "$(tool_name)" in
      Bash)
        run_hook itil-rfc-trailer-advisory.sh
        run_hook itil-commit-trailer-transition-advisory.sh
        run_hook itil-fix-title-lifecycle-advisory.sh
        ;;
      Write|Edit)
        run_hook itil-fictional-defer-detect.sh
        run_hook itil-deferral-cadence-gate.sh
        ;;
    esac
    ;;
  stop)
    ASSISTANT_TEXT="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("last_assistant_message") or "")' 2>/dev/null || true)"
    [ -n "$ASSISTANT_TEXT" ] || exit 0
    # shellcheck source=lib/detectors.sh
    source "$SCRIPT_DIR/lib/detectors.sh"
    MATCH="$(printf '%s' "$ASSISTANT_TEXT" | detect_prose_ask 2>/dev/null || true)"
    [ -z "$MATCH" ] || OUTPUTS+=("$(jq -n --arg match "$MATCH" '{stopReason:("PROSE-ASK DETECTED (pattern: \""+$match+"\"). Act when direction is clear; otherwise use request_user_input in Plan Mode. Never prose-ask.")}')")
    MATCH="$(printf '%s' "$ASSISTANT_TEXT" | detect_mechanical_optional 2>/dev/null || true)"
    [ -z "$MATCH" ] || OUTPUTS+=("$(jq -n --arg match "$MATCH" '{stopReason:("MECHANICAL STEP PRESENTED AS OPTIONAL (closer: \""+$match+"\"). Run the contract-mandated step instead of asking or skipping it.")}')")
    if [[ "$ASSISTANT_TEXT" == *"ALL_DONE"* || "$ASSISTANT_TEXT" == *"## Work Problems Summary"* ]]; then
      rm -f "$(work_problems_marker)"
    fi
    ;;
  *)
    echo "itil-codex-dispatch: unknown event '$EVENT'" >&2
    exit 2
    ;;
esac

emit_outputs
