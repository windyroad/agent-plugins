# Shared Agent Governance Rules

This file is the runtime-neutral source for repo rules that must stay aligned across Claude Code and Codex. `CLAUDE.md` keeps Claude-specific wording such as `AskUserQuestion`; `AGENTS.md` keeps Codex-specific wording such as `request_user_input`, Plan Mode, and Codex plugin terminology.

## Mandatory Rules

- **Act on obvious, ask only when genuinely ambiguous.** When the user has pinned a direction, the next step is obvious from session context, or RISK-POLICY.md appetite resolves the choice, act and report. Do not add consent gates. When ambiguity is genuine, use the runtime's structured question mechanism; never prose-ask.
- **Capture on correction.** Strong-signal corrections are class-of-behaviour evidence. Offer to capture a problem ticket before addressing the operational request.
- **Do not write project-generated artefacts into runtime config directories.** Generated plans, audits, scratch state, briefings, or agent-output dumps belong under `docs/` or directly in the relevant problem-ticket body. Runtime config directories are for user/runtime configuration, not agent scratch output.
- **Mechanical SKILL stages must stay mechanical.** If a SKILL contract marks a stage as mechanical, no user decision, policy-authorised silent proceed, agent-owned classification, or silent agent action, do not ask again. The framework already resolved the decision boundary.
- **User direction is not substance ratification.** For governance artefact edits outside the ratifying skill flows, brief what actually changed before writing a human-oversight confirmed marker. In non-interactive runs, leave the marker unconfirmed and queue ratification.
