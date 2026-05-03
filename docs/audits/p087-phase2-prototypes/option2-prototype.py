"""Prototype: per-plugin composite exercise index from commit history.

Signals collected per plugin (last 60 days, default window in P087 ADR-053):
  - commits_window: commits touching at least one file under packages/<plugin>/
  - days_since_first: how many days since the FIRST ever commit touching the plugin
  - resolved_problem_tickets: closed tickets in docs/problems/ whose body mentions packages/<plugin>/
  - last_breaking_change_days: best-effort — days since last commit message containing 'BREAKING' or major bump marker
"""
import os, subprocess, sys, time
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

REPO = Path("/Users/tomhoward/Projects/windyroad-claude-plugin")
WINDOW_DAYS = 60
TICKET_WINDOW_DAYS = 90  # broader window for ticket count
NOW = datetime.now(timezone.utc)

def run(cmd, cwd=REPO):
    return subprocess.check_output(cmd, cwd=cwd, text=True, errors='replace')

# Discover plugins
plugins = sorted(p.name for p in (REPO / "packages").iterdir() if p.is_dir())

# Get commit log with file paths once
since_iso = (NOW - timedelta(days=WINDOW_DAYS)).strftime('%Y-%m-%d')
log_window = run(['git', 'log', f'--since={since_iso}', '--name-only', '--pretty=format:%H|%aI|%s'])
log_all = run(['git', 'log', '--name-only', '--pretty=format:%H|%aI|%s'])

def parse_log(text):
    """Yield (commit_hash, iso_date, subject, [files])."""
    cur = None
    files = []
    for line in text.splitlines():
        if not line:
            if cur:
                yield (*cur, files)
                cur, files = None, []
            continue
        if '|' in line and (cur is None or line.count('|') >= 2):
            # header line
            parts = line.split('|', 2)
            if len(parts) == 3 and len(parts[0]) == 40:
                if cur:
                    yield (*cur, files)
                cur = (parts[0], parts[1], parts[2])
                files = []
                continue
        if cur:
            files.append(line)
    if cur:
        yield (*cur, files)

# First-ever commit per plugin
first_commit = {}
for h, iso, subj, files in parse_log(log_all):
    for f in files:
        for plug in plugins:
            if f.startswith(f"packages/{plug}/"):
                oldest_iso = first_commit.get(plug)
                if oldest_iso is None or iso < oldest_iso:
                    first_commit[plug] = iso

# Commits in window per plugin
commits_window = Counter()
breaking_change_days = {}
for h, iso, subj, files in parse_log(log_window):
    plugs_touched = set()
    for f in files:
        for plug in plugins:
            if f.startswith(f"packages/{plug}/"):
                plugs_touched.add(plug)
    for p in plugs_touched:
        commits_window[p] += 1
        # crude breaking-change heuristic
        if 'BREAKING' in subj or 'feat!' in subj or 'fix!' in subj:
            try:
                d = datetime.fromisoformat(iso.replace('Z', '+00:00'))
                age = (NOW - d).days
                if p not in breaking_change_days or age < breaking_change_days[p]:
                    breaking_change_days[p] = age
            except Exception: pass

# Resolved problem tickets per plugin (last 90 days)
ticket_root = REPO / "docs" / "problems"
ticket_counts = Counter()
ticket_window = NOW - timedelta(days=TICKET_WINDOW_DAYS)
for ticket in ticket_root.glob("*.md"):
    if ticket.name == "README.md" or ticket.name.startswith("README"):
        continue
    if ticket.name == "TEMPLATE.md":
        continue
    try:
        st = ticket.stat()
        mtime = datetime.fromtimestamp(st.st_mtime, tz=timezone.utc)
        if mtime < ticket_window:
            continue
    except OSError: continue
    is_closed = '.closed.' in ticket.name or '.verifying.' in ticket.name
    if not is_closed:
        continue
    body = ticket.read_text(errors='replace')
    for plug in plugins:
        if f"packages/{plug}/" in body:
            ticket_counts[plug] += 1

# Render
print(f"# Option 2 prototype — per-plugin commit-history composite (window {WINDOW_DAYS}d; tickets {TICKET_WINDOW_DAYS}d)")
print(f"# Plugins discovered: {len(plugins)}")
print()
header = f"{'PLUGIN':<18} {'COMMITS_W':>9} {'DAYS_SHIPPED':>12} {'CLOSED_TICKETS':>14} {'BC_AGE_DAYS':>11}"
print(header)
print('-' * len(header))
for p in plugins:
    first = first_commit.get(p)
    if first:
        try:
            first_dt = datetime.fromisoformat(first.replace('Z', '+00:00'))
            days_shipped = (NOW - first_dt).days
        except Exception:
            days_shipped = -1
    else:
        days_shipped = -1
    cw = commits_window.get(p, 0)
    tc = ticket_counts.get(p, 0)
    bc = breaking_change_days.get(p, 999)
    print(f"{p:<18} {cw:>9d} {days_shipped:>12d} {tc:>14d} {bc:>11d}")

print()
print("## Composite exercise index (strawman per ADR-053)")
print("# index = log10(commits_window + 1) + log10(closed_tickets + 1) + (days_shipped >= 60 ? 1 : 0)")
print(f"{'PLUGIN':<18} {'INDEX':>8}")
import math
scored = []
for p in plugins:
    cw = commits_window.get(p, 0)
    tc = ticket_counts.get(p, 0)
    first = first_commit.get(p)
    days_shipped = -1
    if first:
        try:
            days_shipped = (NOW - datetime.fromisoformat(first.replace('Z', '+00:00'))).days
        except Exception: pass
    idx = math.log10(cw + 1) + math.log10(tc + 1) + (1.0 if days_shipped >= 60 else 0.0)
    scored.append((p, idx))
for p, s in sorted(scored, key=lambda x: -x[1]):
    print(f"{p:<18} {s:>8.2f}")
