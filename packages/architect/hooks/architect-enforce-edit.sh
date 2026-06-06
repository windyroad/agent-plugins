#!/bin/bash
# Architecture - PreToolUse enforcement hook
# BLOCKS Edit/Write to all project files until architect is consulted.
# Excludes only non-architectural files: stylesheets, images, generated files.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/architect-gate.sh"

# P191 Phase 2: resolve the project root from the session signal, not the
# hook's runtime CWD. Claude Code can launch the hook with a working directory
# that differs from the session/project dir while still exporting
# CLAUDE_PROJECT_DIR (and a $PWD env var) pointing at the project. A relative
# `[ -d "docs/decisions" ]` then false-negatives even though docs/decisions is
# present — and because this gate fails OPEN (exit 0) on a missing decisions
# dir, the misfire silently DEACTIVATES the architect gate and edits bypass
# review (a governance hole, strictly worse than the JTBD gate's fail-closed
# nuisance fixed in P191 Phase 1). Anchor every project-relative check on
# PROJECT_DIR. Pattern mirrors architect-oversight-nudge.sh.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ]; then
  architect_gate_parse_error
  exit 0
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# P004: Only gate files inside the project root. Absolute paths outside
# $PWD (e.g., ~/.claude/channels/*) are not project files.
case "$FILE_PATH" in
  /*)
    case "$FILE_PATH" in
      "$PROJECT_DIR"/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

# Only gate if the project has architecture decisions
if [ ! -d "$PROJECT_DIR/docs/decisions" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# Exclude non-architectural files
case "$FILE_PATH" in
  *.css|*.scss|*.sass|*.less)
    exit 0 ;;
  *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.webp)
    exit 0 ;;
  *.woff|*.woff2|*.ttf|*.eot)
    exit 0 ;;
  *package-lock.json|*yarn.lock|*pnpm-lock.yaml)
    exit 0 ;;
  *.map)
    exit 0 ;;
  *.changeset/*.md|*/.changeset/*.md)
    exit 0 ;;
  */MEMORY.md|*/.claude/projects/*/memory/*)
    exit 0 ;;
  # READ tolerance only — gate skips user edits to .claude/plans/. NOT a write
  # target for agents. .claude/ is user-controlled config space; agents must not
  # write project-generated artefacts here. See P131.
  */.claude/plans/*.md|*.claude/plans/*.md)
    exit 0 ;;
  */RISK-POLICY.md)
    exit 0 ;;
  */.risk-reports/*)
    exit 0 ;;
  */docs/BRIEFING.md|docs/BRIEFING.md)
    exit 0 ;;
  */docs/briefing/*|docs/briefing/*)
    exit 0 ;;
  */docs/problems/*.md|docs/problems/*.md)
    exit 0 ;;
  # ADR-031 / RFC-002 T1 dual-pattern: per-state subdir layout
  # (`docs/problems/<state>/<NNN>-<slug>.md`). Coexists with the
  # flat-layout pattern above during the migration window. Drops to
  # single-pattern at RFC-002 T6 once Slice A migration verifies.
  */docs/problems/*/*.md|docs/problems/*/*.md)
    exit 0 ;;
  # Peer-plugin policy files — governed by their own plugin's enforce hook, not architect (P009)
  */docs/PRODUCT_DISCOVERY.md|docs/PRODUCT_DISCOVERY.md)
    exit 0 ;;
  */docs/jtbd/*|docs/jtbd/*)
    exit 0 ;;
  */docs/VOICE-AND-TONE.md|docs/VOICE-AND-TONE.md)
    exit 0 ;;
  */docs/STYLE-GUIDE.md|docs/STYLE-GUIDE.md)
    exit 0 ;;
  # Story maps + stories — governed by capture-story-map / manage-story-map
  # and capture-story / manage-story skills (ADR-060 § Phase 2 amendment
  # 2026-05-12 lines 481-496). Same pattern as docs/problems and docs/jtbd
  # exemptions — these are governance-managed surfaces with their own
  # capture/manage lifecycle skills. P170 Phase 2 Slice 2.5.
  */docs/story-maps/*|docs/story-maps/*)
    exit 0 ;;
  */docs/stories/*|docs/stories/*)
    exit 0 ;;
  # Retros — ask-hygiene + run-retro narrative trail written routinely by
  # `/wr-retrospective:run-retro` (Step 2d + Step 5). Not architecture
  # content; the gate firing on every retro append forces a subagent
  # round-trip before a non-load-bearing narrative artefact can land.
  # Mirrors docs/problems and docs/jtbd peer-plugin-policy exemptions. P203.
  */docs/retros/*|docs/retros/*)
    exit 0 ;;
esac

# Check gate
if check_architect_gate "$SESSION_ID"; then
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Cannot edit '${BASENAME}' without architecture review. You MUST first delegate to wr-architect:agent using the Agent tool (subagent_type: 'wr-architect:agent'). The architect will review against existing decisions in docs/decisions/ and flag if a new decision should be documented. After the review completes, this file will be unblocked automatically."
  }
}
EOF
exit 0
