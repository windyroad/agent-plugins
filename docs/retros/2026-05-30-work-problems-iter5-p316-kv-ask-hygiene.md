# Ask Hygiene Pass — work-problems iter 5 (P316 K→V)

**Date**: 2026-05-30
**Surface**: `/wr-itil:work-problems` iter 5 closing P316 Known Error → Verifying
**Scope**: P316 lifecycle transition + second real-world dogfood of `wr-itil-derive-release-vehicle` helper

## AskUserQuestion calls this iter

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | Orchestrator constraint: "NEVER call AskUserQuestion mid-loop (P135 / ADR-044): queue observations to ITERATION_SUMMARY.outstanding_questions." |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

The orchestrator AFK contract suppresses mid-loop AskUserQuestion entirely. The K→V transition was framework-resolved at every stage:

- Status transition (Known Error → Verifying) is the codified ADR-022 P143 fold-fix lifecycle event with no per-decision question.
- Release-vehicle citation derived deterministically by `wr-itil-derive-release-vehicle P316` (helper exit 0, full RELEASE_VEHICLE block emitted).
- README rendering rules (WSJF removal + Verification Queue insert at Released-ASC, ID-ASC tiebreak) are codified per P062 + P186; no taste decisions surfaced.
- "Last reviewed" line update + history rotation are codified per P134; no per-line question.

Cross-session lazy-count trend: iters 1-5 of this session all report 0. The orchestrator AFK constraint behaves correctly as a structural enforcer of the framework-resolution boundary.

## Iter observations (for ITERATION_SUMMARY)

1. **Helper exit-code 2 case observed.** First `wr-itil-derive-release-vehicle P316` invocation returned exit 2 ("no changeset reference in ticket body") because the P316 ticket body did not name the `.changeset/p316-rejected-pending-supersede-marker.md` path. Resolution per the transition-problem SKILL.md Exit-2 routing: edit the ticket to add the changeset reference in the Fix Released section, then re-run helper. Helper then returned exit 0 with full citation block. Helper behaved correctly per its documented contract; this is normal Exit-2 routing, not a defect.

2. **Multi-package release citation shape works cleanly.** P316 shipped in TWO plugins (`@windyroad/architect@0.12.0` + `@windyroad/jtbd@0.9.0`) via a single PR / changeset / version-packages commit. The helper's structured output (one changeset / one version-packages-commit / one PR / one merge-commit) accommodated the multi-package case naturally; the Fix Released section narrative cites both package versions explicitly above the helper's structured block. No helper change needed for multi-package releases.
