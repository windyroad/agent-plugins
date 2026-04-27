---
"@windyroad/retrospective": patch
---

P135 Reassessment Trigger automation — Step 2d auto-flags Phase 4 enforcement hook when R6 numeric gate fires.

Per ADR-044's Reassessment section + P135's R6 numeric gate (lazy AskUserQuestion count remains ≥2 across 3 consecutive retros after Phase 2/3 land), Step 2d "Ask Hygiene Pass" now auto-queues a deviation-candidate in the orchestrator's `outstanding_questions` queue when the gate fires. The deviation-candidate carries:

- `category: "deviation-approval"`
- `existing_decision: "ADR-044 Reassessment / declarative-first; P135 Phase 4 gated on R6"`
- `contradicting_evidence: <3 consecutive retros' lazy counts + citations to docs/retros/<date>-ask-hygiene.md per retro>`
- `proposed_shape: "amend"`
- `rationale: "R6 numeric gate fired; declarative-first declared insufficient; Phase 4 enforcement hook now warranted per P135 plan"`

The deviation-candidate surfaces at loop end (Step 2.5 in `/wr-itil:work-problems`) with the standard 5-option `AskUserQuestion`. **The framework reminds itself** — no manual tracking needed for the Phase 4 evaluation gate.

ADR-044 Reassessment section amended to explicitly name the R6 numeric criterion + cross-reference Step 2d's auto-queue mechanism.

Bats coverage: `packages/retrospective/skills/run-retro/test/run-retro-step-2d-r6-auto-flag.bats` (9 assertions covering Step 2d + ADR-044 cross-references).

Refs: P135 (master), ADR-044 (Reassessment Trigger), ADR-014 (commit grain).
