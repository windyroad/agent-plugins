#!/usr/bin/env bash
# wr-itil — write the RFC-tier create-gate marker (P119) under every candidate
# session SID (P260 / ADR-050 Option C). Adopter-safe sibling of
# wr-itil-mark-create-gate (P317 / RFC-009): resolves its libs relative to the
# script location, not cwd. SKILLs (capture-rfc / manage-rfc) invoke it by name
# via the `wr-itil-mark-rfc-capture-gate` PATH shim (ADR-049) before writing a
# docs/rfcs/RFC-*.proposed.md file.
#
# The RFC tier has no `_candidates` helper in create-gate.sh (only the single
# `mark_rfc_capture_complete`), so this script loops the candidate set itself —
# the RFC-tier analogue of `mark_step2_complete_candidates`.
set -uo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks/lib" 2>/dev/null && pwd)" || {
  echo "wr-itil-mark-rfc-capture-gate: cannot locate hooks/lib next to the script" >&2
  exit 2
}

# shellcheck source=/dev/null
source "$LIB/session-id.sh"
# shellcheck source=/dev/null
source "$LIB/create-gate.sh"

count=0
while IFS= read -r sid; do
  [ -n "$sid" ] || continue
  mark_rfc_capture_complete "$sid"
  count=$((count + 1))
done < <(get_candidate_session_ids)

# Fail-closed parity with mark_step2_complete_candidates: non-zero if no SID.
[ "$count" -gt 0 ]
