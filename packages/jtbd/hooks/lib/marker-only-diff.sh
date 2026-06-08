#!/bin/bash
# Shared helper: detect "oversight-marker-only" frontmatter diffs.
#
# P301: ADR-066/068 oversight-marker writes to docs/decisions/ ADRs trip the
# full architect+JTBD edit gate each batch of an `/wr-architect:review-decisions`
# drain, producing 2-3 no-op-PASS review round-trips per batch. The marker
# add/update is the mechanical output of a decision the user already
# substance-confirmed via AskUserQuestion (ADR-066 contract); the gate has
# nothing substantive to assess.
#
# This helper exposes `is_marker_only_diff OLD NEW` returning 0 when every
# added/removed non-empty line matches one of the oversight-marker frontmatter
# patterns:
#
#   human-oversight:   confirmed | unconfirmed | rejected-pending-supersede
#   oversight-date:    <date>
#   decision-makers:   <name|email>
#   supersede-ticket:  <ticket>
#
# When the predicate fires PASS, the calling gate short-circuits to exit 0
# without requiring a fresh architect / JTBD review marker. The
# architect-oversight-marker-discipline.sh (and JTBD sibling) hooks remain
# active as the safety net: a marker-only diff that introduces
# `human-oversight: confirmed` still requires the per-ADR session evidence
# marker (P348 / ADR-066 amendment 2026-06-02).
#
# Conservative boundary: any non-empty line outside the marker grammar
# (frontmatter delimiters that shift position, status:/date: changes, body
# edits) fails the predicate. The exemption is exact so it cannot be used
# to slip decision-content edits past the gate.
#
# Fail-safe: if python3 is unavailable or the diff parse errors, the function
# returns 1 (NOT marker-only) and the gate proceeds with its normal review
# requirement.
#
# Sibling copy of packages/architect/hooks/lib/marker-only-diff.sh per the
# existing gate-helpers.sh duplicate-shared pattern (ADR-017). Keep in sync
# manually until a second call site justifies the cost of a sync script.

is_marker_only_diff() {
  local old="$1"
  local new="$2"

  command -v python3 >/dev/null 2>&1 || return 1

  OLD_CONTENT="$old" NEW_CONTENT="$new" python3 - <<'PYEOF'
import os, sys, re
try:
    import difflib
except Exception:
    sys.exit(1)

old = os.environ.get('OLD_CONTENT', '')
new = os.environ.get('NEW_CONTENT', '')

if old == new:
    sys.exit(0)

old_lines = old.splitlines()
new_lines = new.splitlines()

marker_pat = re.compile(
    r'^[ \t]*(human-oversight|oversight-date|decision-makers|supersede-ticket)[ \t]*:.*$'
)

def allowed(line: str) -> bool:
    s = line.strip()
    if s == '':
        return True
    if marker_pat.match(line):
        return True
    return False

sm = difflib.SequenceMatcher(a=old_lines, b=new_lines, autojunk=False)
for tag, i1, i2, j1, j2 in sm.get_opcodes():
    if tag == 'equal':
        continue
    for line in old_lines[i1:i2]:
        if not allowed(line):
            sys.exit(1)
    for line in new_lines[j1:j2]:
        if not allowed(line):
            sys.exit(1)

sys.exit(0)
PYEOF
}
