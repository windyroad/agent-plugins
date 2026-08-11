#!/bin/bash
# PreToolUse hook: Denies git commit when risk policy is stale,
# commit risk score is missing/expired/drifted/above threshold.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/risk-gate.sh"
_enable_err_trap

_parse_input

TOOL_NAME=$(_get_tool_name)
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(_get_command)
echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*git commit' || exit 0
if ! _enter_hook_cwd; then
    risk_gate_deny "Commit blocked: the command checkout could not be validated. Run the command from an absolute Git working directory and rescore that checkout."
    exit 0
fi

# P170 / RFC-002 / ADR-031 T11: commit-message-embedded RISK_BYPASS
# marker recognition. The adopter auto-migrate routine (T7,
# packages/shared/lib/migrate-problems-layout.sh) emits a standalone
# commit with `RISK_BYPASS: adr-031-migration` in its body so the
# pure-rename + pure-mkdir migration commit (policy-authorised under
# ADR-013 Rule 6 + ADR-019 precedent) skips the full risk-score
# overhead while preserving the audit trail (per ADR-031 Open
# Execution-time Questions resolution Q3 lean (b)). Case-sensitive
# token match; only `adr-031-migration` is accepted at this surface.
# Future commit-message-embedded markers MUST be added explicitly
# here and to ADR-014's commit-message convention table.
if echo "$COMMAND" | grep -qE 'RISK_BYPASS:[[:space:]]*adr-031-migration([^A-Za-z0-9_-]|$)'; then
    exit 0
fi

SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

# RISK-POLICY.md must exist and not be stale by its own stated review
# cadence (`> Reviewed <cadence> ...` line; ADR-091 machine-read
# contract). Fallback threshold 14 days when the cadence line is absent
# or the word unrecognised. P408.
if [ ! -f "RISK-POLICY.md" ] || [ ! -s "RISK-POLICY.md" ]; then
    risk_gate_deny "Commit blocked: RISK-POLICY.md is missing. Run /risk-policy to create it before committing."
    exit 0
fi
POLICY_STALE=$(python3 -c "
from datetime import date
import re
CADENCE_DAYS = {'weekly': 7, 'fortnightly': 14, 'biweekly': 14,
                'monthly': 30, 'quarterly': 90, 'annually': 365, 'yearly': 365}
try:
    text = open('RISK-POLICY.md').read()
    m = re.search(r'Last reviewed:\*{0,2}\s*(\d{4}-\d{2}-\d{2})', text)
    # Case-sensitive capital-R match so the cadence line is never
    # confused with the lowercase 'Last reviewed: <date>' line (ADR-091).
    c = re.search(r'(?m)^>?\s*Reviewed\s+([A-Za-z]+)', text)
    cadence = c.group(1) if c else ''
    threshold = CADENCE_DAYS.get(cadence, 14)
    if cadence not in CADENCE_DAYS:
        cadence = ''
    if m:
        reviewed = date.fromisoformat(m.group(1))
        if (date.today() - reviewed).days > threshold:
            reason = ('per the policy\'s stated %s cadence' % cadence) if cadence else '(default threshold; no stated cadence)'
            print('over %d days ago %s' % (threshold, reason))
        else:
            print('no')
    else:
        print('no')
except:
    print('no')
" 2>/dev/null || echo "no")
if [ "$POLICY_STALE" != "no" ]; then
    risk_gate_deny "Commit blocked: RISK-POLICY.md is stale (last reviewed ${POLICY_STALE}). Run /risk-policy to update it before committing."
    exit 0
fi

# Clean tree bypass
RDIR=$(_risk_dir "$SESSION_ID")
if [ -f "${RDIR}/clean" ]; then
    exit 0
fi

# Risk-reducing/neutral bypass — session-scoped, drift-revalidated (P192).
# Preserved across multiple commits while pipeline-state hash matches and
# TTL is unexpired; consumed on drift or TTL expiry so a genuine risk-
# profile change forces a fresh wr-risk-scorer:pipeline rescore. Mirrors
# the clean-marker persist-until-drift precedent (above) — distinct from
# incident-release, which remains the one-shot live-outage override
# (ci-bypass was removed per P377/RFC-029).
if [ -f "${RDIR}/reducing-commit" ]; then
    NOW=$(date +%s)
    MARK_TIME=$(_mtime "${RDIR}/reducing-commit")
    AGE=$(( NOW - MARK_TIME ))
    TTL_SECONDS="${RISK_TTL:-3600}"
    if [ "$AGE" -lt "$TTL_SECONDS" ] && [ -f "${RDIR}/state-hash" ] && _checkout_matches "${RDIR}/checkout-id"; then
        STORED_HASH=$(cat "${RDIR}/state-hash")
        CURRENT_HASH=$("$SCRIPT_DIR/lib/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
        if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
            exit 0
        fi
    fi
    rm -f "${RDIR}/reducing-commit"
fi

# Gate check: existence, TTL, drift, threshold
if ! check_risk_gate "$SESSION_ID" "commit"; then
    risk_gate_deny "Commit blocked: ${RISK_GATE_REASON} To proceed: (1) stage files with git add, (2) delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to assess cumulative pipeline risk. If the commit is risk-neutral or risk-reducing, the scorer will create a bypass marker."
    exit 0
fi

exit 0
