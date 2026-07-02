#!/usr/bin/env bash
# run-agent-eval.sh — promptfoo exec-provider driver for the external-comms
# review AGENT eval (RFC-012 S1b / P384). Loads agents/external-comms.md as the
# FULL system prompt (`--system-prompt`, not `--append-system-prompt`) — an
# agent eval tests the agent in isolation, so its prose IS the entire
# instruction set, unlike the SKILL evals which APPEND SKILL.md to preserve
# harness context (ADR-075 Amendment 2026-06-02). Feeds promptfoo's per-test
# prompt as the user message.
#
# Promptfoo invokes this as: bash run-agent-eval.sh "$PROMPT"
# (per `providers: - id: 'exec:bash ./run-agent-eval.sh'`).
#
# DIVERGENCE from the jtbd run-agent-eval.sh reference (which cd's to repo
# root): the external-comms agent reads `RISK-POLICY.md` from cwd. The live
# home-repo RISK-POLICY.md has NO `## Outbound Credibility / Self-Own` section
# yet (deferred interactive Task 5 of P384), so against it the credibility axis
# is dormant and the F1 self-own draft would return PASS — the axis could never
# be exercised. So we stage the SYNTHETIC fixture policy (which carries the
# credibility section) as `RISK-POLICY.md` in an isolated temp cwd and run the
# agent there. This is the RFC-012 S1b synthetic-fixture-corpus pattern (the
# jtbd positive-fire branch used the same shape for its unratified-job corpus).
# The temp dir is auto-removed on exit.
#
# Subscription auth via the developer's logged-in claude session — no
# ANTHROPIC_API_KEY, no CLAUDE_CODE_OAUTH_TOKEN (CI/release-only per
# ADR-075 §6). Mirrors run-skill-eval.sh's auth posture.
#
# @adr ADR-075 (per-package agent eval; --system-prompt for agent surface)
# @adr ADR-052 (behavioural-tests-default)
# @adr ADR-026 (grounding — the fixture policy IS the class list the agent cites)
# @rfc RFC-012 S1b
# @problem P384
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD="${SCRIPT_DIR}/../external-comms.md"
FIXTURE_POLICY="${SCRIPT_DIR}/fixtures/risk-policy.fixture.md"

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: external-comms.md not found at $AGENT_MD" >&2
  exit 2
fi
if [[ ! -f "$FIXTURE_POLICY" ]]; then
  echo "run-agent-eval.sh: fixture policy not found at $FIXTURE_POLICY" >&2
  exit 2
fi

# Stage the fixture as RISK-POLICY.md in an isolated temp cwd so the agent's
# cwd read of RISK-POLICY.md resolves the credibility-axis-bearing fixture,
# not the live dormant home-repo policy.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cp "$FIXTURE_POLICY" "$WORKDIR/RISK-POLICY.md"
cd "$WORKDIR"

claude -p --system-prompt "$(cat "$AGENT_MD")" "$@"
