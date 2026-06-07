---
"@windyroad/itil": patch
---

P211: work-problems Step 5 "Iteration prompt body" section now carries an
explicit "Re-ground per iter (P211 — orchestrator-side construction
invariant)" paragraph immediately after the "self-contained" opener. The
paragraph names: (a) per-iter re-ground against current ticket ID + title
only; (b) explicit prohibition on inlining the target ticket's
`## Fix Strategy` section verbatim into the dispatch prompt (the subprocess
reads it from disk via `/wr-itil:manage-problem` inside its own context,
where the design rationale stays anchored to the correct ticket);
(c) the cross-iter leakage class (prior ticket ID, prior Fix Strategy
text, prior outcome reason, prior commit SHA, prior retro findings, prior
outstanding-questions) that MUST NOT carry across the iter boundary;
(d) template-driven construction, reset per iter, no global accumulator.
The "self-contained" opener is named as the subprocess-side property
(the subprocess has no prior conversation context); re-grounding is the
symmetric orchestrator-side property (the orchestrator main turn does not
carry prior-iter prompt content into the next iter's dispatch
construction).

Without this invariant, an AFK iter inherits a stale design-rationale
frame and may land fixes anchored on the wrong ticket's intent —
degrading the JTBD-006 audit trail and the workaround burden the AFK loop
is meant to eliminate (the prior workaround was user-in-the-loop
verification after each iter, reading the subprocess's commit and
checking whether it cites the correct ticket's design rationale).

Behavioural second-source: `packages/itil/skills/work-problems/test/work-problems-step-5-prompt-body-re-grounding.bats`
(7 structural assertions; ADR-052 Surface 2 / structural-permitted with
`tdd-review: structural-permitted` justification comment citing P012 as
the harness-gap ticket — synthetic `claude -p` iter dispatch harness sits
outside the skill layer; same pattern as
`work-problems-step-5-iter-changeset-required.bats:14-21`).

Composes with P084 (subprocess-boundary dispatch — re-grounding is the
symmetric orchestrator-side property of the subprocess's "no prior
conversation context"), ADR-032 (AFK iteration-isolation wrapper —
re-grounding clarifies the wrapper's isolation intent on the orchestrator
side), JTBD-006 (load-bearing — audit trail and AFK trust degrade if
iters work the wrong ticket's design rationale).

Inbound-reported by downstream consumer **bbstats** as their P194
(`**Origin**: inbound-reported (bbstats#194)` per ADR-076 sort tier;
upstream tracking https://github.com/windyroad/agent-plugins/issues/97).
