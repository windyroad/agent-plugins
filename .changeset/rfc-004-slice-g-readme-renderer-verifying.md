---
"@windyroad/itil": patch
---

RFC-004 Slice G + in-progress → verifying transition (P079 fix shipped)

Slice G adds the `## Inbound Upstream Reports` section renderer to
`/wr-itil:review-problems` Step 5 README template and applies it to the
live `docs/problems/README.md` as an advisory-row initial state. ADR-062
§ Step 9e per the naming-reconciliation note (current SKILL numbering:
Step 5).

Columns: `# | Source | Title | Author | Created | Classification |
Matched local ticket`. Lazy-empty discipline — empty table body when
discovery has run with zero reports; advisory row when no discovery pass
has run yet.

RFC-004 transitions in-progress → verifying per the manage-rfc
transition-table contract (terminal-slice commit folds in the rename +
§ Verification section per the skill spec). All seven slices (A-G)
shipped. Closure gated on user-side behavioural replay per ADR-062
§ Confirmation criterion 3 — four synthetic-report scenarios (clean /
out-of-scope / info-extraction / matched-local-ticket) — and two
future-touch cross-reference notes (ADR-024 + ADR-046 amendments).

Bats refresh adds 3 Slice G assertions to inbound-discovery-contract.bats
(section header + lazy-empty discipline + column shape).

README index housekeeping:
- docs/rfcs/README.md WSJF Rankings empties; Verification Queue gains
  RFC-004 row with the seven-slice commit chain.
- docs/problems/README.md P079 reverse-trace ## RFCs Status column
  flips in-progress → verifying via idempotent helper.
- docs/problems/README.md P196 (premature-completion class-of-behavior
  ticket captured this session) added to WSJF Rankings at WSJF 1.0
  placeholder — reconciles the P196 capture commit's deferred README
  refresh per capture-problem Step 6 contract.

Refs: RFC-004
