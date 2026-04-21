#!/bin/bash
# Style Guide - UserPromptSubmit hook (P095 / ADR-038)
# Detects STYLE-GUIDE.md in the project and injects delegation instruction.
# If the file doesn't exist, instructs Claude to create it via the agent.
#
# Progressive disclosure (ADR-038): full MANDATORY block on first
# prompt; terse reminder on subsequent prompts in the same session.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/session-marker.sh
source "$SCRIPT_DIR/lib/session-marker.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")

if [ -f "docs/STYLE-GUIDE.md" ]; then
  if has_announced "style-guide" "$SESSION_ID"; then
    cat <<'HOOK_OUTPUT'
MANDATORY style-guide gate active (docs/STYLE-GUIDE.md present). Delegate to wr-style-guide:agent before editing UI files (.css, .html, .jsx, .tsx, .vue, .svelte, .ejs, .hbs). See turn-1 instructions for full scope.
HOOK_OUTPUT
  else
    cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY STYLE GUIDE CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/STYLE-GUIDE.md exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the style-guide-lead agent
before editing any .css or UI component file. This is proactive.
Do not wait for the user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-style-guide:agent
   (subagent_type: "wr-style-guide:agent")
2. The style-guide-lead will review proposed styling against docs/STYLE-GUIDE.md
3. Do NOT write or edit styling without style-guide-lead review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

SCOPE: All .css and UI component files (.html, .jsx, .tsx, .vue, .svelte, .ejs, .hbs).
Does NOT apply to: .ts/.js backend files, .md files, config files.
HOOK_OUTPUT
    mark_announced "style-guide" "$SESSION_ID"
  fi
else
  # Check if this is a web project (has UI files)
  if ls src/**/*.tsx src/**/*.jsx src/**/*.css src/**/*.html 2>/dev/null | head -1 | grep -q .; then
    cat <<'HOOK_OUTPUT'
NOTE: This project has UI files but no docs/STYLE-GUIDE.md.
If the user's task involves editing CSS or UI components, the edit will be blocked
until a style guide exists. Run /wr-style-guide:update-guide to generate one.
HOOK_OUTPUT
  fi
fi
