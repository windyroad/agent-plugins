#!/bin/bash
# JTBD - UserPromptSubmit hook
# Detects JOBS_TO_BE_DONE.md in the project and injects delegation instruction.
# If the file doesn't exist, instructs Claude to create it via the update-guide skill.

if [ -f "docs/JOBS_TO_BE_DONE.md" ]; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY JTBD CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/JOBS_TO_BE_DONE.md exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the jtbd-lead agent
before editing any project file. This is proactive. Do not wait for the
user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-jtbd:agent
   (subagent_type: "wr-jtbd:agent")
2. The jtbd-lead will review proposed changes against docs/JOBS_TO_BE_DONE.md
   and PRODUCT_DISCOVERY.md persona definitions
3. Do NOT write or edit project files without jtbd-lead review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

SCOPE: All project files.
Does NOT apply to: CSS, images, fonts, lockfiles, changesets, memory files, plan files.
HOOK_OUTPUT
else
  cat <<'HOOK_OUTPUT'
NOTE: This project has no docs/JOBS_TO_BE_DONE.md.
Edits to project files will be blocked until a JTBD document exists.
Run /wr-jtbd:update-guide to generate one.
HOOK_OUTPUT
fi
