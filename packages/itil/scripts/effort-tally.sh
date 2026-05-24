#!/usr/bin/env bash
# wr-itil — per-ticket effort tally from AFK iteration cost metadata (ADR-067, P248)
#
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK actuals feed WSJF calibration)
# @jtbd JTBD-202 (Run Pre-Flight Governance Checks — structured, auditable effort tally)
#
# Attributes `.afk-run-state/iter*.json` actuals back to their source ticket
# (the `pNNN` token in the filename) and emits one tally line per ticket in the
# `## Effort Tally` schema. The reusable core shared by:
#   - the backfill (seed historical tickets — ADR-067 Decision Outcome item 4)
#   - go-forward per-iter append (work-problems — ADR-067 item 2)
#
# Authority hierarchy (P089 Gap 2 — load-bearing): `total_cost_usd` is the
# AUTHORITATIVE actual (session-cumulative by CLI contract; reliable token-spend
# proxy). `duration_ms` is reliable wall-clock. Raw `usage.*` token counts are
# BEST-EFFORT (undercount when a subprocess exits on a background-ack turn) and
# are emitted with a `~` best-effort marker.
#
# Usage:
#   effort-tally.sh [AFK_DIR]
#     AFK_DIR defaults to .afk-run-state
#
# Output (stdout): one line per ticket, sorted by descending cost:
#   P<NNN> | iters=<N> | cost_usd=<authoritative> | minutes=<reliable> | tokens=~<best-effort>M
# Always exits 0.

set -euo pipefail

AFK_DIR="${1:-.afk-run-state}"
[ -d "$AFK_DIR" ] || exit 0

python3 - "$AFK_DIR" <<'PY'
import json, glob, os, re, sys
from collections import defaultdict

afk_dir = sys.argv[1]

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
