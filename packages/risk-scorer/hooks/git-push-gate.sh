#!/bin/bash
# PreToolUse hook for pipeline discipline:
# - Blocks bare `git push` and directs to npm run push:watch.
# - Gates `npm run push:watch` on push risk score (TTL + drift + threshold).
# - Gates `npx changeset` / `npm run changeset` on release + push risk (back-pressure).
# - Gates `npm run release:watch` on release risk score (TTL + drift + threshold).
# - Blocks `gh pr merge` and directs to npm run release:watch.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/risk-gate.sh"
_enable_err_trap

_parse_input

TOOL_NAME=$(_get_tool_name)
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(_get_command)
SESSION_ID=$(_get_session_id)

# Block git push to master/main/publish/changeset-release/*, or bare git push.
# Allow explicit pushes to other branches (feature branches etc).
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*git push(\s|$)'; then
    # Allow if pushing to an explicit branch that isn't a protected/managed branch
    if echo "$COMMAND" | grep -qE 'git push\s+\S+\s+\S+' && \
       ! echo "$COMMAND" | grep -qE 'git push\s+\S+\s+(master|main|publish|changeset-release/)'; then
        exit 0
    fi
    risk_gate_deny "Use \`npm run push:watch\` instead of \`git push\`. It pushes, watches the pipeline, and then surfaces either the release PR URL (if there are pending changesets) or the test deploy URL so you can review before releasing. The publish and changeset-release/* branches are managed by the pipeline -- do not push to them directly."
    exit 0
fi

# Gate push:watch on push risk score (inherits three-band TTL via check_risk_gate — P090)
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*npm run push:watch(\s|$)'; then
    if [ -n "$SESSION_ID" ]; then
        RDIR=$(_risk_dir "$SESSION_ID")
        # Risk-reducing/neutral bypass for push — session-scoped, drift-
        # revalidated (P192). Persists across multiple push attempts while
        # pipeline-state hash matches and TTL is unexpired; consumed on
        # drift or TTL expiry. Symmetric with the commit-gate change above.
        if [ -f "${RDIR}/reducing-push" ]; then
            NOW=$(date +%s)
            MARK_TIME=$(_mtime "${RDIR}/reducing-push")
            AGE=$(( NOW - MARK_TIME ))
            TTL_SECONDS="${RISK_TTL:-3600}"
            if [ "$AGE" -lt "$TTL_SECONDS" ] && [ -f "${RDIR}/state-hash" ]; then
                STORED_HASH=$(cat "${RDIR}/state-hash")
                CURRENT_HASH=$("$SCRIPT_DIR/lib/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
                if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
                    exit 0
                fi
            fi
            rm -f "${RDIR}/reducing-push"
        fi
        # Clean tree bypass: if no uncommitted changes, pushing existing commits is safe
        if [ -f "${RDIR}/clean" ]; then
            exit 0
        fi
        # CI-status precondition (P208): a within-appetite predicted-risk
        # score is necessary but not sufficient — the lagging CI signal
        # must also be green (or no-history-yet for the documented
        # first-push case). Fail-closed on gh errors. Ordered AFTER the
        # one-shot bypass markers and BEFORE the predicted-risk gate so
        # incident workflows and clean-tree pushes are unaffected.
        if ! check_ci_status "$SESSION_ID" "push"; then
            risk_gate_deny "Push blocked: ${CI_GATE_REASON}"
            exit 0
        fi
        if ! check_risk_gate "$SESSION_ID" "push"; then
            if [ "$RISK_GATE_CATEGORY" = "threshold" ]; then
                risk_gate_deny "Push blocked: Push risk score ${RISK_GATE_SCORE}/25 (Medium or above). To proceed: (1) release first via \`npm run release:watch\`, (2) split the push, or (3) add risk-reducing measures. If risk-neutral or risk-reducing, delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') — it will create a bypass marker."
            else
                risk_gate_deny "Push blocked: ${RISK_GATE_REASON}"
            fi
            exit 0
        fi
    fi
    exit 0
fi

# Block `changeset version` — versioning is done by the release pipeline,
# not locally. Creating changesets (`npx changeset`) is fine.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*(npx changeset|npm run changeset)\s+version(\s|$)'; then
    risk_gate_deny "Do not run \`changeset version\` locally. The release pipeline handles versioning automatically. To release: (1) push your changes with \`npm run push:watch\`, (2) the pipeline creates a release PR via changesets, (3) merge the release PR to publish. If you need to create a changeset, use \`npx changeset\` (without \`version\`)."
    exit 0
fi

# Gate changeset creation on release risk score (fail-closed).
# Changesets feed directly into releases, so gate on the release score.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*(npx changeset|npm run changeset)(\s|$)'; then
    if [ -n "$SESSION_ID" ]; then
        if ! check_risk_gate "$SESSION_ID" "release"; then
            risk_gate_deny "Changeset blocked: ${RISK_GATE_REASON}. To create a changeset, the release risk score must be within appetite. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to assess."
            exit 0
        fi
    fi
    exit 0
fi

# Gate release:watch on release risk score
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*npm run release:watch(\s|$)'; then
    if [ -n "$SESSION_ID" ]; then
        RDIR=$(_risk_dir "$SESSION_ID")
        # Live-incident bypass: if an incident marker exists, allow release
        # regardless of risk score. Used when addressing outages, security
        # incidents, or information disclosure that requires immediate deployment.
        # Per JTBD-201, this MUST short-circuit BEFORE the CI-status check
        # so the hotfix path is unaffected by red CI on master.
        if [ -f "${RDIR}/incident-release" ]; then
            rm -f "${RDIR}/incident-release"
            exit 0
        fi
        # Risk-reducing bypass for release — session-scoped, drift-
        # revalidated (P192). Same lifecycle as reducing-push above.
        if [ -f "${RDIR}/reducing-release" ]; then
            NOW=$(date +%s)
            MARK_TIME=$(_mtime "${RDIR}/reducing-release")
            AGE=$(( NOW - MARK_TIME ))
            TTL_SECONDS="${RISK_TTL:-3600}"
            if [ "$AGE" -lt "$TTL_SECONDS" ] && [ -f "${RDIR}/state-hash" ]; then
                STORED_HASH=$(cat "${RDIR}/state-hash")
                CURRENT_HASH=$("$SCRIPT_DIR/lib/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
                if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
                    exit 0
                fi
            fi
            rm -f "${RDIR}/reducing-release"
        fi
        # CI-status precondition (P208): a green CI run on the target
        # branch is required before shipping. Fail-closed on gh errors.
        if ! check_ci_status "$SESSION_ID" "release"; then
            risk_gate_deny "Release blocked: ${CI_GATE_REASON}"
            exit 0
        fi
        if ! check_risk_gate "$SESSION_ID" "release"; then
            risk_gate_deny "Release blocked: ${RISK_GATE_REASON}"
            exit 0
        fi
    fi
    exit 0
fi

# Match gh pr merge. Should go via npm run release:watch instead.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh pr merge(\s|$)'; then
    # Check if the project has a release:watch script
    if [ -f "package.json" ] && python3 -c "
import json, sys
pkg = json.load(open('package.json'))
sys.exit(0 if 'release:watch' in pkg.get('scripts', {}) else 1)
" 2>/dev/null; then
        risk_gate_deny "Use \`npm run release:watch\` instead of \`gh pr merge\`. It merges the release PR, watches the publish pipeline, and surfaces the production URL when live -- or tells you what failed and how to fix it."
    else
        risk_gate_deny "Direct \`gh pr merge\` is blocked (no release:watch script found). Create a release:watch npm script that: (1) finds and merges the release PR with \`gh pr merge\`, (2) waits for the CI workflow with \`gh run list\`, and (3) watches it with \`gh run watch --exit-status\`. Then run \`npm run release:watch\` to release."
    fi
    exit 0
fi

exit 0
