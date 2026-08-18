#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

codex exec --ephemeral --cd "$REPO_ROOT" \
  -c 'approval_policy="never"' --sandbox read-only \
  "${*:?prompt argument is required}" </dev/null
