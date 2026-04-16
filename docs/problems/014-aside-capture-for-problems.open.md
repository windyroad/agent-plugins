# Problem 014: No lightweight aside capture for problems mid-task

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)

## Description

There is no lightweight way to log a problem while working on something else. Today, invoking `/wr-itil:manage-problem` consumes the current turn: it pulls the full problem-management skill into context, walks a multi-step intake, and displaces whatever task was in flight. In practice this means real-time discoveries ("I notice Y while working on X") either derail the main task, or go uncaptured and get forgotten.

The desired behaviour is `/btw`-style: **working on X, notice Y, log Y as a stub, keep working on X, don't forget Y**. The aside should add cognitive load proportional to the thought being captured (one line), not proportional to the full manage-problem workflow.

## Symptoms

- Users silently skip logging problems mid-flow because the full `manage-problem` intake is too heavy for a drive-by observation.
- When users do invoke `manage-problem` mid-task, the main task context is buried under several turns of duplicate-search, AskUserQuestion prompts, and file writes. Recovery to the prior task is manual.
- Problem tickets that *do* get created mid-flow are often under-specified because the author is distracted; the full intake surface doesn't actually buy higher quality when the trigger was an aside.
- No convention for "stub" problem files that are intentionally thin and expected to be fleshed out later (either at end-of-session retro or by `problem review`).

## Workaround

- Take a note in conversation and rely on end-of-session retro to capture it (fragile — retro may not run; session may end abruptly).
- Ask the user to do it (breaks the "don't interrupt them either" goal).
- Write a free-form todo memory entry (pollutes memory with transient items).

None of these produce a real ticket with an ID, WSJF score, or a home in `docs/problems/`.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — the "without slowing down" clause is the exact tension here.
  - Tech-lead persona (JTBD-201 Restore Service Fast) — noticing latent problems during incident response is common; capture-without-derailment matters more during incidents than in normal flow.
- **Frequency**: Every non-trivial session. Any meaningful work surface multiple noticed-in-passing issues.
- **Severity**: High. The project's entire problem-management discipline depends on capture being cheap. If capture is expensive, capture stops happening and the discipline silently erodes.
- **Analytics**: N/A. Anecdotally observed this session — user explicitly asked "is there a way to run skills like `/wr-itil:manage-problem` as an aside, similar to how `/btw` works?"

## Root Cause Analysis

Two contributing factors:

1. **Skill invocation is turn-consuming by design.** Claude Code slash commands and Skills occupy the current turn. There is no built-in dispatcher that runs a skill in a side-channel and returns control to the prior task. ADR-011 covers cross-skill invocation (skill-to-skill), not user-initiated mid-turn asides.
2. **`manage-problem` has no capture-only mode.** The skill assumes the user intends to do intake properly — it always runs duplicate search, AskUserQuestion, quality checks. A "just-stub-it-and-remind-me-later" mode does not exist. Even if an aside mechanism existed, the skill itself would still be heavyweight.

### Investigation Tasks

- [ ] Decide the aside mechanism. Options (not yet architect-approved): (a) capture-only sub-skill `manage-problem-stub` that writes a minimal `.open.md` with just title + one-line description + reported date, no AskUserQuestion, no duplicate search; (b) sub-agent dispatched via Agent tool that runs the full flow in an isolated context; (c) hook-driven capture that writes a stub file from a single user line without invoking Claude at all.
- [ ] Author ADR (architect flagged this as a pattern-setting decision — future plugins `wr-connect`, `wr-retrospective` will want the same ergonomics). Candidate: `docs/decisions/012-aside-capture-invocation-pattern.proposed.md`. Must cover: invocation mechanism, how control returns to the main turn, stub-vs-full artefact contract, interaction with ADR-011's `Skill`-tool handoff (don't fork `manage-problem`).
- [ ] Design the stub file contract: what minimum fields ensure `problem review` can pick it up and finish the intake later. Likely just `## Description` + `Reported` date + Status=Open + a `needs-triage` marker.
- [ ] Define the surface: is `/btw` the command, or `/wr-itil:capture`, or a convention like `p: <one-liner>` in a hook? Naming is part of ADR-010's scope.
- [ ] Create reproduction test: simulate a session where the user types the aside mid-task and verify the main task context is preserved.

## Related

- User question this session: "is there a way to run skills like `/wr-itil:manage-problem` as an aside, similar to how `/btw` works?"
- ADR-011 (proposed): `docs/decisions/011-manage-incident-skill.proposed.md` — cross-skill invocation via Skill tool; neighbour pattern but not the same problem
- ADR-010 (proposed): `docs/decisions/010-plugin-command-naming.proposed.md` — command surface naming
- ADR-002 (proposed): `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — skill inventory/layout
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-201: `docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`
- Related skill: `packages/itil/skills/manage-problem/SKILL.md`
