#!/usr/bin/env bash
# run-skill-eval.sh — promptfoo exec-provider driver for the capture-problem
# SKILL eval. Loads SKILL.md as an APPENDED system prompt (preserves harness
# session context for skill-graph traversal per ADR-075 Amendment 2026-06-02)
# and feeds promptfoo's per-test prompt as the user message.
#
# Promptfoo invokes this as: bash run-skill-eval.sh "$PROMPT"
# (per `providers: - id: 'exec:bash <script>'` shape).
#
# Subscription auth via the developer's logged-in claude session — no
# ANTHROPIC_API_KEY, no CLAUDE_CODE_OAUTH_TOKEN (those are CI/release-only
# per ADR-075 §6).
#
# @adr ADR-075 (Amendment 2026-06-02)
# @rfc RFC-012
# @problem P324
# @problem P199
# @problem P350
# @problem P352
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="${SCRIPT_DIR}/../SKILL.md"

if [[ ! -f "$SKILL_MD" ]]; then
  echo "run-skill-eval.sh: SKILL.md not found at $SKILL_MD" >&2
  exit 2
fi

# Pass the promptfoo prompt through as the user message. claude -p prints to
# stdout, which promptfoo captures as the response under assertion.
exec claude -p --append-system-prompt "$(cat "$SKILL_MD")" "$@"
