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
  *)
    exit 0
    ;;
esac
