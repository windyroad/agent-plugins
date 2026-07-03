---
status: proposed
rfc-id: narrow-vp-carve-out-shipped-verifying-changesets-graduate
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P398]
adrs: [ADR-061]
jtbd: [JTBD-007]
stories: []
---

# RFC-040: Narrow the ADR-061 Rule 2 VP carve-out so shipped-verifying changesets graduate

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P398
**ADRs**: ADR-061
**JTBD**: JTBD-007

## Summary

Narrow the ADR-061 Rule 2 Verification-Pending carve-out so an already-shipped (verifying) fix graduates its changelog-attribution changeset instead of being held indefinitely. The graduation evaluator reads each verifying ticket's `## Fix Released` section — populated (code live on npm) ⇒ status `resolved` (graduate); absent or placeholder-only (fix not yet shipped) ⇒ status `vp-blocked` (hold). Interim slice of ADR-082 option (c); subordinate to RFC-025 real shipment control.

## Driving problem trace

- **P398** — the ADR-061 Rule 2 VP carve-out marks a held changeset `vp-blocked` whenever its problem ticket is `.verifying.md`, but a verifying ticket means the fix already shipped to npm; only the changelog attribution is held, so the CHANGELOG never attributes a demonstrably-live fix (16 stranded on 2026-06-28). User corrective feedback 2026-06-28.

## Scope

The fix corrects a current-state defect (changelog stranding for already-shipped code) under ADR-082's de-facto attribution-only behaviour, without waiting for RFC-025's real shipment control.

- `packages/risk-scorer/scripts/evaluate-graduation.sh` — the graduation evaluator gains a mechanical `fix_shipped(ticket_path)` predicate (per ADR-015 deterministic detection, not prose judgement): a verifying ticket with a populated `## Fix Released` section (≥1 non-blank, non-placeholder line) is classed `resolved`; a verifying ticket with no such section (or placeholder-only: `(pending)`/`(deferred)`/`TBD`/`(none)`) stays `vp-blocked`. Output schema unchanged.
- `docs/decisions/061-dogfood-graduation-criteria.proposed.md` — Rule 2 narrowed to fire only for unshipped fixes; the five "symmetric to ADR-042 Rule 2b" sites reconciled to the now-intentional asymmetry; ADR-082 forward-compatibility framing + a Reassessment Trigger tying the interim branch to RFC-025. Frontmatter flipped `human-oversight: unconfirmed` per P357 (freeform amendment awaiting post-change ratification).
- `packages/risk-scorer/scripts/test/evaluate-graduation.bats` — behavioural coverage for shipped-verifying → resolved, placeholder/absent-verifying → vp-blocked, and an all-shipped-verifying cohort rolling up to resolved.

The residual rejection-risk (a later `.verifying.md` → `.known-error.md` flip-back makes one already-published CHANGELOG line stale) is accepted per user direction — rare and correctable.

## Tasks

- [x] Add `fix_shipped()` predicate + narrow the Rule 2 branch in `evaluate-graduation.sh`
- [x] Amend ADR-061 Rule 2 + sweep the five symmetry sites + ADR-082 framing + Reassessment Trigger (frontmatter → `unconfirmed` per P357)
- [x] Behavioural bats for the shipped/unshipped split + shipped-cohort rollup (all green)
- [x] `.changeset/*.md` — `@windyroad/risk-scorer` patch
- [ ] Post-change ratification of the ADR-061 amendment + ADR-082-overlap acknowledgement (queued for the next interactive drain per P357)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

- **P398** — driver problem ticket.
- **ADR-061** — the decision amended (Rule 2 narrowing).
- **ADR-082** — changeset holding semantics; this RFC's shipped-code branch is an interim slice of its option (c).
- **RFC-025** — the ADR-082 option (b)/(c) build vehicle; eventual authority for the K→V reconciliation this RFC interim-approximates.
- **P359** — originating observation (holding withholds only attribution); **P375** — the verifying→closed no-cadence that strands holds.
- (captured via /wr-itil:capture-rfc --fix-time; expand at next /wr-itil:manage-rfc invocation)
