#!/usr/bin/env bash
# packages/risk-scorer/scripts/evaluate-graduation.sh
#
# Evaluates held-changeset graduation candidates per ADR-061
# (Dogfood graduation criteria for held changesets — symmetric risk balance).
# Phase 2a: orthogonal-gate class only (Class 3a per ADR-061 Rule 3).
# Atomic-cohort class (3b) requires RFC ticket cohort enumeration and is
# deferred to Phase 2b per the architect-approved Phase 2a/2b split.
#
# This script implements the deterministic Rule 1a join + Rule 2 VP carve-out
# detection. It does NOT compute release-risk and does NOT apply Rule 4
# evidence-floor judgement — those are LLM-judgement surfaces owned by the
# wr-risk-scorer:pipeline agent (per ADR-015 pure-scorer contract).
#
# Usage:
#   evaluate-graduation.sh [<project-root>]
#
# Default <project-root> is $(pwd).
#
# Behaviour:
#   - Globs docs/changesets-holding/*.md (excludes README.md).
#   - For each held changeset, applies Rule 1a join:
#       1. Filename convention (primary): <package>-p<NNN>-<slug>.md → P<NNN>
#       2. Body grep fallback (secondary): grep '\bP[0-9]+\b' in changeset body
#       3. Multi-ticket: max(Priority) across the referenced set
#   - Resolves the ticket file via dual-tolerant glob (ADR-031 + RFC-002):
#       docs/problems/<NNN>-*.md (flat) AND docs/problems/*/<NNN>-*.md (per-state)
#   - Extracts the Priority value from the ticket's `**Priority**: N (...)` line.
#   - Detects Rule 2 VP carve-out (ticket file ends in .verifying.md).
#   - Emits one structured candidate line per held changeset to stdout.
#
# Stdout format (one candidate per held changeset, agent-parseable):
#   GRADUATION_CANDIDATE: changeset=<filename> | ticket=P<NNN> | priority=<N> | class=3a | status=<resolved|vp-blocked|halt-no-resolution>
#
# Stdout summary line at end:
#   GRADUATION_SUMMARY: total=<N> resolved=<N> vp_blocked=<N> halts=<N>
#
# Exit codes:
#   0 — script ran to completion (any number of halts is still exit 0;
#       halts surface via per-candidate status=halt-no-resolution lines so
#       the agent can present them as Rule 1a halt-and-prompt candidates)
#   1 — no holding-area or empty holding-area (no-op caller signal)
#   2 — invalid project root (missing docs/)
#
# @adr ADR-061 (graduation criteria — Phase 2a Rule 1a join + Rule 2 VP carve-out)
# @adr ADR-049 (resolved via bin/wr-risk-scorer-evaluate-graduation shim)
# @adr ADR-052 (behavioural-fixture coverage at scripts/test/evaluate-graduation.bats)
# @adr ADR-015 (pure-scorer contract — script does deterministic join only;
#               agent owns release-risk re-computation + evidence-floor judgement)
# @adr ADR-031 (dual-tolerant problem-ticket layout per RFC-002 migration window)
# @problem P162 (Phase 2a)

set -uo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
HOLDING_DIR="${PROJECT_ROOT}/docs/changesets-holding"
PROBLEMS_DIR="${PROJECT_ROOT}/docs/problems"

if [ ! -d "${PROJECT_ROOT}/docs" ]; then
  echo "GRADUATION_ERROR: invalid project root (missing docs/): ${PROJECT_ROOT}" >&2
  exit 2
fi

if [ ! -d "$HOLDING_DIR" ]; then
  echo "GRADUATION_SUMMARY: total=0 resolved=0 vp_blocked=0 halts=0"
  exit 1
fi

# Enumerate held changesets (exclude README.md). Use null-delim shape so
# filenames-with-spaces never break iteration (defensive even though our
# convention is kebab-case).
HELD_FILES=()
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  if [ "$base" = "README.md" ]; then
    continue
  fi
  HELD_FILES+=("$f")
done < <(find "$HOLDING_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)

if [ "${#HELD_FILES[@]}" -eq 0 ]; then
  echo "GRADUATION_SUMMARY: total=0 resolved=0 vp_blocked=0 halts=0"
  exit 1
fi

# Delegate the per-candidate join + VP-check to python for re-readable
# regex + dual-layout glob handling.
EVAL_RESULT=$(python3 - "$HOLDING_DIR" "$PROBLEMS_DIR" "${HELD_FILES[@]}" <<'PYEOF'
import os
import re
import sys
import glob

holding_dir = sys.argv[1]
problems_dir = sys.argv[2]
held_files = sys.argv[3:]

FILENAME_TICKET_RE = re.compile(r'-p(\d+)-', re.IGNORECASE)
BODY_TICKET_RE = re.compile(r'\bP(\d+)\b')
PRIORITY_LINE_RE = re.compile(r'^\*\*Priority\*\*:\s*(\d+)\b')


def find_ticket_file(ticket_id_padded: str):
    """Dual-tolerant glob per ADR-031 / RFC-002 migration window.

    Returns (path, status_suffix) where status_suffix is one of
    'open', 'known-error', 'verifying', 'closed', 'parked' or None
    if no file resolves.
    """
    # Per-state subdir layout
    for state in ('open', 'known-error', 'verifying', 'closed', 'parked'):
        candidates = glob.glob(os.path.join(problems_dir, state, f'{ticket_id_padded}-*.md'))
        if candidates:
            return candidates[0], state
    # Flat layout
    for state in ('open', 'known-error', 'verifying', 'closed', 'parked'):
        candidates = glob.glob(os.path.join(problems_dir, f'{ticket_id_padded}-*.{state}.md'))
        if candidates:
            return candidates[0], state
    return None, None


def extract_priority(ticket_path: str):
    """Read the `**Priority**: N (...)` line and return integer N, or None."""
    try:
        with open(ticket_path, 'r', encoding='utf-8') as f:
            for line in f:
                m = PRIORITY_LINE_RE.match(line.strip())
                if m:
                    return int(m.group(1))
    except (OSError, IOError):
        return None
    return None


def resolve_ticket_ids(changeset_path: str):
    """Apply Rule 1a join: filename convention primary, body-grep fallback.

    Returns a list of zero-padded ticket IDs (e.g. ['085']) referenced by
    this changeset. Empty list means halt-no-resolution per Rule 1a terminal.
    """
    basename = os.path.basename(changeset_path)
    # Primary: filename convention
    filename_match = FILENAME_TICKET_RE.search(basename)
    if filename_match:
        return [f'{int(filename_match.group(1)):03d}']

    # Fallback: body grep for P\d+ references
    try:
        with open(changeset_path, 'r', encoding='utf-8') as f:
            body = f.read()
    except (OSError, IOError):
        return []

    body_matches = BODY_TICKET_RE.findall(body)
    if not body_matches:
        return []

    # De-duplicate while preserving order; zero-pad
    seen = set()
    ids = []
    for raw_id in body_matches:
        padded = f'{int(raw_id):03d}'
        if padded not in seen:
            seen.add(padded)
            ids.append(padded)
    return ids


total = 0
resolved = 0
vp_blocked = 0
halts = 0

for changeset_path in held_files:
    total += 1
    basename = os.path.basename(changeset_path)
    ticket_ids = resolve_ticket_ids(changeset_path)

    if not ticket_ids:
        # Rule 1a terminal — halt-and-prompt
        print(f'GRADUATION_CANDIDATE: changeset={basename} | ticket=- | priority=- | class=3a | status=halt-no-resolution')
        halts += 1
        continue

    # Resolve each referenced ticket; collect (ticket_id, priority, status_suffix) triples
    resolutions = []
    unresolved_ids = []
    for tid in ticket_ids:
        path, suffix = find_ticket_file(tid)
        if path is None:
            unresolved_ids.append(tid)
            continue
        priority = extract_priority(path)
        if priority is None:
            unresolved_ids.append(tid)
            continue
        resolutions.append((tid, priority, suffix))

    if not resolutions:
        # All referenced tickets failed to resolve — halt
        print(f'GRADUATION_CANDIDATE: changeset={basename} | ticket={",".join(f"P{i}" for i in ticket_ids)} | priority=- | class=3a | status=halt-no-resolution')
        halts += 1
        continue

    # Rule 1a multi-ticket: max(Priority) across the referenced set
    # Pick the resolution with the highest priority; report its ticket ID.
    resolutions.sort(key=lambda r: r[1], reverse=True)
    chosen_tid, chosen_priority, chosen_suffix = resolutions[0]

    # Rule 2 VP carve-out
    if chosen_suffix == 'verifying':
        print(f'GRADUATION_CANDIDATE: changeset={basename} | ticket=P{chosen_tid} | priority={chosen_priority} | class=3a | status=vp-blocked')
        vp_blocked += 1
        continue

    print(f'GRADUATION_CANDIDATE: changeset={basename} | ticket=P{chosen_tid} | priority={chosen_priority} | class=3a | status=resolved')
    resolved += 1

print(f'GRADUATION_SUMMARY: total={total} resolved={resolved} vp_blocked={vp_blocked} halts={halts}')
PYEOF
)
PY_STATUS=$?

echo "$EVAL_RESULT"

if [ "$PY_STATUS" -ne 0 ]; then
  exit "$PY_STATUS"
fi

exit 0
