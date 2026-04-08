#!/bin/bash
# JTBD - UserPromptSubmit hook
# Detects JOBS_TO_BE_DONE.md in the project and injects delegation instruction.
# If the file doesn't exist, instructs Claude to create it via the agent.

if [ -f "docs/JOBS_TO_BE_DONE.md" ]; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY JTBD CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/JOBS_TO_BE_DONE.md exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the jtbd-lead agent
before editing any user-facing UI file (.html, .jsx, .tsx, .vue, .svelte, .ejs, .hbs).
This is proactive. Do not wait for the user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-jtbd:agent
   (subagent_type: "wr-jtbd:agent")
2. The jtbd-lead will review proposed changes against docs/JOBS_TO_BE_DONE.md
   and PRODUCT_DISCOVERY.md persona definitions
3. Do NOT write or edit UI code without jtbd-lead review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

SCOPE: User-facing files (.html, .jsx, .tsx, .vue, .svelte, .ejs, .hbs).
Does NOT apply to: .css files, .ts/.js backend files, config files.
HOOK_OUTPUT
else
  # Check if this is a web project (has UI files)
  if ls src/**/*.tsx src/**/*.jsx src/**/*.html 2>/dev/null | head -1 | grep -q .; then
    cat <<'HOOK_OUTPUT'
NOTE: This project has UI files but no docs/JOBS_TO_BE_DONE.md.
If the user's task involves editing UI files, the edit will be blocked
until a JTBD document exists. Run /wr-jtbd:create to generate one.
HOOK_OUTPUT
  fi
fi
