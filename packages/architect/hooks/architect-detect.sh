#!/bin/bash
# Architecture - UserPromptSubmit hook
# Detects docs/decisions/ directory and injects delegation instruction.
# The architect agent reviews changes against architectural decision records.

if [ -d "docs/decisions" ]; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY ARCHITECTURE CHECK. YOU MUST FOLLOW THIS.
DETECTED: docs/decisions/ exists in this project.

This is a NON-OPTIONAL instruction. You MUST use the architect agent
before editing any project file. This includes source code, configuration,
CI workflows, hook scripts, build scripts, and decision files. This is
proactive. Do not wait for the user to ask.

REQUIRED ACTIONS:
1. Use the Agent tool to delegate to wr-architect:agent
   (subagent_type: "wr-architect:agent")
2. The architect will review proposed changes against existing decisions
   in docs/decisions/ and flag when new decisions should be documented
3. Do NOT edit project files without architect review FIRST
4. Do NOT skip this step even if you think you can handle it yourself

5. When in plan mode, review the plan file against existing decisions
   in docs/decisions/ before calling ExitPlanMode

6. Before proposing implementation options or alternatives to the user
   (e.g., "Option A vs Option B", "where should this logic live?"),
   consult the architect agent FIRST. Present only architect-approved
   options. Do NOT present options that violate existing decisions.

7. If the architect reports ISSUES FOUND, resolve the issues and
   re-run the architect before editing. Do NOT proceed with edits
   while issues are outstanding.

SCOPE: All project files including source code, configs, CI, hooks,
scripts, and decisions.
Does NOT apply to: CSS/SCSS files, image assets, lockfiles, font files,
docs/problems/ (problem tickets), docs/BRIEFING.md, RISK-POLICY.md,
.risk-reports/, .changeset/, memory files, plan files, docs/jtbd/,
docs/JOBS_TO_BE_DONE.md, docs/PRODUCT_DISCOVERY.md, docs/VOICE-AND-TONE.md,
docs/STYLE-GUIDE.md.
HOOK_OUTPUT
else
  cat <<'HOOK_OUTPUT'
NOTE: This project has no docs/decisions/ directory.
If the user's task involves structural or technology decisions, consider
asking whether they'd like to create an architecture decision record
by delegating to wr-architect:agent.
HOOK_OUTPUT
fi
