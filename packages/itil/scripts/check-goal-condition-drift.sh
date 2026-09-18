#!/usr/bin/env bash
# wr-itil — assert every copy-paste /goal block embeds the canonical goal
# condition VERBATIM.
#
# Step 0e of /wr-itil:work-problems declares its canonical goal condition once,
# then repeats it inside copy-paste-ready blocks (a headless launch one-liner
# and an interactive block the user types). Those copies are prose, so they
# drift: before this check existed, the headless one-liner had silently lost
# two clauses from the canonical text — "(fresh open/known-error glob)
# classifying every ticket" and "naming the gate that could not complete" —
# which is how a drifted condition reaches a user as a copy-paste command.
#
# Contract:
#   - The canonical condition is the first fenced block after the line
#     carrying `<!-- CANONICAL-GOAL-CONDITION-SOURCE -->`.
#   - Every fenced block introduced by `<!-- CANONICAL-CONDITION-EMBED -->`
#     MUST contain that canonical text as a verbatim substring. An invocation
#     carrier is permitted only as a prefix or suffix around it.
#
# This is the CHECK-ONLY variant of the ADR-017 canonical-plus-check shape:
# there is no sync script, because a block carrying a prefix/suffix carrier
# cannot be mechanically regenerated from the canonical.
#
# Usage:
#   check-goal-condition-drift.sh [<skill-md-path>] [--check]
#     Default path: the work-problems SKILL.md, resolved relative to this
#     script so it works from any cwd (ADR-049 — never cwd-relative).
#     `--check` is accepted for symmetry with the sync-script family and is
#     a no-op; this script is always a check.
#
# Exit codes:
#   0 — every embed contains the canonical text verbatim.
#   1 — at least one embed diverged (or none were found).
#   2 — usage error, or the canonical block is missing/empty.
#
# @adr ADR-017 (canonical body + --check drift mode + CI step)
# @adr ADR-049 (plugin-bundled scripts resolve via bin/ on $PATH)
# @adr ADR-128 (per-ticket goal anchors each AFK iteration)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SKILL="$SCRIPT_DIR/../skills/work-problems/SKILL.md"

SKILL_MD=""
for arg in "$@"; do
  case "$arg" in
    --check) ;;
    -*) printf 'check-goal-condition-drift: unknown option %s\n' "$arg" >&2; exit 2 ;;
    *) SKILL_MD="$arg" ;;
  esac
done
[ -n "$SKILL_MD" ] || SKILL_MD="$DEFAULT_SKILL"

if [ ! -f "$SKILL_MD" ]; then
  printf 'check-goal-condition-drift: no such file: %s\n' "$SKILL_MD" >&2
  exit 2
fi

# Extract the fenced block that follows the first line carrying $1.
# Prints the block's contents (without the fence lines).
extract_block_after() {
  awk -v marker="$1" '
    index($0, marker) > 0 && !seen { seen = 1; next }
    seen && !infence && /^[[:space:]]*```/ { infence = 1; next }
    seen && infence && /^[[:space:]]*```/ { exit }
    seen && infence { print }
  ' "$2"
}

CANONICAL="$(extract_block_after 'CANONICAL-GOAL-CONDITION-SOURCE' "$SKILL_MD" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '\n')"

if [ -z "$CANONICAL" ]; then
  printf 'check-goal-condition-drift: canonical block missing or empty (marker: CANONICAL-GOAL-CONDITION-SOURCE) in %s\n' "$SKILL_MD" >&2
  exit 2
fi

# Collect every embed block. Each is the fenced block after an EMBED marker.
# The marker must be a STANDALONE comment line. Anchoring matters: the prose
# above the canonical block names the marker inline when explaining the check,
# and a substring match would count that mention as an embed — inflating the
# count and, worse, "verifying" a block that is not a copy-paste block at all.
EMBED_LINES="$(grep -nE '^[[:space:]]*<!--[[:space:]]*CANONICAL-CONDITION-EMBED[[:space:]]*-->[[:space:]]*$' "$SKILL_MD" | cut -d: -f1)"

if [ -z "$EMBED_LINES" ]; then
  printf 'check-goal-condition-drift: no CANONICAL-CONDITION-EMBED blocks found in %s\n' "$SKILL_MD" >&2
  printf '  The canonical condition is declared but never embedded — either the\n' >&2
  printf '  copy-paste blocks lost their markers, or the check is pointed at the\n' >&2
  printf '  wrong file. Failing rather than passing vacuously.\n' >&2
  exit 1
fi

FAILED=0
INDEX=0
while IFS= read -r lineno; do
  INDEX=$((INDEX + 1))
  BLOCK="$(tail -n "+${lineno}" "$SKILL_MD" | extract_block_after 'CANONICAL-CONDITION-EMBED' /dev/stdin | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '\n')"
  if [ -z "$BLOCK" ]; then
    printf 'DRIFT: embed #%d (line %s) has no fenced block after its marker\n' "$INDEX" "$lineno" >&2
    FAILED=1
    continue
  fi
  case "$BLOCK" in
    *"$CANONICAL"*) ;;
    *)
      printf 'DRIFT: embed #%d (line %s) does not contain the canonical condition verbatim\n' "$INDEX" "$lineno" >&2
      printf '  canonical: %s\n' "$CANONICAL" >&2
      printf '  embed:     %s\n' "$BLOCK" >&2
      FAILED=1
      ;;
  esac
done <<EOF
$EMBED_LINES
EOF

if [ "$FAILED" -ne 0 ]; then
  printf '\ncheck-goal-condition-drift: FAILED — repair the embed(s) to contain the canonical text verbatim.\n' >&2
  printf 'An invocation carrier is allowed only as a prefix or suffix around it.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Second coupling: the unattended-declaration discriminator.
#
# /wr-itil:work-problem's pinned short-circuit keys on a SENTENCE emitted by
# /wr-itil:work-problems Step 5 item 1. That is prose-to-prose coupling across
# two files with nothing binding them: reword either side and the short-circuit
# silently collapses to "never", which re-admits an unanswerable verification
# prompt and an off-grain ranking commit into an absent-user subprocess — the
# exact failure ADR-128 removed. The marked sentence must be identical on both
# sides.
# ---------------------------------------------------------------------------

SIBLING_SKILL="$(dirname "$SKILL_MD")/../work-problem/SKILL.md"

# Extract the bolded sentence immediately FOLLOWING marker $1 on its line in
# file $2. Anchoring on the marker is load-bearing: these marker lines carry
# several bold spans, and an unanchored greedy match silently returns whichever
# one happens to be last — which made this check compare two unrelated phrases
# and report drift on a correct tree.
extract_marked_sentence() {
  grep -F "$1" "$2" 2>/dev/null | head -1 \
    | sed -n "s/.*$1[^*]*\*\*\([^*]*\)\*\*.*/\1/p" \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

SOURCE_SENTENCE="$(extract_marked_sentence 'UNATTENDED-DECLARATION-SOURCE' "$SKILL_MD")"

if [ -z "$SOURCE_SENTENCE" ]; then
  printf 'DRIFT: no UNATTENDED-DECLARATION-SOURCE sentence found in %s\n' "$SKILL_MD" >&2
  printf '  The dispatch prompt must carry the bolded unattended declaration that\n' >&2
  printf '  the singular skill keys its pinned short-circuit on (ADR-128).\n' >&2
  exit 1
fi

if [ ! -f "$SIBLING_SKILL" ]; then
  # Guard the search root: a check over a missing file would assert nothing.
  printf 'check-goal-condition-drift: sibling skill not found: %s\n' "$SIBLING_SKILL" >&2
  exit 2
fi

CONSUMER_SENTENCE="$(extract_marked_sentence 'UNATTENDED-DECLARATION-CONSUMER' "$SIBLING_SKILL")"

if [ -z "$CONSUMER_SENTENCE" ]; then
  printf 'DRIFT: no UNATTENDED-DECLARATION-CONSUMER sentence found in %s\n' "$SIBLING_SKILL" >&2
  exit 1
fi

if [ "$SOURCE_SENTENCE" != "$CONSUMER_SENTENCE" ]; then
  printf 'DRIFT: the unattended declaration differs between the two skills\n' >&2
  printf '  dispatcher (%s): %s\n' "$(basename "$(dirname "$SKILL_MD")")" "$SOURCE_SENTENCE" >&2
  printf '  consumer   (%s): %s\n' "$(basename "$(dirname "$SIBLING_SKILL")")" "$CONSUMER_SENTENCE" >&2
  printf '  The short-circuit keys on this sentence; a mismatch collapses it to "never".\n' >&2
  exit 1
fi

printf 'check-goal-condition-drift: OK (%d embed(s) contain the canonical condition verbatim; unattended declaration matches across both skills)\n' "$INDEX"
exit 0
