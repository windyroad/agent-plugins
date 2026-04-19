# Problem 014: No lightweight aside invocation for governance skills (problems, retros, ADRs)

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: XL — likely new ADR (aside-invocation pattern for governance skills), cross-package coordination (itil + retrospective + architect), per-skill stub template design, intake-flow split (L → XL 2026-04-19 per P047: multi-day, cross-package, new ADR likely)
**WSJF**: 1.5 — (12 × 1.0) / 8

## Description

There is no lightweight way to invoke a governance artefact skill (problem-capture, retrospective, ADR creation) while working on something else. Today, invoking `/wr-itil:manage-problem`, `/wr-retrospective:run-retro`, or `/wr-architect:create-adr` consumes the current turn: each pulls the full skill into context, walks a multi-step intake, and displaces whatever task was in flight. In practice this means real-time discoveries ("I notice Y while working on X", "we should retro this later", "that's a decision worth recording") either derail the main task, or go uncaptured and get forgotten.

The desired behaviour is `/btw`-style: **working on X, notice Y, log Y as a stub, keep working on X, don't forget Y**. The aside should add cognitive load proportional to the thought being captured (one line), not proportional to the full skill's workflow.

This problem covers three known instances of the same pattern — but the pattern itself is the target. Resolving it one skill at a time would repeat the multi-concern failure mode captured in P016/P017.

**In-scope skills:**
- `/wr-itil:manage-problem` — log a problem noticed mid-task
- `/wr-retrospective:run-retro` — queue a retro without running the full wizard now
- `/wr-architect:create-adr` — stub an ADR when a decision is made but not ready to author

## Symptoms

- Users silently skip logging problems, queuing retros, or capturing ADRs mid-flow because the full intake is too heavy for a drive-by observation.
- When users do invoke these skills mid-task, the main task context is buried under multi-turn intake prompts (duplicate search, AskUserQuestion, architect/JTBD delegation, file writes). Recovery to the prior task is manual.
- Artefacts created mid-flow are often under-specified because the author is distracted; the full intake doesn't actually buy higher quality when the trigger was an aside.
- No convention for "stub" artefacts (problem, retro entry, ADR) — intentionally thin and expected to be fleshed out later at end-of-session or by a subsequent review pass.
- The three skills are solving the same pattern independently; whichever lands first risks setting a narrow precedent the others then don't fit.

## Workaround

- Take a note in conversation and rely on end-of-session retro to capture it (fragile — retro may not run; session may end abruptly).
- Ask the user to do it (breaks the "don't interrupt them either" goal).
- Write a free-form todo memory entry (pollutes memory with transient items).

None of these produce a real artefact with an ID, priority, or a home in `docs/`.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — "without slowing down" is exactly this tension, and it applies to problems, retros, and ADRs equally.
  - Tech-lead persona (JTBD-201 Restore Service Fast) — noticing latent problems + capturing decisions during incidents is common; aside capture matters more under time pressure.
  - Plugin-developer persona (JTBD-101) — inconsistent mid-task invocation across governance skills makes "clear patterns" harder.
- **Frequency**: Every non-trivial session. Real work surfaces multiple noticed-in-passing observations across all three categories.
- **Severity**: High. The suite's entire governance discipline depends on capture being cheap. If capture is expensive, capture stops happening across every artefact type, and the discipline silently erodes.
- **Analytics**: N/A. Observed this session in two user statements:
  - "is there a way to run skills like `/wr-itil:manage-problem` as an aside, similar to how `/btw` works?"
  - "`/wr-retrospective:run-retro` is another one that would be handy to run in the background, or with as little interruption to the main flow as possible. Same for creating ADRs."

## Root Cause Analysis

Three contributing factors:

1. **Skill invocation is turn-consuming by design.** Claude Code slash commands and Skills occupy the current turn. There is no built-in dispatcher that runs a skill in a side-channel and returns control to the prior task. ADR-011 covers cross-skill invocation (skill-to-skill), not user-initiated mid-turn asides.
2. **No skill has a capture-only mode.** Every governance skill (manage-problem, run-retro, create-adr) assumes the user intends to do full intake. None have a "just stub it and remind me later" mode. Even if an aside mechanism existed, each skill would still be heavyweight.
3. **No shared aside pattern.** If each skill solves this independently, the three implementations will diverge. A shared "aside invocation" pattern (hook, shim, or stub-mode protocol) applied consistently across governance skills is the right abstraction level.

### Investigation Tasks

- [ ] Decide the aside mechanism — must work for all three skills, not one. Options: (a) a capture-only sub-skill per governance skill (`manage-problem-stub`, `retro-stub`, `adr-stub`) sharing a common stub-file protocol; (b) a single cross-plugin `/btw` or `/aside` command that dispatches to the appropriate skill's stub-mode based on keyword; (c) sub-agent dispatch via the Agent tool that runs the full flow in isolated context and returns a one-line receipt; (d) hook-driven capture that writes a stub file from a single user line without invoking Claude at all.
- [ ] Author ADR — now scoped to the full pattern, not just problems. Candidate path: `docs/decisions/012-aside-invocation-pattern.proposed.md` (renamed from the narrower `-capture-` title). Must cover: invocation mechanism; how control returns to the main turn; stub-vs-full artefact contract shared across problems/retros/ADRs; interaction with ADR-011's `Skill`-tool handoff (don't fork the full skills); tension with P016/P017 (intake-splitting adds friction — P014 wants less friction; the pattern must resolve both).
- [ ] Design the stub file contract per artefact type:
  - **Problem stub**: `## Description` + `Reported` + Status=Open + `needs-triage` marker. `manage-problem review` finishes intake later.
  - **Retro stub**: one-line observation + trigger context. `run-retro` ingests queued stubs when next invoked.
  - **ADR stub**: `## Context` + decision headline + Status=draft. `create-adr` expands when author is ready.
- [ ] Define the command surface. Per-skill aside (`/wr-itil:capture`, `/wr-retrospective:capture`, `/wr-architect:capture`) or one dispatcher (`/btw <kind>: <one-liner>`)? Naming falls under ADR-010's scope.
- [ ] Resolve tension with P016/P017. Those problems want MORE intake rigor (split multi-concern inputs). P014 wants LESS. Pattern must allow both: aside creates a stub; later "review" pass runs the full intake including concern-splitting on the queued stubs.
- [ ] Create reproduction tests: simulate sessions where the user types the aside mid-task for each artefact type; verify (1) the stub is created, (2) the main task context is preserved, (3) a subsequent full-skill invocation picks up and completes the stub.

## Related

- User questions this session (two triggers, two skills):
  - "is there a way to run skills like `/wr-itil:manage-problem` as an aside, similar to how `/btw` works?"
  - "`/wr-retrospective:run-retro` is another one that would be handy to run in the background... Same for creating ADRs."
- ADR-011 (proposed): `docs/decisions/011-manage-incident-skill.proposed.md` — cross-skill invocation via `Skill` tool; neighbour pattern but not user-initiated asides
- ADR-010 (proposed): `docs/decisions/010-plugin-command-naming.proposed.md` — command surface naming
- ADR-002 (proposed): `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — skill inventory/layout
- Tension: `docs/problems/016-manage-problem-should-split-multi-concern-tickets.open.md` — wants more intake rigor
- Tension: `docs/problems/017-create-adr-should-split-multi-decision-records.open.md` — wants more intake rigor
- Affected skills:
  - `packages/itil/skills/manage-problem/SKILL.md`
  - `packages/retrospective/skills/run-retro/SKILL.md`
  - `packages/architect/skills/create-adr/SKILL.md`
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
- JTBD-201: `docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`
