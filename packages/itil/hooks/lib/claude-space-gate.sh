#!/bin/bash
# Shared gate logic for `.claude/` user-space write protection (P131).
#
# Sourced by itil-claude-space-protection.sh. Provides:
#   is_protected_claude_path  — returns 0 if path is project-scoped `.claude/`
#                               AND not in user-space allow-list
#   has_approval_marker       — returns 0 if user pre-authorized this path via
#                               `.claude/.agent-write-approved-<sha256>` marker
#   claude_space_deny         — emits PreToolUse deny JSON
#
# Why this is a separate gate semantic from review-gate.sh / create-gate.sh:
# review-gate.sh enforces per-session "policy was reviewed" markers with TTL.
# create-gate.sh enforces per-session "duplicate-check ran" markers.
# This gate enforces a PERSISTENT "user pre-approved this specific path"
# marker — different lifecycle (no TTL, no drift, never auto-cleared) and
# different scope (file-path-keyed, not session-keyed). Architect verdict
# (P131 Phase 2): keep semantically distinct from existing gate libraries.
#
# Marker convention: `.claude/.agent-write-approved-<sha256-of-rel-path>`
# where `<sha256-of-rel-path>` is the SHA-256 hex of the path relative to
# project root (PWD). Persistent, in-tree, file-existence test — same
# shape as ADR-030 / P120 `.claude/.install-updates-consent` precedent.
#
# Allow-list scope: paths under `.claude/` that are user-controlled by
# convention (Claude Code config, user-authored extensions, system state):
#   - settings.json, settings.local.json, *.local.json (root-depth only)
#   - MEMORY.md
#   - .install-updates-consent, scheduled_tasks.lock
#   - skills/, commands/, agents/, hooks/, projects/, worktrees/ subtrees
#   - .agent-write-approved-* markers themselves (so user can create them)
#
# References:
#   ADR-009 — gate marker lifecycle (this gate adds a NEW persistent
#             marker class; the ADR's session-scoped /tmp markers are
#             unchanged)
#   ADR-013 Rule 6 — non-interactive fail-safe (parse-error => exit 0)
#   ADR-030 — install-updates persistent in-tree consent marker precedent
#   ADR-038 — progressive disclosure (deny message <500 bytes)
#   ADR-045 — hook injection budget (Pattern 1 silent-on-pass; allow path
#             emits zero bytes)
#   P119    — manage-problem-enforce-create.sh precedent for itil
#             PreToolUse:Write enforcement hook shape
#   P120    — install-updates consent-marker persistence precedent
#   P131    — this gate's driver

# Returns 0 (true) if FILE_PATH is a project-scoped .claude/ path AND is
# NOT in the user-space allow-list. Returns 1 (false) otherwise.
#
# Project scope: FILE_PATH must be under PWD (the project root). Paths
# under ~/.claude/, /Users/.../.claude/projects/, or any .claude/
# directory outside PWD are NOT project-scoped — those are user-home
# config or other repos and out of scope for this gate.
#
# Usage: if is_protected_claude_path "$FILE_PATH" "$PWD"; then ...; fi
is_protected_claude_path() {
  local file_path="$1"
  local pwd_root="$2"

  [ -n "$file_path" ] || return 1
  [ -n "$pwd_root" ] || return 1

  # Resolve to a path relative to project root if absolute. Hook callers
  # pass absolute paths in tool_input.file_path; tests may pass relative.
  local rel_path
  case "$file_path" in
    "$pwd_root"/*)
      rel_path="${file_path#"$pwd_root"/}"
      ;;
    /*)
      # Absolute path outside project root — not project-scoped.
      return 1
      ;;
    *)
      # Relative path — assume relative to PWD.
      rel_path="$file_path"
      ;;
  esac

  # Strip leading ./ if present
  rel_path="${rel_path#./}"

  # Must be under .claude/ at project-relative root depth.
  case "$rel_path" in
    .claude/*) ;;
    *) return 1 ;;
  esac

  # User-space allow-list. Match against rel_path only (project-relative).
  # Anchor patterns to avoid accidental allows at deeper paths.
  case "$rel_path" in
    # Root-level config files
    .claude/settings.json) return 1 ;;
    .claude/settings.local.json) return 1 ;;
    .claude/MEMORY.md) return 1 ;;
    .claude/.install-updates-consent) return 1 ;;
    .claude/scheduled_tasks.lock) return 1 ;;
    # Approval markers themselves (so user can create them via Write)
    .claude/.agent-write-approved-*) return 1 ;;
    # Root-depth *.local.json (Claude Code convention for local overrides).
    # Must NOT extend to .claude/<subdir>/foo.local.json — anchor to one
    # path segment after .claude/.
    .claude/*.local.json)
      case "$rel_path" in
        .claude/*/*.local.json) ;;
        *) return 1 ;;
      esac
      ;;
    # User-extension subtrees: skills, commands, agents, hooks
    # (Claude Code conventions). Symlinks under skills/ are common.
    .claude/skills/*) return 1 ;;
    .claude/commands/*) return 1 ;;
    .claude/agents/*) return 1 ;;
    .claude/hooks/*) return 1 ;;
    # Claude Code's own state: projects/<id>/memory/, worktrees/
    .claude/projects/*) return 1 ;;
    .claude/worktrees/*) return 1 ;;
  esac

  # Project-scoped .claude/ path NOT on the allow-list — protected.
  return 0
}

# Returns 0 (true) if user has pre-authorized writes to FILE_PATH via an
# `.claude/.agent-write-approved-<sha256-of-rel-path>` marker file. The
# hash keys on the path relative to project root so the marker is portable
# across machines using the same project tree.
#
# Usage: if has_approval_marker "$FILE_PATH" "$PWD"; then ...; fi
has_approval_marker() {
  local file_path="$1"
  local pwd_root="$2"

  [ -n "$file_path" ] || return 1
  [ -n "$pwd_root" ] || return 1

  local rel_path
  case "$file_path" in
    "$pwd_root"/*) rel_path="${file_path#"$pwd_root"/}" ;;
    /*) return 1 ;;
    *) rel_path="$file_path" ;;
  esac
  rel_path="${rel_path#./}"

  # SHA-256 of the project-relative path. Use shasum (BSD) or sha256sum
  # (GNU) — fall back gracefully.
  local hash
  if command -v shasum >/dev/null 2>&1; then
    hash=$(printf '%s' "$rel_path" | shasum -a 256 | awk '{print $1}')
  elif command -v sha256sum >/dev/null 2>&1; then
    hash=$(printf '%s' "$rel_path" | sha256sum | awk '{print $1}')
  else
    # No hash tool available — treat as no marker (fail-closed for the
    # bypass; hook will emit deny). Better to require explicit user
    # action than to silently allow.
    return 1
  fi

  [ -n "$hash" ] || return 1
  [ -f "${pwd_root}/.claude/.agent-write-approved-${hash}" ]
}

# Emit fail-closed PreToolUse deny JSON. Reason should be terse (<500
# bytes per ADR-038). Hook callers compose the basename + reason inline.
#
# Usage: claude_space_deny "BLOCKED: <reason>"
claude_space_deny() {
  local reason="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$reason"
  }
}
EOF
}
