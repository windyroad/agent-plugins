#!/bin/bash
set -euo pipefail

export AGENT_EVAL_MODEL=claude-sonnet-5
export AGENT_EVAL_GRADER_MODEL=claude-opus-5-5

set +e
probe=$(claude -p --model "$AGENT_EVAL_MODEL" "Reply exactly: available" 2>&1)
status=$?
set -e

if [ "$status" -ne 0 ]; then
  cleaned=$(printf '%s\n' "$probe" | tr -d '\r' | sed '/^[[:space:]]*$/d')
  if [ "$(printf '%s\n' "$cleaned" | wc -l | tr -d ' ')" -eq 1 ] \
    && printf '%s\n' "$cleaned" | grep -Eq "^You've hit your (weekly|session) limit( · resets ([A-Za-z]{3} [0-9]{1,2}, )?[0-9]{1,2}(:[0-9]{2})?(am|pm) \(UTC\))?$"; then
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
      echo "quota-exhausted=true" >> "$GITHUB_OUTPUT"
    fi
    echo "::warning::Claude subscription quota is exhausted; agent-prose evals produced no evidence and will retry on the next run."
    exit 0
  fi
  printf '%s\n' "$probe" >&2
  exit "$status"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "quota-exhausted=false" >> "$GITHUB_OUTPUT"
fi

if [ "${AGENT_EVAL_RUN_AGENTS:-true}" != "true" ]; then
  exit 0
fi

exec npm run eval:agents
