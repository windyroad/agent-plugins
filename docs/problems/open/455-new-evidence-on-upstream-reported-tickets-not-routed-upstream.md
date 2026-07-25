# Problem 455: new evidence on an already-upstream-reported ticket is not routed upstream without a user prompt — no evidence-append mode exists

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 6 (Medium) — Impact: 2 (Minor — upstream maintainer misses field evidence until the user manually prompts; no local data loss) × Likelihood: 3 (Possible — every retro/session that surfaces new evidence on an upstream-reported, still-open ticket) — derived at capture per Step 4a
**Origin**: inbound-reported (#348)
**Effort**: M — run-retro Step 2b sub-step (detections deduping to an upstream-reported ticket draft a gated upstream comment) and/or update-upstream extension covering evidence-appends, not just lifecycle transitions
**WSJF**: 3 — (6 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

When a retrospective (or ordinary session work) surfaces new evidence on a problem that is already reported upstream, or a new upstream-shaped finding, the assistant does not route it upstream on its own — it appends the evidence to the local ticket and stops. The user has to explicitly prompt before the evidence reaches the upstream maintainer.

Two layers: (1) tooling gap — `update-upstream` exists for lifecycle transitions (root-cause-confirmed / fix-released / closed) but has no mode for evidence-appends on a still-open ticket, and run-retro Step 2b has no route-upstream sub-step even when the local ticket carries a `## Reported Upstream` back-link; (2) assistant-discipline gap — "append evidence locally" is treated as done, leaving outward propagation for the user to request.

Fix direction: a run-retro Step 2b sub-step that, for detections deduping to an already-upstream-reported ticket, drafts an upstream comment (gated through external-comms + credibility review, then queued or auto-posted per appetite); and/or an update-upstream evidence-append mode.

## Symptoms

- New evidence lands only in the local problem body; the upstream issue is not updated until the user prompts.
- Upstream-shaped retro findings recorded locally (Pipeline Instability section) but never filed/commented upstream unprompted.

## Workaround

User manually prompts the assistant to post the evidence upstream.

## Impact Assessment

- **Who is affected**: plugin-user persona (downstream reporter whose evidence should reach the upstream maintainer) + the upstream maintainer.
- **Frequency**: per evidence-bearing retro/session on upstream-reported tickets.
- **Severity**: Minor — close-the-loop contract (JTBD-301 family) silently under-delivered on the evidence leg.
- **Analytics**: downstream repo tracked as P164.

## Root Cause Analysis

### Investigation Tasks

- [ ] Design the evidence-append trigger surface (run-retro Step 2b sub-step vs update-upstream mode vs both); ride the P376 four-directive template rework for generation.
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P080 (outbound master, verifying — transition-only trigger class this extends), P270 (verifying — same append-locally-and-stop discipline class, initial-filing leg), P363 (status-sync sibling; issue #348 is deliberately-kept-open live evidence there), P376 (its four directives should govern the generated evidence comment)

## Related

- Upstream issue #348 (inbound; reporter's downstream ticket P164). Sibling issue #349 (verification-confirmation leg) absorbed into P376 Gap 2 at the same 2026-07-15 triage.
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P080's three phases are all lifecycle-transition-anchored (evidence-appends are outside its trigger class; P376's own sibling-capture precedent applies); P363 is content-class status, not evidence, and primarily the inbound-verdict leg; P270's shipped RFC-018 fix covers filing-on-detect (one lifecycle stage earlier); P413 (verifying) fixed a work-problems wrap-time invariant on initial filings; P376's remaining Gap 2 scope is comment shape/wording, not a new trigger surface (composes, doesn't absorb).
