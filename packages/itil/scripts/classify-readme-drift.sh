#!/usr/bin/env bash
# packages/itil/scripts/classify-readme-drift.sh
#
# Classify reconcile-readme.sh exit-1 drift output as either
# inline-refresh-deferrable (covered by uncommitted ticket renames in the
# working tree — in-flow P094/P062 refresh will land the README correction
# in the upcoming commit per ADR-014) or halt-route-reconcile (committed
# cross-session drift — must route to /wr-itil:reconcile-readme).
#
# Usage:
#   classify-readme-drift.sh <drift-stdout-file> [<problems-dir>]
#
# <drift-stdout-file>: path to a file containing the captured stdout of
# `reconcile-readme.sh` (one structured drift line per row — `DRIFT`,
# `MISSING`, `STALE`, or `MISMATCH`).
#
# <problems-dir>: defaults to ./docs/problems. Used by `git status
# --porcelain` to scope the staged-rename probe.
#
# Output (stdout, single classification line):
#   INLINE_REFRESH covered=<N>            — every drift ID is the destination
#                                            of a staged rename in the working
#                                            tree; defer to in-flow P094/P062
#                                            refresh per ADR-014.
#   HALT_ROUTE_RECONCILE uncovered=<N>    — at least one drift ID is NOT
#                                            covered by a working-tree rename;
#                                            committed cross-session drift OR
#                                            mixed; route to
#                                            /wr-itil:reconcile-readme.
#
# Exit codes:
#   0 = INLINE_REFRESH
#   1 = HALT_ROUTE_RECONCILE
#   2 = parse error (drift-stdout-file missing or empty)
#
# @problem P149 — manage-problem Step 0 reconcile halt-on-drift directive
#                 doesn't distinguish uncommitted-rename-rooted drift from
#                 committed cross-session drift; this script is the
#                 detection mechanism that makes the carve-out behavioural.
# @adr ADR-014 (single-commit grain — the carve-out preserves it for the
#               in-flow path while keeping cross-session drift safety)
# @adr ADR-013 Rule 6 (AFK fail-safe — committed drift still routes to
#                       /wr-itil:reconcile-readme; only the inline path
#                       is added)
# @adr ADR-038 (progressive disclosure — output is a single terse line)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK loop continuity)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — single-commit grain)

set -uo pipefail

DRIFT_FILE="${1:-}"
PROBLEMS_DIR="${2:-docs/problems}"

if [ -z "$DRIFT_FILE" ]; then
  echo "USAGE: classify-readme-drift.sh <drift-stdout-file> [<problems-dir>]" >&2
  exit 2
fi

if [ ! -f "$DRIFT_FILE" ]; then
  echo "PARSE_ERROR: drift-stdout-file not found: $DRIFT_FILE" >&2
  exit 2
fi

# ── Extract drifting IDs from the script's structured output ────────────────
# Each line is one of:
#   DRIFT    P<NNN> wsjf-rankings: ...
#   MISSING  P<NNN> wsjf-rankings: ...
#   MISSING  P<NNN> verification-queue: ...
#   STALE    P<NNN> verification-queue: ...
#   MISMATCH P<NNN> closed: ...
DRIFT_IDS="$(grep -oE 'P[0-9]{3}' "$DRIFT_FILE" 2>/dev/null | sort -u)"

if [ -z "$DRIFT_IDS" ]; then
  echo "PARSE_ERROR: drift-stdout-file empty (no P<NNN> tokens): $DRIFT_FILE" >&2
  exit 2
fi

# ── Build set of IDs covered by staged renames in the working tree ──────────
# `git status --porcelain` v1 emits rename lines as:
#   R  <old-path> -> <new-path>
#   RM <old-path> -> <new-path>   (rename + unstaged modification)
# We match the destination path's ticket ID — the post-rename status is what
# the in-flow P094/P062 refresh will reconcile in the upcoming commit.
RENAMED_IDS=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  RENAMED_IDS="$(
    git status --porcelain "$PROBLEMS_DIR" 2>/dev/null \
      | awk '/^R/' \
      | sed 's|.*-> ||' \
      | sed "s|^${PROBLEMS_DIR}/||" \
      | grep -oE '^[0-9]{3}' \
      | awk '{ printf "P%s\n", $0 }' \
      | sort -u
  )"
fi

# ── Cross-reference each drift ID against the renamed set ───────────────────
COVERED=0
UNCOVERED=0
while IFS= read -r id; do
  [ -z "$id" ] && continue
  if [ -n "$RENAMED_IDS" ] && printf '%s\n' "$RENAMED_IDS" | grep -qx "$id"; then
    COVERED=$((COVERED + 1))
  else
    UNCOVERED=$((UNCOVERED + 1))
  fi
done <<< "$DRIFT_IDS"

if [ "$UNCOVERED" -gt 0 ]; then
  printf 'HALT_ROUTE_RECONCILE uncovered=%d\n' "$UNCOVERED"
  exit 1
fi

printf 'INLINE_REFRESH covered=%d\n' "$COVERED"
exit 0
