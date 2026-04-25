# Problem 119: Agent bypasses `/wr-itil:manage-problem` Step 2 duplicate-check by writing tickets directly to `docs/problems/`

**Status**: Open
**Reported**: 2026-04-25
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: S
**WSJF**: (12 × 1.0) / 1 = **12.0**

> Surfaced 2026-04-25 in `/wr-retrospective:run-retro` Step 4b Stage 1 as a codification candidate. This session shipped three duplicate problem tickets (P119/P120/P121, since deleted) by writing directly to `docs/problems/` via the Write tool instead of invoking `/wr-itil:manage-problem`. All three were near-perfect duplicates of P038 and P064 — both Open since 2026-04-17 with ADR-028 already landed 2026-04-21 — and were caught only after an unrelated user prompt triggered a manual grep that surfaced the existing tickets.

## Description

`/wr-itil:manage-problem` Step 2 ("For new problems: Check for duplicates FIRST") is the canonical duplicate-prevention surface for this repo's problem backlog. The Step 2 contract: extract keywords, grep `docs/problems/` filenames + bodies, present matches via `AskUserQuestion`, switch to update flow if the user picks an existing ticket. This works correctly when the skill is invoked.

The gap is structural: there is no enforcement that `docs/problems/<NNN>-<title>.open.md` files MUST be created via the skill. The agent can call the Write tool directly with any path, and no PreToolUse hook intercepts new-file creation under `docs/problems/`. The skill is advisory by convention; the enforcement layer is missing.

This produces a recurring duplicate-creation pattern: the agent observes something codify-worthy mid-task (e.g. inside a retrospective, a session-wrap summary, or a long investigation), instinctively reaches for the Write tool to capture it inline, ships a `.open.md` file, and only later discovers the concept was already tracked. Cleanup is mechanical (file deletes + evidence-merge) but the duplicates corrupt the audit trail in flight, distort the WSJF queue if not caught immediately, and burn user attention on triage.

## Symptoms

- New `.open.md` files appear in `docs/problems/` whose titles overlap concept-space with existing Open / Known Error tickets, with no record of a Step 2 grep having run.
- `docs/problems/README.md` Last-reviewed line records the new ticket but with no audit-trail evidence that duplicate-check fired.
- Cleanup commits (`rm` of just-created tickets + evidence-append to surviving tickets) appear in the same session as the create, indicating the duplicate was caught reactively not preventively.
- The agent's session log shows direct Write calls to `docs/problems/<NNN>-*.open.md` rather than `Skill { wr-itil:manage-problem ... }` invocations.
- Observed 2026-04-25: P119/P120/P121 created via Write, deleted within the same conversation turn pair after user prompt led to manual grep that found P038/P064 as the actual home.

## Workaround

Manual discipline: the agent must remember to invoke `/wr-itil:manage-problem` for any new ticket creation. Brittle — relies on the agent recalling the contract every time, which empirically fails in retrospective / wrap-up contexts where the agent is already mid-thought on a captured observation. The same memory failure mode P078 covers for user-correction-triggered tickets applies here for agent-observation-triggered tickets.

## Impact Assessment

- **Who is affected**:
  - **solo-developer persona** (JTBD-001 — enforce governance without slowing down) — duplicate triage shifts to the user when the agent ships duplicates that should have been caught at create-time.
  - **tech-lead persona** (JTBD-201 — restore service fast with audit trail) — the WSJF queue temporarily lies when duplicates are present; ranking decisions made on a duplicated queue are not defensible post-hoc.
  - **AFK orchestrator (JTBD-006)** — work-problems iterating a backlog with duplicates wastes iteration budget on near-identical work; cleanup-after-the-fact compounds with the iteration cost.
- **Frequency**: every codify-worthy observation the agent encounters mid-task that doesn't route through the skill. Empirically: 3 duplicates in one session (2026-04-25).
- **Severity**: Moderate. Not a runtime breakage; not a release-impact issue; but a recurring backlog-quality defect that corrodes the WSJF queue's signal-to-noise ratio. The trust loss is comparable to P078's.
- **Analytics**: 2026-04-25 session — 3 duplicates created, all 3 deleted within the same conversation turn pair after user prompt triggered manual grep. Cleanup cost: 3 file deletes + 2 evidence-append edits to surviving tickets (P038, P064) + retroactive duplicate-grep across the docs/problems/ surface.

## Root Cause Analysis

### Structural

`packages/itil/skills/manage-problem/SKILL.md` Step 2 is the canonical duplicate-prevention surface, but it only fires when the skill is invoked. There is no PreToolUse hook in `packages/itil/hooks/` that intercepts Write to new files under `docs/problems/`.

The agent's default capture instinct in retrospective / wrap-up contexts is to reach for Write directly — particularly when capturing multiple related observations in quick succession (the 2026-04-25 P119/P120/P121 case: three back-to-back Write calls without a single Skill invocation between them). This is the same default-action pattern P085 covers for the prose-ask anti-pattern — once the agent has decided what it wants to write, it skips the gating step.

The hook-based enforcement pattern is well-established for similar concerns in this repo:
- `packages/voice-tone/hooks/voice-tone-enforce-edit.sh` gates Edit/Write to copy-bearing files on a voice-tone review marker.
- `packages/jtbd/hooks/jtbd-enforce-edit.sh` gates Edit/Write to project files on a JTBD review marker.
- `packages/risk-scorer/hooks/risk-policy-enforce-edit.sh` gates Edit/Write to RISK-POLICY.md on a risk-policy review marker.

A parallel `packages/itil/hooks/manage-problem-enforce-create.sh` matching `PreToolUse` on `Write` to `docs/problems/<NNN>-*.<status>.md` (when the file does not yet exist) would close the gap with the same shape. The marker would be set by the manage-problem skill itself when Step 2's grep completes.

### Investigation Tasks

- [ ] Architect review: confirm hook shape (PreToolUse Write matcher on docs/problems/ new-file path) and marker contract (set by manage-problem Step 2 completion). Decide: should the hook also gate Edit (e.g., status transitions outside the skill) or only new-file Write? Lean: Write only — Edit-to-existing is a different concern.
- [ ] Decide marker scope: per-session marker (cleared each session) vs per-grep marker (set by every Step 2 grep completion). Lean: per-grep, so a single session can create multiple unrelated tickets without re-grep blocking.
- [ ] Decide how the hook detects "is this a new file": `[ ! -f "$FILE_PATH" ]` is the natural check; needs to handle the same-turn case (file written then immediately re-edited).
- [ ] Decide failure-mode UX: `permissionDecision: deny` with message directing the agent to `/wr-itil:manage-problem`, parallel to existing review-gate.sh deny pattern.
- [ ] Prototype `packages/itil/hooks/manage-problem-enforce-create.sh` and add to `packages/itil/hooks/hooks.json`.
- [ ] Add bats coverage: simulate a Write to `docs/problems/999-foo.open.md` without prior Step 2 marker → expect deny. Then set marker → expect allow.
- [ ] Update `packages/itil/skills/manage-problem/SKILL.md` Step 2 to write the marker after the grep completes (analog to how voice-tone-eval.sh sets the voice-tone review marker after PASS).

### Fix Strategy

**Shape**: hook (PreToolUse Write matcher on `docs/problems/<NNN>-*.<status>.md` new-file paths) gating on a session marker set by manage-problem Step 2 completion. Parallel to existing `packages/{voice-tone,style-guide,jtbd}/hooks/*-enforce-edit.sh` pattern; reuses the `lib/review-gate.sh` infrastructure (or a sibling `lib/create-gate.sh` if the marker semantics differ enough).

**Target files (likely)**: new `packages/itil/hooks/manage-problem-enforce-create.sh`, update `packages/itil/hooks/hooks.json` to register the PreToolUse Write matcher, optionally extend `packages/itil/hooks/lib/` with a `create-gate.sh` helper, update `packages/itil/skills/manage-problem/SKILL.md` Step 2 to set the marker after grep, new bats test under `packages/itil/hooks/test/`.

**Marker placement**: aligns with the existing review-gate.sh marker convention — per-session under `~/.claude/.../session/<id>/`. Cleared at session boundaries.

**Out of scope**: Edit gating on existing tickets (handled by status-transition contract elsewhere). Gating on `Write` to `docs/problems/README.md` (the README is regenerated by manage-problem Steps 5/6/7 and write-gating it would be a chicken-and-egg).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P078 (assistant does not offer ticket on user correction) — same general "agent should route through manage-problem rather than handling tickets ad-hoc" gap class but different trigger (user correction vs. agent self-observation). Both fix paths are hook-based per ADR-024-style ownership; can ship independently.

## Related

- **P078** (`docs/problems/078-assistant-does-not-offer-problem-ticket-on-user-correction.open.md`) — sibling gap class. P078's trigger is user correction; this ticket's trigger is agent self-observation. Both warrant hook-based enforcement; P078 is on `UserPromptSubmit` / `Stop`, this one is on `PreToolUse:Write`.
- **P085** (`docs/problems/085-assistant-asks-when-obvious-and-uses-prose-instead-of-askuserquestion.verifying.md`) — same "agent default-action skips a contract step" pattern; P085 ships the prose-ask hook + CLAUDE.md combination as a precedent.
- **P016** (`docs/problems/016-manage-problem-should-split-multi-concern-tickets.verifying.md`) — concern-boundary analysis is the inverse problem: a single Write covering multiple concerns. This ticket's hook would also catch multi-concern bypass since a direct Write skips Step 4b's split prompt.
- **P070** (`docs/problems/070-report-upstream-does-not-check-for-existing-upstream-issues.open.md`) — same duplicate-prevention concern on a different surface (upstream issue creation). Different scope, same shape.
- `packages/itil/skills/manage-problem/SKILL.md` Step 2 — the duplicate-check this hook gates against.
- `packages/itil/hooks/hooks.json` — registration target.
- `packages/voice-tone/hooks/voice-tone-enforce-edit.sh`, `packages/jtbd/hooks/jtbd-enforce-edit.sh`, `packages/risk-scorer/hooks/risk-policy-enforce-edit.sh` — precedent enforce-gate hook shapes.
- `packages/itil/hooks/lib/` (if it exists; otherwise create) — host for any shared helper.
- ADR-009 (gate marker lifecycle) — the marker contract this hook follows.
- ADR-013 Rule 1 (AskUserQuestion for governance decisions) — the deny message should direct the agent to invoke the skill where Step 2 fires AskUserQuestion if duplicates exist.
- ADR-014 (governance skills commit their own work) — this hook does not commit; manage-problem already does.
- 2026-04-25 session evidence: this retro's `/wr-retrospective:run-retro` invocation; concrete duplicates were P119/P120/P121 (deleted) of P038/P064; commit 80e8e72 captures the cleanup-evidence pattern (update-over-create after Step 2 grep).
