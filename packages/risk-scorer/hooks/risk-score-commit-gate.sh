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

# RISK-POLICY.md must exist and not be stale (>14 days)
if [ ! -f "RISK-POLICY.md" ] || [ ! -s "RISK-POLICY.md" ]; then
    risk_gate_deny "Commit blocked: RISK-POLICY.md is missing. Run /risk-policy to create it before committing."
    exit 0
fi
POLICY_STALE=$(python3 -c "
from datetime import date
import re
try:
    text = open('RISK-POLICY.md').read()
    m = re.search(r'Last reviewed:\*{0,2}\s*(\d{4}-\d{2}-\d{2})', text)
    if m:
        reviewed = date.fromisoformat(m.group(1))
        print('yes' if (date.today() - reviewed).days > 14 else 'no')
    else:
        print('no')
except:
    print('no')
" 2>/dev/null || echo "no")
if [ "$POLICY_STALE" = "yes" ]; then
    risk_gate_deny "Commit blocked: RISK-POLICY.md is stale (last reviewed over 2 weeks ago). Run /risk-policy to update it before committing."
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
# incident-release / ci-bypass, which remain deliberate one-time overrides.
if [ -f "${RDIR}/reducing-commit" ]; then
    NOW=$(date +%s)
    MARK_TIME=$(_mtime "${RDIR}/reducing-commit")
    AGE=$(( NOW - MARK_TIME ))
    TTL_SECONDS="${RISK_TTL:-3600}"
    if [ "$AGE" -lt "$TTL_SECONDS" ] && [ -f "${RDIR}/state-hash" ]; then
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
