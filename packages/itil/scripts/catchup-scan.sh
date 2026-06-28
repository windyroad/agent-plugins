#!/usr/bin/env bash
# packages/itil/scripts/catchup-scan.sh
#
# Phase 2 of P080 — `--catchup` migration-mode worklist scanner for
# `/wr-itil:update-upstream`. Walks the EXISTING `.verifying.md` +
# `.closed.md` ticket corpus, filters to tickets carrying a `## Reported
# Upstream` back-link section (written by `/wr-itil:report-upstream`
# Step 7), and emits a per-ticket worklist of upstream issues that still
# need a retroactive lifecycle-update comment.
#
# Read-only / local-only: this script makes NO `gh` calls and NO writes.
# It only reads local ticket files and prints a worklist to stdout. The
# actual `gh issue comment` / `gh issue close` posts — and the ADR-028
# external-comms + voice-tone gate composition that guards them — stay in
# the `/wr-itil:update-upstream` SKILL's per-ticket Step 4-6 loop, which
# consumes this worklist. Keeping the writes out of the scanner keeps it
# AFK-safe and behaviourally testable without a live upstream.
#
# Idempotency (P080 Phase 2 acceptance criterion 3): a ticket whose
# `## Upstream Lifecycle Updates` log already records an entry for the
# current target-state transition is reported as SKIP/already-logged, NOT
# re-posted. The marker-on-body log (append-only per the ADR-024 P080
# amendment) is the source of truth — re-running catchup is safe.
#
# Usage:
#   catchup-scan.sh
#     [--problems-dir <dir>]   default: docs/problems
#     [--ticket P<NNN>]        restrict the scan to one ticket
#
# Exit codes:
#   0 = success (zero or more worklist lines on stdout)
#   1 = error (problems-dir missing, malformed CLI args)
#
# Two surfaces are walked (P376 — cross-direction parity):
#   OUTBOUND — tickets with a `## Reported Upstream` section (issues WE filed
#     against an upstream we depend on).
#   INBOUND  — tickets with an `**Origin**: inbound-reported (#NN)` field
#     (ADR-076 — issues someone else filed *against us* on our own repo, which
#     the P363 rework made dispatchable). Without this leg the inbound catchup
#     candidates were a manual `grep -lE '^\*\*Origin\*\*:\s*inbound-reported'`
#     surface the maintainer had to remember after every `--catchup` run.
# A ticket carrying BOTH surfaces emits BOTH an outbound and an inbound line
# (the two legs are independent, mirroring the update-upstream SKILL).
#
# Structured stdout (one per actionable upstream entry; <= 150 bytes per
# line per ADR-038). ASCII `->` for the transition arrow per the P334
# awk/script portability lesson (no Unicode in machine-read output):
#   CATCHUP P<NNN> <url> state=<state> transition=<KE->Verifying|Verifying->Closed>
#   CATCHUP P<NNN> inbound-<ref> state=<state> transition=<…> direction=inbound
#   SKIP    P<NNN> <url> reason=already-logged
#   SKIP    P<NNN> inbound-<ref> reason=already-logged
#   SKIP    P<NNN> <url> reason=out-of-band
# Tickets with neither surface (and inbound tickets whose Origin ref carries no
# actionable `#NN`, e.g. `inbound-reported (relayed from other projects)`) are
# skipped silently — the common case.
#
# Trailing summary line (stderr) for the SKILL / human reader:
#   SUMMARY scanned=<N> catchup=<N> skip-logged=<N> skip-out-of-band=<N>
#
# @problem P080 — no bidirectional update of upstream-reported problems (Phase 2 --catchup)
# @adr ADR-024 (amended P080 Phase 2 — --catchup migration mode + idempotency contract)
# @adr ADR-014 (governance skills commit their own work)
# @adr ADR-038 (progressive disclosure — per-row byte budget)
# @adr ADR-049 (invoked via wr-itil-catchup-scan bin shim, never repo-relative path)
# @adr ADR-032 (foreground synchronous skill)
# @adr ADR-076 (reads the `**Origin**: inbound-reported (#NN)` field for the inbound leg)
# @problem P376 — catchup scanner misses the inbound direction (cross-direction parity)
# @rfc RFC-028 (consume the Origin field for inbound-reported verdict — extended to the catchup surface)
# @jtbd JTBD-301 (reporter feedback loop — the catchup's primary job)
# @jtbd JTBD-006 (AFK-safe worklist scanner)
# @jtbd JTBD-004 (cross-repo coordination — reconcile local corpus vs upstream trackers)
# @jtbd JTBD-001 (governance without slowing down — derive the worklist, no manual policing)
# @jtbd JTBD-201 (symmetric local/upstream audit trail)

set -uo pipefail

# ── Parse CLI args ──────────────────────────────────────────────────────────

PROBLEMS_DIR="docs/problems"
TICKET_FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --problems-dir) PROBLEMS_DIR="$2"; shift 2 ;;
    --ticket) TICKET_FILTER="$2"; shift 2 ;;
    -h|--help)
      sed -n '/^# Usage:/,/^# Exit codes:/p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -d "$PROBLEMS_DIR" ]; then
  echo "ERROR: problems-dir not found: $PROBLEMS_DIR" >&2
  exit 1
fi

# ── Discover the post-fix corpus (.verifying.md + .closed.md only) ──────────
#
# Catchup only covers tickets PAST the fix point — the lifecycle updates a
# reporter most wants (fix released / closed) are the ones the pre-Phase-1
# corpus is missing. Open / Known-Error / Parked tickets are out of scope
# for the migration (their transitions, if linked, fire the per-ticket
# path going forward). Dual-tolerant per RFC-002: flat layout
# `<NNN>-*.<status>.md` AND per-state subdir `<status>/<NNN>-*.md`.

shopt -s nullglob

declare -a TICKET_FILES
TICKET_FILES=()
for f in "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.verifying.md \
         "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.closed.md \
         "$PROBLEMS_DIR"/verifying/[0-9][0-9][0-9]-*.md \
         "$PROBLEMS_DIR"/closed/[0-9][0-9][0-9]-*.md ; do
  TICKET_FILES+=("$f")
done

# Extract the first `## Reported Upstream` URL from a ticket file.
extract_upstream_url() {
  awk '
    /^## Reported Upstream/ { in_section = 1; next }
    /^## / && in_section { in_section = 0 }
    in_section && /^- \*\*URL\*\*:/ {
      sub(/^- \*\*URL\*\*: */, "")
      sub(/[[:space:]].*$/, "")
      print
      exit
    }
  ' "$1"
}

# Extract the `## Reported Upstream` disclosure-path line (lower-cased).
extract_disclosure_path() {
  awk '
    /^## Reported Upstream/ { in_section = 1; next }
    /^## / && in_section { in_section = 0 }
    in_section && /^- \*\*Disclosure path\*\*:/ {
      sub(/^- \*\*Disclosure path\*\*: */, "")
      print
      exit
    }
  ' "$1" | tr "[:upper:]" "[:lower:]"
}

# Does the `## Upstream Lifecycle Updates` log already record the target
# transition? `needle` is the ASCII-or-Unicode transition suffix to match
# (e.g. "Verification Pending" target, or "Closed" target). The back-write
# format is `- **<date>** — <from> → <to>`, so we match the `<to>` token.
log_has_target() {
  local file="$1" target="$2"
  awk -v target="$target" '
    /^## Upstream Lifecycle Updates/ { in_section = 1; next }
    /^## / && in_section { in_section = 0 }
    in_section && index($0, target) > 0 { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

extract_ticket_id() {
  local base
  base="$(basename "$1")"
  echo "P${base%%-*}"
}

# Extract the actionable inbound issue ref from the `**Origin**:
# inbound-reported (<ref>)` field (ADR-076). Returns the `#NN` /
# `<repo>#NN` token, or empty when the Origin is not inbound-reported OR
# carries no actionable issue number (e.g. "relayed from other projects").
extract_inbound_ref() {
  local line ref
  line="$(grep -m1 -E '^\*\*Origin\*\*:[[:space:]]*inbound-reported' "$1" 2>/dev/null)"
  [ -z "$line" ] && return 0
  # First parenthesised group after `inbound-reported`.
  ref="$(printf '%s\n' "$line" | sed -n 's/.*inbound-reported[[:space:]]*(\([^)]*\)).*/\1/p')"
  [ -z "$ref" ] && return 0
  # Must contain an actionable `#NN` (optionally repo-qualified). Emit the
  # normalised `<repo>#<num>` token; drop trailing prose / spaces.
  printf '%s\n' "$ref" | grep -oE '[A-Za-z0-9._/-]*#[0-9]+' | head -1
}

# Does the `## Upstream Lifecycle Updates` log already record an
# `(inbound)`-tagged entry for the target transition? Distinct from
# log_has_target: the inbound leg's idempotency must NOT be satisfied by an
# outbound-tagged entry for the same target (a ticket reported BOTH ways may
# have posted its outbound verdict but not its inbound one).
log_has_inbound_target() {
  local file="$1" target="$2"
  awk -v target="$target" '
    /^## Upstream Lifecycle Updates/ { in_section = 1; next }
    /^## / && in_section { in_section = 0 }
    in_section && index($0, "(inbound)") > 0 && index($0, target) > 0 { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

# ── Per-ticket scan loop ────────────────────────────────────────────────────

SCANNED=0
CATCHUP_COUNT=0
SKIP_LOGGED=0
SKIP_OUT_OF_BAND=0

declare -A SEEN_IDS

for ticket_file in "${TICKET_FILES[@]}"; do
  ticket_id="$(extract_ticket_id "$ticket_file")"

  if [ -n "$TICKET_FILTER" ] && [ "$ticket_id" != "$TICKET_FILTER" ]; then
    continue
  fi

  # Dedup: if the same ID appears via both layouts (mid-migration), the
  # per-state subdir copy wins (same rule as check-upstream-responses.sh).
  if [ -n "${SEEN_IDS[$ticket_id]:-}" ]; then
    if [[ "$ticket_file" != *"/verifying/"* && "$ticket_file" != *"/closed/"* ]]; then
      continue
    fi
  fi
  SEEN_IDS[$ticket_id]="$ticket_file"

  # Detect both surfaces. Outbound = `## Reported Upstream` section;
  # inbound = an actionable `**Origin**: inbound-reported (#NN)` ref.
  has_outbound=0
  grep -q '^## Reported Upstream' "$ticket_file" && has_outbound=1
  inbound_ref="$(extract_inbound_ref "$ticket_file")"

  # Neither surface → silent skip (the common case).
  if [ "$has_outbound" -eq 0 ] && [ -z "$inbound_ref" ]; then
    continue
  fi

  SCANNED=$((SCANNED + 1))

  # Derive the transition the current suffix implies (direction-agnostic).
  case "$ticket_file" in
    *.verifying.md|*/verifying/*)
      state="verifying"
      transition="KE->Verifying"
      log_target="Verification Pending" ;;
    *.closed.md|*/closed/*)
      state="closed"
      transition="Verifying->Closed"
      log_target="Closed" ;;
    *)
      continue ;;
  esac

  # ── Outbound leg (`## Reported Upstream`) ──────────────────────────────────
  if [ "$has_outbound" -eq 1 ]; then
    upstream_url="$(extract_upstream_url "$ticket_file")"
    disclosure="$(extract_disclosure_path "$ticket_file")"

    if [ -z "$upstream_url" ] \
       || [[ "$disclosure" == *out-of-band* ]] \
       || [[ "$disclosure" == *mailbox* ]]; then
      # Out-of-band / non-gh disclosure path, or no actionable URL → SKIP.
      printf "SKIP    %s %s reason=out-of-band\n" "$ticket_id" "${upstream_url:-none}"
      SKIP_OUT_OF_BAND=$((SKIP_OUT_OF_BAND + 1))
    elif log_has_target "$ticket_file" "$log_target"; then
      # Idempotency: the lifecycle log already records this target → SKIP.
      printf "SKIP    %s %s reason=already-logged\n" "$ticket_id" "$upstream_url"
      SKIP_LOGGED=$((SKIP_LOGGED + 1))
    else
      printf "CATCHUP %s %s state=%s transition=%s\n" \
        "$ticket_id" "$upstream_url" "$state" "$transition"
      CATCHUP_COUNT=$((CATCHUP_COUNT + 1))
    fi
  fi

  # ── Inbound leg (`**Origin**: inbound-reported (#NN)`) ─────────────────────
  if [ -n "$inbound_ref" ]; then
    if log_has_inbound_target "$ticket_file" "$log_target"; then
      # Idempotency: an (inbound)-tagged log entry already records this target.
      printf "SKIP    %s inbound-%s reason=already-logged\n" "$ticket_id" "$inbound_ref"
      SKIP_LOGGED=$((SKIP_LOGGED + 1))
    else
      printf "CATCHUP %s inbound-%s state=%s transition=%s direction=inbound\n" \
        "$ticket_id" "$inbound_ref" "$state" "$transition"
      CATCHUP_COUNT=$((CATCHUP_COUNT + 1))
    fi
  fi
done

printf "SUMMARY scanned=%s catchup=%s skip-logged=%s skip-out-of-band=%s\n" \
  "$SCANNED" "$CATCHUP_COUNT" "$SKIP_LOGGED" "$SKIP_OUT_OF_BAND" >&2

exit 0
