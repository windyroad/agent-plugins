#!/usr/bin/env bash
# run-agent-eval.sh — promptfoo exec-provider driver for the jtbd review
# AGENT eval (RFC-012 S1 / P324). Loads agents/agent.md as the FULL system
# prompt (`--system-prompt`, not `--append-system-prompt`) — an agent eval
# tests the agent in isolation, so its prose IS the entire instruction set,
# unlike the SKILL evals which APPEND SKILL.md to preserve harness context
# (ADR-075 Amendment 2026-06-02). Feeds promptfoo's per-test prompt as the
# user message.
#
# Promptfoo invokes this as: bash run-agent-eval.sh "$PROMPT"
# (per `providers: - id: 'exec:bash ./run-agent-eval.sh'`).
#
# cwd at invocation is the config dir (promptfoo basePath). The jtbd agent
# reads live docs/jtbd/ and runs the `wr-jtbd-is-job-or-persona-unconfirmed`
# PATH shim, whose default root is `docs/jtbd` relative to cwd — so cd to the
# repo root first. ADR-049: this driver is dev-only (tarball-excluded), so the
# repo-relative root resolution only ever runs in the source monorepo.
#
# Subscription auth via the developer's logged-in claude session — no
# ANTHROPIC_API_KEY, no CLAUDE_CODE_OAUTH_TOKEN (CI/release-only per
# ADR-075 §6). Mirrors run-skill-eval.sh's auth posture.
#
# @adr ADR-075 (per-package agent eval; --system-prompt for agent surface)
# @adr ADR-052 (behavioural-tests-default)
# @adr ADR-049 (PATH shim resolution from repo-root cwd)
# @rfc RFC-012 S1
# @problem P324
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD="${SCRIPT_DIR}/../agent.md"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: agent.md not found at $AGENT_MD" >&2
  exit 2
fi

# Run from repo root so docs/jtbd/ and the shim's default root resolve.
cd "$REPO_ROOT"

exec claude -p --system-prompt "$(cat "$AGENT_MD")" "$@"
