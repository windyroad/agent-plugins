#!/usr/bin/env bash
# packages/itil/scripts/check-fix-rfc-trace.sh
#
# The load-bearing PREDICATE half of the fix-time trace gate. Before fix work
# commences on a Known Error, the framework requires a fix vehicle that traces
# the problem. This script answers the deterministic question — "does anything
# propose a fix for this problem?" — and, when nothing does, emits a directive
# on stdout telling the calling skill what to do about it.
#
# A FIX PROPOSAL IS A RELEASE ROW ON A STORY MAP, NEVER A DOCUMENT. This
# predicate used to scan the RFC document directory alone, and its directive
# told the caller to create a new document — the artefact the current decision
# retired. It now answers from the UNION of both tiers:
#
#   - a legacy RFC document whose frontmatter `problems:` array names the PID;
#   - a release row carrying an RFC identity whose cards' stories name the PID.
#
# The union is a strict widening: nothing that read as traced before reads as
# untraced now, so repointing the reader cannot hard-stop work that used to
# proceed. That is why the reader moves first, ahead of the writer.
#
# The row half resolves through the sibling story-map query, which owns the
# single oversight-hash definition — hence the .sh wrapper and not the .mjs
# behind it. It is captured into a variable, its stderr discarded and its exit
# status branched on, so it can only ever contribute a trace it actually found.
# It reads </dev/null so it cannot consume a caller's inherited stdin.
#
# FAILING CLOSED IS STRUCTURAL, NOT A CONVENTION. The query reports maps it
# could not read separately from rows it found, so "this map cannot answer" can
# never be mistaken for "no row proposes a fix". Drawing a second row over a map
# that already carries one would fragment the fix across two vehicles, which is
# the failure this gate exists to prevent.
#
# Usage:
#   check-fix-rfc-trace.sh <problem-file> [<rfcs-dir>] [<maps-dir>]
#
# Defaults are `docs/rfcs` and `docs/story-maps`.
#
# The PID is derived from the problem filename: `<NNN>-<slug>.md`
# (under any docs/problems/<state>/ subdir) → `P<NNN>`.
#
# Behaviour:
#   - Something proposes a fix → exit 0, EMPTY stdout. Work proceeds.
#   - Nothing proposes a fix, and a row can be drawn → exit 0, stdout carries a
#     directive naming the row to draw and the identity to give it. Exit 0
#     because the caller resolves this itself, with no person involved: drawing
#     a row on a map a person already approved inherits that approval. The work
#     still does not begin until the row exists — that halt lives in the calling
#     skill, which is where the drawing happens.
#   - A map could not be read → exit 3, directive naming the maps and asking for
#     a re-render. MECHANICAL, no person: a renderer clears this condition, so
#     the caller re-renders and asks again, and escalates only if a clean
#     re-render still reports it.
#   - The repository holds no story maps at all → exit 3, directive naming the
#     one thing a person has to do — draw the first map for this journey, which
#     is new substance nothing may mint on their behalf. The caller records that
#     single item and moves to the next problem; it does not stop.
#   - Missing problem file / no args → exit 2 (caller misuse), stderr usage.
#
# Exit 3 is a refusal the caller can act on without reading prose, and is
# distinct from caller-misuse 2.
#
# @adr ADR-119 (a fix proposal draws a release row, never a document; the reader
#   is repointed ahead of the writer and fails closed during the window)
# @adr ADR-103 (a release row is the RFC; the map is the approval surface, and
#   a proposal needing a new map queues for a person)
# @adr ADR-071 (every fix goes through an RFC — unconditional, no carve-out)
# @adr ADR-060 (I1 load-bearing-from-the-start; I13 fix-proposal invariant)
# @adr ADR-049 (invoked via the wr-itil-check-fix-rfc-trace bin shim on
#   $PATH; never repo-relative from a SKILL)
# @adr ADR-052 (behavioural bats coverage in
#   packages/itil/scripts/test/check-fix-rfc-trace.bats)
# @problem P314
# @problem P508

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

PROBLEM_FILE="${1:-}"
RFCS_DIR="${2:-docs/rfcs}"
MAPS_DIR="${3:-docs/story-maps}"

if [ -z "$PROBLEM_FILE" ]; then
  echo "usage: check-fix-rfc-trace.sh <problem-file> [<rfcs-dir>] [<maps-dir>]" >&2
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

# ── Tier 1: a legacy RFC document whose `problems:` array claims PID. ────────
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

# ── Tier 2: a release row proposing a fix for PID. ──────────────────────────
# Any failure here leaves `traced` and `stale_maps` untouched, so the row half
# can only ever add a trace, never assert one it did not find.
stale_maps=""
map_count=0
if [ -d "$MAPS_DIR" ]; then
  shopt -s nullglob
  maps=("$MAPS_DIR"/*.html "$MAPS_DIR"/*/*.html)
  shopt -u nullglob
  map_count="${#maps[@]}"
fi

if [ "$map_count" -gt 0 ]; then
  if rows_json="$("$HERE/story-map-query.sh" find-problem "$PID" --maps-dir "$MAPS_DIR" 2>/dev/null </dev/null)"; then
    # Parsed by the same runtime that produced it. A shell-side JSON parse would
    # be a second, worse reader of a format this repo already owns one of.
    if summary="$(printf '%s' "$rows_json" | node -e '
        let raw = "";
        process.stdin.on("data", (c) => { raw += c; });
        process.stdin.on("end", () => {
          const d = JSON.parse(raw);
          process.stdout.write(
            (d.hits || []).length + "\n" +
            (d.unanswerable || []).map((u) => u.path).join(" ") + "\n"
          );
        });
      ' 2>/dev/null)"; then
      [ "$(printf '%s' "$summary" | sed -n 1p)" -gt 0 ] 2>/dev/null && traced=1
      stale_maps="$(printf '%s' "$summary" | sed -n 2p)"
    fi
  fi
fi

if [ "$traced" -eq 1 ]; then
  # Something already proposes a fix for this problem — work proceeds.
  exit 0
fi

# ── Nothing proposes a fix. Which of the three refusals is it? ───────────────

if [ -n "${stale_maps// /}" ]; then
  printf 'no-rfc-trace: %s — these story maps were edited without being re-rendered, so they cannot say whether a row already proposes this fix: %s. Re-render them and ask again. Do not draw a row first: if one of them already carries it, a second row would split the fix across two vehicles. Nobody needs to be asked about this — re-rendering is mechanical.\n' \
    "$PID" "${stale_maps% }"
  exit 3
fi

if [ "$map_count" -eq 0 ]; then
  printf 'no-rfc-trace: %s — a fix is proposed as a release row on a story map, and this repository has no story maps yet. Drawing the first map for a journey decides what that journey is, so it needs a person and must not be created automatically. Record one item for the maintainer — draw a story map covering this work — and carry on to the next problem rather than stopping.\n' \
    "$PID"
  exit 3
fi

NEXT_ID="$("$HERE/next-rfc-id.sh" --rfcs-dir "$RFCS_DIR" --maps-dir "$MAPS_DIR" 2>/dev/null </dev/null || true)"
printf 'no-rfc-trace: %s — no release row proposes a fix for this problem. Draw one on a story map that already covers this journey, give it at least one story card, and make sure that card'"'"'s story file names %s in its own problems list — the link from a row to a problem is read through its cards, so a row without one will still read as untraced. Give the row the identity %s. Fix work does not begin until the row exists.\n' \
  "$PID" "$PID" "${NEXT_ID:-the next free RFC identity}"
exit 0
