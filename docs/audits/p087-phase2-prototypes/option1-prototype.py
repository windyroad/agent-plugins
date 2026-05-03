"""Prototype: parse session transcripts for per-skill / per-agent / per-plugin invocation counts.

Data source: ~/.claude/projects/*/sessions/*.jsonl
Time window: last 30 days (mtime-based)
Tool kinds tallied:
  - Skill (skill name from input.skill)
  - Agent (agent kind from input.subagent_type)
  - Bash (pattern-matched against plugin script paths)
"""
import json, os, sys, time, re
from collections import Counter
from pathlib import Path

WINDOW_DAYS = 30
NOW = time.time()
CUTOFF = NOW - WINDOW_DAYS * 86400

# Map Bash command patterns to plugin-of-origin. Two flavours:
#   - bin/wr-<plugin>-*   → that plugin
#   - packages/<plugin>/  → that plugin (script files)
BIN_RE = re.compile(r'\bwr-([a-z0-9-]+?)(?:-[a-z0-9-]+)?(?:\s|$|"|\'|;|\|)')
PKG_RE = re.compile(r'packages/([a-z0-9-]+)/')

def plugin_from_skill(skill_name):
    """A skill name like 'wr-itil:manage-problem' → plugin 'itil'."""
    if not skill_name: return None
    if ':' in skill_name:
        prefix = skill_name.split(':', 1)[0]
        if prefix.startswith('wr-'):
            return prefix[3:]
        return prefix
    return None

def plugin_from_agent(agent_kind):
    """Agent kind like 'wr-architect:agent' → 'architect'."""
    return plugin_from_skill(agent_kind)

def plugin_from_bash(cmd):
    """Try to identify the plugin a bash command exercises."""
    if not cmd: return None
    # bin shim grammar
    m = BIN_RE.search(cmd)
    if m:
        return m.group(1)
    # packages path
    m = PKG_RE.search(cmd)
    if m:
        return m.group(1)
    return None

skill_counts = Counter()
agent_counts = Counter()
plugin_counts = Counter()  # any tool attributed to a plugin
bash_plugin_counts = Counter()

sessions_root = Path.home() / '.claude' / 'projects'
files_scanned = 0
files_in_window = 0

for jsonl in sessions_root.rglob('*.jsonl'):
    files_scanned += 1
    try:
        st = jsonl.stat()
    except OSError:
        continue
    if st.st_mtime < CUTOFF:
        continue
    files_in_window += 1
    try:
        with jsonl.open() as fh:
            for line in fh:
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                if rec.get('type') != 'assistant':
                    continue
                # Filter by message timestamp if present (more accurate than file mtime)
                ts = rec.get('timestamp')
                if ts:
                    try:
                        # ISO 8601
                        from datetime import datetime, timezone
                        dt = datetime.fromisoformat(ts.replace('Z','+00:00'))
                        if dt.timestamp() < CUTOFF:
                            continue
                    except Exception:
                        pass
                msg = rec.get('message', {})
                content = msg.get('content', [])
                if not isinstance(content, list):
                    continue
                for c in content:
                    if not isinstance(c, dict):
                        continue
                    if c.get('type') != 'tool_use':
                        continue
                    name = c.get('name')
                    inp = c.get('input', {}) or {}
                    if name == 'Skill':
                        skill = inp.get('skill')
                        if skill:
                            skill_counts[skill] += 1
                            p = plugin_from_skill(skill)
                            if p: plugin_counts[p] += 1
                    elif name == 'Agent':
                        sub = inp.get('subagent_type')
                        if sub:
                            agent_counts[sub] += 1
                            p = plugin_from_agent(sub)
                            if p: plugin_counts[p] += 1
                    elif name == 'Bash':
                        cmd = inp.get('command', '')
                        p = plugin_from_bash(cmd)
                        if p:
                            bash_plugin_counts[p] += 1
                            plugin_counts[p] += 1
    except OSError:
        continue

print(f"# Option 1 prototype — session-transcript invocation counts (last {WINDOW_DAYS}d)")
print(f"# Sessions scanned: {files_scanned}; in-window: {files_in_window}")
print()
print("## Top skills (by Skill tool invocations)")
print(f"{'COUNT':>7}  SKILL")
for name, n in skill_counts.most_common(40):
    print(f"{n:7d}  {name}")
print()
print("## Top agents (by Agent.subagent_type)")
print(f"{'COUNT':>7}  AGENT")
for name, n in agent_counts.most_common(20):
    print(f"{n:7d}  {name}")
print()
print("## Per-plugin rollup (Skill + Agent + Bash-attributed)")
print(f"{'COUNT':>7}  PLUGIN")
for name, n in plugin_counts.most_common(20):
    print(f"{n:7d}  {name}")
print()
print("## Bash-only plugin attribution (subset of above)")
print(f"{'COUNT':>7}  PLUGIN")
for name, n in bash_plugin_counts.most_common(15):
    print(f"{n:7d}  {name}")
