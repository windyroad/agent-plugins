# Project: windyroad-claude-plugin

Plugin-development monorepo publishing `@windyroad/*` Claude Code plugins and Codex-compatible plugin surfaces by Windy Road Technology. Claude Code remains the default runtime until Codex parity is proven.

`docs/agent-instructions/shared-governance.md` is the runtime-neutral source for shared behavioral rules. Keep this file aligned with `CLAUDE.md` through `npm run check:agent-instructions`; do not weaken a rule in one runtime without updating the other.

**MANDATORY - act on obvious, request_user_input for ambiguous, never prose-ask**: when the user has pinned a direction (yes / go / proceed / act / just do it) or the next step is obvious from session context or RISK-POLICY.md appetite, act and report. When genuinely ambiguous in Plan Mode, use `request_user_input`. Outside Plan Mode, ask one concise direct question only when no reasonable assumption is safe. Do not prose-ask with decorative option lists when a structured question is available.

**MANDATORY - capture on correction**: when the user delivers a strong-signal correction, offer to capture a problem ticket via the ITIL problem flow before addressing the operational request. Treat the correction as a durable class-of-behaviour signal.

**MANDATORY - never write project-generated artefacts under `.codex/` or `.claude/`**: runtime config directories are user/runtime-controlled config space. Generated plans, audit logs, scratch state, briefing artefacts, and agent-output dumps belong under `docs/` or directly inline in problem-ticket bodies. Generated runtime surfaces that are intentionally checked in, such as `.codex/agents/wr-architect.toml`, must be produced by repo sync scripts and guarded by tests.

**MANDATORY - when a SKILL contract names a stage as mechanical, do not ask**: when a SKILL stage is mechanical, no user decision, policy-authorised silent proceed, agent-owned silent classification, or silent agent action, do not call `request_user_input` or add a prose consent gate. The framework already resolved the decision.

**MANDATORY - user direction is not substance ratification**: when applying a user-directed edit to a governance artefact outside the ratifying skill flows, brief the actual change before writing a confirmed human-oversight marker. In non-interactive `codex exec` runs, write or preserve `human-oversight: unconfirmed` and queue ratification instead of guessing.
