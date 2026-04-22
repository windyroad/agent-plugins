#!/bin/bash
# wr-retrospective — SessionStart hook (P100 slice 2, ADR-040)
# Surfaces the "Critical Points" roll-up from docs/briefing/README.md at session start.
# Fires only on matcher="startup" per hooks.json; silent no-op if briefing tree is absent.

set -euo pipefail

BRIEFING_README="${CLAUDE_PROJECT_DIR:-.}/docs/briefing/README.md"

# No briefing tree yet (adopter hasn't run /wr-retrospective:run-retro) — silent exit.
[ -f "$BRIEFING_README" ] || exit 0

# Extract everything under "## Critical Points (Session-Start Surface)" up to (but not
# including) the next level-2 heading.
CRITICAL_POINTS=$(awk '
  /^## Critical Points \(Session-Start Surface\)/ { in_section=1; next }
  in_section && /^## / { exit }
  in_section { print }
' "$BRIEFING_README")

# Section missing (e.g. older briefing README format) — silent exit.
[ -n "$CRITICAL_POINTS" ] || exit 0

cat <<EOF
CROSS-SESSION BRIEFING — critical points (source: docs/briefing/README.md).
Read that file for the full topic index + per-topic files when context warrants.

$CRITICAL_POINTS
EOF
