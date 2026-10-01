#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

claude -p --model "${AGENT_EVAL_MODEL:-claude-sonnet-5}" --permission-mode dontAsk \
  --tools "" --setting-sources "" --settings '{"disableAllHooks":true}' --no-session-persistence \
  --system-prompt "$(cat "$REPO_ROOT/CLAUDE.md")" \
  "${*:?prompt argument is required}"
