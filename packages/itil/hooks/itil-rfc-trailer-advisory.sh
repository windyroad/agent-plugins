#!/bin/bash
# P170: PostToolUse:Bash hook — detects `git commit` invocations whose
# HEAD commit message carries a `Refs: RFC-<NNN>` trailer (the
# commit-message RFC trailer convention introduced by ADR-060 Phase 1
# item 12 + finding 8). For each such trailer, the hook checks whether
# the driving problem ticket(s) `## RFCs` reverse-trace section lists
# the RFC; emits a stderr advisory when stale.
#
# This is the SECONDARY surface for the auto-maintained `## RFCs` section
# contract. The PRIMARY surface is skill-side inline refresh in
# `/wr-itil:capture-rfc` Step 6 + `/wr-itil:manage-rfc` Step 7+9 (architect
# Q1 verdict). The hook is the drift-detection backstop for ARBITRARY
# commits — `feat(...)` / `fix(...)` / `chore(...)` commits that carry
# `Refs: RFC-<NNN>` trailers but were authored OUTSIDE the RFC skills
# and therefore did not run the inline refresh.
#
# Advisory-only per architect Q2 verdict + ADR-014 single-commit grain:
# the hook NEVER auto-fixes (no follow-up commit; no working-tree edit
# after the commit lands). It emits a stderr advisory pointing the
# user at `/wr-itil:manage-rfc <RFC-NNN>` to refresh the reverse-trace
# in a subsequent commit, OR at `wr-itil-reconcile-rfcs docs/rfcs
# docs/problems` to verify drift in batch.
#
# Allow paths (silent-on-pass per ADR-045 Pattern 1):
#   - tool_name != "Bash"           (only Bash invocations gated)
#   - command lacks `git commit`     (non-commit Bash bypasses)
#   - BYPASS_RFC_TRAILER_ADVISORY=1  (env-var escape)
#   - outside git work tree
#   - no `./docs/rfcs/`              (RFC framework not adopted)
#   - no `./docs/problems/`          (problem framework not adopted)
#   - HEAD commit lacks Refs: RFC trailer
#   - all referenced RFCs' driving problems' `## RFCs` tables are current
#
# Multi-`Refs:` malformed-per-finding-8 advisory: when HEAD's commit
# message carries multiple `Refs: RFC-<NNN>` trailer lines, the hook
# emits a malformed-per-finding-8 advisory directing the user to split
# the commit (one commit advances at most one RFC per ADR-060 finding
# 8). The split itself is user-side work; the hook flags only.
#
# Failmode (per ADR-013 Rule 6 fail-open): on parse error in the
# trailer, on a Refs: trailer pointing to a non-existent RFC file
# (could be a capture-rfc invocation in flight), on `git interpret-trailers`
# failure — exit 0 silently. The reconcile-rfcs.sh batch surface
# catches these cases at the next manage-rfc Step 0 preflight per
# Confirmation criterion 3.
#
# Cost: one git invocation per `git commit` Bash call (~30-60ms). No
# marker (per-invocation deterministic; mirrors P125 staging-detect.sh
# and P141 itil-changeset-discipline.sh precedent).
#
# Command-shape detection delegates to
# `lib/command-detect.sh::command_invokes_git_commit`, which strips
# common prefix shapes (leading whitespace, env-var assignments,
# `cd <path> &&`) and checks whether the residual leading token pair
# is literally `git commit`. P274: replaced the prior substring match
# `*"git commit"*` that misfired on non-commit Bash whose argument
# vectors merely mentioned the phrase (grep / sed / cat-heredoc /
# echo / `git log --grep`).
#
# References:
#   ADR-005 — plugin testing strategy (hook bats live under hooks/test/).
#   ADR-013 Rule 6 — fail-open on missing inputs / parse errors.
#   ADR-014 — single-commit grain (this hook never auto-fixes via
#             follow-up commit; advisory-only).
#   ADR-017 — shared-code sync pattern (command-detect.sh canonical at
#             packages/shared/hooks/lib/).
#   ADR-038 — progressive disclosure / advisory band ≤300 bytes.
#   ADR-045 — hook injection budget; Pattern 1 silent-on-pass.
#   ADR-051 — load-bearing-from-the-start (drift detection ships at
#             the same time as the convention; never deferred).
#   ADR-052 — behavioural-tests default; bats live alongside.
#   ADR-060 — Phase 1 item 12 + Confirmation criterion 3.
#   P170    — driving problem ticket.
#   P081    — behavioural tests preferred over structural greps.
#   P125    — sibling per-invocation no-marker hook precedent.
#   P141    — sibling commit-time gate hook precedent.
#   P268    — shared `command_invokes_git_commit` helper.
#   P274    — sibling-hook refactor: substring-match → helper here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only fire on Bash.
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only fire on actual `git commit` invocations. P274: delegates to the
# shared `command_invokes_git_commit` helper for leading-executable
# semantics (was substring match prone to grep/sed/echo false positives).
command_invokes_git_commit "$COMMAND" || exit 0

# Bypass via env var.
if [ "${BYPASS_RFC_TRAILER_ADVISORY:-}" = "1" ]; then
  exit 0
fi

# Fail-open if not in a git work tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Fail-open if RFC / problem framework not adopted.
[ -d "./docs/rfcs" ] || exit 0
[ -d "./docs/problems" ] || exit 0

# Read HEAD commit message.
COMMIT_MSG=$(git log -1 --format='%B' HEAD 2>/dev/null) || exit 0
[ -n "$COMMIT_MSG" ] || exit 0

# Parse `Refs:` trailers via git's native parser. The `key=Refs` filter
# extracts every Refs: line; we then keep only those naming RFC-<NNN>.
TRAILERS=$(printf '%s\n' "$COMMIT_MSG" | git interpret-trailers --parse 2>/dev/null \
  | grep -E '^Refs:[[:space:]]+RFC-[0-9]{3}' || true)

# No RFC trailer → silent.
[ -n "$TRAILERS" ] || exit 0

# Multi-Refs: malformed-per-finding-8 advisory.
TRAILER_COUNT=$(printf '%s\n' "$TRAILERS" | wc -l | tr -d ' ')
if [ "$TRAILER_COUNT" -gt 1 ]; then
  echo "P170 ADVISORY: HEAD commit carries ${TRAILER_COUNT} Refs: RFC trailers (malformed-per-finding-8 — one commit advances at most one RFC per ADR-060). Recovery: split the commit; rerun /wr-itil:manage-rfc on each RFC. Bypass: BYPASS_RFC_TRAILER_ADVISORY=1." >&2
  exit 0
fi

# Single trailer — extract RFC ID.
RFC_ID=$(printf '%s' "$TRAILERS" | grep -oE 'RFC-[0-9]{3}' | head -1)
[ -n "$RFC_ID" ] || exit 0
RFC_NUM="${RFC_ID#RFC-}"

# Locate the RFC file (any status suffix).
shopt -s nullglob
RFC_FILES=(./docs/rfcs/RFC-${RFC_NUM}-*.md)
shopt -u nullglob
if [ ${#RFC_FILES[@]} -eq 0 ]; then
  # RFC file not yet on disk (capture-rfc may be in flight). Fail-open.
  exit 0
fi
RFC_FILE="${RFC_FILES[0]}"

# Parse RFC frontmatter `problems: [P<NNN>, P<NNN>, ...]`.
RAW_PROBLEMS=$(awk '/^problems:/ { print; exit }' "$RFC_FILE")
INNER=$(echo "$RAW_PROBLEMS" | sed -E 's/^[[:space:]]*problems:[[:space:]]*\[//; s/\][[:space:]]*$//')

# Tokenise.
PIDS=()
while IFS= read -r tok; do
  tok=$(echo "$tok" | tr -d ' "'\''')
  case "$tok" in
    P[0-9][0-9][0-9]) PIDS+=("$tok") ;;
  esac
done <<< "$(echo "$INNER" | tr ',' '\n')"

# No claims → fail-open (RFC has no problem trace; trailer hook can't
# verify anything).
if [ ${#PIDS[@]} -eq 0 ]; then
  exit 0
fi

# For each PID, check whether the problem's `## RFCs` table lists RFC_ID.
STALE_PIDS=""
for pid in "${PIDS[@]}"; do
  pnum="${pid#P}"
  shopt -s nullglob
  PFILES=(./docs/problems/${pnum}-*.md)
  shopt -u nullglob
  if [ ${#PFILES[@]} -eq 0 ]; then
    # Problem file missing — fail-open (could be a stale frontmatter
    # claim or a problem in flight).
    continue
  fi
  pfile="${PFILES[0]}"

  # Locate `## RFCs` section.
  sec_start=$(awk '/^## RFCs[[:space:]]*$/ { print NR; exit }' "$pfile")
  if [ -z "$sec_start" ]; then
    STALE_PIDS="${STALE_PIDS:+$STALE_PIDS,}$pid"
    continue
  fi

  # Check if the section lists RFC_ID.
  if ! awk -v start="$sec_start" -v rid="$RFC_ID" '
    NR > start && /^## / { exit }
    NR > start && index($0, rid) > 0 { print "found"; exit }
  ' "$pfile" | grep -q found; then
    STALE_PIDS="${STALE_PIDS:+$STALE_PIDS,}$pid"
  fi
done

# No drift → silent.
[ -n "$STALE_PIDS" ] || exit 0

# Emit advisory (per ADR-045 ≤300 byte band; stderr; exit 0).
echo "P170 ADVISORY: HEAD commit ${RFC_ID} trailer; problem(s) ${STALE_PIDS} ## RFCs section stale (skill-side refresh missed). Recovery: /wr-itil:manage-rfc ${RFC_ID} OR wr-itil-reconcile-rfcs docs/rfcs docs/problems. Bypass: BYPASS_RFC_TRAILER_ADVISORY=1." >&2
exit 0
