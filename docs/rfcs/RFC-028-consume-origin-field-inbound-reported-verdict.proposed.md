---
status: proposed
rfc-id: consume-origin-field-inbound-reported-verdict
reported: 2026-06-22
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P363]
adrs: [ADR-024]
jtbd: [JTBD-301]
stories: []
---

# RFC-028: Consume the `**Origin**` field for inbound-reported fix-released verdict

**Status**: proposed
**Reported**: 2026-06-22
**Problems**: P363
**ADRs**: ADR-024 (amendment 2026-06-22 — inbound-verdict dispatch leg)
**JTBD**: JTBD-301

## Summary

Consume the `**Origin**: inbound-reported (#NN)` field so inbound-reported tickets receive a fix-released verdict comment on the originating own-repo issue (P363 option (b), user-ratified 2026-06-22). Teach `/wr-itil:update-upstream` and the two lockstep transition-time grep pre-checks to recognise the inbound `**Origin**` field in addition to the outbound `## Reported Upstream` section, closing the JTBD-301 fix-released-verdict promise for the inbound (plugin-user reporter) direction.

## Driving problem trace

- **P363** (Inbound-reported tickets never receive fix-released verdict on originating issue) — RCA confirmed a direction asymmetry: the verdict surface (`/wr-itil:update-upstream`) exists and fires for outbound tickets, but inbound intake records the originating issue only as `**Origin**: inbound-reported (#NN)`, which the verdict machinery never reads. This RFC implements the user-ratified option (b): consume the `**Origin**` field.

## Scope

Implemented this iteration (ADR-024 amendment 2026-06-22 authorises the contract extension):

- `/wr-itil:update-upstream` SKILL.md — Step 1 dual read (section + Origin field); inbound-origin verdict dispatch leg (I1–I7): own-repo resolution, reporter-facing fix-released/closed templates with P229 anti-leakage, idempotency guard (`gh issue view --json comments`), same external-comms + voice-tone dual gate, `gh issue close` on Verifying→Closed, direction-tagged back-write, both-direction independent dispatch.
- `/wr-itil:transition-problem` Step 7b + `/wr-itil:manage-problem` Step 7 — both grep pre-checks extended in lockstep to match `^## Reported Upstream` OR `^\*\*Origin\*\*: inbound-reported \(#`.
- Tests — extended `update-upstream-contract.bats` (structural-permitted) + paired promptfoo behavioural cases (inbound-only dispatch, idempotency-skip, anti-leakage, both-present, dual-absence no-op, P249 non-contamination).

## Tasks

- [x] ADR-024 amendment recording the inbound-verdict dispatch leg + anti-leakage Confirmation criterion
- [x] update-upstream SKILL.md inbound dispatch branch
- [x] transition-problem + manage-problem grep pre-checks extended in lockstep
- [x] Behavioural eval cases + structural bats coverage
- [ ] Live verification: next inbound-reported ticket's K→V transition auto-posts the fix-released verdict on its originating issue (deferred to a real transition post-release)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
