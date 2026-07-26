# Problem 472: reconcile-stories reports permanent false MISSING_REVERSE_TRACE drift against ADR-090's ratified-stories-only rule

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 2: dev-tooling signal degraded and an agent that trusts it can be pushed into an ADR-090 violation; no shipped-package or adopter harm. Likelihood 4: fires on every AFK vehicle-authoring iteration from the moment the vehicle is authored until its story is ratified, and was observed on two consecutive iterations the same day.
**Origin**: internal
**Effort**: S — derived at capture per Step 4a. One predicate in one script plus behavioural bats over two cases; grounded on the scope-shape of P312 (`reconcile-rfcs` spurious MISSING_REVERSE_TRACE from missing subdir traversal — same detector family, same symptom, single-predicate fix). P312 carries no `Actual Effort:` field, so per ADR-026 this citation grounds the scope shape, not a measured duration. WSJF = (8 × 1.0) / 1 = 8.0.
**JTBD**: JTBD-006
**Persona**: developer

## Description

`wr-itil-reconcile-stories docs/stories` reports `MISSING_REVERSE_TRACE STORY-053 in RFC-057 ## Stories` and `MISSING_REVERSE_TRACE STORY-052 in RFC-056 ## Stories`. Both are false.

ADR-090 forbids exactly the reverse trace the reconciler demands: an RFC may reference only ratified (`human-oversight: confirmed`) stories, and a story captured under AFK is born `human-oversight: unconfirmed`. RFC-056 and RFC-057 therefore both deliberately carry `stories: []` plus a narrative `## Stories` section stating why, and the architect explicitly confirmed that shape as correct during the P434 iteration (2026-07-26), citing RFC-056 as the precedent RFC-057 should mirror.

So the reconciler and ADR-090 disagree. The detector will report drift on every AFK-authored fix vehicle from the moment it is authored until its story is ratified — which is precisely the window the AFK ratification hold is designed to sit in, so the false positive is not an edge case but the normal state of every held vehicle.

Consequence: the reconciler's output cannot be used as a clean/dirty signal for the story tier during any AFK vehicle-authoring iteration. An agent that trusts it will either wire a reverse trace ADR-090 forbids — the real harm, since that makes an RFC reference an unratified story — or learn to discount reconciler output wholesale, which is the softer harm but costs the detector its value everywhere else.

## Symptoms

- `wr-itil-reconcile-stories docs/stories` emits `MISSING_REVERSE_TRACE STORY-<NNN> in RFC-<NNN> ## Stories` for a draft story whose RFC correctly carries `stories: []` per ADR-090. Observed 2026-07-26 for STORY-052/RFC-056 (the P433 vehicle) and STORY-053/RFC-057 (the P434 vehicle).
- The finding does not clear by any correct action: satisfying it violates ADR-090, and leaving it means the detector never reports clean while a vehicle is held.

## Workaround

Read the `MISSING_REVERSE_TRACE ... in RFC-<NNN> ## Stories` lines as advisory-only and check the named story's `human-oversight` field before acting: `unconfirmed` means the finding is false and must NOT be actioned. The reconciler's other finding classes (`STALE` rankings rows, `MISSING_REVERSE_TRACE ... in P<NNN>`, `... in JTBD-<NNN>`) are unaffected and remain trustworthy — this affects only the RFC-directed reverse-trace class.

## Impact Assessment

- **Who is affected**: developer running `/wr-itil:reconcile-stories` or the reconciliation preflight during any AFK vehicle-authoring iteration.
- **Frequency**: every AFK-authored fix vehicle, for the whole interval between authoring and story ratification.
- **Severity**: Medium (8) — degrades a governance detector into an unreliable signal and pushes toward an ADR-090 violation if trusted; dev-tooling only, no shipped-package harm.
- **Analytics**: 2026-07-26 — 2 of 2 fix vehicles authored that day reported the false finding (P433's and P434's).

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm the reverse-trace predicate in the reconcile-stories script expects every story's ID in its linked RFC's `## Stories` section regardless of the story's `human-oversight` value.
- [ ] Gate the predicate on ADR-090: suppress the finding for a story whose `human-oversight` is `unconfirmed`, or equivalently expect the reverse trace only once the story has reached `accepted`.
- [ ] Behavioural coverage: an unconfirmed draft story linked to a `stories: []` RFC must NOT report drift; a ratified story missing from its RFC's `stories:` array MUST still report drift. Assert on emitted lines against fixture trees, not on script source.
- [ ] Check whether the sibling `wr-itil-reconcile-rfcs` detector carries the same ungated expectation in the other direction.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P463 (relevance-close evaluator over-fires on a bare citation read as fix-evidence), P461 (downstream evidence-scan over-firing without version-gating), P434 (capture writes unverified claims as fact). All four are the same class — a detector treating something that is not evidence as evidence — and P434's own ADR-100 records the general shape.

## Related

- **ADR-090** — the ratified-stories-only rule the detector contradicts; the authority that makes these findings false rather than merely noisy.
- **P312** (`docs/problems/closed/312-reconcile-rfcs-spurious-missing-reverse-trace-no-subdir-traversal.md`) — closest prior: the same `MISSING_REVERSE_TRACE` symptom on the sibling `reconcile-rfcs` detector, root-caused to missing subdir traversal. **Different root cause** (traversal vs an ungated predicate) so not a duplicate, but a reviewer should confirm that reading before treating this as new.
- **P417** (`docs/problems/known-error/417-stories-readme-rankings-done-never-reconciled.md`) — adjacent: the same script's rankings/Done render never being reconciled. Distinct concern (the render vs the reverse-trace predicate), but the two share a fix surface and a reviewer may prefer to fold this in as a second phase there.
- Captured via `/wr-itil:capture-problem` during the `/wr-retrospective:run-retro` Step 2b pipeline-instability scan of the P434 iteration (2026-07-26).
- **Hang-off-check not dispatched**: the Step 2b mechanical pre-filter surfaced **7** candidates sharing ≥1 signal (ADR-090 / RFC-056 / RFC-057 / STORY-052 / STORY-053 / `docs/stories`), above the ≤5 latency cap, so the fresh-context arbiter was skipped per the SKILL's candidate-cap short-circuit. The two candidates worth a human read are named above (P312, P417); re-evaluate the absorb-vs-sibling call at the next `/wr-itil:review-problems`.
</content>
