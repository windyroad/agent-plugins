#!/bin/bash
set -euo pipefail

set +e
probe=$(claude -p "Reply exactly: available" 2>&1)
status=$?
set -e

if [ "$status" -ne 0 ]; then
  cleaned=$(printf '%s\n' "$probe" | tr -d '\r' | sed '/^[[:space:]]*$/d')
  if [ "$(printf '%s\n' "$cleaned" | wc -l | tr -d ' ')" -eq 1 ] \
    && printf '%s\n' "$cleaned" | grep -Eq "^You've hit your weekly limit( · resets [A-Za-z]{3} [0-9]{1,2}, [0-9]{1,2}(:[0-9]{2})?(am|pm) \(UTC\))?$"; then
    echo "::warning::Claude subscription quota is exhausted; agent-prose evals produced no evidence and will retry on the next run."
    exit 0
  fi
  printf '%s\n' "$probe" >&2
  exit "$status"
fi

exec npm run eval:agents
