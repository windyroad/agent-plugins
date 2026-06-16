#!/bin/bash
# PreToolUse hook: gates outbound prose for evaluator review (P064 / P038 / ADR-028 amended 2026-05-14).
#
# This is the CANONICAL hook synced byte-identically into each consumer plugin
# (risk-scorer, voice-tone, …) via ADR-017 duplicate-script pattern. Each copy
# sources `${SCRIPT_DIR}/external-comms-evaluator.conf` to determine its
# evaluator identity (risk / voice-tone / …) — the .conf file is per-package
# and NOT synced.
#
# Surface (matched on Bash command text or Edit/Write file_path):
#   - gh issue create | comment | edit            (public issue bodies)
#   - gh pr   create | comment | edit             (public PR bodies)
#   - gh api .../security-advisories              (advisory drafts)
#   - gh api .../comments                         (any REST surface accepting prose)
#   - npm publish                                 (README / package metadata to npm)
#   - PreToolUse:Write|Edit on .changeset/*.md    (P073 — gates author-time)
#   - git commit -m / --message (incl. HEREDOC)   (P082 Phase 1 — commit message
#                                                  body reaches every reader of git
#                                                  log, PR commits tab, release-page
#                                                  auto-notes, CHANGELOG. Editor
#                                                  flow is out of scope per P082 SC1
#                                                  — message is written to
#                                                  .git/COMMIT_EDITMSG AFTER
#                                                  PreToolUse, nothing to read.)
#
# Gate behaviour:
#   1. BYPASS_RISK_GATE=1 short-circuits the gate (consistent with git-push-gate.sh).
#   2. POLICY_FILE absent → advisory-only mode (permits with systemMessage).
#   3. Hybrid leak-pattern pre-filter (lib/leak-detect.sh) hard-fails on
#      credentials, prod-URL prefixes, business-context-paired financial figures,
#      or business-context-paired user counts. Deny includes the matched class.
#      (Voice-tone evaluator: skips leak pre-filter — leak detection is the
#      risk evaluator's concern; voice-tone reviews tone/voice only.)
#   4. Otherwise: check for THIS evaluator's per-evaluator marker keyed on
#      compute_external_comms_key(draft, surface) =
#      sha256(normalize(draft, surface) + '\n' + surface) — the SINGLE
#      canonical key shared with the mark hook (lib/external-comms-key.sh).
#      For the changeset-author surface normalize() strips the leading YAML
#      frontmatter block so the gate (which sees the FULL Write content) and
#      the mark hook (which sees only the <draft> body) hash identical input
#      (P010 / ADR-028 amended 2026-05-25). Marker present → permit.
#      Marker absent → deny with directive to delegate to this plugin's
#      subagent (configured via external-comms-evaluator.conf).
#
# Marker location: ${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}/external-comms-<EVALUATOR_ID>-reviewed-<sha256>
# Marker writer:   PostToolUse:Agent hook in each consumer plugin
#                  (risk-score-mark.sh or external-comms-mark-reviewed.sh) on
#                  subagent type wr-<plugin>:external-comms. The mark hook
#                  derives the marker key from the agent's tool_input.prompt
#                  by parsing the same `SURFACE:` + `<draft>` structure the
#                  orchestrator was instructed to include (P166 / ADR-028
#                  amended 2026-05-16). Single fire per gate cycle suffices;
#                  the agent no longer needs to compute the key itself.
#
# Per-evaluator marker scheme (ADR-028 amended 2026-05-14): when both
# voice-tone and risk-scorer are installed, both gates fire on the same
# PreToolUse event; each gate denies until its own per-evaluator marker
# exists. Gates compose at firing level — no shared composite marker.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/leak-detect.sh
source "$SCRIPT_DIR/lib/leak-detect.sh"
# shellcheck source=lib/external-comms-key.sh
# Provides compute_external_comms_key — the SINGLE canonical marker-key
# normalization shared with the PostToolUse mark hook (ADR-028 amended
# 2026-05-25 / P010). Sourced via the same $SCRIPT_DIR/lib convention as
# leak-detect.sh so byte-identity holds across the synced per-package copies.
source "$SCRIPT_DIR/lib/external-comms-key.sh"

# ---------- Per-package evaluator config (ADR-028 amended 2026-05-14) ----------
# Each consumer plugin ships its own external-comms-evaluator.conf alongside this
# byte-identical canonical hook. The .conf defines:
#   EXTERNAL_COMMS_EVALUATOR_ID    — short id (risk, voice-tone)
#   EXTERNAL_COMMS_SUBAGENT_TYPE   — subagent to delegate to (wr-<plugin>:external-comms)
#   EXTERNAL_COMMS_VERDICT_PREFIX  — structured-output prefix the mark hook parses
#   EXTERNAL_COMMS_ASSESS_SKILL    — on-demand skill path for manual delegation
#   EXTERNAL_COMMS_POLICY_FILE     — policy doc whose absence triggers advisory-only
#   EXTERNAL_COMMS_LEAK_PREFILTER  — yes|no — whether to run leak-detect pre-filter
#   EXTERNAL_COMMS_SKIP_SURFACES   — space-separated surface list this evaluator's
#                                    policy disclaims; the marker-review delegation
#                                    silent-passes on those surfaces (P360). Default
#                                    empty (gate every detected surface).
# Fail-closed if absent: this hook cannot operate without a configured evaluator.
CONF_FILE="$SCRIPT_DIR/external-comms-evaluator.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "ERROR: external-comms-gate.sh requires $CONF_FILE (ADR-028 amended 2026-05-14)" >&2
    exit 0
fi
# shellcheck source=/dev/null
source "$CONF_FILE"
: "${EXTERNAL_COMMS_EVALUATOR_ID:?evaluator id missing from $CONF_FILE}"
: "${EXTERNAL_COMMS_SUBAGENT_TYPE:?subagent type missing from $CONF_FILE}"
: "${EXTERNAL_COMMS_ASSESS_SKILL:?assess-skill missing from $CONF_FILE}"
EXTERNAL_COMMS_POLICY_FILE="${EXTERNAL_COMMS_POLICY_FILE:-RISK-POLICY.md}"
EXTERNAL_COMMS_LEAK_PREFILTER="${EXTERNAL_COMMS_LEAK_PREFILTER:-yes}"
EXTERNAL_COMMS_SKIP_SURFACES="${EXTERNAL_COMMS_SKIP_SURFACES:-}"

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
        elif echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)\s*git commit(\s|$)'; then
            # P082 Phase 1: gate `git commit -m / --message / HEREDOC` so commit
            # message bodies are reviewed by the voice-tone + risk evaluators
            # before they land in git log / PR commits tab / release notes /
            # CHANGELOG. Editor flow (bare `git commit`) is out of scope per
            # P082 SC1 — git writes .git/COMMIT_EDITMSG AFTER PreToolUse fires,
            # so there's no body to extract at gate time. Skip silently when
            # neither -m nor --message is present.
            if echo "$COMMAND" | grep -qE '(\s|^)(-m|--message)(\s|=)'; then
                SURFACE="git-commit-message"
            else
                exit 0
            fi
        else
            exit 0
        fi

        # Best-effort body extraction. Order matters — most-specific first.
        #
        #   HEREDOC first: `git commit -m "$(cat <<'EOF'\n...\nEOF\n)"` is the
        #     AI-dominant form. Must precede --body "..." / -m "..." because
        #     those would otherwise match the literal `$(cat <<'EOF'...EOF)`
        #     text as the body, defeating the marker key match against the
        #     subagent's <draft> body.
        #   Then --body / --field for the gh + npm + security-advisories surfaces.
        #   Then -m / --message for git commit (single-line literal forms).
        #
        # When absent (npm publish, --body-file, editor flow already filtered),
        # DRAFT="" is acceptable: the agent will be invoked with command
        # context and read whatever body source the call uses.
        DRAFT=$(printf '%s' "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()
# P364: bash double-quote unescape. The double-quoted body capture groups
# carry RAW shell-escaped command text — an orchestrator must backslash-escape
# backticks (and \$, \", \\) inside \"...\" to survive bash parsing, e.g.
# --body \"Fixed in \\\`code\\\` ...\". The PostToolUse mark hook hashes the
# LOGICAL <draft> body (plain backticks), so the gate must undo those escapes
# or the two marker keys diverge → permanent deny-after-PASS. Inside double
# quotes a backslash is special ONLY before \$ \` \" \\ or a newline (line
# continuation); single-quoted and <<'EOF' forms are literal and need none.
# Single left-to-right pass so an escaped backslash adjacent to another escape
# (\\\\\` -> backslash + backtick) is NOT mis-collapsed. chr() literals keep
# this source free of the very metacharacters the surrounding shell double
# quotes would otherwise eat.
def unescape_dq(s):
    out = []
    i = 0
    n = len(s)
    special = set([chr(36), chr(96), chr(34), chr(92), chr(10)])
    while i < n:
        if s[i] == chr(92) and i + 1 < n and s[i + 1] in special:
            if s[i + 1] != chr(10):
                out.append(s[i + 1])
            i += 2
        else:
            out.append(s[i])
            i += 1
    return ''.join(out)
# (pattern, flags, unescape) — first match wins. unescape=True for the
# double-quoted forms only (P364).
patterns = [
    # HEREDOC body — matches a here-doc with EOF delimiter (quoted or
    # unquoted). The literal '<<' is written as the char-class pair
    # [<][<] so bash's command-substitution parser does NOT mis-parse
    # this regex as a real here-doc operator (P082 implementation note).
    # DOTALL so the body can span newlines. Left literal: the AI-canonical
    # form is the quoted <<'EOF' heredoc, whose body bash does not unescape.
    (r\"[<][<]\s*['\\\"]?EOF['\\\"]?\s*\n(.*?)\nEOF\", re.DOTALL, False),
    # gh issue/pr + npm publish --body 'TEXT' / --body \"TEXT\" (existing).
    (r\"--body[= ]'([^']*)'\", 0, False),
    (r'--body[= ]\"([^\"]*)\"', 0, True),
    # gh api --field summary='TEXT' / --field summary=\"TEXT\" (existing).
    (r\"--field [a-zA-Z_]+='([^']*)'\", 0, False),
    (r'--field [a-zA-Z_]+=\"([^\"]*)\"', 0, True),
    # git commit -m / --message single-line literal forms (P082 Phase 1).
    (r\"(?:-m|--message)[= ]'([^']*)'\", 0, False),
    (r'(?:-m|--message)[= ]\"([^\"]*)\"', 0, True),
]
for pat, flags, unescape in patterns:
    m = re.search(pat, cmd, flags)
    if m:
        body = m.group(1)
        if unescape:
            body = unescape_dq(body)
        print(body)
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
if [ ! -f "$EXTERNAL_COMMS_POLICY_FILE" ]; then
    permit_with_advisory "$EXTERNAL_COMMS_POLICY_FILE not found — $EXTERNAL_COMMS_SUBAGENT_TYPE gate is advisory-only on $SURFACE."
    exit 0
fi

# ---------- Hard-fail leak-pattern pre-filter (risk evaluator only) ----------
# Voice-tone evaluator skips this — leak detection is the risk evaluator's
# concern. Each per-package external-comms-evaluator.conf sets
# EXTERNAL_COMMS_LEAK_PREFILTER=yes (risk) or =no (voice-tone).
if [ "$EXTERNAL_COMMS_LEAK_PREFILTER" = "yes" ]; then
    if ! leak_detect_scan "$DRAFT"; then
        REASON=$(printf 'BLOCKED (external-comms gate / %s evaluator): %s on %s. Remove the leak before retrying. Override only if intentional (pre-session env): BYPASS_RISK_GATE=1.' \
            "$EXTERNAL_COMMS_EVALUATOR_ID" "$LEAK_DETECT_REASON" "$SURFACE")
        deny_with_reason "$REASON"
        exit 0
    fi
fi

# ---------- Per-evaluator surface skip (P360) ----------
# Some surfaces are explicitly disclaimed by THIS evaluator's policy doc, so the
# marker-review delegation below would be a guaranteed-PASS no-op (the subagent
# reads the policy, declares the surface out of scope, emits PASS — ~19K tokens
# per round-trip). EXTERNAL_COMMS_SKIP_SURFACES (per-package .conf) lists those
# surfaces; the gate silent-passes the prose-review delegation when the detected
# surface is on the list. Voice-tone sets this to `git-commit-message` because
# docs/VOICE-AND-TONE.md § Scope excludes commit messages ("covered by ADR-014 +
# ADR-018"); risk-scorer leaves it empty (its leak check on commit messages is
# meaningful). Placed AFTER the leak pre-filter so a skipped surface still gets
# credential/prod-URL scanning — this silences ONLY the prose-review deny, the
# same conservative shape as the P365 repo-visibility precondition below.
if [ -n "$EXTERNAL_COMMS_SKIP_SURFACES" ]; then
    case " $EXTERNAL_COMMS_SKIP_SURFACES " in
        *" $SURFACE "*)
            exit 0
            ;;
    esac
fi

# ---------- Repo-visibility precondition: git-commit-message surface (P365) ----------
# A commit message only becomes external-facing prose when it lands in a PUBLIC
# GitHub repo (git log / PR commits tab / release-page auto-notes / CHANGELOG).
# In private or internal repos the marker-review delegation deny below is a pure
# false-positive (P365 — user direction 2026-06-11: "this MUST NOT fire for
# private repos"). Confirm visibility authoritatively via gh and silent-pass the
# marker gate on any non-PUBLIC result. Any INDETERMINATE result (gh absent,
# unauthenticated, no remote, API error → empty $REPO_VISIBILITY) is treated as
# non-public: a commit message is only demonstrably external when the repo is
# confirmably PUBLIC, so the conservative direction for THIS surface is to not
# fire. This is a fail-open on the voice/tone-and-prose review ONLY — the
# leak-pattern pre-filter above (credentials / prod-URLs) has already run for
# every surface in every repo, so the high-stakes secrecy net is unaffected.
# Scoped to git-commit-message only; the gh-issue/pr/api, npm-publish, and
# changeset-author surfaces are inherently external and stay gated regardless.
if [ "$SURFACE" = "git-commit-message" ]; then
    REPO_VISIBILITY=$(gh repo view --json visibility -q .visibility 2>/dev/null || echo "")
    if [ "$REPO_VISIBILITY" != "PUBLIC" ]; then
        exit 0
    fi
fi

# ---------- Marker-based gate (per-evaluator marker per ADR-028 amended 2026-05-14) ----------
SESSION_DIR="${TMPDIR:-/tmp}/claude-risk-${SESSION_ID}"
mkdir -p "$SESSION_DIR"
# Canonical marker key — normalize() strips changeset frontmatter + trailing
# whitespace so this PreToolUse key matches the PostToolUse mark-hook key
# (compute_external_comms_key in lib/external-comms-key.sh; P010 / ADR-028
# amended 2026-05-25). For changeset-author $DRAFT is the FULL Write content
# (frontmatter + body); compute_external_comms_key strips the frontmatter.
KEY=$(compute_external_comms_key "$DRAFT" "$SURFACE")
MARKER="${SESSION_DIR}/external-comms-${EXTERNAL_COMMS_EVALUATOR_ID}-reviewed-${KEY}"

if [ -f "$MARKER" ]; then
    exit 0
fi

# Marker absent — deny + delegate.
# P166: instruct the orchestrator to structure the agent prompt with a
# leading `SURFACE: <name>` line and a `<draft>...</draft>` block so the
# PostToolUse mark hook can derive the canonical marker key locally
# (sha256(DRAFT + '\n' + SURFACE)). Single fire per gate cycle.
VERDICT_PREFIX="${EXTERNAL_COMMS_VERDICT_PREFIX:-EXTERNAL_COMMS_${EXTERNAL_COMMS_EVALUATOR_ID^^}}"
REASON=$(printf 'BLOCKED (external-comms gate / %s evaluator): %s draft has not been reviewed by %s. Delegate to %s (subagent_type: '"'"'%s'"'"') with a prompt that starts with the line `SURFACE: %s` and wraps the draft body verbatim inside `<draft>...</draft>` markers (for the changeset-author surface the body is the changeset summary WITHOUT the leading `---` frontmatter block — the gate strips frontmatter before hashing the marker key). The PostToolUse hook derives the marker key from that structure and marks the draft reviewed when the subagent emits %s_VERDICT: PASS — single fire suffices. Use %s for an interactive walkthrough. Override only when intentional (pre-session env): BYPASS_RISK_GATE=1.' \
    "$EXTERNAL_COMMS_EVALUATOR_ID" "$SURFACE" "$EXTERNAL_COMMS_SUBAGENT_TYPE" "$EXTERNAL_COMMS_SUBAGENT_TYPE" "$EXTERNAL_COMMS_SUBAGENT_TYPE" "$SURFACE" "$VERDICT_PREFIX" "$EXTERNAL_COMMS_ASSESS_SKILL")
deny_with_reason "$REASON"
exit 0
