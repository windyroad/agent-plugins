# Problem 460: Agent surfaces ticket-worthy findings and obvious next-actions as recommendations instead of autonomously capturing or acting

**Status**: Open
**Reported**: 2026-07-25
**Priority**: 12 (High) — Impact: 3 (Moderate — erodes user trust and re-imposes the manual-policing-the-AI friction the suite exists to remove) × Likelihood: 4 (Likely — recurred repeatedly within a single session) — derived at capture
**Origin**: internal
**Effort**: L — behavioural-discipline defect; a durable fix is a shipped surface (detector/SKILL-contract/eval), not a memory note — same class as P423
**WSJF**: 3 — (12 × 1.0) / 4 (added 2026-07-26 review)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The agent repeatedly surfaces ticket-worthy findings and obvious, within-appetite next-actions to the user as *recommendations* — "worth capturing", "you should decide", "want me to…", "flagged for you" — instead of autonomously capturing the ticket or performing the action and reporting it done.

User correction 2026-07-25 (verbatim): *"'Real bugs surfaced this session, uncaptured' I shouldn't have to ask you to capture these."* Immediately prior, the same session's sitrep listed adopter-portability regressions and a "new defect" as items for the user to action, and closed multiple turns with consent-gate prose ("which would you like?", "want me to…") for work that was obvious within the documented risk appetite.

This is the mirror of P078 (offer-capture-on-*correction*): the agent should also capture findings it *itself surfaces* during any work, and act on obvious next-steps, reserving user-facing surfacing for the genuine direction / deviation-approval / taste decisions in the ADR-044 6-class taxonomy. The failure re-imposes exactly the "user manually polices AI output" friction the suite is built to remove.

## Symptoms

- Sitreps / wrap-ups end with a list of "recommendations" or "open items for you to decide" that are actually obvious mechanical next-steps within appetite.
- Findings discovered mid-task (a real bug, a lifecycle mis-file, a missing ticket) are reported as "worth capturing" rather than captured.
- Consent-gate prose ("want me to…?", "which would you like?") appears for actions the direction/policy already authorises (P085 class, but triggered by agent-surfaced findings rather than user prompts).

## Workaround

The user explicitly directs the capture/action each time — which is the friction this ticket is about.

## Impact Assessment

- **Who is affected**: the maintainer (has to notice and re-direct); erodes the AFK-autonomy value proposition
- **Frequency**: multiple times per long session
- **Severity**: Moderate — trust + throughput, not data loss
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

No surface enforces "capture-or-act on self-surfaced findings." P078 covers the correction-triggered capture offer, and ADR-044 defines when to surface vs act, but nothing catches the specific anti-pattern of ending a report with agent-surfaced findings left uncaptured/unactioned. Likely needs the same treatment as P423 — a shipped detector or SKILL/agent-contract surface (e.g. a Stop-hook scan for "recommendation without capture/action" in the agent's own output, or a review-turn discipline), not a memory note.

### Investigation Tasks

- [ ] Confirm scope vs P078 (correction-triggered) and ADR-044 (surface-vs-act taxonomy) — this is the self-surfaced-finding gap between them
- [ ] Decide the durable surface (Stop-hook output scan / SKILL wrap-up contract / behavioural eval) per P423's "ship a surface, not a memory" principle
- [ ] Create a behavioural repro/eval

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P179 (defers work into untracked phases), P423 (fixes via memory instead of shipping a surface), P078 (offer-capture on correction), P375/P377/P378 ("system holds the memory, not the user" cluster)

## Related

- P078 — offer-capture on user correction (the correction-triggered sibling; this is the self-surfaced-finding sibling).
- P179 — agent defers requested work into untracked phases.
- P423 — agent "fixes" recurring behavioural corrections via memory instead of shipping an adopter-facing surface (this ticket should adopt the same fix shape).
- ADR-044 — decision-delegation contract (when to surface vs act).

(captured via direct write; hang-off considered — sibling to P179/P423/P078, distinct mechanism, so captured new)
