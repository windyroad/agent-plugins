---
"@windyroad/itil": minor
---

P076 — WSJF scoring in `/wr-itil:manage-problem` now models transitive dependencies. Ticket effort is split into `marginal` (the ticket's own added work) and `transitive` (`max(marginal, max{ Blocked_by upstreams })`); WSJF uses the transitive effort so a dependent ticket can never out-rank a ticket whose work is strictly contained within it. Additions:

- New `### Transitive dependencies (P076)` subsection in `packages/itil/skills/manage-problem/SKILL.md` WSJF Prioritisation section defining the rule, the `**Blocked by**` signal, the `**Composes with**` non-propagation carve-out, the `.closed.md` / `.verifying.md` / `.parked.md` upstream-contributes-0 carve-out, cycle-bundling semantics, a worked example (P073 marginal S + blocked by P038 XL → transitive XL → WSJF 1.5), a concrete re-rate message format (`P<NNN>: Effort <OLD> → <NEW> (transitive via <UPSTREAM>)`), and a reassessment-criteria note for future sibling-ADR extraction if a second skill adopts the `## Dependencies` convention.
- New `## Dependencies` section in the Step 5 problem-ticket template with `**Blocks**` / `**Blocked by**` / `**Composes with**` rows (bare IDs, empty lists allowed) and a concrete example block.
- New Step 9b.1 dependency-graph-traversal pass in `manage-problem` and a mirrored Step 2.5 in `/wr-itil:review-problems` (the executor split per P071) that builds the `**Blocked by**` adjacency map, topologically sorts, propagates effort, writes an `<!-- transitive: <bucket> via <UPSTREAM> -->` audit comment on the Effort line, and reports each re-rate in the step-3 review output.
- New `manage-problem-transitive-dependencies.bats` contract + behavioural test file (21 assertions — 15 structural contract assertions per ADR-037 plus 6 behavioural fixture tests exercising the transitive-closure algorithm directly so prose-drift like `min` instead of `max`, or a missing carve-out for closed upstreams, is caught at test time).
- Three new contract assertions on `review-problems-contract.bats` covering the new Step 2.5 pass, canonical-rule citation, and re-rate message shape.

No new ADR authored (following ADR-022's inline-amendment precedent for WSJF additions); reassessment trigger documented inline. Backward-compatible — tickets without a `## Dependencies` section behave as before (empty closure → transitive == marginal).
