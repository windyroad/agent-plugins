#!/usr/bin/env bash
# architect-compendium-refresh-discipline.sh — PreToolUse:Bash hook
# (safety net per ADR-077). Denies `git commit` invocations whose staged
# set includes a `docs/decisions/<NNN>-*.md` ADR change but does NOT also
# stage a refreshed `docs/decisions/README.md` compendium that matches
# the current ADR bodies.
#
# Per ADR-077: the architect agent and the architect skills
# (`/wr-architect:create-adr`, `/wr-architect:capture-adr`,
# `/wr-architect:review-decisions`) are the PRIMARY mechanism for keeping
# the compendium fresh — they invoke `wr-architect-generate-decisions-compendium`
# at the right point in their flows. This hook is the SAFETY NET: it
# catches edits that bypass those flows (hand-edits via Edit/Write tools,
# off-skill bulk renames, direct file modifications). Mirrors the
# P165 `itil-readme-refresh-discipline.sh` pattern at the decisions surface.
#
# Allow paths (exit 0 silently per ADR-045 Pattern 1):
#   - tool_name != "Bash"
#   - command's leading effective executable is not `git commit`
#   - `RISK_BYPASS: architect-compendium-deferred` token present in command
#     (intentional follow-up refresh; same allow-list shape as the P165 +
#     ADR-014 commit-message bypass-token pattern)
#   - staged set has no `docs/decisions/<NNN>-*.md` ADR change
#
# Deny paths (exit 2 with PreToolUse deny JSON on stderr):
#   - ADR staged but compendium not staged
#   - both staged but staged compendium does not match generator output
#     against current working-tree ADR bodies
#
# Recovery is mechanical per ADR-013 Rule 1:
#     wr-architect-generate-decisions-compendium && git add docs/decisions/README.md
#
# Override (legitimate intentional split):
#     append "RISK_BYPASS: architect-compendium-deferred" to the commit message
#
# Cross-ref: ADR-077 Confirmation item (h). See also packages/itil/hooks/itil-readme-refresh-discipline.sh
# for the P165 sibling pattern.

set -uo pipefail

# PreToolUse input arrives on stdin as JSON.
input=$(cat)

# Tool gate: only Bash.
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0

# Extract the command.
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -n "$command" ] || exit 0

# Only fire on `git commit` invocations. Leading-executable check (P268
# pattern): substring "git commit" anywhere can match unrelated commands
# (e.g. grep / sed / cat with that literal). We check the first effective
# token sequence: optional env-var assignments + optional `git`-aliasing
# wrappers (none in this codebase) + the literal `git commit`.
echo "$command" | awk '
    {
        # Strip leading whitespace and env assignments (FOO=bar).
        sub(/^[[:space:]]+/, "")
        while ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+/) {
            sub(/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+/, "")
        }
        # Match git followed by commit.
        if ($0 ~ /^git[[:space:]]+commit\b/) exit 0
        exit 1
    }
' || exit 0

# Allow-list bypass token. Same shape as P165 and ADR-014.
if echo "$command" | grep -qF 'RISK_BYPASS: architect-compendium-deferred'; then
    exit 0
fi

# Env-var bypass for batch/migration cases (parity with BYPASS_README_REFRESH_GATE).
if [ "${BYPASS_COMPENDIUM_REFRESH_GATE:-0}" = "1" ]; then
    exit 0
fi

# Resolve repo root so subsequent git plumbing is path-stable.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# Inspect the staged set.
staged_adrs=$(git diff --cached --name-only 2>/dev/null \
    | awk '/^docs\/decisions\/[0-9]+-.*\.md$/ { print }' \
    | head -20)
[ -n "$staged_adrs" ] || exit 0

staged_compendium=$(git diff --cached --name-only 2>/dev/null \
    | awk '/^docs\/decisions\/README\.md$/ { print }')

if [ -z "$staged_compendium" ]; then
    # ADR staged but compendium not staged. Deny.
    first_adr=$(echo "$staged_adrs" | head -1)
    cat >&2 <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "architect-compendium-refresh-discipline: '${first_adr}' is staged for commit but 'docs/decisions/README.md' is NOT. The compendium is the architect agent's routine load surface (ADR-077). Run: wr-architect-generate-decisions-compendium && git add docs/decisions/README.md. Intentional follow-up split: append 'RISK_BYPASS: architect-compendium-deferred' to the commit message. Batch/migration: set BYPASS_COMPENDIUM_REFRESH_GATE=1."}}
EOF
    exit 2
fi

# Both staged. Verify the staged compendium matches generator output for the
# current ADR bodies (working tree). The --check mode generates to temp, no
# mutation. Exit 0 => match; exit 1 => stale.
if ! wr-architect-generate-decisions-compendium --check >/dev/null 2>&1; then
    cat >&2 <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "architect-compendium-refresh-discipline: 'docs/decisions/README.md' is staged but does NOT match the current ADR bodies (stale compendium). Run: wr-architect-generate-decisions-compendium && git add docs/decisions/README.md to refresh, then re-commit. Intentional follow-up split: append 'RISK_BYPASS: architect-compendium-deferred' to the commit message."}}
EOF
    exit 2
fi

# All clear.
exit 0
