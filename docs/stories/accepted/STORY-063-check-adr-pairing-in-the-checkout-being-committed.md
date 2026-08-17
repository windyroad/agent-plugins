---
status: accepted
story-id: check-adr-pairing-in-the-checkout-being-committed
reported: 2026-08-17
decision-makers: [Tom Howard]
problems: [P499]
rfcs: [RFC-069]
jtbd: [JTBD-001]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-063: Check ADR pairing in the checkout being committed

## User value (INVEST Valuable)

In order to trust governance gates while working across isolated checkouts, as a developer committing a reviewed change, I want the ADR pairing hook to inspect the exact checkout and index that the commit command targets.

## Acceptance criteria (INVEST Testable)

- [ ] A command `workdir` or `cwd` selects that Git checkout before the hook inspects staged ADRs.
- [ ] An explicit leading absolute `cd` selects the target checkout when the payload omits a command workdir.
- [ ] A declared relative, missing, or non-Git checkout fails closed with an actionable denial.
- [ ] Legacy payloads that declare no checkout preserve the existing process-cwd behaviour.
- [ ] Cross-checkout behavioural tests prove both permit and deny decisions come only from the target index.
- [ ] The published architect package is installed and the original two-checkout witness passes before downstream work is called unblocked.

## Driving problem trace

P499 records that the hook inspected an unrelated dirty checkout and denied a clean isolated commit. This story binds the pairing decision to the actual command checkout without weakening the ADR body and compendium invariant.

## JTBD trace

- **JTBD-001**: automatic governance remains reliable without forcing developers to copy work into the task's original checkout or bypass a safety gate.

## Implementation notes

ADR-078 owns the pairing invariant, ADR-083 requires Codex compatibility, and ADR-052 requires behavioural regression coverage. Keep checkout resolution local to the architect hook; do not broaden risk-scorer or shared gate-helper packages.

## Dependencies

- **Blocks**: none.
- **Blocked by**: none.

## Related

- STORY-MAP-002 - Take a problem from noticed to resolved
- RFC-069 - Honor the command checkout in ADR pairing
- P499 - Architect ADR pairing hook reads the task checkout instead of the command checkout
