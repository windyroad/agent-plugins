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
FIXTURE_POLICY="${SCRIPT_DIR}/fixtures/risk-policy.fixture.md"
PROMPT_PARTS=()
for arg in "$@"; do
  [[ "$arg" = '{"id":'* ]] && break
  PROMPT_PARTS+=("$arg")
done
PROMPT="${PROMPT_PARTS[*]}"
AGENT="$(printf '%s\n' "$PROMPT" | sed -E -n 's/.*AGENT: (external-comms|pipeline|plan|wip).*/\1/p' | head -1)"
AGENT="${AGENT:-external-comms}"
AGENT_MD="${SCRIPT_DIR}/../${AGENT}.md"

if [[ ! -f "$AGENT_MD" ]]; then
  echo "run-agent-eval.sh: agent not found at $AGENT_MD" >&2
  exit 2
fi
if [[ ! -f "$FIXTURE_POLICY" ]]; then
  echo "run-agent-eval.sh: fixture policy not found at $FIXTURE_POLICY" >&2
  exit 2
fi

AGENT_INSTRUCTIONS="$(cat "$AGENT_MD")"
if [[ "$AGENT" = "pipeline" && "$PROMPT" = *"CODEX_BINDING_CONTRACT: true"* ]]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
  AGENT_INSTRUCTIONS="$(python3 -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["developer_instructions"])' "$REPO_ROOT/.codex/agents/wr-risk-scorer-pipeline.toml")"
fi

# Stage the fixture as RISK-POLICY.md in an isolated temp cwd so the agent's
# cwd read of RISK-POLICY.md resolves the credibility-axis-bearing fixture,
# not the live dormant home-repo policy.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cp "$FIXTURE_POLICY" "$WORKDIR/RISK-POLICY.md"
threshold="$(printf '%s\n' "$PROMPT" | sed -n 's/.*POLICY_THRESHOLD: \([0-9][0-9]*\).*/\1/p' | head -1)"
if [[ -n "$threshold" ]]; then
  printf '\n## Risk Appetite\n\nThreshold: %s\n' "$threshold" >> "$WORKDIR/RISK-POLICY.md"
fi
cd "$WORKDIR"

if [[ "${WR_EVAL_RUNTIME:-claude}" = "codex" ]]; then
  CODEX_PROMPT="Follow these agent instructions exactly:\n\n${AGENT_INSTRUCTIONS}\n\nEvaluation prompt:\n$PROMPT"
  CODEX_PROMPT="$(python3 -c 'import sys; print(sys.stdin.read().translate(str.maketrans({"§":"section ","—":"--","→":"->","≤":"<=","≥":">="})), end="")' <<< "$CODEX_PROMPT")"
  exec codex exec --ephemeral --cd "$WORKDIR" --skip-git-repo-check -c 'approval_policy="never"' --sandbox read-only - <<< "$CODEX_PROMPT"
fi

# Bounded retry for eval determinism (P459). `claude -p` is non-deterministic and
# occasionally omits the agent's mandated contract verdict token; the single-shot
# `icontains` assertions then fail and red-line the whole Agent-Prose Evals job —
# flaking CI ~50% of pushes regardless of the diff. Retry up to 3× until the output
# carries a consistent contract verdict. This absorbs transient omissions and
# self-contradictory plan markers without masking persistent regressions.
case "$AGENT" in
  external-comms) VERDICT_TOKEN='EXTERNAL_COMMS_RISK_VERDICT:' ;;
  pipeline)       VERDICT_TOKEN='RISK_SCORES:' ;;
  plan|wip)       VERDICT_TOKEN='RISK_VERDICT:' ;;
  *)              VERDICT_TOKEN='' ;;
esac
agent_out=""
for _attempt in 1 2 3; do
  agent_out="$(claude -p --system-prompt "$AGENT_INSTRUCTIONS" "$PROMPT")"
  if [[ "$AGENT" = "plan" ]] && {
    { printf '%s' "$agent_out" | grep -Eiq 'Overall:.*FAIL' && ! printf '%s' "$agent_out" | grep -q '^RISK_VERDICT: FAIL$'; } ||
    { printf '%s' "$agent_out" | grep -Eiq 'Overall:.*PASS' && ! printf '%s' "$agent_out" | grep -q '^RISK_VERDICT: PASS$'; }
  }; then
    continue
  fi
  if [[ -z "$VERDICT_TOKEN" ]] || printf '%s' "$agent_out" | grep -qF "$VERDICT_TOKEN"; then
    break
  fi
done
printf '%s' "$agent_out"
