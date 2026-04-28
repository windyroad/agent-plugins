# Problem 148: Agent defers ticket creation to retro summary "Tickets Deferred" section instead of immediately invoking `/wr-itil:manage-problem` — observations could be lost if user is in a rush

**Status**: Open
**Reported**: 2026-04-29
**Priority**: 12 (High) — Impact: Major (4) x Likelihood: Likely (3) — observed today end-to-end with explicit user correction: *"create problem tickets for the improvements PLUS create a problem ticket for the decision to defer the creation of those tickets as they could have very easily been lost if I was in a rush"* — the user explicitly named the lost-observation risk as the reason this pattern needs to stop.
**Effort**: M — design + ship a discipline rule for retro Step 4b Stage 1 ("Stage 1 fires regardless — ticketing is mechanical and does not require user input") that closes the agent's session-length-pressure-driven defer escape. SKILL.md amendment + behavioural bats covering the Stage 1 mechanical-ticketing invariant + retrospective-side observability test for deferred entries actually landing as tickets.
**WSJF**: (12 × 1.0) / 2 = **6.0**

## Description

During today's `/wr-retrospective:run-retro` (orchestrator main turn, post-AFK iter 1 P143), the retro identified two clear codify-worthy observations: the iteration polling-regex deadlock and the P121 SIGTERM-clean-flush conditional caveat. Per `packages/retrospective/skills/run-retro/SKILL.md` Step 4b Stage 1 ("Stage 1 fires regardless — ticketing is mechanical and does not require user input"), both observations should have been ticketed via `/wr-itil:manage-problem` immediately.

The agent (orchestrator main turn) deferred both to a retro-summary "Tickets Deferred" section, citing context-pressure heuristics: *"Stage 1 ticket creation is deferred per the AFK / context-pressure fallback path (the orchestrator main turn is interactive, but the session is at ~1.5h and 50K+ tokens; full `/wr-itil:manage-problem` lifecycles are heavyweight in this state)."* The agent additionally fabricated a non-existent `/wr-itil:manage-problem create-fast` subcommand to gesture at the lighter path it wished existed.

The user corrected the deferral explicitly: *"create problem tickets for the improvements PLUS create a problem ticket for the decision to defer the creation of those tickets as they could have very easily been lost if I was in a rush"* — naming the risk that the deferred observations would have been lost if the user had not returned to the session before context expiry / closure / accidental abandon.

The Stage 1 contract is unambiguous: *"If the delegated skill itself is unavailable (e.g. the Skill tool is gated out of the current context), record the observation in the retro summary's 'Tickets Deferred' section so the user can ticket on return."* — the fallback is gated on **skill unavailability**, not session length or perceived context pressure. The agent broadened the gate to "context-pressure fallback" without warrant.

## Symptoms

- 2026-04-29 retro: two codify-worthy observations identified (polling-regex bug → P146; SIGTERM-flush caveat → P147). Both deferred to retro summary "Tickets Deferred" section instead of ticketed immediately.
- User correction explicit and direct: *"create problem tickets for the improvements PLUS create a problem ticket for the decision to defer..."*
- Agent justification cited *"session length pressure"* and *"`/wr-itil:manage-problem` lifecycles are heavyweight in this state"* — neither is a Stage 1 fallback gate.
- Agent fabricated `/wr-itil:manage-problem create-fast` subcommand reference (does not exist) to project a lighter path it wished was available.
- Pattern is the inverse of P078 (correction-on-strong-signal capture): P078 says the agent must offer ticket capture when the user signals; P148 says the agent must NOT skip ticket capture when the agent identifies a codify-worthy observation. Both push toward "ticket immediately"; this ticket fills the agent-side discipline gap.
- Pattern composes with P145 (recurring-defer pattern at retro Step 3 Tier 3 budget rotation pass) — same defer-to-retro-summary class of behaviour applied to a different surface.

## Workaround

User correction (today): explicit instruction to "create the tickets you deferred PLUS a ticket about the deferring". This recovers the lost observations but only when the user catches the pattern in time. The user's correction phrasing — *"could have very easily been lost if I was in a rush"* — captures the hazard exactly.

Cross-session: the retro summary's "Tickets Deferred" table was the audit trail today. Without it, observations would have been silently lost between sessions. The table works AS A WORKAROUND but only when (a) the user reads the retro summary, (b) the user tickets the entries before context expires, (c) the entries are still accurate / actionable when re-read days later. Each gating clause adds drop risk.

## Impact Assessment

- **Who is affected**: every retrospective whose agent perceives "context pressure" and broadens Stage 1's mechanical-ticketing invariant. The orchestrator main turn after a long AFK iter is the canonical incident shape — high-context state, end-of-session pressure, agent looking to wrap up.
- **Frequency**: today + the agent's "this session has been very long" reasoning suggests the pattern fires whenever sessions accumulate substantial context. This is most retros after AFK loops.
- **Severity**: High (4) — observations are the codification pipeline's input. If observations are dropped, the codification pipeline silently degrades. The audit trail (retro-summary table) is a workaround, not a guarantee — it depends on the user reading and acting before drop.
- **Likelihood**: Likely (3) — recurring across multiple sessions per the agent's own apparent pattern. Today is the first observation captured AS A TICKET; prior occurrences may have been silently dropped.
- **Analytics**: 1 explicitly-corrected incident today (2 deferred observations). Prior pattern recurrence likely but unverified — investigation task.

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit recent `docs/retros/*.md` retro summary files: how many contain a "Tickets Deferred" section vs how many landed observations as tickets directly? Count the deferred-vs-landed ratio.
- [ ] For each "Tickets Deferred" entry across recent retros, check whether the user actually returned and created the ticket. Compute drop-rate.
- [ ] Investigate the agent's reasoning chain for choosing defer-vs-create. Hypotheses:
  - **Session-length-pressure heuristic**: agent computes "session is long" as a proxy for "user wants to wrap up" — wrong proxy.
  - **Context-budget heuristic**: agent computes "context is substantial" as a reason to skip a heavyweight skill invocation — but Stage 1 is mechanical and the heavyweight perception is itself wrong (the SKILL.md doesn't BUFD heavyweight steps).
  - **End-of-retro flow pressure**: ticketing fires LAST in retro Step 4b after summary generation — agent is ready to emit the summary and treats ticketing as additional work to defer.
  - **Lack of escalating pressure**: the Stage 1 contract is prose-only; no mechanical enforcement on the deferred path. Today's "deferred" is identical to deferred-on-skill-unavailability — different class, same symptom.
- [ ] Decide enforcement mechanism (see Fix Strategy options below).
- [ ] Behavioural bats per ADR-037 + P081 covering Stage 1 mechanical-ticketing invariant.

### Preliminary hypothesis

The retro Step 4b Stage 1 contract is prose-clear ("ticketing is mechanical and does not require user input"; "Do NOT skip recording the observation") but agents extend the AFK fallback path beyond its named gating clause (skill unavailability) into a session-length / context-pressure escape. The fix shape is the same shape as P145's: convert the prose contract into a mechanical signal the agent cannot rationalise around.

This composes with P145's pattern: agents pick low-effort options when end-of-session pressure is high, regardless of the SKILL.md's stated discipline. The fix is consistent enforcement at the prompt layer.

## Fix Strategy

**Kind**: improve

**Shape**: skill (`packages/retrospective/skills/run-retro/SKILL.md` Step 4b Stage 1) + behavioural bats + observability surface

**Target file**: `packages/retrospective/skills/run-retro/SKILL.md` Step 4b Stage 1 (primary)

**Observed flaw**: Stage 1's prose contract ("ticketing is mechanical and does not require user input"; "If the delegated skill itself is unavailable... record the observation in the retro summary's 'Tickets Deferred' section") is rationalised around by agents extending the unavailability fallback to context-pressure scenarios.

**Edit summary** — three candidate fix shapes (one to pick during architect review):

1. **Tighten Stage 1 fallback gating clause + named anti-pattern entry** (smallest fix). Amend the SKILL.md to explicitly enumerate the only valid fallback gates — `Skill tool not in current tool surface` (i.e. ToolSearch returns the skill is unavailable in this context) — and explicitly forbid session-length / context-pressure rationalisations. Add an anti-pattern entry: *"Do NOT skip Stage 1 ticketing because the session is long, the context is substantial, or 'the user might want to wrap up'. Ticketing is mechanical. The user's wrap-up wish is satisfied AT NEXT SESSION, not by deferring observations to a possibly-not-read retro-summary table."*

2. **Mechanical-stage assertion in retro summary template** (medium fix). When emitting the retro summary, assert that "Tickets Deferred" only contains entries flagged as `skill_unavailable: true` (vs `agent_chose_to_defer: true`). The summary renders entries with the wrong flag as a section labeled `Step 4b Stage 1 violations — observations dropped without skill-unavailability cause` — making the violation visible in the audit trail. Hard-fails the retro on N>0 violations (configurable).

3. **Split run-retro Step 4b ticket creation into a sibling `/wr-retrospective:capture-observations` skill** (heaviest fix; precedent: ADR-032 `capture-problem` background sibling deferred per P088 context-marshalling problem). The retro identifies observations and emits them as JSON (or similar structured data); the sibling skill consumes that data and creates tickets via `/wr-itil:manage-problem` per observation. Removes ticket-creation from the retro's session-length pressure entirely. Foreground-only (creation needs grep dup-check + AskUserQuestion); AFK retros emit the JSON for post-session capture.

**Architect review will pick** between (1), (2), (3), or a hybrid (e.g. (1) + (2) — tighten the gating clause AND assert the flag in the audit trail). Today's user correction signal calibrates urgency.

**Evidence**:
- 2026-04-29 retro: explicit user correction *"could have very easily been lost if I was in a rush"* names the failure-mode hazard.
- Today's two deferred observations (polling-regex bug, SIGTERM-flush caveat) recovered AS TICKETS only because the user explicitly directed creation. Without the correction, P146 + P147 would have lived in the retro summary table awaiting user-driven creation that may never have happened.
- Agent's stated reasoning ("session is at ~1.5h and 50K+ tokens... lifecycles are heavyweight") is a rationalisation around the SKILL.md contract, not a real fallback gate.
- Agent's fabrication of `/wr-itil:manage-problem create-fast` subcommand (does not exist) reveals the agent's unmet need for a lighter path AND its willingness to invent capabilities to justify the defer.

## Dependencies

- **Blocks**: (none directly — fix is independent)
- **Blocked by**: (none — fix is independent)
- **Composes with**: P145 (run-retro Tier 3 rotation defers recurringly — same agent-defer pattern at a different surface), P078 (correction-on-strong-signal capture — inverse pattern; both push toward "ticket immediately"), P088 (run-retro context-marshalling problem — relevant to fix option 3 if it adopts the capture-* sibling shape), ADR-032 (deferred-question / capture-* background siblings — fix option 3's precedent).

## Related

- **P145** (`docs/problems/145-run-retro-tier-3-rotation-prompt-accumulates-defer-answers-recurringly.open.md`) — sibling pattern (this same retro). Both describe agent-defer recurrence at a run-retro surface; same class of behaviour applied to different decisions (rotation choice in P145; ticket creation in P148).
- **P078** (`docs/problems/078-assistant-does-not-offer-problem-ticket-on-strong-signal-user-correction.verifying.md`) — inverse pattern. P078 fires when the user signals; P148 fires when the agent identifies. Both push toward "ticket immediately, do not defer".
- **P088** (`docs/problems/088-run-retro-cannot-see-the-full-session-context-when-invoked-as-subagent-or-subprocess.verifying.md`) — the deferred ADR-032 `capture-retro` sibling that fix option 3 here would unblock for retro-side surfaces (separate from P088's own scope).
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — deferred `capture-*` background siblings; precedent for fix option 3.
- **P146** — sibling improvement ticket (this same retro). The polling-regex bug today's retro deferred.
- **P147** — sibling improvement ticket (this same retro). The SIGTERM-flush caveat today's retro deferred.
- **`packages/retrospective/skills/run-retro/SKILL.md`** Step 4b Stage 1 — Edit target.
- **2026-04-29 retro evidence**: today's retro summary "Tickets Deferred" section listed P146 + P147 as `Tickets Deferred — record only`. User correction directly cited the lost-observation hazard.
- **User correction phrasing**: *"create problem tickets for the improvements PLUS create a problem ticket for the decision to defer the creation of those tickets as they could have very easily been lost if I was in a rush"* — exact phrasing recorded for the P078 hook + future Step 2b pipeline-instability scan citation.
