#!/bin/bash
set -euo pipefail

export AGENT_EVAL_MODEL=claude-sonnet-5
export AGENT_EVAL_GRADER_MODEL=claude-opus-5-5
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/agent-eval-quota.py"

quota_unavailable() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "quota-exhausted=true" >> "$GITHUB_OUTPUT"
  fi
  echo "::warning::Claude subscription quota is exhausted; remaining evaluations are unavailable. Retained partial results receive no additional model-test pass credit; selected evaluations retry on a future available run."
  exit 0
}

set +e
probe=$(claude -p --model "$AGENT_EVAL_MODEL" "Reply exactly: available" 2>&1)
status=$?
set -e
if [ "$status" -ne 0 ]; then
  if printf '%s' "$probe" | python3 "$HELPER" pure; then
    quota_unavailable
  fi
  printf '%s\n' "$probe" >&2
  exit "$status"
fi
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "quota-exhausted=false" >> "$GITHUB_OUTPUT"
fi

# Resolve before placing the temporary forwarding shim on PATH. No credentials
# are copied, and no state survives this job's orchestration process.
export AGENT_EVAL_CLAUDE_REAL="$(command -v claude)"
export AGENT_EVAL_BASH_REAL="$(command -v bash)"
export AGENT_EVAL_ROOT="$(pwd)"
export AGENT_EVAL_QUOTA_STATE="$(mktemp -d)"
trap 'rm -rf "$AGENT_EVAL_QUOTA_STATE"' EXIT
python3 "$HELPER" nonce > "$AGENT_EVAL_QUOTA_STATE/nonce"
mkdir "$AGENT_EVAL_QUOTA_STATE/bin" "$AGENT_EVAL_QUOTA_STATE/proofs"
printf '#!/bin/bash\nexec python3 %q claude "$@"\n' "$HELPER" > "$AGENT_EVAL_QUOTA_STATE/bin/claude"
printf '#!/bin/bash\nexec python3 %q bash "$@"\n' "$HELPER" > "$AGENT_EVAL_QUOTA_STATE/bin/bash"
chmod +x "$AGENT_EVAL_QUOTA_STATE/bin/claude" "$AGENT_EVAL_QUOTA_STATE/bin/bash"
export PATH="$AGENT_EVAL_QUOTA_STATE/bin:$PATH"

run_eval() {
  local status=0
  python3 "$HELPER" run "$@" || status=$?
  if [ "$status" -ne 0 ]; then
    exit "$status"
  fi
  if [ -f "$AGENT_EVAL_QUOTA_STATE/unavailable" ]; then
    quota_unavailable
  fi
}

if [ "${AGENT_EVAL_RUN_AGENTS:-true}" = true ]; then
  run_eval npm run eval:agents
fi
if [ "${AGENT_EVAL_RUN_SKILLS:-false}" = true ]; then
  run_eval npx promptfoo eval -c packages/itil/skills/work-problems/eval/risk-appetite.promptfooconfig.yaml --no-table --output docs/audits/agent-evals-workspace/work-problems-appetite.json
  run_eval npx promptfoo eval -c packages/itil/skills/update-upstream/eval/promptfooconfig.yaml --filter-pattern 'AFK below-appetite|AFK external-comms FAIL|Gate composition is mandatory' --no-table --output docs/audits/agent-evals-workspace/update-upstream.json
fi
if [ "${AGENT_EVAL_RUN_REMEDIATION:-false}" = true ]; then
  run_eval npx promptfoo eval -c packages/voice-tone/skills/assess-external-comms/eval/promptfooconfig.yaml --filter-pattern 'Routine failed release|Material unresolved' --no-table --output docs/audits/agent-evals-workspace/voice-remediation.json
  run_eval npx promptfoo eval -c packages/risk-scorer/skills/assess-external-comms/eval/promptfooconfig.yaml --no-table --output docs/audits/agent-evals-workspace/risk-remediation.json
fi
if [ "${AGENT_EVAL_RUN_SKILLS:-false}" = true ]; then
  run_eval npx promptfoo eval -c packages/itil/skills/work-problems/eval/grader-boundary.promptfooconfig.yaml --no-table --output docs/audits/agent-evals-workspace/grader-boundary.json
  run_eval npx promptfoo eval -c packages/itil/skills/manage-incident/eval/promptfooconfig.yaml --filter-pattern 'Incident eligibility' --no-table --output docs/audits/agent-evals-workspace/incident-eligibility.json
fi
if [ "${AGENT_EVAL_RUN_PLANNING:-false}" = true ]; then
  node scripts/sync-codex-plugin-surfaces.mjs planning --build
  export PLANNING_EVAL_RUNTIME=claude
  run_eval npx promptfoo eval -c packages/planning/skills/outcome-led-planning/eval/promptfooconfig.yaml --max-concurrency 2 --no-table --output docs/audits/agent-evals-workspace/planning-claude.json
fi
