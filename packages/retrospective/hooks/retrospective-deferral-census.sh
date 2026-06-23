#!/usr/bin/env bash
# wr-retrospective — SessionStart hook (ADR-040 class-B surface; P375)
#
# The "self-firing deferral census". Every session start, count deferred-work
# markers across docs/ + packages/ (.md only) that name a re-entry point nothing
# self-fires, and surface a bounded census so the parked work cannot silently
# rot (P375). Clones the class-B oversight-nudge shape (architect/jtbd nudges,
# ADR-040 session-start surface): silent-on-zero, fail-open, advisory stdout.
#
# .md-only scope is the code-comment false-positive guard — shipped-skill
# deferrals live in SKILL.md, not source comments. Marker vocabulary is the
# single source of truth in lib/deferral-markers.sh.
#
# AFK self-suppress: WR_SUPPRESS_DEFERRAL_CENSUS=1 (distinct from the interactive
# oversight nudges' WR_SUPPRESS_OVERSIGHT_NUDGE — the census is advisory-stdout-
# never-halts and is valuable under AFK, so the orchestrator suppresses it on a
# separate axis). Only the literal "1" suppresses.
#
# Fail-open: never aborts session startup (ADR-013 Rule 6). Missing dirs,
# unsourceable lib, or zero matches all exit 0 silently. ADR-040 Tier-1 budget
# (<=2KB) honoured by capping the worst-offender list at 5 rows.
#
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down) primary;
#       JTBD-006 (Progress the Backlog While I'm Away) secondary.

set -o pipefail

[ "${WR_SUPPRESS_DEFERRAL_CENSUS:-}" = "1" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Resolve the marker vocabulary (CLAUDE_PLUGIN_ROOT in installs; dirname fallback
# in the source monorepo / tests). Fail-open if neither resolves.
LIB="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/lib/deferral-markers.sh"
[ -r "$LIB" ] || LIB="$(dirname "$0")/lib/deferral-markers.sh"
# shellcheck source=/dev/null
. "$LIB" 2>/dev/null || exit 0
[ -n "${DEFERRAL_MARKER_RE:-}" ] || exit 0

# Scan .md files under docs/ and packages/ only.
SCAN_DIRS=""
[ -d "$PROJECT_DIR/docs" ] && SCAN_DIRS="$SCAN_DIRS $PROJECT_DIR/docs"
[ -d "$PROJECT_DIR/packages" ] && SCAN_DIRS="$SCAN_DIRS $PROJECT_DIR/packages"
[ -n "$SCAN_DIRS" ] || exit 0

# Per-file match-line counts; keep only files with >0 matches. grep no-match
# exits 1 → `|| true` keeps the hook fail-open.
# shellcheck disable=SC2086
COUNTS="$(grep -rIcE --include='*.md' --exclude='CHANGELOG.md' --exclude='*-history.md' "$DEFERRAL_MARKER_RE" $SCAN_DIRS 2>/dev/null | awk -F: '$NF>0' || true)"
[ -n "$COUNTS" ] || exit 0

TOTAL=$(printf '%s\n' "$COUNTS" | awk -F: '{s+=$NF} END{print s+0}')
FILES=$(printf '%s\n' "$COUNTS" | grep -c . 2>/dev/null || true)
[ "${TOTAL:-0}" -gt 0 ] 2>/dev/null || exit 0

# Top 5 worst offenders (bounds output to the ADR-040 Tier-1 budget).
TOP=$(printf '%s\n' "$COUNTS" | sort -t: -k2 -nr | head -5)

echo "[wr-retrospective] ${TOTAL} deferred-work marker(s) across ${FILES} file(s) name a re-entry point that nothing self-fires — they rot until someone runs a command (P375). Top offenders:"
while IFS=: read -r f c; do
  [ -n "$f" ] || continue
  rel="${f#"$PROJECT_DIR"/}"
  echo "  • ${rel}: ${c}"
done <<< "$TOP"
echo "  Drain: /wr-retrospective:run-retro, /wr-itil:review-problems, or work the backlog. Advisory only."

exit 0
