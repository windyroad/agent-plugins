# Detailed planning guidance

Read the section explicitly required by the planning entrypoint. Essential gates remain in that entrypoint.

## Use-case slicing

Map the workflow once at a level that exposes choices. Name the steps, branches, joins, empty results and changes in authority. Number the steps when comparing separate path views and preserve the original steps and connections in those views.

Trace continuous paths from real entry points to useful results. A shorter path can stop as soon as a named beneficiary can use the result or make a specific decision. For example, selecting and reading the next ticket can yield the conversation or confirm the queue is empty. Sending a prepared reply can start separately with a selected ticket and end with provider confirmation. A hidden write on a sample ticket belongs in the verification of the increment it supports. Bounded discovery can qualify when it resolves a concrete decision.

Group paths that share delivery work and preserve their prerequisites. Compare feasible candidates by value and remaining effort. If using WSJF, estimate the additional effort once dependencies are met and revisit estimates as shared work lands. Select one Now and keep later slices provisional. Check the whole outcome for delivery and verification beyond the mapped workflow, such as enablement, submission, approval and publication when required. Sequence each by its actual dependencies.

## Bounded discovery

If material uncertainty prevents a small, estimable implementation increment, make Now a bounded discovery or qualification increment instead of labeling unbounded implementation INVEST-shaped. State its concrete value, limited investigation scope, observable artifact or decision evidence, stopping condition and verification. Keep implementation provisional until that evidence supports a bounded increment. Bound and qualitatively estimate the discovery work itself from its limited inspection scope; keep uncertainty about the subsequent implementation estimate separate. Do not defer discovery's own effort assessment until discovery completes. Define a finite inspection pass, its stopping condition and a qualitative effort estimate grounded in that scope; keep unresolved implementation effort separate. State which evidence or artifacts the pass will inspect and what concrete artifact or decision it will yield. Treat the cap as a proposed plan constraint, not a claim that inputs were inspected or effort measured. If required evidence is unavailable, record the exact gap and stop the affected inspection while continuing useful authorized alternatives. If a defensible qualitative bound cannot yet be established, narrow the pass before execution rather than claiming it is estimable. Use available authorized read-only evidence before asking the user for facts you can establish. Do not manufacture an estimate, make discovery mandatory when evidence is sufficient, or substitute discovery for the final outcome.

## Critic responsibilities

Iterate each **initial or materially revised executable plan with five independent critics before dependent execution**. Give them the confirmed objective, exact revision, evidence, scope, assumptions, dependencies and project rules:

- **Architect:** checks structural choices, interfaces and existing decisions. Ask the architect to sketch the simplest design that meets the exact revision's acceptance criteria and constraints. For each new resource, mapping, abstraction or parallel path, ask what required behavior would fail without it. An avoidable mechanism is a substantive finding: name what to remove and revise the plan before dependent execution. For blocking design or verification findings, ask for the requirement or invariant, its source, the enforcement owner and evidence from the reviewed artifact. Ask whether the proposed mechanism and verification are needed at that boundary.
- **JTBD:** checks intended beneficiaries and their desired outcomes.
- **Risk:** checks action risk and whether proposed mitigation work is justified. The risk scorer vetoes speculative work justified only by imagined failure or agent discomfort. Necessary treatments require an established risk or applicable requirement, credible impact/likelihood and proportionate reduction relative to cost and delay. A prior incident is not required; established preventive risks and required controls remain valid. An in-appetite action score does not establish necessity or priority. Remove unjustified work rather than invent a registry, report, human gate or discovery increment to justify it.
- **Cognitive accessibility:** checks whether beneficiaries and contributors can understand the result, choices and next action without unnecessary cognitive work, jargon or human handoffs.
- **Planning:** tests INVEST for Now. Before passing, identify who can use the result and what they can do or decide, compare smaller feasible slices, and check that the sequence covers the full outcome and actual dependencies. A bounded technical check without usable value or a decision it resolves needs to move into the work it verifies. Future horizons remain provisional, without full Now detail. For initial or material plan reviews, inspect the authoritative plan in the chosen vehicle and actual affected tracking records, where used, against the assessed revision, including relevant task and selected Project setup evidence. Return concrete discrepancies; have repairs reflected in that same vehicle and rechecked before dependent work. Do not create a new artifact or tracking vehicle just for review. This is the existing planning review, not another five-critic cycle for routine updates.

## Independent reviewer capability

Use the installed review roles or available independent agents assigned those responsibilities. The JTBD reviewer checks the objective and plan against the relevant persona and desired outcomes. Follow its recommendation-review contract, including a `RECOMMENDATION REVIEW` prompt prefix where required; recommendation review does not authorize file edits. Identify any substitution and its limits. If a substantive review cannot be obtained, report the exact missing capability and hold dependent implementation. Continue useful authorized preparation within existing authority. An ordinary go-ahead does not provide the missing review or itself waive this gate; do not infer informed risk acceptance or substitute another confirmation for that capability. Do not claim the plan passed or silently substitute self-approval.

Prefer a named installed reviewer when available. If the reviewer or named-agent
selector is unavailable, give an independent general reviewer the complete
installed reviewer's instructions and the original request. Use a fresh context
and preserve its read-only scope and verdict format. For reviews that satisfy a
plugin gate, follow that installed plugin's fallback dispatch and completion
instructions. A failed review requires remediation; it is not a reason to switch
reviewers. Missing instructions or completion evidence still means the review is
unavailable.


## Independent increment acceptance

Before declaring an increment complete, its owner obtains one bounded independent acceptance check through the existing planning critic. Reuse an independent check that already covers these criteria. The owner retains the final acceptance decision; a critic verdict does not automatically complete the increment.

Give the critic the acceptance criteria, current revision, actual execution results and access to the affected authoritative plan and saved records. The critic inspects those results directly and compares the completion claim with the affected outcome, increment and task records, including selected Project state where applicable. Reviewing only the executor's summary or a PASS label is insufficient. Use the existing Local plan/conversation or GitHub records.

The critic identifies concrete discrepancies or missing results. Withhold Done, repair within existing authority and obtain a recheck of the repaired results and saved state. If the independent reviewer or required results are unavailable, report the precise gap and withhold the completion claim. This review grants no wider access or operation authority.

This is an increment-acceptance boundary. Completing an individual task or making a routine update does not trigger it or another five-critic cycle. Earlier review, coordination and prerequisite obligations still apply.

## New integrations

Make the first real request from the local development environment to the actual service or its official sandbox within existing authority. Inspect actual responses and behaviour before writing integration tests or deploying; use what you observe to shape implementation and tests. Reuse already-known real behaviour where applicable. Do not invent response shapes, qualify an integration solely against mocks, or learn its behaviour by iterating in production. If real access is unavailable, state that gap and continue useful independent work; mocks do not establish that the interaction works. No new report is required.
