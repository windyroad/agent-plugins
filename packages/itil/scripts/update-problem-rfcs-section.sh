#!/usr/bin/env bash
# packages/itil/scripts/update-problem-rfcs-section.sh
#
# Idempotently refresh the auto-maintained `## RFCs` section on a
# problem ticket file based on which RFCs in <rfcs-dir> claim the
# ticket via their YAML frontmatter `problems:` list.
#
# Called inline by `/wr-itil:capture-rfc` Step 6 and `/wr-itil:manage-rfc`
# Step 7 (transitions) + Step 9 (review re-rank) so the cross-tier
# reverse-trace is current at every commit per ADR-014 single-commit
# grain. Closes ADR-060 Phase 1 item 10 + Confirmation criterion 3
# (skill-side primary surface; architect Q1 + Q3 verdicts).
#
# Usage:
#   update-problem-rfcs-section.sh <problem-file> [<rfcs-dir>]
#
# Default <rfcs-dir> is `docs/rfcs`.
#
# Lazy-empty discipline (per JTBD-101 atomic-fix-adopter friction
# guard + architect Q3 verdict): if zero RFCs trace this problem, the
# `## RFCs` section is REMOVED entirely. Atomic-fix tickets with no
# RFC trace stay free of empty-table noise.
#
# Idempotent: running over a current section is a no-op (no file diff).
#
# Section placement (per architect Q3 verdict):
#   - Before `## Fix Released` if present (closure section stays at tail
#     per ADR-022 trailing-audit-artefact convention).
#   - Else at EOF.
#
# Output:
#   - Rewrites the problem ticket in-place when the section needs an
#     update; otherwise leaves the file untouched.
#   - Emits exit 0 always (caller skills don't need defensive handling).
#
# @adr ADR-060 (Phase 1 item 10 + Confirmation criterion 3 — auto-
#   maintained reverse trace; architect Q3 — table format, lazy empty,
#   between `## Related` and `## Fix Released`)
# @adr ADR-014 (called by capture-rfc Step 6 + manage-rfc Step 7+9
#   to ride the same single-purpose commit)
# @adr ADR-022 (`## Fix Released` is the trailing closure section;
#   `## RFCs` precedes it)
# @adr ADR-052 (behavioural bats coverage in
#   packages/itil/scripts/test/update-problem-rfcs-section.bats)
# @problem P170

set -uo pipefail

PROBLEM_FILE="${1:?missing problem-file arg}"
RFCS_DIR="${2:-docs/rfcs}"

[ -f "$PROBLEM_FILE" ] || exit 0

PBASE="$(basename "$PROBLEM_FILE")"
PNUM="${PBASE%%-*}"
PID="P${PNUM}"

# ── Step 1: scan rfcs-dir for RFCs whose frontmatter claims PID ─────────────

ROWS_TMP=$(mktemp)
trap 'rm -f "$ROWS_TMP"' EXIT

shopt -s nullglob
for f in "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.md; do
  base="$(basename "$f")"
  num="${base#RFC-}"
  num="${num%%-*}"
  rfc_id="RFC-${num}"
  case "$base" in
    *.proposed.md)     ticket_status="proposed" ;;
    *.accepted.md)     ticket_status="accepted" ;;
    *.in-progress.md)  ticket_status="in-progress" ;;
    *.verifying.md)    ticket_status="verifying" ;;
    *.closed.md)       ticket_status="closed" ;;
    *)                 continue ;;
  esac

  # Parse frontmatter `problems: [P<NNN>, P<NNN>, ...]` (single-line form).
  raw=$(awk '/^problems:/ { print; exit }' "$f")
  inner=$(echo "$raw" | sed -E 's/^[[:space:]]*problems:[[:space:]]*\[//; s/\][[:space:]]*$//')

  claims=0
  while IFS= read -r tok; do
    tok=$(echo "$tok" | tr -d ' "'\''')
    [ "$tok" = "$PID" ] && { claims=1; break; }
  done <<< "$(echo "$inner" | tr ',' '\n')"

  [ "$claims" -eq 0 ] && continue

  # Extract title from `# RFC-<NNN>: <Title>` heading.
  title=$(awk -v rid="$rfc_id" 'BEGIN{prefix="^# " rid ": "} { if (match($0, prefix)) { print substr($0, RSTART + RLENGTH); exit } }' "$f")
  [ -z "$title" ] && title="(untitled)"

  printf '%s\t%s\t%s\n' "$rfc_id" "$ticket_status" "$title" >> "$ROWS_TMP"
done
shopt -u nullglob

SORTED_ROWS=$(sort -k1,1 "$ROWS_TMP" 2>/dev/null || true)
HAS_ROWS=0
[ -n "$SORTED_ROWS" ] && HAS_ROWS=1

# ── Step 2: rewrite problem file with idempotent section ────────────────────

TMPFILE=$(mktemp)
trap 'rm -f "$ROWS_TMP" "$TMPFILE"' EXIT

# Single-pass awk:
#   - drops any existing `## RFCs` section (header through line before
#     next `## ` header or EOF).
#   - splits the rest into PRE (lines before `## Fix Released`) and
#     POST (`## Fix Released` and after).
PRE_LINES=$(awk '
  BEGIN { skip=0; in_post=0 }
  /^## RFCs[[:space:]]*$/ { skip=1; next }
  /^## / && skip==1 { skip=0 }
  skip==1 { next }
  /^## Fix Released/ { in_post=1 }
  in_post==0 { print }
' "$PROBLEM_FILE")

POST_LINES=$(awk '
  BEGIN { skip=0; in_post=0 }
  /^## RFCs[[:space:]]*$/ { skip=1; next }
  /^## / && skip==1 { skip=0 }
  skip==1 { next }
  /^## Fix Released/ { in_post=1 }
  in_post==1 { print }
' "$PROBLEM_FILE")

# Trim trailing blank lines off PRE_LINES.
PRE_LINES=$(printf '%s\n' "$PRE_LINES" | awk '
  { lines[NR]=$0 }
  END {
    last=NR
    while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
    for (i=1; i<=last; i++) print lines[i]
  }
')

{
  printf '%s\n' "$PRE_LINES"
  if [ "$HAS_ROWS" -eq 1 ]; then
    printf '\n## RFCs\n\n'
    printf '| RFC | Status | Title |\n'
    printf '|-----|--------|-------|\n'
    while IFS=$'\t' read -r rid st ti; do
      [ -z "$rid" ] && continue
      printf '| %s | %s | %s |\n' "$rid" "$st" "$ti"
    done <<< "$SORTED_ROWS"
  fi
  if [ -n "$POST_LINES" ]; then
    printf '\n%s\n' "$POST_LINES"
  fi
} > "$TMPFILE"

# Idempotency: only replace when content changed.
if ! cmp -s "$PROBLEM_FILE" "$TMPFILE"; then
  mv "$TMPFILE" "$PROBLEM_FILE"
fi
exit 0
