---
"@windyroad/itil": minor
---

Inbound-reported problems now rank ahead of internally-discovered problems (ADR-076; P138 amendment).

Problem-ticket selection gains a top-level sort partition above the WSJF tie-break ladder:

- **Tier 0 Critical-bypass** — Severity Very High (≥17) OR security-classified OR incident-linked. The most critical issues always come first.
- **Tier 1 Inbound-reported** — tickets carrying `**Origin**: inbound-reported` (reported to us by an external user via ADR-062's discovery pipeline).
- **Tier 2 Internal** — everything else.

Each tier is internally ranked by the unchanged P138 ladder `(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)`. The WSJF formula and the ADR-067-frozen 1/2/4/8 effort divisor are untouched — the tier operates purely at the sort/selection layer where the tie-break ladder already lives. The reasoning is customer-service and feedback-signal preservation: reporters who watch their reports sit untouched stop reporting and move to other plugins.

- New on-ticket `**Origin**` body field (`internal` by default, `inbound-reported (#NN)` for external reports) in the manage-problem and capture-problem templates. This field — not the regenerable `.upstream-cache.json` — is the authoritative rank input. ADR-062's inbound-discovery safe-and-valid branch stamps `inbound-reported (#NN)` at ticket creation.
- An `**Origin**` column and a greppable `REPORTED-FIRST-TIER-SOURCE` marker now ride every P138 render surface (work-problems Step 1/3, manage-problem Step 5/7/9c/9e, review-problems Step 3/5), mirroring the existing `TIE-BREAK-LADDER-SOURCE` drift tripwire.
- review-problems Step 2 gains honest-likelihood-re-score guidance: an inbound report is legitimate "previously observed" evidence (RISK-POLICY level 5) and may raise Likelihood on its own merits — explicitly not a rank lever. The tier does the prioritisation; the risk axes stay honest because the release-risk gate reads the same Likelihood scale.
