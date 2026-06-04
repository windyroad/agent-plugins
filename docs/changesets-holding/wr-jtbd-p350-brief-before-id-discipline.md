---
"@windyroad/jtbd": patch
---

P350 fold-fix (`@windyroad/jtbd` side): apply the brief-before-ID discipline at the `/wr-jtbd:confirm-jobs-and-personas` AskUserQuestion surface. The Step 3 presentation rule (P302 "lead with the job statement / persona definition, never with the meta") is now followed by an explicit Brief-before-ID clause: the question/options text MUST inline what each cited job statement or persona definition actually asserts BEFORE naming it by `JTBD-NNN` / `P-NNN` / `ADR-NNN` / `RFC-NNN`. Acceptable shape demonstrated inline (the job in plain-prose terms with parenthetical IDs as audit-trail annotations); unacceptable shape (bare `JTBD-001 + sibling to JTBD-006`) demonstrated as the counter-example. Mirrors the canonical `/wr-architect:create-adr` Step 5 § 5a Rule 3 ("No IDs as explainers"). Companion patches in `@windyroad/itil`, `@windyroad/architect`, `@windyroad/retrospective` land the same discipline at their respective surfaces.
