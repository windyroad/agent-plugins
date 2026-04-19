#!/bin/bash
# JTBD - UserPromptSubmit hook
# Detects the docs/jtbd/ directory in the project and injects the
# delegation instruction. Canonical layout is docs/jtbd/ only
# (ADR-008, Option 3 chosen 2026-04-20). Legacy docs/JOBS_TO_BE_DONE.md
# is NOT consulted at runtime — projects still on that layout must run
# /wr-jtbd:update-guide to migrate. The update-guide skill is the sole
# component permitted to read the legacy file (for one-shot migration).

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
RISK-POLICY.md, .risk-reports/, docs/jtbd/,
docs/PRODUCT_DISCOVERY.md, docs/VOICE-AND-TONE.md, docs/STYLE-GUIDE.md.
HOOK_OUTPUT
else
  cat <<'HOOK_OUTPUT'
NOTE: This project has no docs/jtbd/ directory. Edits to project files
will be blocked until a JTBD document exists. Run /wr-jtbd:update-guide
to generate one. If the project has a legacy docs/JOBS_TO_BE_DONE.md,
update-guide will migrate it into the directory layout (ADR-008 Option 3).
HOOK_OUTPUT
fi
