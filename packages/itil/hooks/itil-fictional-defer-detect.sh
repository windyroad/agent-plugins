#!/bin/bash
# P234 Phase 1 — wr-itil PostToolUse:Write|Edit hook.
#
# Detects "fictional defer" rationales in `docs/retros/*.md` writes —
# defer-rationale phrases (`next retro`, `next session`, `defer
# pending`, `defer with cause:`, `deferred per`) that lack a
# SCHEDULED-FUTURE-SURFACE citation in the surrounding +/-5-line
# window. The regression class P234 captures (2026-05-17 session 3
# retro: 3 MUST_SPLIT files deferred with "cascade case: archive-of-
# archive tier design needed" rationale; user correction "Don't defer"
# revealed the cascade was mechanical, not a design barrier).
#
# Detection signal (per ticket Investigation Task 2 two-axis test):
#   1. tool_name is Write OR Edit OR MultiEdit AND file_path matches
#      `docs/retros/*.md`.
#   2. Written file contains a defer-rationale phrase (case-insensitive).
#   3. Within +/-5 lines of the match there is NO citation of a
#      SCHEDULED-FUTURE-SURFACE — concretely any of:
#        * Ticket ID:  P\d{3} / STORY-\d{3} / R\d{3} / RFC-\d{3}
#        * Skill:      /wr-[a-z-]+:[a-z-]+
#        * Hook/script: \.sh\b (path component or filename)
#        * CI workflow: \.github/workflows/
#        * Dated ADR:  ADR-\d{3} + \d{4}-\d{2}-\d{2} both present
#   4. Match line is NOT on the exception allowlist
#      (e.g. `deferred per Branch B` — Branch B's next-retro
#      check-briefing-budgets.sh trigger IS the scheduled surface).
#
# When all four hold, the hook emits a stderr advisory citing P234 +
# the SCHEDULED-FUTURE-SURFACE definition + remediation pattern
# (cite a surface OR execute the deferred work now). The advisory
# names the file path, line number, and detected phrase so the next
# assistant turn has enough context to self-correct.
#
# Advisory only — NEVER blocks. Per ADR-013 Rule 6 fail-safe + ADR-045
# honour-system budget (target ~600 bytes; hard ceiling 1000). Mirrors
# the itil-rfc-trailer-advisory.sh PostToolUse precedent (stderr +
# exit 0) and the itil-mid-loop-ask-detect.sh per-surface configuration
# pattern (DEFER_RATIONALE_RE / SCHEDULED_FUTURE_SURFACE_RE /
# EXEMPT_PHRASES at the top so the hook is copy-and-retarget extensible).
#
# References:
#   P234     — this hook (Phase 1 structural enforcement).
#   P148     — Tickets Deferred section misuse; same class, different
#              surface (advisory script not hook).
#   P132     — over-ask class (inverse-correctness axis of P234 under-do);
#              Phase 2b hook itil-mid-loop-ask-detect.sh is the canonical
#              advisory-shape template.
#   ADR-013  — Rule 6 fail-open on missing inputs / parse errors.
#   ADR-014  — single-commit grain (this hook never auto-fixes).
#   ADR-040  — declarative-first; advisory-only over hard block.
#   ADR-044  — framework-resolution boundary; named in advisory.
#   ADR-045  — hook injection budget; honour-system <1000 hard ceiling.
#   ADR-052  — behavioural-tests default; bats live alongside.
#   ADR-057  — three-phase declarative-first cluster rollout
#              (Phase 2 advisory-second slot).

# Per-surface configuration. Extending coverage to other accumulator-
# doc surfaces (briefing topic files, decision logs, capture skill
# outputs) is a copy-and-retarget operation — adjust PATH_GLOB +
# the three regex vars below.
PATH_GLOB_RE='docs/retros/.*\.md$'
DEFER_RATIONALE_RE='next retro|next session|defer pending|deferred pending|defer with cause|deferred with cause|deferred per'
TICKET_ID_RE='\b(P[0-9]{3}|STORY-[0-9]{3}|R[0-9]{3}|RFC-[0-9]{3})\b'
SKILL_INVOCATION_RE='/wr-[a-z-]+:[a-z-]+'
HOOK_PATH_RE='[A-Za-z0-9_./-]+\.sh\b'
CI_WORKFLOW_RE='\.github/workflows/'
ADR_REF_RE='ADR-[0-9]{3}'
DATE_RE='[0-9]{4}-[0-9]{2}-[0-9]{2}'
EXEMPT_PHRASES_RE='deferred per Branch B'

INPUT=$(cat 2>/dev/null || true)

# Fail-open on empty/malformed stdin.
[ -n "$INPUT" ] || exit 0

# Parse tool_name + tool_input.file_path via python3 (sibling precedent
# itil-rfc-trailer-advisory.sh). Fail-open on parse error.
TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
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
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Short-circuit: no file_path → silent.
[ -n "$FILE_PATH" ] || exit 0

# Short-circuit: path doesn't match retro glob → silent.
if ! echo "$FILE_PATH" | grep -qE "$PATH_GLOB_RE"; then
  exit 0
fi

# Short-circuit: file doesn't exist on disk (could be a pre-PostToolUse
# Write that hasn't materialised yet, or a path the hook can't reach) →
# silent.
[ -f "$FILE_PATH" ] || exit 0

# Scan for defer-rationale matches. grep -nE produces `lineno:content`.
MATCHES=$(grep -inE "$DEFER_RATIONALE_RE" "$FILE_PATH" 2>/dev/null || true)
[ -n "$MATCHES" ] || exit 0

# For each match, check the +/-5 line window for a SCHEDULED-FUTURE-
# SURFACE citation. Accumulate fictional-defer findings; the first
# fictional finding triggers the advisory (one advisory per write,
# even if multiple defers fail — keeps the advisory dense).
TOTAL_LINES=$(wc -l < "$FILE_PATH" | tr -d ' ')

FICTIONAL_FOUND=""
FICTIONAL_LINE=""
FICTIONAL_PHRASE=""

while IFS= read -r match_row; do
  [ -n "$match_row" ] || continue
  LN="${match_row%%:*}"
  match_text="${match_row#*:}"

  # Skip exception-allowlisted phrases (e.g. `deferred per Branch B`).
  if echo "$match_text" | grep -qiE "$EXEMPT_PHRASES_RE"; then
    continue
  fi

  # Compute window [LN-5, LN+5] clamped to file bounds.
  START=$((LN - 5))
  [ "$START" -lt 1 ] && START=1
  END=$((LN + 5))
  [ "$END" -gt "$TOTAL_LINES" ] && END="$TOTAL_LINES"

  WINDOW=$(sed -n "${START},${END}p" "$FILE_PATH" 2>/dev/null || true)

  # Check for any SCHEDULED-FUTURE-SURFACE citation in the window.
  if echo "$WINDOW" | grep -qE "$TICKET_ID_RE"; then continue; fi
  if echo "$WINDOW" | grep -qE "$SKILL_INVOCATION_RE"; then continue; fi
  if echo "$WINDOW" | grep -qE "$HOOK_PATH_RE"; then continue; fi
  if echo "$WINDOW" | grep -qE "$CI_WORKFLOW_RE"; then continue; fi
  # Dated ADR requires BOTH an ADR-NNN ref AND a date in the window.
  if echo "$WINDOW" | grep -qE "$ADR_REF_RE" \
     && echo "$WINDOW" | grep -qE "$DATE_RE"; then
    continue
  fi

  # No surface citation found — this is a fictional defer. Record the
  # first one (advisory carries one example; remediation pattern
  # generalises).
  FICTIONAL_FOUND="yes"
  FICTIONAL_LINE="$LN"
  # Compact + truncate the matched phrase for the advisory body.
  FICTIONAL_PHRASE=$(echo "$match_text" | tr -s ' ' ' ' | sed 's/^[[:space:]]*//' | cut -c1-80)
  break
done <<< "$MATCHES"

# No fictional defers → silent.
[ -n "$FICTIONAL_FOUND" ] || exit 0

# Emit advisory to stderr (PostToolUse precedent matches
# itil-rfc-trailer-advisory.sh). Always exit 0 — advisory, never block.
# Voice-tone target ~600 bytes; ADR-045 honour-system ceiling <1000.
echo "P234 ADVISORY: fictional defer detected in ${FILE_PATH}:${FICTIONAL_LINE} — phrase: \"${FICTIONAL_PHRASE}\". No SCHEDULED-FUTURE-SURFACE cited within +/-5 lines. Per ADR-044 framework-resolution boundary, cite a concrete surface (ticket ID Pnnn, named skill /wr-foo:bar, hook path *.sh, CI workflow .github/workflows/, or dated ADR-nnn YYYY-MM-DD) OR execute the deferred work in this session. See P234." >&2

exit 0
