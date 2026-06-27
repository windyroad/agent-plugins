---
"@windyroad/architect": patch
---

P350 fold-fix (`@windyroad/architect` side): apply the brief-before-ID discipline at the `/wr-architect:review-decisions` AskUserQuestion surface. The Step 3 presentation rule (P302 "lead with the Decision Outcome, never with the meta") is now followed by an explicit Brief-before-ID clause: the question/options text MUST inline what each referenced artefact decides BEFORE naming it by `ADR-NNN` / `P-NNN` / `JTBD-NNN` / `RFC-NNN`. Acceptable shape demonstrated inline (sibling-decision framing in plain prose with parenthetical IDs as audit-trail annotations); unacceptable shape (`sibling to ADR-038 and ADR-040`) demonstrated as the counter-example. Mirrors the canonical `/wr-architect:create-adr` Step 5 § 5a Rule 3 ("No IDs as explainers"). Companion patches in `@windyroad/itil`, `@windyroad/jtbd`, `@windyroad/retrospective` land the same discipline at their respective surfaces.
