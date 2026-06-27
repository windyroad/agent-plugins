#!/usr/bin/env bash
# run-agent-eval.sh — promptfoo exec-provider driver for the review-test
# AGENT eval (P290 Phase 2 / P324 / RFC-012). Loads agents/review-test.md as
# the FULL system prompt (`--system-prompt`, not `--append-system-prompt`) —
# an agent eval tests the agent in isolation, so its prose IS the entire
# instruction set, unlike the SKILL evals which APPEND SKILL.md to preserve
# harness context (ADR-075 Amendment 2026-06-02). Feeds promptfoo's per-test
# prompt (the test source, inline) as the user message.
#
# Promptfoo invokes this as: bash run-agent-eval.sh "$PROMPT"
# (per `providers: - id: 'exec:bash ./run-agent-eval.sh'`).
#
# The review-test agent classifies the test source it is given. Each eval test
# embeds the fixture test source inline in the prompt (no on-disk fixture
# files), mirroring the architect agent eval's inline proposed-change shape.
#
# Subscription auth via the developer's logged-in claude session — no
# ANTHROPIC_API_KEY, no CLAUDE_CODE_OAUTH_TOKEN (CI/release-only per
# ADR-075 §6). Mirrors the architect / jtbd run-agent-eval.sh auth posture.
#
# @adr ADR-075 (per-package agent eval; --system-prompt for agent surface)
# @adr ADR-052 (behavioural-only; review-test verdict vocabulary)
# @rfc RFC-012
# @problem P290
# @problem P324
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD="${SCRIPT_DIR}/../review-test.md"

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: review-test.md not found at $AGENT_MD" >&2
  exit 2
fi

exec claude -p --system-prompt "$(cat "$AGENT_MD")" "$@"
