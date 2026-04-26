#!/bin/bash
# PreToolUse hook: gates outbound prose for risk/leak review (P064 / ADR-028 amended).
#
# Surface (matched on Bash command text or Edit/Write file_path):
#   - gh issue create | comment | edit            (public issue bodies)
#   - gh pr   create | comment | edit             (public PR bodies)
#   - gh api .../security-advisories              (advisory drafts)
#   - gh api .../comments                         (any REST surface accepting prose)
#   - npm publish                                 (README / package metadata to npm)
#   - PreToolUse:Write|Edit on .changeset/*.md    (P073 — gates author-time)
#
# Gate behaviour:
#   1. BYPASS_RISK_GATE=1 short-circuits the gate (consistent with git-push-gate.sh).
#   2. RISK-POLICY.md absent → advisory-only mode (permits with systemMessage).
#   3. Hybrid leak-pattern pre-filter (lib/leak-detect.sh) hard-fails on
#      credentials, prod-URL prefixes, business-context-paired financial figures,
#      or business-context-paired user counts. Deny includes the matched class.
#   4. Otherwise: check for a per-evaluator marker keyed on
#      sha256(draft_body + '\n' + surface). Marker present → permit.
#      Marker absent → deny with directive to delegate to wr-risk-scorer:external-comms.
#
# Marker location: ${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}/external-comms-reviewed-<sha256>
# Marker writer:   PostToolUse:Agent hook (risk-score-mark.sh) on subagent
#                  type wr-risk-scorer:external-comms.
#
# Composite-marker scheme (combining with wr-voice-tone:agent verdict for
# the same draft) is deferred until P038 lands its evaluator. This iteration
# ships the risk-evaluator side as a standalone gate; the two hooks compose
# at the PreToolUse:Bash matcher level when both packages are installed.
# See ADR-028 amendment Reassessment Criteria.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/leak-detect.sh
source "$SCRIPT_DIR/lib/leak-detect.sh"

# ---------- Bypass ----------
if [ "${BYPASS_RISK_GATE:-0}" = "1" ]; then
    exit 0
fi

INPUT=$(cat)

# Extract tool name + tool_input via python3 (consistent with sibling hooks).
TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('session_id', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Permit silently when session_id is absent; the gate cannot key a marker.
[ -n "$SESSION_ID" ] || exit 0

# ---------- Surface detection ----------
SURFACE=""
DRAFT=""

case "$TOOL_NAME" in
    Bash)
        COMMAND=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

        # Surface match — most-specific first.
        if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh issue create(\s|$)'; then
            SURFACE="gh-issue-create"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh issue comment(\s|$)'; then
            SURFACE="gh-issue-comment"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh issue edit(\s|$)'; then
            SURFACE="gh-issue-edit"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh pr create(\s|$)'; then
            SURFACE="gh-pr-create"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh pr comment(\s|$)'; then
            SURFACE="gh-pr-comment"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*gh pr edit(\s|$)'; then
            SURFACE="gh-pr-edit"
        elif echo "$COMMAND" | grep -qE 'gh api .*security-advisories'; then
            SURFACE="gh-api-security-advisories"
        elif echo "$COMMAND" | grep -qE 'gh api .*/comments'; then
            SURFACE="gh-api-comments"
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*npm publish(\s|$)'; then
            SURFACE="npm-publish"
        else
            exit 0
        fi

        # Best-effort body extraction: --body 'TEXT' or --body "TEXT" or --field summary='TEXT'.
        # When absent (npm publish, --body-file), DRAFT="" is acceptable: the agent will
        # be invoked with command context and read whatever body source the call uses.
        DRAFT=$(printf '%s' "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
# Match --body '...' or --body \"...\" or --field summary='...'
for pat in [r\"--body[= ]'([^']*)'\", r'--body[= ]\"([^\"]*)\"',
            r\"--field [a-zA-Z_]+='([^']*)'\", r'--field [a-zA-Z_]+=\"([^\"]*)\"']:
    m = re.search(pat, cmd)
    if m:
        print(m.group(1))
        break
" 2>/dev/null || echo "")
        ;;

    Write|Edit)
        FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    ti = json.load(sys.stdin).get('tool_input', {})
    print(ti.get('file_path', ti.get('path', '')))
except Exception:
    print('')
" 2>/dev/null || echo "")

        case "$FILE_PATH" in
            *.changeset/*.md|*/.changeset/*.md|.changeset/*.md)
                SURFACE="changeset-author"
                ;;
            *)
                exit 0
                ;;
        esac

        DRAFT=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    ti = json.load(sys.stdin).get('tool_input', {})
    print(ti.get('content', '') + ti.get('new_string', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")
        ;;

    *)
        exit 0
        ;;
esac

# ---------- Helpers ----------
deny_with_reason() {
    local reason="$1"
    python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny',
        'permissionDecisionReason': sys.argv[1]
    }
}))
" "$reason"
}

permit_with_advisory() {
    local msg="$1"
    python3 -c "
import json, sys
print(json.dumps({'systemMessage': sys.argv[1]}))
" "$msg"
}

# ---------- Advisory-only fallback when policy file is absent ----------
if [ ! -f "RISK-POLICY.md" ]; then
    permit_with_advisory "RISK-POLICY.md not found — wr-risk-scorer:external-comms gate is advisory-only on $SURFACE."
    exit 0
fi

# ---------- Hard-fail leak-pattern pre-filter ----------
if ! leak_detect_scan "$DRAFT"; then
    REASON=$(printf 'BLOCKED (P064 external-comms gate): %s on %s. Remove the leak before retrying. Override only if intentional: BYPASS_RISK_GATE=1.' \
        "$LEAK_DETECT_REASON" "$SURFACE")
    deny_with_reason "$REASON"
    exit 0
fi

# ---------- Marker-based gate ----------
SESSION_DIR="${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}"
mkdir -p "$SESSION_DIR"
KEY=$(printf '%s\n%s' "$DRAFT" "$SURFACE" | shasum -a 256 | cut -d' ' -f1)
MARKER="${SESSION_DIR}/external-comms-reviewed-${KEY}"

if [ -f "$MARKER" ]; then
    exit 0
fi

# Marker absent — deny + delegate.
REASON=$(printf 'BLOCKED (P064 external-comms gate): %s draft has not been risk-reviewed. Delegate to wr-risk-scorer:external-comms (subagent_type: '"'"'wr-risk-scorer:external-comms'"'"') with the draft body for review. The PostToolUse hook will mark this draft reviewed when the subagent emits EXTERNAL_COMMS_RISK_VERDICT: PASS. Use /wr-risk-scorer:assess-external-comms for an interactive walkthrough. Override only when intentional: BYPASS_RISK_GATE=1.' \
    "$SURFACE")
deny_with_reason "$REASON"
exit 0
