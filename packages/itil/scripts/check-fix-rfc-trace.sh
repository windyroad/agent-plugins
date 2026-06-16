#!/usr/bin/env bash
# packages/itil/scripts/check-fix-rfc-trace.sh
#
# The load-bearing PREDICATE half of the fix-time RFC-trace gate
# (P314 Phase 2 / RFC-005 B3). Before fix work commences on a Known
# Error, ADR-072 requires an RFC tracing the problem; ADR-073 requires
# that a *missing* RFC be auto-created (never blocked), everywhere the
# gate fires (interactive /wr-itil:manage-problem AND AFK
# /wr-itil:work-problems).
#
# This script answers the deterministic question — "does any RFC trace
# this problem?" — and, when none does, emits an auto-create DIRECTIVE
# on stdout naming the canonical vehicle (/wr-itil:capture-rfc). It does
# NOT create the RFC itself: the create is skill-orchestrated through
# capture-rfc (the canonical ADR-070-compliant problem-traced-skeleton
# vehicle — already allocates the next RFC ID, refreshes the README, and
# carries no Considered-Options block), so the create logic is not
# duplicated here. Architect verdict 2026-06-16 (P314 iter 11): the
# detect-in-script / create-via-capture-rfc split is consistent with the
# ADR-060 I1 load-bearing-from-the-start standard (the sibling trace
# invariant enforces identically — deterministic detection in committed
# shell, create orchestrated through capture).
#
# Usage:
#   check-fix-rfc-trace.sh <problem-file> [<rfcs-dir>]
#
# Default <rfcs-dir> is `docs/rfcs`.
#
# The PID is derived from the problem filename: `<NNN>-<slug>.md`
# (under any docs/problems/<state>/ subdir) → `P<NNN>`.
#
# Behaviour (ADR-073 — auto-create-not-block; the gate NEVER blocks):
#   - An RFC traces the problem when its frontmatter `problems:` array
#     contains the exact PID (boundary-safe: P31 / P3140 do NOT match a
#     P314 query). → exit 0, EMPTY stdout (fix proceeds; no auto-create).
#   - No RFC traces the problem → exit 0, stdout carries the directive
#     `no-rfc-trace: P<NNN> — ...capture-rfc...ADR-073...` for the calling
#     skill to act on (auto-create then proceed). Exit stays 0: a missing
#     RFC is never a block (ADR-073).
#   - Missing problem file / no args → exit 2 (caller misuse), stderr usage.
#
# @adr ADR-072 (RFC required at the propose-fix step on a Known Error —
#   the gate placement this predicate serves)
# @adr ADR-073 (fix-time gate auto-creates a missing RFC, everywhere —
#   never blocks; hence exit 0 on the absent branch + a directive, not a
#   deny)
# @adr ADR-071 (every fix goes through an RFC — unconditional, no carve-out)
# @adr ADR-070 (the auto-created RFC is a problem-traced skeleton with no
#   independent decisions — guaranteed by routing the create through
#   capture-rfc rather than a second create surface)
# @adr ADR-060 (I1 load-bearing-from-the-start; I13 fix-proposal invariant)
# @adr ADR-049 (invoked via the wr-itil-check-fix-rfc-trace bin shim on
#   $PATH; never repo-relative from a SKILL)
# @adr ADR-052 (behavioural bats coverage in
#   packages/itil/scripts/test/check-fix-rfc-trace.bats)
# @problem P314

set -uo pipefail

PROBLEM_FILE="${1:-}"
RFCS_DIR="${2:-docs/rfcs}"

if [ -z "$PROBLEM_FILE" ]; then
  echo "usage: check-fix-rfc-trace.sh <problem-file> [<rfcs-dir>]" >&2
  exit 2
fi

if [ ! -f "$PROBLEM_FILE" ]; then
  echo "check-fix-rfc-trace.sh: problem file not found: $PROBLEM_FILE" >&2
  exit 2
fi

# ── Derive PID from the problem filename (`<NNN>-<slug>.md`). ────────────────
PBASE="$(basename "$PROBLEM_FILE")"
PNUM="${PBASE%%-*}"
if ! [[ "$PNUM" =~ ^[0-9]+$ ]]; then
  echo "check-fix-rfc-trace.sh: cannot derive PID from filename: $PBASE" >&2
  exit 2
fi
PID="P${PNUM}"

# ── Scan rfcs-dir for any RFC whose frontmatter `problems:` claims PID. ──────
# Mirrors the PID-boundary-safe parse in update-problem-rfcs-section.sh.
traced=0
if [ -d "$RFCS_DIR" ]; then
  shopt -s nullglob
  for f in "$RFCS_DIR"/RFC-[0-9][0-9][0-9]-*.md; do
    # Single-line frontmatter form: `problems: [P<NNN>, P<NNN>, ...]`.
    raw="$(awk '/^problems:/ { print; exit }' "$f")"
    [ -z "$raw" ] && continue
    inner="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]*problems:[[:space:]]*\[//; s/\][[:space:]]*$//')"
    while IFS= read -r tok; do
      tok="$(printf '%s' "$tok" | tr -d " \"'")"
      if [ "$tok" = "$PID" ]; then
        traced=1
        break
      fi
    done <<< "$(printf '%s' "$inner" | tr ',' '\n')"
    [ "$traced" -eq 1 ] && break
  done
  shopt -u nullglob
fi

if [ "$traced" -eq 1 ]; then
  # An RFC traces the problem — the fix proceeds; no auto-create needed.
  exit 0
fi

# No RFC traces the problem. Emit the auto-create directive (ADR-073) and
# exit 0 — a missing RFC is NEVER a block. The calling skill auto-creates a
# problem-traced skeleton via /wr-itil:capture-rfc, then proceeds with the fix.
printf 'no-rfc-trace: %s — auto-create a problem-traced RFC via /wr-itil:capture-rfc before fix work, then proceed (ADR-072 placement / ADR-073 auto-create-not-block)\n' "$PID"
exit 0
