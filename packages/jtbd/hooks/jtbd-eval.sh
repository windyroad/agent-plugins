#!/bin/bash
# JTBD - UserPromptSubmit hook
# Detects JTBD docs in the project and injects delegation instruction.
# Supports both docs/jtbd/ directory (preferred) and docs/JOBS_TO_BE_DONE.md (legacy).
# If neither exists, instructs Claude to create via the update-guide skill.

if [ -f "docs/jtbd/README.md" ]; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY JTBD CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/jtbd/ exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the jtbd-lead agent
before editing any project file. This is proactive. Do not wait for the
user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-jtbd:agent
   (subagent_type: "wr-jtbd:agent")
2. The jtbd-lead will review proposed changes against docs/jtbd/ persona
   and job definitions
3. Do NOT write or edit project files without jtbd-lead review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

SCOPE: All project files.
Does NOT apply to: CSS, images, fonts, lockfiles, changesets, memory files,
plan files, docs/problems/ (problem tickets), docs/BRIEFING.md,
RISK-POLICY.md, .risk-reports/, docs/jtbd/, docs/JOBS_TO_BE_DONE.md,
docs/PRODUCT_DISCOVERY.md, docs/VOICE-AND-TONE.md, docs/STYLE-GUIDE.md.
HOOK_OUTPUT
elif [ -f "docs/JOBS_TO_BE_DONE.md" ]; then
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
Does NOT apply to: CSS, images, fonts, lockfiles, changesets, memory files,
plan files, docs/problems/ (problem tickets), docs/BRIEFING.md,
RISK-POLICY.md, .risk-reports/, docs/jtbd/, docs/JOBS_TO_BE_DONE.md,
docs/PRODUCT_DISCOVERY.md, docs/VOICE-AND-TONE.md, docs/STYLE-GUIDE.md.
HOOK_OUTPUT
else
  cat <<'HOOK_OUTPUT'
NOTE: This project has no docs/jtbd/ directory or docs/JOBS_TO_BE_DONE.md.
Edits to project files will be blocked until a JTBD document exists.
Run /wr-jtbd:update-guide to generate one.
HOOK_OUTPUT
fi
