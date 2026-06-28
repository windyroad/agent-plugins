#!/bin/bash
# P375 — wr-itil PostToolUse:Write|Edit|MultiEdit hook.
#
# The ratified Option-C "authoring-time enforcement gate" (CORE SLICE,
# advisory rollout). P375's root cause: the repo conflates a "named
# re-entry point" (a /skill, a lifecycle transition, "next review") with
# a SELF-FIRING cadence. A deferral that names `/wr-itil:manage-rfc`
# rots because nothing self-fires manage-rfc on that artefact ("BUT
# NOTHING TRIGGERS THAT WORK!!!", 2026-06-23). The correct rot test: a
# deferral is legal only if its trigger chain is reachable from a
# SELF-FIRING event (a hook, SessionStart, PreToolUse/PostToolUse, a CI
# workflow, cron, or a work-problems pre-flight). ADR-084's SessionStart
# census (Option A) only SURFACES accumulated rot; this gate attacks the
# root cause — it fires at AUTHORING time, the moment a new uncadenced
# deferral is written.
#
# Detection (diff-aware — scans the NEWLY-authored text only, so
# descriptive prose already on disk never re-triggers):
#   1. tool_name is Write/Edit/MultiEdit AND file_path is a SHIPPED
#      authoring surface — SKILL.md, docs/decisions/*.md (ADRs),
#      docs/rfcs/*.md (RFCs), or a hook *.sh — and is NOT under
#      docs/problems/ (tickets descriptively narrate deferrals; highest
#      false-positive surface; already covered by the ADR-084 census).
#   2. The new text (Edit new_string / Write content / MultiEdit joined
#      new_strings) introduces a deferral phrasing (DEFER_RE).
#   3. Within the +/-5 line window of the match there is NO cadence
#      annotation naming a SELF-FIRING trigger (CADENCE_RE) — an explicit
#      `<!-- cadence: <trigger> -->` comment is the recommended carrier,
#      but a bare prose mention of a self-firing surface also satisfies.
#
# THE LOAD-BEARING P375 REFINEMENT vs the P234 sibling
# (itil-fictional-defer-detect.sh): a bare named on-demand skill
# (/wr-foo:bar) or a bare ticket ID (Pnnn / RFC-nnn / ADR-nnn) does NOT
# satisfy the cadence requirement — that bare-naming IS the conflation
# P375 names illegal. So CADENCE_RE deliberately OMITS skill-invocation
# and ticket-ID forms (which the P234 hook WRONGLY accepts).
#
# CORE-SLICE BOUNDARY (named loudly per the architect review): the gate
# checks the cadence names a self-firing CLASS — it does NOT validate
# that the named trigger actually EXISTS or fires on that artefact (the
# transitive-reachability graph is a DEFERRED later slice; <!-- cadence:
# retrospective-deferral-census.sh -->). Citing a plausible-but-fictional
# hook name passes this slice; the graph check closes that gap later.
#
# Advisory only — NEVER blocks (exit 0 always). Per ADR-040/045
# declarative-first + ADR-013 Rule 6 fail-open + the P375 architect
# review (advisory-first per ADR-057 staged rollout; escalation to a
# PreToolUse block is a queued user-owned rollout-mode decision once the
# advisory's false-positive rate is measured). AFK self-suppress:
# WR_SUPPRESS_DEFERRAL_CADENCE_GATE=1 (mirrors the census's
# WR_SUPPRESS_DEFERRAL_CENSUS — advisory, valuable, but an AFK loop
# authoring governance prose should be able to mute it).
#
# References:
#   P375     — driver (this gate is the Option-C root-cause fix).
#   P234     — the PostToolUse sibling (retro-only, accepts skills/IDs);
#              converging the two onto a shared vocabulary is a tracked
#              P375 follow-on, NOT done here (ADR-002/003 self-containment
#              — itil keeps its own copy of the deferral vocabulary).
#   ADR-084  — the surfacing-only census (Option A) this gate complements.
#   ADR-040  — declarative-first; advisory over hard block.
#   ADR-045  — hook injection budget; advisory ~600 bytes, ceiling 1000.
#   ADR-013  — Rule 6 fail-open on empty/malformed stdin.
#   ADR-052  — behavioural bats live alongside.
#   ADR-057  — staged advisory-first rollout for cluster-shaped rules.

# Self-suppress (AFK). Only the literal "1" suppresses.
[ "${WR_SUPPRESS_DEFERRAL_CADENCE_GATE:-}" = "1" ] && exit 0

# Per-surface configuration (copy-and-retarget extensible, like the
# P234 sibling: adjust the regex vars below).
DEFER_RE='deferred to|deferred pending|defer pending|pending review|re-rate at next|\(deferred|: deferred|deferred[ ]*[—.,;:-]|lands in [Ss]lice|future slice|flesh(ed)? out later|next review|when ready'
# Cadence-satisfying SELF-FIRING citations. NOTE the deliberate absence
# of skill-invocation (/wr-foo:bar) and ticket-ID (Pnnn/RFC-nnn/ADR-nnn)
# — those are the P375 conflation and do NOT satisfy the cadence.
HOOK_PATH_RE='[A-Za-z0-9_./-]+\.sh\b'
SESSIONSTART_RE='SessionStart'
TOOLUSE_RE='PreToolUse|PostToolUse'
CI_WORKFLOW_RE='\.github/workflows/'
CRON_RE='\bcron\b'
PREFLIGHT_RE='work-problems Step|pre-flight|Step 0[a-z]'

INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

[ -n "$FILE_PATH" ] || exit 0

# Scope: shipped authoring surfaces only; docs/problems/ excluded.
case "$FILE_PATH" in
  */docs/problems/*|docs/problems/*) exit 0 ;;
esac
if ! echo "$FILE_PATH" | grep -qE '(^|/)SKILL\.md$|/docs/decisions/.*\.md$|docs/decisions/.*\.md$|/docs/rfcs/.*\.md$|docs/rfcs/.*\.md$|\.sh$'; then
  exit 0
fi

# Extract the NEWLY-authored text (diff-aware). Write content; Edit
# new_string; MultiEdit joined new_strings.
NEW_TEXT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    ti = json.load(sys.stdin).get('tool_input', {})
    if 'content' in ti:
        print(ti.get('content', ''))
    elif 'new_string' in ti:
        print(ti.get('new_string', ''))
    elif 'edits' in ti:
        print('\n'.join(e.get('new_string', '') for e in ti.get('edits', [])))
    else:
        print('')
except Exception:
    print('')
" 2>/dev/null || echo "")

[ -n "$NEW_TEXT" ] || exit 0

# Buffer the new text so we can do the +/-5 line window check.
SCAN=$(mktemp 2>/dev/null) || exit 0
printf '%s\n' "$NEW_TEXT" > "$SCAN"
TOTAL_LINES=$(wc -l < "$SCAN" | tr -d ' ')

MATCHES=$(grep -inE "$DEFER_RE" "$SCAN" 2>/dev/null || true)
if [ -z "$MATCHES" ]; then
  rm -f "$SCAN"
  exit 0
fi

FICTIONAL_LINE=""
FICTIONAL_PHRASE=""

while IFS= read -r row; do
  [ -n "$row" ] || continue
  LN="${row%%:*}"
  text="${row#*:}"

  START=$((LN - 5)); [ "$START" -lt 1 ] && START=1
  END=$((LN + 5)); [ "$END" -gt "$TOTAL_LINES" ] && END="$TOTAL_LINES"
  WINDOW=$(sed -n "${START},${END}p" "$SCAN" 2>/dev/null || true)

  # Self-firing cadence citation present? → cadenced, skip.
  echo "$WINDOW" | grep -qE "$HOOK_PATH_RE"   && continue
  echo "$WINDOW" | grep -qE "$SESSIONSTART_RE" && continue
  echo "$WINDOW" | grep -qE "$TOOLUSE_RE"     && continue
  echo "$WINDOW" | grep -qE "$CI_WORKFLOW_RE" && continue
  echo "$WINDOW" | grep -qE "$CRON_RE"        && continue
  echo "$WINDOW" | grep -qE "$PREFLIGHT_RE"   && continue

  # No self-firing citation → uncadenced deferral. Record the first.
  FICTIONAL_LINE="$LN"
  FICTIONAL_PHRASE=$(echo "$text" | tr -s ' ' ' ' | sed 's/^[[:space:]]*//' | cut -c1-70)
  break
done <<< "$MATCHES"

rm -f "$SCAN"

[ -n "$FICTIONAL_LINE" ] || exit 0

# Advisory to stderr. ADR-045 budget (~600 bytes target). exit 0 always.
echo "P375 ADVISORY: uncadenced deferral authored in ${FILE_PATH} — \"${FICTIONAL_PHRASE}\". A named on-demand re-entry point (/wr-foo:bar, a lifecycle transition, \"next review\") is NOT a cadence — nothing self-fires it, so the work rots. Add a cadence annotation naming a SELF-FIRING trigger within +/-5 lines: <!-- cadence: <hook *.sh | SessionStart | PreToolUse/PostToolUse | .github/workflows/ | cron | work-problems pre-flight> --> OR do the work now. (Core slice checks the trigger CLASS, not that it exists.) See P375." >&2

exit 0
