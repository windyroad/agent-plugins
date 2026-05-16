#!/usr/bin/env bash
# packages/itil/scripts/plugin-exercise-index.sh
#
# Phase 2b (P087) git-axis maturity-measurement script.
#
# Runs `git log --since=<window>d --name-only --pretty=format:%H|%aI|%s`
# once at the project root, auto-discovers plugins by listing `packages/*/`,
# and emits one NDJSON record per plugin with the v1.0 schema fields per
# ADR-058 §Script contracts (line 87-113).
#
# Schema (per ADR-058 line 95-110):
#   {"schema_version":"1.0","axis":"plugin-exercise-index","plugin":"<name>",
#    "commits_window":<N>,"window_days":<N>,"days_shipped":<N>,
#    "closed_tickets_window":<N>,"tickets_window_days":<N>,
#    "breaking_change_age_days":<N|null>,"composite_index":<float>}
#
# composite_index = log10(commits_window+1)
#                 + log10(closed_tickets_window+1)
#                 + (days_shipped >= 60 ? 1.0 : 0.0)
# (ADR-058 line 112, Option E6 "MAY emit alongside band" carve-out.)
#
# Usage:
#   wr-itil-plugin-exercise-index [--window-days=N] [--tickets-window-days=N]
#                                  [--project-root=PATH]
#                                  [--category-overrides=FILE]
#
# Defaults:
#   --window-days           60   (ADR-058 line 89)
#   --tickets-window-days   90   (ADR-058 line 93)
#   --project-root          $PWD
#
# Exit codes:
#   0 = always — ADR-013 Rule 6 fail-safe. Outside-git-repo, missing
#                `packages/`, opt-out marker all hit the zero-records path
#                with stderr-comment.
#
# Privacy (ADR-035 clauses adopted verbatim, adapted for the git axis):
#   - Opt-out marker `.claude/.skill-metrics-opt-out` disables reads.
#   - No network egress — the script body invokes no exfiltration
#     primitives. ADR-058 §Confirmation 3 enforces via negative-grep on
#     this file (banned-token list lives in the bats fixture, not here,
#     to avoid self-matching).
#   - Content sanitisation — commit subjects are parsed ONLY for
#     `BREAKING|feat!|fix!` token presence (boolean test); the subject
#     prose is discarded after the test and never echoed to stdout. The
#     only plugin-attribution surface is the `packages/<plugin>/` path
#     prefix extracted from `--name-only` output.
#
# @problem P087 (Phase 2b — git axis)
# @adr ADR-058 (Plugin maturity measurement mechanism)
# @adr ADR-049 (Shim grammar — bin/wr-itil-plugin-exercise-index on $PATH)
# @adr ADR-035 (Privacy posture adopted verbatim)
# @adr ADR-052 (Behavioural tests default; ADR-058 §Confirmation 6-8)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — exit 0 always)
# @adr ADR-023 (Performance — ≤1.0s warm-cache; 60-day window default)
# @jtbd JTBD-101 (Extend the Suite — hardening-prioritisation outcome,
#   2026-05-04 amendment serves Phase 2 NDJSON as data source)
# @jtbd JTBD-201 (Restore Service Fast — audit-trail composition)

set -uo pipefail

# ── CLI parse ───────────────────────────────────────────────────────────────

WINDOW_DAYS=60
TICKETS_WINDOW_DAYS=90
PROJECT_ROOT="$PWD"
CATEGORY_OVERRIDES=""

for arg in "$@"; do
  case "$arg" in
    --window-days=*) WINDOW_DAYS="${arg#--window-days=}" ;;
    --tickets-window-days=*) TICKETS_WINDOW_DAYS="${arg#--tickets-window-days=}" ;;
    --project-root=*) PROJECT_ROOT="${arg#--project-root=}" ;;
    --category-overrides=*) CATEGORY_OVERRIDES="${arg#--category-overrides=}" ;;
    --help|-h)
      sed -n '4,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "# wr-itil-plugin-exercise-index: ignoring unknown argument: $arg" >&2
      ;;
  esac
done

# ── Opt-out marker check (ADR-035 / ADR-058 §Privacy posture) ───────────────

OPT_OUT_MARKER="${PROJECT_ROOT}/.claude/.skill-metrics-opt-out"
if [ -e "$OPT_OUT_MARKER" ]; then
  echo "# wr-itil-plugin-exercise-index: opt-out marker present at ${OPT_OUT_MARKER}" >&2
  exit 0
fi

# ── Git-repo check (ADR-013 Rule 6 fail-safe) ───────────────────────────────

if [ ! -d "${PROJECT_ROOT}/.git" ] && ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "# wr-itil-plugin-exercise-index: not a git repository at ${PROJECT_ROOT}" >&2
  exit 0
fi

# ── packages/ discovery check (ADR-013 Rule 6 fail-safe) ────────────────────

if [ ! -d "${PROJECT_ROOT}/packages" ]; then
  echo "# wr-itil-plugin-exercise-index: no packages/ directory at ${PROJECT_ROOT}" >&2
  exit 0
fi

# Discover plugins as immediate subdirectories of packages/. Empty result is
# also a fail-safe case (no plugins to score).
PLUGIN_COUNT=0
for d in "${PROJECT_ROOT}/packages"/*/; do
  [ -d "$d" ] && PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
done
if [ "$PLUGIN_COUNT" -eq 0 ]; then
  echo "# wr-itil-plugin-exercise-index: no packages/ directory at ${PROJECT_ROOT}" >&2
  exit 0
fi

# ── --category-overrides validation (ADR-058 §Per-category override hook) ───
# Forward-extension flag; ships unused in Phase 2.

if [ -n "$CATEGORY_OVERRIDES" ] && [ ! -f "$CATEGORY_OVERRIDES" ]; then
  echo "# wr-itil-plugin-exercise-index: category-overrides file not found: ${CATEGORY_OVERRIDES}" >&2
  exit 0
fi

# ── Git log + NDJSON emit (Python 3 stdlib) ─────────────────────────────────
# Inputs pinned via environment to avoid argv leakage.

export PEI_PROJECT_ROOT="$PROJECT_ROOT"
export PEI_WINDOW_DAYS="$WINDOW_DAYS"
export PEI_TICKETS_WINDOW_DAYS="$TICKETS_WINDOW_DAYS"

python3 - <<'PYEOF'
import json, os, re, subprocess, sys, time, math
from pathlib import Path
from collections import defaultdict
from datetime import datetime, timezone

project_root = Path(os.environ["PEI_PROJECT_ROOT"]).resolve()
window_days = int(os.environ["PEI_WINDOW_DAYS"])
tickets_window_days = int(os.environ["PEI_TICKETS_WINDOW_DAYS"])
now = time.time()
cutoff = now - window_days * 86400
tickets_cutoff = now - tickets_window_days * 86400

# Discover plugins (immediate subdirs of packages/).
plugins = sorted(
    p.name for p in (project_root / "packages").iterdir() if p.is_dir()
)
if not plugins:
    sys.exit(0)

# Per-plugin accumulators.
commits_window = defaultdict(int)
breaking_age_days = {}   # plugin -> int (days since most recent breaking commit in window)
oldest_commit_ts = {}    # plugin -> float epoch seconds (across ALL history)
closed_tickets_window = defaultdict(int)

# `BREAKING` token presence — boolean test only, subject discarded after.
BREAKING_RE = re.compile(r"\b(BREAKING)\b|(?:^|\s)(feat!|fix!|chore!|refactor!)")

# ── Single git log pass with in-Python window filter ────────────────────────
# ADR-058 line 89 pins `git log --since=<window>d --name-only
# --pretty=format:%H|%aI|%s`. Git's `--since=Nd` was observed unreliable on
# 2026-05-16 against the test fixture (returned empty even for commits well
# within the window — likely a date-parser quirk with future-year commit
# dates), so the window filter is applied in-Python against the `%aI`
# author-date field that is already extracted for `breaking_change_age_days`
# and `days_shipped`. The `git log` invocation otherwise matches the ADR-058
# contract verbatim (--name-only, the literal `|` separator). Single pass
# instead of two — pass-2 (oldest-commit) and pass-1 (in-window) collapse
# into one walk because we already iterate every commit's date.
#
# Defensive split on first 2 `|` occurrences only — subjects may contain
# literal `|` characters per the architect's 2026-05-16 advisory.

def parse_log_all():
    """Yield (sha, iso_ts, subject, paths_list) tuples for every commit."""
    try:
        proc = subprocess.run(
            [
                "git",
                "-C", str(project_root),
                "log",
                "--reverse",  # oldest-first; first hit per plugin = days_shipped
                "--name-only",
                "--pretty=format:%H|%aI|%s",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return
    if proc.returncode != 0:
        return

    # Output shape: <header>\n<path>\n<path>\n\n<header>\n... Commits are
    # separated by blank lines; the header line is always identifiable by
    # containing exactly two `|` separators (lines without separators are
    # path lines).
    current = None
    for line in proc.stdout.split("\n"):
        if not line.strip():
            if current is not None:
                yield current
                current = None
            continue
        # Header line: contains the `|` separator pattern. Defensive split
        # on first 2 occurrences so `|` characters in subjects are preserved.
        if "|" in line:
            parts = line.split("|", 2)
            if len(parts) == 3 and re.match(r"^[0-9a-f]{7,40}$", parts[0]):
                if current is not None:
                    yield current
                current = (parts[0], parts[1], parts[2], [])
                continue
        # Path line under current commit.
        if current is not None:
            current[3].append(line)
    if current is not None:
        yield current

for sha, iso_ts, subject, paths in parse_log_all():
    # Per-commit plugin set (dedupe — one commit touching N files under
    # packages/foo counts as 1, not N).
    plugins_touched = set()
    for p in paths:
        parts = p.split("/")
        if len(parts) >= 3 and parts[0] == "packages":
            plug = parts[1]
            if plug in plugins:
                plugins_touched.add(plug)

    if not plugins_touched:
        del subject
        continue

    # Parse author-date once — fed into days_shipped (every commit) and
    # the in-window filter (commits_window, breaking_change_age_days).
    try:
        commit_dt = datetime.fromisoformat(iso_ts.replace("Z", "+00:00"))
        ts = commit_dt.timestamp()
    except Exception:
        del subject
        continue

    # days_shipped: track min(author_date) per plugin. ADR-058 line 91 says
    # "days since the OLDEST git commit"; oldest is interpreted as min by
    # author-date rather than min by commit-topology so the value is stable
    # against commit-reordering and rebase. (Topological --reverse can
    # disagree with author-date order when commits are made out of
    # chronological order — common in tests; possible in cherry-picks and
    # backports in production.)
    for plug in plugins_touched:
        cur = oldest_commit_ts.get(plug)
        if cur is None or ts < cur:
            oldest_commit_ts[plug] = ts

    # In-window filter — applied in Python (ADR-058 line 89 contract for the
    # git invocation; window cutoff in-process for portability).
    if ts < cutoff:
        del subject
        continue

    # Commit-window tally.
    for plug in plugins_touched:
        commits_window[plug] += 1

    # Breaking-marker test on subject (boolean test; subject discarded after).
    if BREAKING_RE.search(subject):
        age_days = int((now - ts) / 86400)
        if age_days >= 0:
            for plug in plugins_touched:
                cur = breaking_age_days.get(plug)
                # Want the YOUNGEST (smallest age_days) breaking commit.
                if cur is None or age_days < cur:
                    breaking_age_days[plug] = age_days
    # subject explicitly not retained beyond this point.
    del subject

# ── Pass 3: closed/verifying ticket scan (citation match + 90-day mtime) ────
# Tolerate both layouts:
#   (a) suffix-based: docs/problems/**/<NNN>-*.closed.md, *.verifying.md
#   (b) directory-based: docs/problems/closed/<NNN>-*.md, verifying/<NNN>-*.md

problems_root = project_root / "docs" / "problems"
ticket_files = []
if problems_root.is_dir():
    # Suffix-based (recursive).
    ticket_files.extend(problems_root.rglob("*.closed.md"))
    ticket_files.extend(problems_root.rglob("*.verifying.md"))
    # Directory-based.
    for subdir in ("closed", "verifying"):
        d = problems_root / subdir
        if d.is_dir():
            for f in d.rglob("*.md"):
                if not (f.name.endswith(".closed.md") or f.name.endswith(".verifying.md")):
                    ticket_files.append(f)

# Dedupe (a file may match both globs in pathological cases).
ticket_files = sorted(set(ticket_files))

for ticket in ticket_files:
    try:
        st = ticket.stat()
    except OSError:
        continue
    if st.st_mtime < tickets_cutoff:
        continue
    try:
        body = ticket.read_text(encoding="utf-8", errors="replace")
    except OSError:
        continue
    for plug in plugins:
        # Citation marker — any occurrence of `packages/<plugin>/` in body.
        if f"packages/{plug}/" in body:
            closed_tickets_window[plug] += 1

# ── Emit one NDJSON record per discovered plugin ────────────────────────────

for plug in plugins:
    cw = commits_window.get(plug, 0)
    ctw = closed_tickets_window.get(plug, 0)
    if plug in oldest_commit_ts:
        ds = int((now - oldest_commit_ts[plug]) / 86400)
    else:
        ds = 0
    bca = breaking_age_days.get(plug)
    bonus = 1.0 if ds >= 60 else 0.0
    composite = round(math.log10(cw + 1) + math.log10(ctw + 1) + bonus, 2)
    record = {
        "schema_version": "1.0",
        "axis": "plugin-exercise-index",
        "plugin": plug,
        "commits_window": cw,
        "window_days": window_days,
        "days_shipped": ds,
        "closed_tickets_window": ctw,
        "tickets_window_days": tickets_window_days,
        "breaking_change_age_days": bca,
        "composite_index": composite,
    }
    sys.stdout.write(json.dumps(record, separators=(",", ":")) + "\n")
PYEOF

exit 0
