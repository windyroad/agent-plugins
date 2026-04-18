# Problem 045: Auto plugin install on user's machine after governance release

**Status**: Open
**Reported**: 2026-04-19
**Priority**: 6 (Medium) — Impact: Minor (2) x Likelihood: Possible (3)
**Effort**: L
**WSJF**: 1.5 — (6 × 1.0) / 4

## Description

Split from P028 on 2026-04-19. P028 was originally scoped to cover both auto-release and auto-install. This ticket tracks the **auto-install** concern only; the auto-release concern stays in P028 and is being implemented under ADR-020.

When a governance skill fix completes and a release lands on npm (manually or via auto-release), the running Claude Code session does not pick up the new plugin code until the marketplace cache refreshes AND the plugin is re-installed AND the session is restarted. This means even with auto-release in place, the user's active session continues running the pre-fix code until they manually complete the install sequence.

Observed 2026-04-16 after P027 fix: user said "this should have released by itself. Maybe even installed." The auto-release half of that wish is being addressed by P028/ADR-020. The auto-install half lands here.

## Symptoms

- After a governance skill fix is committed, pushed, merged, and published to npm, the active Claude Code session continues running the old plugin code.
- Manual `claude plugin install <package>@windyroad --scope project` is required to pick up the new release.
- A session restart is also required for some plugin changes (skills, hooks) to take full effect.
- Invoking `claude plugin install` programmatically from within a skill succeeds but has session-restart side effects that can destabilise an in-progress Claude Code session.

## Workaround

Run manually: `claude plugin install <package>@windyroad --scope project` after release, then restart Claude Code. This is the status quo for all governance flows, AFK and non-AFK.

## Impact Assessment

- **Who is affected**: Solo-developer persona (JTBD-001, JTBD-005) — every governance fix session where the fix is meant to take effect immediately.
- **Frequency**: Every governance release where the user wants the fix to affect their current session.
- **Severity**: Minor (Impact 2) — the manual install is a single command and the workaround is well-understood. Unlike auto-release, there is no unreleased-WIP accumulation risk here; the release still lands on npm. Impact is limited to "my current session runs old code for a while".
- **Likelihood**: Possible (3) — occurs on every governance release. The risk of session destabilisation from mid-session install is what keeps this from being automated today.

## Root Cause Analysis

### Confirmed constraints (inherited from P028 investigation, 2026-04-18)

1. `claude plugin install` is shell-only; calling it from a skill via Bash is possible but has session-restart side effects (the running session does not pick up new code from a freshly-installed plugin without a restart).
2. Even when the install succeeds, Claude Code does not currently support in-session plugin reload. The user must restart their session to load the new skill/hook code.
3. Attempting to install-and-restart mid-session would abort the user's active work without warning — not acceptable for interactive sessions.

### Why this is deferred

This concern was intentionally split out of P028 on architect review (2026-04-19): auto-install is independent enough to warrant its own decision, and the constraints above make it **blocked on an upstream Claude Code capability** (in-session plugin reload) rather than a decision we can make today. Until that capability exists, safe auto-install in interactive sessions is not feasible.

For AFK loops specifically, a session-restart side effect is less disruptive because the loop is designed to resume from a scheduled tick. A narrower scope covering only AFK orchestrators may become viable before full in-session reload arrives.

### Investigation Tasks

- [ ] Monitor Claude Code releases for in-session plugin reload support. Un-park / re-rank this problem when that capability lands.
- [ ] If AFK-only scope becomes viable: design a post-release install step for `wr-itil:work-problems` (and any other AFK orchestrators) that re-installs affected plugins after a release lands, accepting the session-restart side effect as AFK-acceptable.
- [ ] Evaluate whether `claude plugin install` can be called with a flag that defers session-reload until next natural restart (would make interactive auto-install safe).
- [ ] Spike: scripted install + session restart from inside a skill — measure end-to-end behaviour in an AFK loop.

## Related

- P028: `docs/problems/028-governance-skills-should-auto-release-and-install.known-error.md` — parent; auto-release concern stays there and is fixed by ADR-020
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — lean release principle (commit layer)
- ADR-018: `docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md` — AFK release cadence (push/release layer)
- ADR-020: (to be created alongside P028 fix) — governance auto-release for non-AFK flows (release layer for governance)
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" target; auto-install is the final mile
- JTBD-005: `docs/jtbd/solo-developer/JTBD-005-assess-on-demand.proposed.md` — must not leave task context
- JTBD-003: `docs/jtbd/solo-developer/JTBD-003-compose-guardrails.proposed.md` — composition may also benefit from seamless install
