# Problem 240: Phase 3d — JTBD outcome amendments for P087 plugin maturity Phase 3 reactivation

**Status**: Open
**Reported**: 2026-05-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)

**Type**: user-business
**JTBD**: JTBD-302, JTBD-007, JTBD-101, JTBD-003
**Persona**: plugin-user

## Description

Phase 3d of the P087 plugin maturity rollout per ADR-063 §JTBD outcome amendments queued for Phase 3 follow-on. Four JTBD job files receive outcome-bullet amendments triggered by ADR-063's Phase 3 reactivation:

1. **JTBD-302** (`docs/jtbd/plugin-user/JTBD-302-trust-readme-describes-installed-behaviour.proposed.md`) — add desired-outcome bullet covering maturity-band visibility: *"(Amended in P087 Phase 3) I can see the maturity band (and, during the suite-bootstrap window, the compound evidence per ADR-053 §Bootstrapping clause Phase 3 rendering requirement) for every plugin and every per-skill surface from the README alone, without source archaeology under `node_modules/` and without invoking measurement scripts."* Cite ADR-053 + ADR-058 + ADR-063 as drivers.

2. **JTBD-007** (`docs/jtbd/solo-developer/JTBD-007-keep-plugins-current.proposed.md`) — extend currency framing: add a sentence to the currency-tracks-code-currency bullet noting that maturity-band currency (recomputed by Phase 3a writer per ADR-044 silent-framework carve-out) is a third dimension of the same currency concern (code, README-content, maturity-band).

3. **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — extend hardening-prioritisation framing: add a desired-outcome bullet covering "promotion criteria are documented so contributors know the bar to clear when authoring a new skill or splitting an existing one" — this was deferred in ADR-053 §Confirmation #4 as a Phase 3 follow-up; Phase 3 is the trigger to land it.

4. **JTBD-003** (`docs/jtbd/solo-developer/JTBD-003-compose-guardrails.proposed.md`) — add desired-outcome bullet covering at-glance stability awareness: *"I can see at glance which surfaces in a plugin are stable enough to depend on without invoking measurement scripts."* JTBD-003 currently has no maturity-aware outcome.

May fold into the Phase 3b commit (P238) as part of the same rollout, or ship as a separate JTBD-amendment commit per ADR-014 commit grain. ADR-051 commit-hook drift detector will fire on each JTBD-edit commit; the prose-weaving anti-pattern is JTBD-anchor-shape (not maturity-anchor-shape), so the amendments themselves don't trigger maturity-axis drift.

Child of P087. Driver: ADR-063 Phase 3 follow-on amendment queue.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: plugin-user persona (JTBD-302, JTBD-003), solo-developer persona (JTBD-007, JTBD-003), plugin-developer persona (JTBD-101). The amendments make the Phase 3 maturity surface persona-visible at the canonical persona-documentation layer.
- **Frequency**: every adopter consulting `docs/jtbd/` for plugin-suite framing.
- **Severity**: documentation-currency severity; low until Phase 3a + 3b ship and the maturity surface becomes adopter-visible.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Author the four JTBD amendments per the exact wording captured in this ticket (and refined in ADR-063 §JTBD outcome amendments).
- [ ] Verify the ADR-051 commit-hook drift detector passes on the amendment commit (no JTBD-anchor citations should drift; the amendments add bullets to existing JTBD files without removing citations).
- [ ] Verify no architect / risk-scorer review flags the amendment as out-of-contract — amendments are scope-limited per ADR-063's named outcome additions.

## Dependencies

- **Blocks**: P087 closure path (P087 closes only after Phase 3a/b/c/d all land per ADR-063 + ticket Decision record)
- **Blocked by**: (none — JTBD amendments may land before Phase 3a/3b/3c implementation, since the amendments document persona outcomes the implementation will then serve)
- **Composes with**: ADR-063 (drives the amendments), ADR-051 (JTBD-anchored README + drift detector — the amendments compose with the existing JTBD-anchoring contract), ADR-053 §Confirmation #4 deferred-bullet (JTBD-101 amendment closes this)

## Related

- P087 — parent
- ADR-063 — Phase 3 presentation-layer contract (drives the amendments)
- ADR-053 §Confirmation #4 — JTBD-101 deferred bullet closed by this ticket
- ADR-051 — JTBD-anchored README + drift detector composition
- JTBD-302 — plugin-user trust the README outcome (amended here)
- JTBD-007 — solo-developer keep plugins current outcome (amended here)
- JTBD-101 — plugin-developer extend suite outcome (amended here)
- JTBD-003 — solo-developer compose guardrails outcome (amended here)
- P237 — Phase 3a population script
- P238 — Phase 3b renderer + drift detector
- P239 — Phase 3c bats doc-lint per plugin
