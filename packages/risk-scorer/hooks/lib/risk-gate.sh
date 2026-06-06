#!/bin/bash
# Shared gate logic for risk scoring enforcement hooks.
# Sourced by risk-score-commit-gate.sh, git-push-gate.sh, risk-score-plan-enforce.sh.
# Provides: check_risk_gate, risk_gate_deny

# Source shared portable helpers (_mtime, _hashcmd)
_RISK_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_RISK_GATE_DIR/gate-helpers.sh"

# Check risk gate for a given action. Returns 0 if allowed, 1 if denied.
# Sets RISK_GATE_REASON on failure with human-readable message.
# Also sets RISK_GATE_CATEGORY ∈ {missing, expired, drift, invalid, threshold}
# and RISK_GATE_SCORE (on threshold) for callers that customise deny messages.
#
# Implements the three-band TTL policy (P090, ADR-009 footnote):
#   Band A: age < TTL/2        → pass silently (no slide).
#   Band B: TTL/2 ≤ age < TTL  → if state-hash is invariant since the
#                                scorer ran, pass AND slide the marker
#                                forward (touch score file); bounded by
#                                a 2×TTL hard-cap from the scorer-run
#                                birth time stored in <action>-born.
#                                If the hash drifted, halt as before.
#   Band C: age ≥ TTL          → halt with the existing expired message.
# Usage: check_risk_gate "$SESSION_ID" "commit"
check_risk_gate() {
  local SESSION_ID="$1"
  local ACTION="$2"
  local RDIR
  RDIR=$(_risk_dir "$SESSION_ID")
  local SCORE_FILE="${RDIR}/${ACTION}"
  local BORN_FILE="${RDIR}/${ACTION}-born"
  local HASH_FILE="${RDIR}/state-hash"
  local TTL_SECONDS="${RISK_TTL:-3600}"

  RISK_GATE_CATEGORY=""
  RISK_GATE_SCORE=""

  # 1. Score file must exist (fail-closed)
  if [ ! -f "$SCORE_FILE" ]; then
    RISK_GATE_CATEGORY="missing"
    RISK_GATE_REASON="No ${ACTION} risk score found. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to assess cumulative pipeline risk."
    return 1
  fi

  # 2. TTL — Band C hard expiry first
  local NOW=$(date +%s)
  local SCORE_TIME=$(_mtime "$SCORE_FILE")
  local AGE=$(( NOW - SCORE_TIME ))
  if [ "$AGE" -ge "$TTL_SECONDS" ]; then
    RISK_GATE_CATEGORY="expired"
    RISK_GATE_REASON="Risk score expired (${AGE}s old, TTL ${TTL_SECONDS}s). Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore."
    return 1
  fi

  # Detect Band B candidacy (age in [TTL/2, TTL))
  local HALF_TTL=$(( TTL_SECONDS / 2 ))
  local BAND_B=0
  if [ "$AGE" -ge "$HALF_TTL" ]; then
    BAND_B=1
  fi

  # 3. Drift detection — pipeline state hash must match
  # The hash is computed from git diff HEAD --stat at prompt submit time.
  # If you staged files AFTER the prompt, the hash will differ.
  # Fix: stage everything BEFORE submitting the prompt, then commit in the response.
  if [ -f "$HASH_FILE" ]; then
    local STORED_HASH=$(cat "$HASH_FILE")
    local CURRENT_HASH
    CURRENT_HASH=$("$_RISK_GATE_DIR/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
    if [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
      RISK_GATE_CATEGORY="drift"
      RISK_GATE_REASON="Pipeline state drift: working tree changed since the last ${ACTION} risk assessment. Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore against the current state."
      return 1
    fi

    # Band B + hash invariant: slide the marker forward, bounded by 2×TTL
    # from the scorer-run birth time. The hard cap prevents an unchanged-but-
    # perpetually-idle tree from riding a single marker indefinitely.
    if [ "$BAND_B" = "1" ]; then
      if [ -f "$BORN_FILE" ]; then
        local BORN_TIME=$(_mtime "$BORN_FILE")
        local BORN_AGE=$(( NOW - BORN_TIME ))
        local HARD_CAP=$(( TTL_SECONDS * 2 ))
        if [ "$BORN_AGE" -ge "$HARD_CAP" ]; then
          RISK_GATE_CATEGORY="expired"
          RISK_GATE_REASON="Risk score expired (${BORN_AGE}s total since scoring, hard cap ${HARD_CAP}s). Delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') to rescore."
          return 1
        fi
      fi
      touch "$SCORE_FILE"
    fi
  fi
  # No hash file = backward compat, skip drift check and Band B slide

  # 4. Read and validate score
  local SCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo "")
  if ! echo "$SCORE" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
    RISK_GATE_CATEGORY="invalid"
    RISK_GATE_REASON="Risk score file contains an invalid value. Re-run the risk-scorer agent."
    return 1
  fi

  # 5. Threshold check — block when the score EXCEEDS the project's
  #    RISK-POLICY.md risk appetite (P007 / ADR-065). The threshold is the
  #    adopter's documented appetite, not a code constant: a project whose
  #    policy sets a higher appetite (e.g. "exceeds 9") must not have its
  #    within-appetite changes gate-rejected.
  #    Precedence: RISK_APPETITE env override > RISK-POLICY.md § Risk Appetite
  #    parse > default 4. Default 4 reproduces the prior hardcoded `score >= 5`
  #    behaviour exactly for integer scores (5 blocks, 4 passes) when the
  #    policy is absent or unparseable. The parse is tolerant of the phrasings
  #    "Threshold: N", "exceeds N", and "N/Low appetite", scoped to the
  #    "## Risk Appetite" section. Cost ~3-8ms/invocation (ADR-065 § Consequences).
  local DECISION
  DECISION=$(RISK_SCORE_VAL="$SCORE" RISK_APPETITE_ENV="${RISK_APPETITE:-}" python3 -c "
import os, re, sys
try:
    score = float(os.environ['RISK_SCORE_VAL'])
except Exception:
    print('no 4'); sys.exit(0)
N = None
override = os.environ.get('RISK_APPETITE_ENV', '').strip()
if override.isdigit():
    N = int(override)
else:
    try:
        text = open('RISK-POLICY.md', encoding='utf-8').read()
    except Exception:
        text = ''
    if text:
        # Scope to the '## Risk Appetite' section so unrelated numbers
        # elsewhere in the policy cannot match.
        sec = re.search(r'##\s*Risk Appetite\s*(.*?)(?=\n##\s|\Z)', text, re.DOTALL | re.IGNORECASE)
        scope = sec.group(1) if sec else text
        for pat in (r'Threshold:\s*(\d+)', r'exceeds\s+(\d+)', r'(\d+)\s*/\s*Low appetite'):
            m = re.search(pat, scope, re.IGNORECASE)
            if m:
                N = int(m.group(1)); break
if N is None:
    N = 4
print(('yes' if score > N else 'no') + ' ' + str(N))
" 2>/dev/null || echo "no 4")
  local DENIED="${DECISION%% *}"
  local APPETITE="${DECISION##* }"

  if [ "$DENIED" = "yes" ]; then
    RISK_GATE_CATEGORY="threshold"
    RISK_GATE_SCORE="$SCORE"
    RISK_GATE_REASON="${ACTION} risk score ${SCORE}/25 exceeds the project appetite of ${APPETITE}/25 (RISK-POLICY.md). To proceed: (1) split the ${ACTION}, (2) add risk-reducing measures, or (3) for a LIVE INCIDENT, delegate to wr-risk-scorer:pipeline (subagent_type: 'wr-risk-scorer:pipeline') with incident context for an incident bypass."
    return 1
  fi

  return 0
}

# Check CI health for the current branch (P208).
#
# Returns 0 if push/release may proceed, 1 if denied. Sets CI_GATE_REASON
# on deny with a human-readable message that names the CI conclusion and
# the run URL. Sets CI_GATE_CATEGORY ∈ {bypass, no-history, allow, red,
# pending, gh-error}.
#
# Consults `gh run list --branch <current-branch> --limit 1 --json
# status,conclusion,databaseId,url` for the working branch's most recent
# CI run.
#
# Decision table:
#   - bypass marker present (${RDIR}/ci-bypass-${ACTION}) → allow, consume
#   - gh failure (auth / timeout / API error) → DENY (fail-CLOSED, per
#     P208 safe-high-fix-risk classifier — a buggy harden must NOT
#     degrade to allow)
#   - empty result `[]` → allow (no CI history yet; first push triggers
#     CI naturally)
#   - status ∈ {queued, in_progress, pending, requested, waiting} → deny
#   - conclusion ∈ {failure, cancelled, timed_out, action_required,
#     startup_failure} → deny
#   - conclusion ∈ {success, skipped, neutral} or unknown → allow
#
# Usage: check_ci_status "$SESSION_ID" "push"   # or "release"
check_ci_status() {
  local SESSION_ID="$1"
  local ACTION="$2"
  local RDIR
  RDIR=$(_risk_dir "$SESSION_ID")
  local BYPASS_MARKER="${RDIR}/ci-bypass-${ACTION}"

  CI_GATE_REASON=""
  CI_GATE_CATEGORY=""

  # One-shot bypass marker — consumed on use, same family as
  # reducing-push / incident-release. Documented override for the
  # legitimate "first push triggers CI" edge case and infra incidents.
  if [ -f "$BYPASS_MARKER" ]; then
    rm -f "$BYPASS_MARKER"
    CI_GATE_CATEGORY="bypass"
    return 0
  fi

  # Resolve current branch. If we're not in a git repo or HEAD is
  # detached, skip the CI check (the surrounding push/release gate
  # would itself fail at the git layer with a clearer error).
  local BRANCH
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
    CI_GATE_CATEGORY="allow"
    return 0
  fi

  # Query GitHub. Bounded at 10s wall-clock so a network stall cannot
  # hang push:watch indefinitely. `command -v timeout` because macOS
  # default install does not ship GNU `timeout`.
  local JSON GH_EXIT
  if command -v timeout >/dev/null 2>&1; then
    JSON=$(timeout 10s gh run list --branch "$BRANCH" --limit 1 \
        --json status,conclusion,databaseId,url 2>/dev/null) || GH_EXIT=$?
  else
    JSON=$(gh run list --branch "$BRANCH" --limit 1 \
        --json status,conclusion,databaseId,url 2>/dev/null) || GH_EXIT=$?
  fi

  if [ -n "${GH_EXIT:-}" ] && [ "$GH_EXIT" != "0" ]; then
    CI_GATE_CATEGORY="gh-error"
    CI_GATE_REASON="CI status check failed (gh exit ${GH_EXIT}: auth / timeout / API error). Fail-closed per P208 safe-high-fix-risk. Fix the underlying gh failure, or to override for a legitimate first-push-triggers-CI run, create the bypass marker: touch ${BYPASS_MARKER}"
    return 1
  fi

  # Empty array = no CI history for this branch yet. Natural allow for
  # the documented "first push triggers CI" case — no marker needed.
  local TRIMMED
  TRIMMED=$(printf '%s' "$JSON" | tr -d '[:space:]')
  if [ -z "$TRIMMED" ] || [ "$TRIMMED" = "[]" ]; then
    CI_GATE_CATEGORY="no-history"
    return 0
  fi

  # Parse status, conclusion, url. Fail-closed on parse error.
  local PARSED
  PARSED=$(echo "$JSON" | python3 -c "
import sys, json
try:
    runs = json.load(sys.stdin)
    if not isinstance(runs, list) or not runs:
        print('||')
        sys.exit(0)
    r = runs[0]
    print('{}|{}|{}'.format(r.get('status') or '', r.get('conclusion') or '', r.get('url') or ''))
except Exception:
    print('PARSE_ERROR||')
" 2>/dev/null || echo "PARSE_ERROR||")

  local STATUS CONCLUSION URL
  STATUS="${PARSED%%|*}"
  local REST="${PARSED#*|}"
  CONCLUSION="${REST%%|*}"
  URL="${REST#*|}"

  if [ "$STATUS" = "PARSE_ERROR" ]; then
    CI_GATE_CATEGORY="gh-error"
    CI_GATE_REASON="CI status check returned unparseable response. Fail-closed per P208 safe-high-fix-risk. To override for a legitimate first-push case, create the bypass marker: touch ${BYPASS_MARKER}"
    return 1
  fi

  case "$STATUS" in
    queued|in_progress|pending|requested|waiting)
      CI_GATE_CATEGORY="pending"
      CI_GATE_REASON="Latest CI run on branch '${BRANCH}' is still in flight (status: ${STATUS}). Wait for it to settle: ${URL}. To override, create the bypass marker: touch ${BYPASS_MARKER}"
      return 1
      ;;
    completed)
      case "$CONCLUSION" in
        success|skipped|neutral|"")
          CI_GATE_CATEGORY="allow"
          return 0
          ;;
        failure|cancelled|timed_out|action_required|startup_failure)
          CI_GATE_CATEGORY="red"
          CI_GATE_REASON="Latest CI run on branch '${BRANCH}' concluded ${CONCLUSION}: ${URL}. Fix CI before pushing/releasing. To override for a legitimate first-push or infra-incident case, create the bypass marker: touch ${BYPASS_MARKER}"
          return 1
          ;;
        *)
          # Unknown conclusion — allow rather than block on a value we
          # don't recognise. New GitHub conclusion values are infrequent.
          CI_GATE_CATEGORY="allow"
          return 0
          ;;
      esac
      ;;
    *)
      # Unknown status — allow rather than block on a value we don't
      # recognise. Conservative tilts toward the threshold check below
      # catching the actual risk.
      CI_GATE_CATEGORY="allow"
      return 0
      ;;
  esac
}

# Emit fail-closed deny JSON for PreToolUse hooks.
risk_gate_deny() {
  local REASON="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$REASON"
  }
}
EOF
}
