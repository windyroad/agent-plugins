---
"@windyroad/itil": patch
---

Add the ADR-052 behavioural lint enforcing ADR-070 (RFCs hold no independent decisions): `packages/itil/scripts/check-rfc-rejected-alternatives.sh`.

Given an RFC corpus directory (default `docs/rfcs`), the checker scans each `RFC-*.md` body and flags any that carries a "Considered Options / Alternatives Rejected" heading block without a matching `adrs:` frontmatter reference — the machine-detectable tell (ADR-070) of a decision masquerading as RFC scope. Contested choices belong in an ADR (referenced via `adrs:`), never re-argued in the RFC body. Detection targets a markdown heading, so a prose mention (e.g. a retrofit note explaining the section was removed) does not trip it; the lint scopes to `docs/rfcs/` only and never inspects `docs/decisions/`, where "Considered Options" headings are correct.

Ships with behavioural bats coverage (`packages/itil/scripts/test/check-rfc-rejected-alternatives.bats`) exercising the checker against synthetic fixture corpora (violation, ADR-referenced-allowed, clean, prose-mention-not-flagged, variant heading, mixed corpus, usage error) and a dogfood assertion that the real `docs/rfcs/` corpus is clean.
