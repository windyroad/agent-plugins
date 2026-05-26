# Ask Hygiene — 2026-05-26 (ADR-070/071 implementation session)

Per ADR-044 (Decision-Delegation Contract). Lazy count is the regression metric — target 0.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | ADR grain | direction | Gap: architect emitted Needs-Direction (ADR-064) — the one-vs-two-ADR decomposition of the permanent ADR ledger for the F1/F4 extraction was a genuine choice the framework could not resolve; ADR-070's own Reassessment names ADR-sprawl as the tension. |
| 2 | JTBD-008 / JTBD-101 | deviation-approval | Framework-required: ADR-068 mandates human confirm on a material JTBD amend (clear-and-reconfirm JTBD-101 which carries a marker; born-confirm JTBD-008 which does not). Surfaced the wrong "thin-RFC" framing → user correction (P311). |
| 3 | P078 capture | correction-followup | Gap: P078 capture-on-correction surface — offered the problem-ticket capture before addressing the operational request, per the mandatory-capture-on-strong-correction contract. |
| 4 | Release scope + lint bump | direction | Gap: release = outward-facing, irreversible npm publish; operating contract requires confirming hard-to-reverse/outward actions absent durable authorization (foreground, user leaving). NOTE: the bundled lint-bump rider (patch vs minor) was borderline-lazy — semver (new script → minor) could resolve it; it rode the legitimate release-auth call with the user present. Avoid bundling framework-resolvable riders next time. |

**Lazy count: 0**
**Direction count: 2**
**Deviation-approval count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 1**

Note: this session's failure mode (P311 — the unauthorized "thin RFC" softening) was NOT an ask-hygiene regression (asks were legitimate); it was a content/judgment error on framing, captured separately. The one self-flag is the call-4 bump-class rider (borderline-lazy, bundled).
