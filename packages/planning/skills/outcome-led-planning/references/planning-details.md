# Detailed planning guidance

Read the section explicitly required by the planning entrypoint. Essential gates remain in that entrypoint.

## Bounded discovery

If material uncertainty prevents a small, estimable implementation increment, make Now a bounded discovery or qualification increment instead of labeling unbounded implementation INVEST-shaped. State its concrete value, limited investigation scope, observable artifact or decision evidence, stopping condition and verification. Keep implementation provisional until that evidence supports a bounded increment. Bound and qualitatively estimate the discovery work itself from its limited inspection scope; keep uncertainty about the subsequent implementation estimate separate. Do not defer discovery's own effort assessment until discovery completes. Define a finite inspection pass, its stopping condition and a qualitative effort estimate grounded in that scope; keep unresolved implementation effort separate. State which evidence or artifacts the pass will inspect and what concrete artifact or decision it will yield. Treat the cap as a proposed plan constraint, not a claim that inputs were inspected or effort measured. If required evidence is unavailable, record the exact gap and stop the affected inspection while continuing useful authorized alternatives. If a defensible qualitative bound cannot yet be established, narrow the pass before execution rather than claiming it is estimable. Use available authorized read-only evidence before asking the user for facts you can establish. Do not manufacture an estimate, make discovery mandatory when evidence is sufficient, or substitute discovery for the final outcome.

## Critic responsibilities

Iterate each **initial or materially revised executable plan with five independent critics before dependent execution**. Give them the confirmed objective, exact revision, evidence, scope, assumptions, dependencies and project rules:

- **Architect:** checks structural choices, interfaces and existing decisions.
- **JTBD:** checks intended beneficiaries and their desired outcomes.
- **Risk:** checks action risk and whether proposed mitigation work is justified.
- **Cognitive accessibility:** checks whether beneficiaries and contributors can understand the result, choices and next action without unnecessary cognitive work, jargon or human handoffs.
- **Planning:** tests INVEST for Now, especially whether a smaller still-valuable increment exists, and outcome-directed dependencies and sequencing across Now/Next/Later. Future horizons remain provisional, without full Now detail.

## Independent reviewer capability

Use the installed review roles or available independent agents assigned those responsibilities. The JTBD reviewer checks the objective and plan against the relevant persona and desired outcomes. Follow its recommendation-review contract, including a `RECOMMENDATION REVIEW` prompt prefix where required; recommendation review does not authorize file edits. Identify any substitution and its limits. If a substantive review cannot be obtained, report the exact missing capability and hold dependent implementation. Continue useful authorized preparation within existing authority. An ordinary go-ahead does not provide the missing review or itself waive this gate; do not infer informed risk acceptance or substitute another confirmation for that capability. Do not claim the plan passed or silently substitute self-approval.

