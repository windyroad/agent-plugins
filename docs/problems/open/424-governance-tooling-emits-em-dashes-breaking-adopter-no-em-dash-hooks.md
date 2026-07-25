# Problem 424: Governance tooling emits U+2014 em-dashes in generated output, breaking adopter no-em-dash Edit/Write hooks

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#185, #186, #219, #223, #319)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 6.0.
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

Multiple `@windyroad/*` tooling surfaces emit U+2014 em-dashes into generated artefacts. Adopter projects that enforce a no-em-dash policy via an Edit/Write hook then have those hooks fire on plugin-generated content the adopter cannot edit (the content ships from the cached plugin, per ADR-036). Cluster of inbound reports, one root cause + one fix pattern (substitute U+2014 → ASCII separator).

## Symptoms

Per-surface (each an investigation task):
1. architect `capture-adr` / `create-adr` SKILL.md skeleton templates carry U+2014 in template literals (#185, #223).
2. `wr-architect-generate-decisions-compendium` emits U+2014 in ADR header / chosen-option summary lines (#219, #223).
3. P186 evidence-cell canonical wire format uses a U+2014 separator across the six itil SKILL render sites keyed by the `LIKELY-VERIFIED-CELL-SHAPE` marker (#186).
4. `check-upstream-responses` writes a U+2014 into the audit-log heading, tripping the gate every Step-0d pass (#319).

## Impact Assessment

- **Who is affected**: adopters running a no-em-dash Edit/Write policy; every regen re-introduces the character they must scrub.
- **Frequency**: every ADR capture / compendium regen / upstream-response poll / VQ render.
- **Severity**: High — plugin-generated content violates adopter policy with no adopter-side remedy (must ship upstream per P423).

## Root Cause Analysis

### Investigation Tasks

- [ ] Substitute U+2014 → ASCII separator (` - ` / `--`) across the four surfaces above; update bats that assert the P186 cell shape + the compendium output shape.
- [ ] Ship as an adopter-facing plugin change (not a local scrub) per P423 — the fix must reach installed caches.

## Dependencies

- **Composes with**: P210 (already-fixed work-problems AFK-fallback-marker em-dash — the precedent/pattern), P423 (fixes must be adopter-facing, not memory/local scrub).

## Related

- Inbound issues #185, #186, #219, #223, #319. Precedent: P210 (narrow, already-fixed instance).
