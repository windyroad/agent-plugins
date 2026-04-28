#!/bin/bash
# P131: PreToolUse:Write|Edit enforcement hook for `.claude/` user-space.
#
# DENIES Write|Edit to project-scoped `.claude/` paths that are NOT in the
# user-space allow-list, unless the user has pre-authorized that specific
# path via an `.claude/.agent-write-approved-<sha256-of-rel-path>` marker.
#
# Why: `.claude/` is user-controlled config space (settings, memory, MCP
# servers, user-authored skills/hooks/commands/agents, Claude Code's own
# state in projects/ and worktrees/). Agents misread the architect/JTBD
# gate-exclusion list as "approved write zones" and write project-generated
# content (plans, audits, scratch state) under `.claude/`, polluting user
# space. Project-generated content belongs in `docs/` (plans, audits) or
# inline in problem-ticket bodies. See P131 + project CLAUDE.md MANDATORY
# rule.
#
# Allow-list (per is_protected_claude_path in lib/claude-space-gate.sh):
#   - .claude/settings.json, settings.local.json, *.local.json (root)
#   - .claude/MEMORY.md
#   - .claude/.install-updates-consent, scheduled_tasks.lock
#   - .claude/skills/, commands/, agents/, hooks/ subtrees
#   - .claude/projects/, worktrees/ subtrees (Claude Code's own state)
#   - .claude/.agent-write-approved-* markers themselves
#
# Bypass: user creates `.claude/.agent-write-approved-<sha256>` marker
# (sha256 of project-relative path). Marker is persistent (no TTL); user
# pre-authorizes once per path. Distinct from session-scoped review
# markers (ADR-009) — this is the persistent in-tree shape used by
# `.claude/.install-updates-consent` (ADR-030 / P120 precedent).
#
# Out of scope:
#   - Read|Glob|Grep on .claude/ paths — only Write|Edit gated
#   - Paths outside PWD project root (~/.claude/, other repos' .claude/)
#   - Empty session_id / file_path — fail-open (ADR-013 Rule 6 parity
#     with sibling hooks like manage-problem-enforce-create.sh)
#
# References:
#   ADR-009 — gate marker lifecycle (this hook adds a NEW persistent
#             marker class; ADR-009's session-scoped /tmp markers
#             unchanged)
#   ADR-013 Rule 6 — non-interactive fail-safe; deny via stdin JSON
#   ADR-030 — persistent in-tree consent marker precedent
#   ADR-038 — progressive disclosure (deny message <500 bytes)
#   ADR-045 — hook injection budget (silent on allow path)
#   P119    — manage-problem-enforce-create.sh hook shape precedent
#   P131    — driver

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/claude-space-gate.sh
source "$SCRIPT_DIR/lib/claude-space-gate.sh"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null || echo "")

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only gate Write and Edit. Read|Glob|Grep on .claude/ are out of scope.
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Empty file_path — fail-open (parse failure / non-file tool variant).
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Apply gate. PWD is the project root at the moment Claude Code invokes
# the hook (Claude Code spawns hooks in the project directory).
if ! is_protected_claude_path "$FILE_PATH" "$PWD"; then
  # Either not under .claude/, or in user-space allow-list. Allow.
  exit 0
fi

# Check for approval marker bypass.
if has_approval_marker "$FILE_PATH" "$PWD"; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

claude_space_deny "BLOCKED: Cannot Write|Edit '${BASENAME}' under .claude/. That directory is user-controlled config space — agents must not write project-generated artefacts there. Use docs/plans/ for plans, docs/audits/ for audit logs, or attach inline to the relevant problem ticket. To pre-authorize a specific .claude/ path, create marker '.claude/.agent-write-approved-<sha256-of-rel-path>' (P131; see project CLAUDE.md MANDATORY rule)."
exit 0
