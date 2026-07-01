# Problem 045: Auto plugin install on user's machine after governance release

**Status**: Open
**Reported**: 2026-04-19
**Reopened**: 2026-07-02
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 (Likely) = 12. **Re-rated at reopen from observed evidence, NOT deferred.** Impact 3 (up from 2): the gap does not merely delay a fix — it silently **re-introduces already-closed bugs** into a live session (witnessed 2026-07-01: a stale 0.51.0 cache ran the pre-ADR-067 capture-problem template and leaked the exact uncadenced deferred-placeholder default P375 had retired → P402). Likelihood 4 (up from 3): occurs on every session that starts before picking up a release; concretely witnessed.
**Effort**: L — cross-plugin shared SessionStart hook (packages/shared, synced to all `@windyroad/*` plugins) + tests + release. WSJF = (12 × 1.0) / 4 = 3.0.

## Reopened 2026-07-02 — closed on a P375-antipattern

**Why reopened (user direction, 2026-07-02):** the 2026-05-31 closure substituted the **on-demand** `/install-updates` skill (+ the AFK-loop Step 6.5 refresh) for the **self-firing startup check** this ticket's own Direction decision (2026-04-20) and ADR-034 specify. Both substitutes are on-demand — neither self-fires — so by the [[feedback_named_re_entry_is_not_self_firing_cadence]] / P375 rot test the closure was invalid: it credited a named-but-uncadenced re-entry as "handled." The startup-check hook `packages/itil/hooks/session-start-update-check.sh` that this ticket says it "closes when [it] ships" **was never shipped** (verified 2026-07-02: no SessionStart hook surfaces plugin staleness anywhere in `packages/*/hooks`).

**Consequence that forced the reopen:** P402 (`docs/problems/open/402-*.md`) — a session silently running stale plugin code re-introduced a retired bug. This ticket is the structural fix; P375 is the class.

**Landing:** RFC-framed per ADR-071 (Problem→RFC trace) — see `## RFCs` — building on the existing ADR-034 design (SessionStart hook + consent gate), refined to the network-free class-B surfacer shape (each plugin's hook reads its own version from its script path, compares to highest-installed cache, surfaces a one-line "restart to pick up X" nudge when behind).

## Prior closure (SUPERSEDED 2026-07-02 — see Reopened section above)

**Closure date**: 2026-05-31 (foreground relevance-scan session, user-confirmed)
**Closure reason**: implementation-shipped — `/install-updates` skill exists and is the operational path for picking up new plugin code; wired into the work-problems Step 6.5 post-release cache refresh (P233).
**Evidence (per ADR-026 grounding + ADR-079 evidence-based relevance-close pass)**:
- `scripts/repo-local-skills/install-updates/SKILL.md` exists (verified `ls`)
- `packages/itil/skills/work-problems/SKILL.md` Step 6.5 "Post-release cache refresh (P233)" subsection wires `/install-updates` into the orchestrator after a within-appetite release drain
- User actively runs `/install-updates` at end-of-session per the install-updates skill's documented contract
- The skill resolves the practical concern this ticket described (active session running old code after release); the original "auto-install via queue file + startup check" mechanism was superseded by the simpler "user runs `/install-updates` at end-of-session, orchestrator runs it after AFK releases" pattern
- Outstanding sub-concerns (PATH-ordering — P343 captured the residual; per-project auto-install via ADR-034 SessionStart — P299 / P297 captured those) are sibling tickets, not part of this umbrella

**Relevance evidence shape**: implementation-shipped-via-different-shape (the "auto" half landed as orchestrator-cadenced + user-cadenced rather than full session restart)
**Authorising decision**: P346 user direction 2026-05-31; user confirmed P045 in the foreground relevance-scan batch.

## Direction decision (2026-04-20, user — AFK loop stop-condition #2)

**Install mechanism**: **Deferred install on next session start**. After release lands on npm, queue the install rather than restarting the active session. Claude Code picks up the new plugin code on next session start. This avoids destabilising in-progress sessions (including AFK loops that are mid-iteration).

Implication: the fix needs (1) a queue mechanism (e.g., a file under `~/.claude/plugins/pending-install/` or similar) that the auto-release step writes to, (2) a startup check that runs `claude plugin install` for queued packages before the first turn, (3) a user-facing log/status so the user knows the current session is still on the old code and the next session will have the fix. The option to auto-restart the active session is **explicitly rejected**.

Open sub-questions (not blocking, can be resolved at implementation time): does Claude Code expose a session-start hook? If not, does `claude plugin install` on first terminal interaction suffice? These are implementation details for the ADR draft, not direction questions.

## Interim stopgap (2026-04-20, ADR-030)

Until the automated queue + startup-check is built, a user-invoked **repo-local skill** `.claude/skills/install-updates/` serves as the manual stopgap. `/install-updates` refreshes the marketplace cache, detects which `@windyroad/*` plugins are enabled in the current project + each sibling project, and re-installs them with `--scope project` after a consent-gated `AskUserQuestion` listing detected siblings. ADR-030 documents the repo-local-skill pattern used here. The stopgap does NOT close P045 — it narrows the remaining scope to the automated queue.

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

## Decision record

**ADR-034** (Auto-install on next session start — SessionStart hook + per-project consent gate) — drafted 2026-04-21. SessionStart hook in `packages/itil/hooks/session-start-update-check.sh` detects outdated `@windyroad/*` plugins. Consent marker per project at `.claude/.auto-install-consent` (preserves ADR-004 isolation). Absent consent → systemMessage only (ADR-013 Rule 6 fail-safe). Present consent → background-capture `/install-updates` via ADR-032 pattern (ADR-013 Rule 5 policy-authorised). AFK-launched sessions defer the check (ADR-032 + ADR-018 + ADR-019 carve-out mirrored). Consent granted interactively at the end of a successful `/install-updates` run.

This ticket (P045) remains **Open** as the execution tracker. Closes when:
- `packages/itil/hooks/session-start-update-check.sh` ships with `@windyroad/itil`.
- `.claude/skills/install-updates/SKILL.md` gains the consent-grant AskUserQuestion step at the end of its flow.
- Consent marker file format landed + bats coverage.
- AFK-launch detection envvar convention standardised (coordination with ADR-019 execution ticket).
- Plugin manifest for `@windyroad/itil` declares the SessionStart hook.

## Related

- **ADR-034** (Auto-install on next session start) — decision record for this ticket. Closes the design question.
- P028: `docs/problems/028-governance-skills-should-auto-release-and-install.known-error.md` — parent; auto-release concern stays there and is fixed by ADR-020
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — lean release principle (commit layer)
- ADR-018: `docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md` — AFK release cadence (push/release layer)
- ADR-020: (to be created alongside P028 fix) — governance auto-release for non-AFK flows (release layer for governance)
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md` — "under 60 seconds" target; auto-install is the final mile
- JTBD-005: `docs/jtbd/solo-developer/JTBD-005-assess-on-demand.proposed.md` — must not leave task context
- JTBD-003: `docs/jtbd/solo-developer/JTBD-003-compose-guardrails.proposed.md` — composition may also benefit from seamless install

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-036 | proposed | SessionStart plugin-staleness surfacer |
