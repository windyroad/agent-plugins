#!/usr/bin/env bash
# architect-readme-pairing-check.sh — PreToolUse:Bash hook.
#
# ADR-078 Phase 1, Option 9. RFC-014 Story B. The structural replacement for
# the retired architect-compendium-refresh-discipline.sh: instead of comparing
# the staged compendium against PROGRAMMATIC generator output (which no longer
# holds under architect-authored entries), this hook asserts a simpler, robust
# invariant — every commit that stages a `docs/decisions/<NNN>-*.md` ADR body
# change MUST also stage `docs/decisions/README.md`.
#
# Under Option 9 the PostToolUse architect-compendium-update-entry.sh hook
# (Story A) re-authors + stages the README entry on every ADR body edit, so a
# commit that touches a body but NOT the README means Story A did not run (or
# ran in degraded mode after a subprocess failure). Denying surfaces that for
# manual recovery: re-run the edit (re-triggers Story A) or regenerate via
# `wr-architect-generate-decisions-compendium && git add docs/decisions/README.md`.
#
# Replaces ADR-077 Confirmation criterion (g) (the generator-output drift gate /
# bats test 2145). See ADR-078 § "Drift safety under Option 9".
#
# Allow paths (exit 0 silently per ADR-045 Pattern 1):
#   - tool_name != "Bash"
#   - command's leading effective executable is not `git commit`
#   - `RISK_BYPASS: architect-compendium-deferred` token present in command
#   - BYPASS_COMPENDIUM_REFRESH_GATE=1 (batch/migration parity)
#   - staged set has no `docs/decisions/<NNN>-*.md` ADR body change
#   - staged set already includes `docs/decisions/README.md`
#
# Deny path (exit 2 with PreToolUse deny JSON on stderr):
#   - ADR body staged but README not staged

set -uo pipefail

# PreToolUse input arrives on stdin as JSON.
input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0

command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -n "$command" ] || exit 0

# Only fire on `git commit` invocations. Leading-executable check (P268
# pattern): a bare substring match would catch unrelated commands that mention
# "git commit" (grep/sed/cat). Strip leading whitespace + env assignments, then
# require the first effective tokens to be `git commit`.
echo "$command" | awk '
    {
        sub(/^[[:space:]]+/, "")
        while ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+/) {
            sub(/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+/, "")
        }
        if ($0 ~ /^git[[:space:]]+commit([[:space:]]|$)/) exit 0
        exit 1
    }
' || exit 0

# Allow-list bypass token (parity with the retired refresh-discipline hook and
# ADR-014 commit-message bypass shape).
if echo "$command" | grep -qF 'RISK_BYPASS: architect-compendium-deferred'; then
    exit 0
fi

# Env-var bypass for batch/migration cases.
if [ "${BYPASS_COMPENDIUM_REFRESH_GATE:-0}" = "1" ]; then
    exit 0
fi

# Resolve repo root so the git plumbing is path-stable.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

# Inspect the staged set. ADR bodies are docs/decisions/<NNN>-*.md (exclude the
# README itself and the -history / -summary siblings).
staged_adrs=$(git diff --cached --name-only 2>/dev/null \
    | awk '/^docs\/decisions\/[0-9]+-.*\.md$/ { print }' \
    | head -20)
[ -n "$staged_adrs" ] || exit 0

staged_compendium=$(git diff --cached --name-only 2>/dev/null \
    | awk '/^docs\/decisions\/README\.md$/ { print }')

if [ -z "$staged_compendium" ]; then
    first_adr=$(echo "$staged_adrs" | head -1)
    cat >&2 <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "architect-readme-pairing-check: '${first_adr}' is staged for commit but 'docs/decisions/README.md' is NOT. Under ADR-078 Option 9 every ADR body change must be paired with its compendium entry refresh (the architect-compendium-update-entry PostToolUse hook does this automatically — if README is unstaged the hook did not run or hit degraded mode). Recover: re-run the ADR edit to re-trigger the hook, OR run 'wr-architect-generate-decisions-compendium && git add docs/decisions/README.md'. Intentional follow-up split: append 'RISK_BYPASS: architect-compendium-deferred' to the commit message. Batch/migration: set BYPASS_COMPENDIUM_REFRESH_GATE=1."}}
EOF
    exit 2
fi

# Both staged — pairing satisfied. (No generator-output comparison: the README
# is architect-authored under Option 9, not generator-derived.)
exit 0
