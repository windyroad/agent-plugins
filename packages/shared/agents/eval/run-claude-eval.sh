#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

claude -p --permission-mode plan \
  --system-prompt "$(cat "$REPO_ROOT/CLAUDE.md")" \
  "${*:?prompt argument is required}"
