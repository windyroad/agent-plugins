#!/usr/bin/env bash
# wr-itil — per-ticket effort tally from AFK iteration cost metadata (ADR-067, P248)
#
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK actuals feed WSJF calibration + audit trail)
# @jtbd JTBD-202 (Run Pre-Flight Governance Checks — structured, auditable effort tally)
#
# Attributes `.afk-run-state/iter*.json` actuals back to their source ticket
# (the `pNNN` token in the filename) and emits the `## Effort Tally` schema. The
# reusable core shared by:
#   - the backfill (seed historical tickets — ADR-067 Decision Outcome item 4)
#   - go-forward per-iter append (work-problems — ADR-067 item 2)
#
# Authority hierarchy (P089 Gap 2 — load-bearing): `total_cost_usd` is the
# AUTHORITATIVE actual (session-cumulative by CLI contract; reliable token-spend
# proxy). `duration_ms` is reliable wall-clock. Raw `usage.*` token counts are
# BEST-EFFORT (undercount when a subprocess exits on a background-ack turn) and
# are emitted with a `~` best-effort marker.
#
# Modes:
#   effort-tally.sh [AFK_DIR]
#     Legacy list mode — one stdout line per ticket, sorted by descending cost:
#       P<NNN> | iters=<N> | cost_usd=<authoritative> | minutes=<reliable> | tokens=~<best-effort>M
#   effort-tally.sh --render [--source <afk-backfill|live-iter>] <ticket-file> [AFK_DIR]
#     Print the `## Effort Tally` markdown section for ONE ticket to stdout.
#   effort-tally.sh --write [--source <afk-backfill|live-iter>] <ticket-file> [AFK_DIR]
#     Idempotently inject/replace that section in the ticket file (lazy-empty:
#     zero iters → section removed). Mirrors update-problem-references-section.sh.
#
#   --source defaults to afk-backfill (ADR-067 item 2a — every row generated from
#   pre-existing .afk-run-state data is a historical backfill until a go-forward
#   per-iter append wires `--source live-iter`).
#
# Phase bucketing (ADR-067 item 2 — RCA vs RFC): derived from the ticket's
# **Status** body line — `Open` → RCA, anything else → RFC.
#   ponytail: single-phase attribution; a ticket that accrued iters while Open
#   then more while Known Error buckets ALL iters to its current phase. Named
#   upgrade path = per-iter git-log status discrimination (ADR-067 item 2 Phase
#   2 design). Correct for the common single-phase case; the ceiling travels in
#   the AUTO-GENERATED marker below.
#
# Always exits 0 (legacy + render); --write exits 0 on success.

set -euo pipefail

MODE="list"
SOURCE="afk-backfill"
TICKET_FILE=""

# Arg parse: flags in any order before positionals.
POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --render) MODE="render"; shift ;;
    --write)  MODE="write";  shift ;;
    --source) SOURCE="${2:-afk-backfill}"; shift 2 ;;
    *) POS+=("$1"); shift ;;
  esac
done

if [ "$MODE" = "list" ]; then
  AFK_DIR="${POS[0]:-.afk-run-state}"
else
  TICKET_FILE="${POS[0]:-}"
  AFK_DIR="${POS[1]:-.afk-run-state}"
  if [ -z "$TICKET_FILE" ] || [ ! -f "$TICKET_FILE" ]; then
    echo "ERROR: --$MODE needs an existing <ticket-file>" >&2
    exit 1
  fi
fi

# aggregate <afk-dir> [ticket-id]
# Emits the per-ticket tally lines (all tickets, or just the one when ticket-id
# is given). The single source of the iter-JSON aggregation logic.
aggregate() {
  local afk_dir="$1" only_tid="${2:-}"
  [ -d "$afk_dir" ] || return 0
  python3 - "$afk_dir" "$only_tid" <<'PY'
import json, glob, os, re, sys
from collections import defaultdict

afk_dir = sys.argv[1]
only_tid = sys.argv[2] if len(sys.argv) > 2 else ""

def cost_obj(d):
    """Return the dict carrying total_cost_usd, whether d is a dict or an event list."""
    if isinstance(d, dict):
        return d if d.get("total_cost_usd") is not None else None
    if isinstance(d, list):
        for item in reversed(d):
            if isinstance(item, dict) and item.get("total_cost_usd") is not None:
                return item
    return None

agg = defaultdict(lambda: {"cost": 0.0, "dur_ms": 0, "tokens": 0, "iters": 0})
for path in glob.glob(os.path.join(afk_dir, "*.json")):
    m = re.search(r'p(\d{3})', os.path.basename(path))
    if not m:
        continue
    tid = "P" + m.group(1)
    if only_tid and tid != only_tid:
        continue
    try:
        with open(path) as fh:
            d = json.load(fh)
    except Exception:
        continue
    o = cost_obj(d)
    if not o:
        continue
    a = agg[tid]
    a["cost"] += float(o.get("total_cost_usd") or 0)
    a["dur_ms"] += int(o.get("duration_ms") or 0)
    u = o.get("usage") or {}
    a["tokens"] += sum(int(u.get(k) or 0) for k in
                       ("input_tokens", "output_tokens",
                        "cache_creation_input_tokens", "cache_read_input_tokens"))
    a["iters"] += 1

for tid, a in sorted(agg.items(), key=lambda kv: kv[1]["cost"], reverse=True):
    print(f"{tid} | iters={a['iters']} | cost_usd={a['cost']:.2f} | "
          f"minutes={a['dur_ms']/60000:.1f} | tokens=~{a['tokens']/1e6:.1f}M")
PY
}

# --- legacy list mode -------------------------------------------------------
if [ "$MODE" = "list" ]; then
  aggregate "$AFK_DIR"
  exit 0
fi

# --- render / write modes ---------------------------------------------------

# Ticket id from filename (NNN-slug.md → PNNN).
tid_num="$(basename "$TICKET_FILE" | grep -oE '^[0-9]+' || true)"
if [ -z "$tid_num" ]; then
  echo "ERROR: cannot extract ticket ID from filename: $(basename "$TICKET_FILE")" >&2
  exit 1
fi
TID="P${tid_num}"

# Phase from the **Status** body line: Open → RCA, else → RFC (see header ceiling).
status_line="$(grep -m1 '^\*\*Status\*\*:' "$TICKET_FILE" | sed -E 's/^\*\*Status\*\*:[[:space:]]*//' || true)"
case "$status_line" in
  Open|open) PHASE="RCA" ;;
  *)         PHASE="RFC" ;;
esac

# Aggregate just this ticket.
line="$(aggregate "$AFK_DIR" "$TID")"

# Render the section (empty string ⇒ lazy-empty: no iters for this ticket).
new_section=""
if [ -n "$line" ]; then
  iters="$(echo "$line"   | sed -E 's/.*iters=([0-9]+).*/\1/')"
  cost="$(echo "$line"    | sed -E 's/.*cost_usd=([0-9.]+).*/\1/')"
  minutes="$(echo "$line" | sed -E 's/.*minutes=([0-9.]+).*/\1/')"
  tokens="$(echo "$line"  | sed -E 's/.*tokens=~([0-9.]+M).*/\1/')"
  new_section="## Effort Tally"$'\n\n'
  new_section+="<!-- AUTO-GENERATED by wr-itil-effort-tally; do not hand-edit. source: ${SOURCE}."$'\n'
  new_section+="     Phase bucketed from current **Status** (single-phase ceiling — ADR-067 item 2). -->"$'\n\n'
  new_section+="| Phase | Iters | Cost (USD, authoritative) | Time (min) | Tokens (best-effort) |"$'\n'
  new_section+="|---|---|---|---|---|"$'\n'
  new_section+="| ${PHASE} | ${iters} | \$${cost} | ${minutes} | ~${tokens} |"$'\n'
fi

if [ "$MODE" = "render" ]; then
  printf '%s' "$new_section"
  [ -n "$new_section" ] && echo
  exit 0
fi

# --- write mode: idempotent replace-section -------------------------------
# Strip any existing `## Effort Tally` section (and the blank run that abutted
# it), normalise trailing whitespace to one final newline, then re-insert
# before `## Fix Released` (else `## Related`, else EOF). Mirrors the awk idiom
# in update-problem-references-section.sh.
tmp_file="$(mktemp)"
awk -v sec="## Effort Tally" '
  BEGIN { in_target=0; blank_buffer=0 }
  # On section start, FLUSH the pending blank (it is the body-side separator,
  # not part of the section) so strip+reinsert is blank-stable / idempotent.
  $0 == sec { if (blank_buffer) { print ""; blank_buffer=0 } in_target=1; next }
  in_target && /^## / && $0 != sec { in_target=0 }
  !in_target {
    if ($0 ~ /^[[:space:]]*$/) { blank_buffer=1; next }
    if (blank_buffer) { print ""; blank_buffer=0 }
    print
  }
' "$TICKET_FILE" > "$tmp_file"

# Collapse blank runs to exactly one + ensure a single final newline. Collapsing
# (not preserving count) is what makes a double-blank from insertion idempotent.
tmp_file2="$(mktemp)"
awk 'BEGIN{c=0} /^[[:space:]]*$/{c++; next} {if(c>0)print ""; c=0; print} END{print ""}' "$tmp_file" > "$tmp_file2"
mv "$tmp_file2" "$tmp_file"

if [ -n "$new_section" ]; then
  if grep -q '^## Fix Released' "$tmp_file"; then
    anchor='^## Fix Released'
  elif grep -q '^## Related' "$tmp_file"; then
    anchor='^## Related'
  else
    anchor=''
  fi
  # Pass the multi-line section via a file (awk -v rejects embedded newlines on
  # BSD awk); getline keeps it portable across BSD awk + gawk. new_section ends
  # in a single \n, so the file carries no trailing blank line; the separator
  # blank between section and anchor is emitted explicitly (one `print ""`).
  section_file="$(mktemp)"
  printf '%s' "$new_section" > "$section_file"
  if [ -n "$anchor" ]; then
    tmp_file2="$(mktemp)"
    awk -v sf="$section_file" -v anchor="$anchor" '
      $0 ~ anchor && !done {
        while ((getline ln < sf) > 0) print ln
        close(sf); print ""; done=1
      }
      { print }
    ' "$tmp_file" > "$tmp_file2"
    mv "$tmp_file2" "$tmp_file"
  else
    printf '\n%s' "$new_section" >> "$tmp_file"
  fi
  rm -f "$section_file"
fi

if ! cmp -s "$tmp_file" "$TICKET_FILE"; then
  mv "$tmp_file" "$TICKET_FILE"
else
  rm -f "$tmp_file"
fi
exit 0
