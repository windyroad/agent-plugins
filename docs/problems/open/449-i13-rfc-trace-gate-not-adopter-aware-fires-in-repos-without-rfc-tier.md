# Problem 449: I13 RFC-trace predicate + manage-problem I13 gate are not adopter-aware — fire no-rfc-trace in repos without an RFC tier

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 9 (Medium) — Impact: 3 (Moderate — the directive would bootstrap an entire governance tier for a trivial fix, a direction-setting framework-adoption decision mis-framed as mechanical; each occurrence forces manual false-positive recognition) × Likelihood: 3 (Possible — three downstream hits already: their P070/P103/P101) — derived at capture per Step 4a
**Origin**: inbound-reported (#321)
**Effort**: M — adoption predicate (docs/rfcs/ presence + RFC git history) in `wr-itil-check-fix-rfc-trace` + manage-problem I13 gate prose + bats; design-bearing because the fix must reconcile with P412's fold-in direction (see Related)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

The I13 propose-fix RFC-trace predicate (`wr-itil-check-fix-rfc-trace`) and the manage-problem SKILL I13 gate emit `no-rfc-trace: P<NNN> … auto-create a problem-traced RFC via /wr-itil:capture-rfc` and direct an RFC auto-create even in consumer repos that never adopted the RFC tier (no `docs/rfcs/` directory, zero RFC history in git). The predicate is a naive grep: it cannot distinguish "RFC tier exists but this problem lacks a trace" (the real case it is designed for) from "this repo has no RFC tier at all" (a false positive). Acting on the directive would bootstrap an entire governance tier (docs/rfcs/, RFC-001, README, lifecycle skills) for what may be a trivial doc fix — a direction-setting framework-adoption decision, not a mechanical fix-time auto-create.

Hit three times in the downstream consumer repo (their P070 closed 2026-06-16, P103 and P101 both 2026-06-27); each time the working agent had to recognise the false positive out-of-band and fall back to the documented Phase-1 legacy direct-implementation path.

## Symptoms

- `no-rfc-trace` fires during fix work in repos with `docs/problems/` + `docs/decisions/` + `docs/jtbd/` but no RFC/story tiers.
- Working agents must manually verify `docs/rfcs/` absence + zero RFC history and apply the downstream precedent instead of the directive.

## Workaround

Recognise the false positive (verify `docs/rfcs/` absent and git carries zero RFC history) and use the SKILL's documented Phase-1 legacy direct-implementation path, carrying the fix-design trace on the problem ticket plus any cited ADR. Do NOT auto-create an RFC.

## Impact Assessment

- **Who is affected**: plugin-user persona — consumer repos that adopted problems/decisions/jtbd tiers but not the RFC tier.
- **Frequency**: every fix-proposal in such repos; three downstream witnesses.
- **Severity**: Moderate — mis-framed framework-adoption directive; recognition cost paid per occurrence.
- **Analytics**: downstream repo windy-road content project, tracked there as P104.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add an adopter-adoption predicate (docs/rfcs/ exists OR RFC history present) ahead of the no-rfc-trace directive; decide the not-adopted branch's behaviour (silent legacy path vs one-time adoption offer).
- [ ] Reconcile with P412's opposite-face direction (make RFC/USM creation not need activation) — the two pull opposite ways and need a joint design read.
- [ ] Create reproduction test (consumer-repo fixture without docs/rfcs/).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P412 (RFC/story tiers invisible to adopters — OPPOSITE face: it wants auto-create to fire reliably; this ticket wants the gate to recognise where firing is inappropriate; reconcile at design time), P435 (same "gate not adopter-aware" class, wr-risk-scorer surface)

## Related

- Upstream issue #321 (inbound; reporter's downstream ticket P104).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P371's third-branch fix (existing-vehicle-untraced) presupposes the RFC tier exists and its fix already shipped; P314 is verifying with the adopter-awareness dimension never in its ADR-072/073 scope; P412 is a sibling on the opposite policy face (fold-in direction ratified 2026-07-03), not a parent — silently absorbing a policy-contesting capture there would bury the tension; P435 is the same class in a different plugin with a disjoint fix locus.
