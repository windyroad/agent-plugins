#!/bin/bash
# wr-itil — PostToolUse:Bash hook (P345/RFC-044/STORY-038). Detects the
# fix-without-paired-lifecycle-transition drift: a just-landed commit whose
# subject is fix-typed (`fix: ...` / `fix(<pkg>): ...`) and names P<NNN>
# ticket(s) that are still in `docs/problems/open/` — i.e. the commit claims
# to fix a ticket but carried no Open -> Known Error (or -> Verifying)
# transition in the same grain. The ticket then ages across release + CI
# verification until a catch-up cadence notices (P345; P334 witness chain).
#
# ADVISORY-ONLY per ADR-092: Open -> Known Error asserts a knowledge claim
# (root cause known + workaround documented) that a fix-titled commit does
# NOT establish, so this hook must never auto-fire the transition and never
# block the commit. The hook DETECTS and ADVISES; a skill
# (/wr-itil:transition-problem) — or the human — PERFORMS the transition
# (ADR-014 hook-detects-skill-commits grain). Sibling (copy-and-retarget) of
# itil-commit-trailer-transition-advisory.sh (P378): different signal —
# commit-title P<NNN> tokens vs Refs: trailers.
#
# Advisory-only (ADR-013 Rule 6 fail-open; ADR-045 ≤300-byte TOTAL emission
# even with multiple named tickets; exit 0 on every path).
# Bypass: BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1.
#
# @adr ADR-092 (advisory-only posture + binding rule) ADR-014 (hook detects,
#      skill commits) ADR-045 (budget) ADR-013 (Rule 6 fail-open) ADR-052 (bats)
# @problem P345  @rfc RFC-044  @story STORY-038

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh"

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_name',''))
except: print('')" 2>/dev/null || echo "")
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_input',{}).get('command',''))
except: print('')" 2>/dev/null || echo "")
command_invokes_git_commit "$COMMAND" || exit 0
[ "${BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY:-}" = "1" ] && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -d "./docs/problems/open" ] || exit 0

SUBJECT=$(git log -1 --format='%s' HEAD 2>/dev/null) || exit 0
case "$SUBJECT" in
  "fix: "*|"fix("*) ;;
  *) exit 0 ;;
esac

PIDS=$(printf '%s' "$SUBJECT" | grep -oE 'P[0-9]{3}' | sort -u || true)
[ -n "$PIDS" ] || exit 0

OPEN_IDS=""
OPEN_COUNT=0
while IFS= read -r pid; do
  [ -n "$pid" ] || continue
  num="${pid#P}"
  shopt -s nullglob; files=(./docs/problems/open/${num}-*.md); shopt -u nullglob
  if [ ${#files[@]} -gt 0 ]; then
    OPEN_COUNT=$((OPEN_COUNT + 1))
    # Cap the named IDs at 3 so TOTAL emission stays ≤300 bytes (ADR-045).
    if [ "$OPEN_COUNT" -le 3 ]; then
      OPEN_IDS="${OPEN_IDS:+$OPEN_IDS,}$pid"
    fi
  fi
done <<< "$PIDS"
[ "$OPEN_COUNT" -gt 0 ] || exit 0
[ "$OPEN_COUNT" -gt 3 ] && OPEN_IDS="${OPEN_IDS}+$((OPEN_COUNT - 3))"

echo "P345 ADVISORY: fix-titled commit names ${OPEN_IDS} still Open — no paired lifecycle transition landed. Transition it (/wr-itil:transition-problem <NNN> known-error) or document why not. Bypass: BYPASS_FIX_TITLE_LIFECYCLE_ADVISORY=1." >&2
exit 0
