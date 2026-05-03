#!/bin/bash
# wr-itil — SessionStart hook (P157, ADR-032 P157 amendment, ADR-040 precedent)
#
# Surfaces accumulated `outstanding_questions` entries from the AFK loop's
# session-level queue file at .afk-run-state/outstanding-questions.jsonl
# when the user starts a new interactive session. The queue is populated
# between iters by /wr-itil:work-problems Step 5 / Step 2.5 / Step 2.5b
# (P135 Phase 3 + ADR-044 6-class taxonomy schema).
#
# Without this hook, accumulated questions persist across session boundaries
# unread when an AFK loop halts before its Step 2.5 / Step 2.5b emit fires
# (manual stop, quota exhaustion, network failure). With this hook, the
# accumulated queue surfaces deterministically on session start; the agent
# fires AskUserQuestion in batches (<=4 per call per ADR-013 Rule 1) on the
# user's first interactive turn and rewrites the queue file to remove
# resolved entries.
#
# Wired from packages/itil/hooks/hooks.json SessionStart array with
# matcher "startup" (per ADR-040 Option A). Silent exit if queue is missing,
# empty, or whitespace-only per ADR-040 Mechanism step 1.
#
# AFK-iter cross-context-leak prevention (ADR-032 line 127): when invoked
# inside a /wr-itil:work-problems iter subprocess (which inherits the
# orchestrator's queue file), the orchestrator's Step 5 dispatch block sets
# WR_SUPPRESS_PENDING_QUESTIONS=1 before each `claude -p` spawn. The hook
# self-suppresses on that env var so the orchestrator-session queue does not
# surface inside iter subprocess contexts.

set -euo pipefail

# AFK-iter self-suppress — orchestrator sets this before spawning each
# `claude -p` subprocess so the session-level queue does not leak into iter
# subprocess contexts. Only literal "1" suppresses; any other value (including
# "0", unset, empty) lets the hook proceed.
if [ "${WR_SUPPRESS_PENDING_QUESTIONS:-}" = "1" ]; then
  exit 0
fi

QUEUE_FILE="${CLAUDE_PROJECT_DIR:-.}/.afk-run-state/outstanding-questions.jsonl"

# Silent-on-no-content per ADR-040 Mechanism step 1.
[ -f "$QUEUE_FILE" ] || exit 0
[ -s "$QUEUE_FILE" ] || exit 0

# ADR-044 6-class taxonomy precedence — lower rank value = higher priority.
# Strings match the JSONL schema in work-problems SKILL.md Step 5 verbatim.
rank_for_category() {
  case "$1" in
    deviation-approval)  echo 1 ;;
    direction)           echo 2 ;;
    one-time-override)   echo 3 ;;
    silent-framework)    echo 4 ;;
    taste)               echo 5 ;;
    correction-followup) echo 6 ;;
    *)                   echo 9 ;;
  esac
}

# Parse + dedupe + rank entries. Streams TSV with rank-prefix for sort.
# Tab-delimited columns: rank \t category \t ticket_id \t question_text
# (where question_text falls back to rationale for deviation-approval).
# Malformed JSON lines are silently skipped so a corrupted queue does not
# block session start.
ENTRIES_TSV=$(
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip blank / whitespace-only lines.
    [ -z "$(printf '%s' "$line" | tr -d '[:space:]')" ] && continue
    # Skip non-JSON lines silently.
    printf '%s' "$line" | jq -e . >/dev/null 2>&1 || continue
    cat="$(printf '%s' "$line" | jq -r '.category // "unknown"')"
    tid="$(printf '%s' "$line" | jq -r '.ticket_id // "—"')"
    # Question text: standard-shape entries use .question; deviation-approval
    # entries use .rationale (the load-bearing one-liner) since they have no
    # .question field per the schema.
    qtext="$(printf '%s' "$line" | jq -r '.question // .rationale // "(no question text)"')"
    rank=$(rank_for_category "$cat")
    printf '%s\t%s\t%s\t%s\n' "$rank" "$cat" "$tid" "$qtext"
  done < "$QUEUE_FILE" \
  | sort -u                       `# dedupe identical (rank+cat+tid+qtext)` \
  | sort -t $'\t' -k1,1n -s       `# stable sort by rank ascending`
)

# Empty after dedupe / parse-skip → silent exit.
[ -n "$ENTRIES_TSV" ] || exit 0

ENTRY_COUNT=$(printf '%s\n' "$ENTRIES_TSV" | wc -l | tr -d ' ')

# Emit additionalContext on stdout (ADR-040 plain-stdout shape per
# session-start-briefing.sh precedent).
{
  echo "PENDING QUESTIONS FROM PRIOR AFK LOOP — accumulated outstanding_questions"
  echo "queue (source: .afk-run-state/outstanding-questions.jsonl, ${ENTRY_COUNT} entries)."
  echo ""
  echo "These are direction / deviation-approval / one-time-override / silent-framework"
  echo "/ taste / correction-followup observations queued by /wr-itil:work-problems"
  echo "iters per ADR-044 6-class taxonomy. Surface them via AskUserQuestion batched"
  echo "<=4 per call (sequential when >4) on the user's first interactive turn,"
  echo "ranked deviation-approval > direction > one-time-override > silent-framework"
  echo "> taste > correction-followup. After resolving each entry, remove the"
  echo "matching line from the queue file by rewriting"
  echo ".afk-run-state/outstanding-questions.jsonl with the unresolved entries"
  echo "remaining. Empty queue → next session no-op."
  echo ""
  echo "| # | Category | Ticket | Question |"
  echo "|---|----------|--------|----------|"
  i=0
  while IFS=$'\t' read -r _rank cat tid qtext; do
    i=$((i + 1))
    # Truncate question text to keep table cells bounded; agent retrieves
    # full body from the queue file when constructing AskUserQuestion calls.
    short_q="$(printf '%s' "$qtext" | cut -c1-160)"
    [ "${#qtext}" -gt 160 ] && short_q="${short_q}..."
    # Escape pipe chars in cells so the table renders.
    short_q="${short_q//|/\\|}"
    printf '| %d | %s | %s | %s |\n' "$i" "$cat" "$tid" "$short_q"
  done <<< "$ENTRIES_TSV"
  echo ""
  if [ "$ENTRY_COUNT" -gt 4 ]; then
    echo "Note: ${ENTRY_COUNT} entries exceeds the AskUserQuestion <=4 per-call"
    echo "cap (ADR-013 Rule 1). Fire sequential calls — first 4 highest-ranked"
    echo "first, then the next batch, until the queue is drained."
  fi
} 2>/dev/null

exit 0
