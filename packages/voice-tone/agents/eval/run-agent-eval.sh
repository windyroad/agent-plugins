#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
AGENT_MD="${SCRIPT_DIR}/../agent.md"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd -P)"

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: agent.md not found at $AGENT_MD" >&2
  exit 2
fi

cd "$REPO_ROOT"
claude -p \
  --setting-sources "" \
  --tools "Read,Glob,Grep" \
  --system-prompt "$(<"$AGENT_MD")" \
  "$@"
