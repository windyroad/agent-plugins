---
name: outcome-led-planning
description: Establish and confirm a SMART outcome, then deliver through INVEST-shaped Now increments, provisional Next and Later, and architecture, JTBD and risk review of each revised plan. Use for requested outcome-led planning or substantial work needing iterative delivery; skip routine single-step tasks.
---

# Outcome-led planning

Keep the objective as the reference point while the plan evolves through delivery and learning. Treat the plan as the current hypothesis about how to achieve the result.

## Establish and confirm the SMART objective

State the result the user wants and the observable evidence that will establish completion. Separate that result from proposed technologies, activities, and delivery mechanisms. Preserve explicit user constraints and any prescribed means; do not rewrite the objective to fit an easier implementation.

Read the relevant current evidence, project instructions, decisions, jobs, risk policy, and delivery workflow. Use that context before asking for information the user has already supplied.

Use SMART to make the objective specific, measurable through observable completion evidence, achievable against known constraints, relevant to the user's job, and time-bound using the user's stated deadline or timeframe. Qualitative evidence can establish success. Surface feasibility uncertainty instead of weakening the objective or promising certainty. Never invent numerical targets or dates. Preserve the user's stated timing. Keep relative wording unless available verified context establishes the calendar date; do not invent or silently substitute a deadline. If neither a time bound nor an explicit decision to omit one is established, ask one timing question and wait. If the user declines a time bound, record the exception honestly rather than claiming full SMART compliance.

If intent is unclear or information is missing, interview the user: **ask one focused question, then stop and wait for their answer before asking the next**. Select the next question from their actual answer and remaining uncertainty. Do not bundle questions, answer on their behalf, invent their intent, or resolve ambiguity by selecting a solution. Bounded read-only investigation can establish facts within existing authority.

One question requests **one missing fact**. Do not combine multiple information needs, such as who benefits and what is wrong, into a multipart question. Sharing a topic or using one question mark does not make it one question.

Once confident the outcome is captured correctly, **play back the complete objective, its completion evidence and material constraints, and ask the user to confirm or suggest changes. Wait for their response before creating an executable plan or beginning iteration.** This applies even when the initial request already supplies a clear goal. If they suggest changes, resolve them and replay the revised goal for confirmation. Existing explicit confirmation of that exact playback satisfies this gate; do not ask again solely because the session resumed.

When the supplied outcome already contains enough information for confirmation, ask only for confirmation or changes to that playback. Do not append a new interview about implementation formats, technologies or delivery options; address those means after goal confirmation when needed.

Keep the confirmed objective as the reference point throughout delivery. Ordinary replanning changes the means and does not repeat goal confirmation. A substantive change to the desired result, completion evidence or constraints requires renewed user confirmation before dependent planning or execution.

## Choose the tracking vehicle

After the SMART outcome is confirmed, honor any existing user, session or repository choice of planning vehicle. If none is established and shared tracking is relevant, offer **GitHub Issues or conversation/local tracking** in one focused question, then wait for the answer. Do not require a GitHub account, access setup or Project for local planning. Record the choice with the plan; do not ask again merely because an agent joins or the session resumes. Absent an existing GitHub choice or evidence that shared coordination adds value, retain conversation/local tracking and continue planning. Do not interrupt ordinary local work with an unnecessary tracking-choice question; multiple beneficiaries alone do not establish shared contribution work.

**When GitHub tracking is selected, read [the GitHub coordination protocol](references/github-coordination.md) before building its executable plan, claiming work or making planning-related issue/Project mutations.** Follow its outcome → increment → task hierarchy, contribution ownership and shared handoff rules. Load this reference only for that mode. An optional Project mirrors the same issues; it does not create another authoritative plan. Selecting a tracker does not independently grant permission to message people, broaden access or create persistent automation.

## Build the current plan

Keep one authoritative plan in the conversation or an agreed artifact. Use an existing planning vehicle when the project requires one. If continuity needs a saved plan, use the project's permitted document location, outside runtime configuration directories. Keep updates proportional to the work.

Include:

- **Objective and completion evidence:** the desired result and how to verify it.
- **Now:** one coherent release increment to work on now. Specify its intended result, scope, important assumptions or dependencies, verification, and what counts as delivered. Make it small enough to test, integrate, and learn from safely. A foundation increment is valid when its contribution and limits are explicit.
- **Next:** provisional subsequent release increments, describing their results and major dependencies with less detail. Their sequence and scope can change.
- **Later:** the broad direction beyond Next, at the highest level of uncertainty. Avoid speculative implementation detail and implied commitments.
- **Assessment:** the plan revision reviewed, architecture findings, JTBD findings, risk findings, conditions, and unresolved blockers.

Do not fill Next or Later with invented features. If evidence does not yet justify further work toward the confirmed outcome, leave those horizons to be determined from verified remaining gaps. Preserve known delivery stages required by the objective.

Use INVEST as a quality check for **Now**: independently deliverable, negotiable means within the confirmed goal, valuable, estimable with uncertainty disclosed, small, and testable. Internal dependencies are acceptable when the whole increment remains coherently and safely deliverable. Do not manufacture precise estimates. Do not introduce story documents just to use INVEST; retain any story and approval requirements the project already imposes. Next and Later stay provisional and need less detail.

Choose the smallest independently useful business result. Name who benefits and the observable improvement, validated decision or capability. Split again if a smaller result has value; shared code does not justify bundling. Technical activity alone is insufficient. Retain required security, integrity, recovery and acceptance. Foundations need explicit value and limits; environment promotion stages are not automatically increments. Deliver the verified minimum and replan before adding work. Apply whenever Now changes; keep remaining delivery plans provisional.

If material uncertainty prevents a small, estimable implementation increment, make Now a bounded discovery or qualification increment instead of labeling unbounded implementation INVEST-shaped. State its concrete value, limited investigation scope, observable artifact or decision evidence, stopping condition and verification. Keep implementation provisional until that evidence supports a bounded increment. Bound and qualitatively estimate the discovery work itself from its limited inspection scope; keep uncertainty about the subsequent implementation estimate separate. Do not defer discovery's own effort assessment until discovery completes. Define a finite inspection pass, its stopping condition and a qualitative effort estimate grounded in that scope; keep unresolved implementation effort separate. State which evidence or artifacts the pass will inspect and what concrete artifact or decision it will yield. Treat the cap as a proposed plan constraint, not a claim that inputs were inspected or effort measured. If required evidence is unavailable, record the exact gap and stop the affected inspection while continuing useful authorized alternatives. If a defensible qualitative bound cannot yet be established, narrow the pass before execution rather than claiming it is estimable. Use available authorized read-only evidence before asking the user for facts you can establish. Do not manufacture an estimate, make discovery mandatory when evidence is sufficient, or substitute discovery for the final outcome.

Use the project's existing delivery and environment-promotion process. Do not turn a planning convention or hypothetical unrelated interference into extra operator preflights, predicted resource or diff allowlists, approval gates, scripts or pipelines. Preserve required project checks and authority boundaries. When the existing workflow qualifies changes in a test environment before promotion, inspect the actual result, repair through that workflow and promote when qualified. Investigate observed interference and reassess material risk; do not invent an extra prerequisite without evidence or an applicable project rule.

Define delivery according to the requested outcome and established workflow: for example, a locally installed artifact or a qualified production release. Complete its required stages. A commit, green CI, or publication proves only its own stage.

## Assess before executing

Authorized bounded context and sample inspection may inform a proposed plan before these reviews; do not make simple read-only evidence gathering wait on a plan-review ceremony. Stay within existing access and project rules. Executing a formal discovery increment or implementing its findings still requires the reviews below.

Have **the architect, JTBD reviewer and risk scorer assess the initial plan and every revised executable plan before dependent execution**. Give each reviewer the objective, exact plan revision, relevant evidence, scope, assumptions, and applicable project rules.

Use the installed review roles or available independent agents assigned those responsibilities. The JTBD reviewer checks the objective and plan against the relevant persona and desired outcomes. Follow its recommendation-review contract, including a `RECOMMENDATION REVIEW` prompt prefix where required; recommendation review does not authorize file edits. Identify any substitution and its limits. If any of the three substantive reviews cannot be obtained, report the exact missing capability and hold dependent implementation. Continue useful authorized preparation within existing authority. An ordinary go-ahead does not provide the missing review or itself waive this gate; do not infer informed risk acceptance or substitute another confirmation for that capability. Do not claim the plan passed or silently substitute self-approval.

Resolve substantive architecture **and JTBD** failures and reduce above-appetite risk under the applicable policy, then reassess the revised plan before dependent execution. A completed review with unresolved substantive findings is not a pass. Distinguish forecast controls from controls already verified. Plan assessment does not replace concrete code, commit, push, release, or operational reviews required by the project.

Reviews are part of execution, not an extra request for human approval at every cycle. Continue within existing user authorization and policy. Replanning does not grant permission for new external effects, wider scope, persistent goals, or automations.

## Deliver, verify, learn, replan

Execute the assessed **Now** increment through the applicable delivery workflow. Integrate independently safe changes promptly and preserve other owners' work. Keep unfinished functionality safely dormant where necessary.

After every delivered increment:

1. **Verify:** inspect the actual completion evidence and state exactly what it establishes. Compare the result with both the increment's acceptance criteria and the overall objective.
2. **Learn:** record the material facts that changed understanding: invalidated assumptions, unexpected coupling, failures, useful measurements, and remaining uncertainty. Keep this brief and evidence-based.
3. **Replan:** rewrite Now from the remaining gap to the objective; revise, reorder, split, replace, or drop Next and Later items as evidence warrants. Do not mechanically promote the old Next item or retain work merely because it was planned.
4. **Reassess:** obtain architecture, JTBD and risk assessments of that revised plan before its dependent work begins.
5. **Continue:** execute the new Now within authorization. Completing an increment is a planning checkpoint, not automatic completion of the user's task.

Replan earlier when evidence invalidates an assumption or makes the current increment unsafe, infeasible, or ineffective. Do not wait for its nominal release to reconsider it. Preserve recoverable work and respect action-specific safety and retry rules.

When verification fails, the increment remains unverified. Diagnose and repair within the assessed scope, or revise and reassess the plan if the evidence changes its scope, assumptions, sequence, or risk. Do not count a failed check as delivery and advance anyway.

## Improvise, overcome, adapt

Treat an obstacle as a prompt to find a workable route toward the confirmed outcome. A missing tool, failed command or recoverable check failure is a problem to diagnose and work through. Inspect the cause, use available equivalents, make bounded reversible repairs and try another practical approach within the assessed scope. Continue useful independent work while a dependency is unavailable. Do not stop or ask the user to resolve routine implementation choices you can handle.

Adapt the means while preserving the confirmed outcome, its completion evidence, constraints and authority. Reassess a materially revised executable plan. Persistence does not justify bypassing reviews, inventing access, weakening acceptance or blindly repeating an external action with an ambiguous result. Call the task blocked only when the remaining progress genuinely needs unavailable capability, authority or an irreducible user action after useful authorized alternatives have been exhausted; report that precise gap and the smallest action that unlocks it.

## Finish or report the exact blocker

Finish when the objective's completion evidence is satisfied. Record the verified result and useful learning; mark remaining speculative work unnecessary or outside the achieved objective. Do not manufacture another increment to keep the loop running.

Recording verified completion is a terminal status update, not another executable plan. Any newly proposed work still needs its own assessed plan.

If blocked, first exhaust useful authorized steps available to the agent. Preserve work, distinguish completed increments from unfinished outcomes, and report the precise missing evidence, capability, authority, or irreducible user action. Resume from fresh evidence when the blocker clears; do not restart completed effects.

Communicate the objective, consequential plan changes, decisions requiring input, exact blockers, and verified outcomes concisely. Avoid narrating routine commands or every review and wait.
