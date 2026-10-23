---
name: outcome-led-planning
description: Establish and confirm a SMART outcome, then deliver through INVEST-shaped Now increments, provisional Next and Later, and five independent plan critics for initial and material plan revisions. Use for requested outcome-led planning or substantial work needing iterative delivery; skip routine single-step tasks.
---

# Outcome-led planning

Keep the confirmed outcome as the reference point; replan the means from evidence.

## Establish and confirm the SMART objective

State the result the user wants and the observable evidence that will establish completion. Separate that result from proposed technologies, activities, and delivery mechanisms. Preserve explicit user constraints and any prescribed means; do not rewrite the objective to fit an easier implementation.

Read the relevant current evidence, project instructions, decisions, jobs, risk policy, and delivery workflow. Use that context before asking for information the user has already supplied.

Use SMART to make the objective specific, measurable through observable completion evidence, achievable against known constraints, relevant to the user's job, and time-bound using the user's stated deadline or timeframe. Qualitative evidence can establish success. Surface feasibility uncertainty instead of weakening the objective or promising certainty. Never invent numerical targets or dates. Preserve stated timing and prefer relative wording. Any added date must match verified context and its weekday. Never turn a guessed date into a new timing interview. If neither a time bound nor an explicit decision to omit one is established, ask one timing question and wait. If the user declines a time bound, record the exception honestly rather than claiming full SMART compliance.

If outcome information is unclear or missing, interview the user: **ask one focused question, then stop and wait for their answer before asking the next**. Select the next question from their actual answer and remaining uncertainty. Do not bundle questions, answer on their behalf, invent their intent, or resolve ambiguity by selecting a solution. Bounded read-only investigation can establish facts within existing authority.

One question requests **one missing fact**. Do not combine multiple information needs, such as who benefits and what is wrong, into a multipart question. Sharing a topic or using one question mark does not make it one question.

Once confident the outcome is captured correctly, **play back the complete objective, its completion evidence and material constraints, and ask the user to confirm or suggest changes. Wait for their response before creating an executable plan or beginning iteration.** This applies even when the initial request already supplies a clear goal. If they suggest changes, resolve them and replay the revised goal for confirmation. Existing explicit confirmation of that exact playback satisfies this gate; do not ask again solely because the session resumed.

For a fully specified outcome, ask only whether that exact playback is correct or needs changes, then wait. Do not append examples, clarification questions or a menu about formats, interfaces, technologies, beneficiaries or delivery options. Resolve necessary means after confirmation.

Keep the confirmed objective as the reference point throughout delivery. Ordinary replanning changes the means and does not repeat goal confirmation. A substantive change to the desired result, completion evidence or constraints requires renewed user confirmation before dependent planning or execution.

## Choose the tracking vehicle

After confirming the SMART outcome, read [project tracking and shared contributions](references/project-tracking.md). Both planning and `contribute` read the same project configuration, defaulting to `.agents/planning.json`. Reuse a saved or explicit choice. When none exists, ask one question: **GitHub Issues or Local?** Wait, save the answer, read it back, and reuse it across sessions. Preserve unrelated configuration and honor explicit changes; do not silently replace malformed or unsupported settings.

Local mode needs no GitHub account or Project. When GitHub is selected, read [the GitHub coordination protocol](references/github-coordination.md) before planning or tracker mutations; use its [bootstrap instructions](references/github-coordination.md#bootstrap-github-tracking) for missing selected setup. Project fields and views apply only to selected or required Projects. Configuration grants no access, messaging or automation authority.

## Build the current plan

Keep one authoritative plan in the conversation or an agreed artifact. Honor any required project vehicle. Save continuity in a permitted document location outside runtime configuration directories. Keep updates proportional.

Include:

- **Objective and completion evidence:** the desired result and how to verify it.
- **Now:** one coherent release increment to work on now. Specify its intended result, scope, important assumptions or dependencies, verification, and what counts as delivered. Make it small enough to test, integrate, and learn from safely. A foundation increment is valid when its contribution and limits are explicit.
- **Next:** provisional subsequent release increments, describing their results and major dependencies with less detail. Their sequence and scope can change.
- **Later:** the broad direction beyond Next, at the highest level of uncertainty. Avoid speculative implementation detail and implied commitments.
- **Assessment:** the exact plan revision, five critic findings, conditions and unresolved blockers.

The plan MUST consider bounded tasks within Now and expose useful opportunities for others to contribute. A starting battle plan may describe likely work, dependencies and parallel opportunities without precreating, assigning or reserving all future tasks. In shared work, contributors create/reuse and claim bounded tasks just before work under the selected coordination rules. The increment owner keeps acceptance, sequence and integration clear and resolves overlap; explicit assignments and handoffs remain valid.

Do not fill Next or Later with invented features. If evidence does not yet justify further work toward the confirmed outcome, leave those horizons to be determined from verified remaining gaps. Preserve known delivery stages required by the objective.

Use INVEST as a quality check for **Now**: independently deliverable, negotiable means within the confirmed goal, valuable, estimable with uncertainty disclosed, small, and testable. Internal dependencies are acceptable when the whole increment remains coherently and safely deliverable. Do not manufacture precise estimates. Do not introduce story documents just to use INVEST; retain any story and approval requirements the project already imposes. Next and Later stay provisional and need less detail.

Choose the smallest independently useful business result. Name who benefits and the observable improvement, validated decision or capability. Split again if a smaller result has value; shared code does not justify bundling. Technical activity alone is insufficient. Retain required security, integrity, recovery and acceptance. Foundations need explicit value and limits; environment promotion stages are not automatically increments. Deliver the verified minimum and replan before adding work. Apply whenever Now changes; keep remaining delivery plans provisional.

If uncertainty prevents a bounded, estimable implementation increment, use a small discovery or qualification increment with explicit value, finite inspection targets, stopping condition, output and grounded qualitative effort. Read [bounded discovery guidance](references/planning-details.md#bounded-discovery) before making that increment executable. Keep later implementation provisional; do not replace the final outcome with discovery.

Use the project's existing delivery and environment-promotion process. Do not turn a planning convention or hypothetical unrelated interference into extra operator preflights, predicted resource or diff allowlists, approval gates, scripts or pipelines. Preserve required project checks and authority boundaries. When the existing workflow qualifies changes in a test environment before promotion, inspect the actual result, repair through that workflow and promote when qualified. Investigate observed interference and reassess material risk; do not invent an extra prerequisite without evidence or an applicable project rule.

Complete every delivery stage required by the confirmed outcome and project workflow. A commit, green CI, or publication proves only its own stage.

## Assess before executing

Authorized bounded context and sample inspection may inform a proposed plan before these reviews; do not make simple read-only evidence gathering wait on a plan-review ceremony. Stay within existing access and project rules. Executing a formal discovery increment or implementing its findings still requires the reviews below.

Iterate each **initial or materially revised executable plan with five independent critics before dependent execution**: architect, JTBD, risk, cognitive accessibility and planning. Give them the confirmed outcome, exact revision, evidence, scope, assumptions, dependencies and project rules. Read [critic responsibilities](references/planning-details.md#critic-responsibilities) before requesting these reviews.

Task creation, claims and routine status updates within the assessed plan do not require five new reviews or renewed human confirmation.

Use available independent reviewers and identify substitutions. Follow the JTBD recommendation-review prefix where required; that review does not authorize edits. If a substantive critic is unavailable, report the exact missing capability and hold dependent implementation; continue authorized preparation. Do not self-approve, claim a pass or treat ordinary go-ahead as a missing review. Read [reviewer capability guidance](references/planning-details.md#independent-reviewer-capability).

The planner MUST NOT add speculative risk-mitigation tasks. The risk scorer identifies necessary treatments from the applicable risk policy and risk register. The risk critic vetoes speculative mitigation increments justified only by imagined failure or agent discomfort. Require an evidenced risk or applicable requirement, credible impact/likelihood, connection to the confirmed outcome and proportionate expected reduction relative to cost and delay. A prior incident is not required: established preventive risks and required controls remain valid. A low action-risk score permits an action within appetite; it does not establish necessity or priority. Remove unjustified mitigation work from Now/Next/Later instead of inventing a registry, report, human gate or mandatory discovery increment to justify it.

Resolve substantive findings from all five critics and reduce above-appetite risk under the applicable policy. Reassess affected critics after material changes until the exact plan revision is coherent and within appetite. Record the reviewer identities, assessed revision, verdicts and evidence in the existing issue or plan artifact; no new report or template is required. A completed review with unresolved substantive findings is not a pass. Distinguish forecast controls from controls already verified. Plan assessment does not replace concrete code, commit, push, release, or operational reviews required by the project.

Perform reviews within existing authorization and policy. Replanning grants no wider scope, new external effects, persistent goals or automation authority.

## Deliver, verify, learn, replan

Execute the assessed **Now** increment through the applicable delivery workflow. Integrate independently safe changes promptly and preserve other owners' work. Keep unfinished functionality safely dormant where necessary.

For GitHub delivery, follow the [work checkpoints](references/github-coordination.md#reconcile-tracking-at-work-checkpoints), with regular discussion reads AND event checks. Reconcile each affected record and selected Project from saved state; read back changes.

At each increment boundary:

1. **Verify:** compare actual results with the increment's acceptance criteria and overall objective. Before declaring completion, obtain the [independent acceptance check](references/planning-details.md#independent-increment-acceptance), then repair and recheck discrepancies.
2. **Learn:** record the material facts that changed understanding: invalidated assumptions, unexpected coupling, failures, useful measurements, and remaining uncertainty. Keep this brief and evidence-based.
3. **Replan:** rewrite Now from the remaining gap to the objective; revise, reorder, split, replace, or drop Next and Later items as evidence warrants. Do not mechanically promote the old Next item or retain work merely because it was planned.
4. **Reassess:** iterate the revised executable plan with the five independent critics above before its dependent work begins.
5. **Continue:** execute the new Now within authorization. Completing an increment is a planning checkpoint, not automatic completion of the user's task.

Replan earlier when evidence invalidates an assumption or makes the current increment unsafe, infeasible, or ineffective. Do not wait for its nominal release to reconsider it. Preserve recoverable work and respect action-specific safety and retry rules.

When verification fails, the increment remains unverified. Diagnose and repair within the assessed scope, or revise and reassess the plan if the evidence changes its scope, assumptions, sequence, or risk. Do not count a failed check as delivery and advance anyway.

## Improvise, overcome, adapt

Treat an obstacle as a prompt to find a workable route toward the confirmed outcome. A missing tool, failed command or recoverable check failure is a problem to diagnose and work through. Inspect the cause, use available equivalents, make bounded reversible repairs and try another practical approach within the assessed scope. Continue useful independent work while a dependency is unavailable. Do not stop or ask the user to resolve routine implementation choices you can handle.

Adapt the means while preserving the confirmed outcome, its completion evidence, constraints and authority. Reassess a materially revised executable plan. Persistence does not justify bypassing reviews, inventing access, weakening acceptance or blindly repeating an external action with an ambiguous result. Call the task blocked only when the remaining progress genuinely needs unavailable capability, authority or an irreducible user action after useful authorized alternatives have been exhausted; report that precise gap and the smallest action that unlocks it.

## Finish or report the exact blocker

Finish when the objective's completion evidence is satisfied. Record the verified result and useful learning; mark remaining speculative work unnecessary or outside the achieved objective. Do not manufacture another increment to keep the loop running.

Recording verified completion is a terminal status update, not another executable plan. Any newly proposed work still needs its own assessed plan.

Before handing back a blocker, finish useful authorized work, including running checks. Preserve work, distinguish completed increments from unfinished outcomes, and report the precise missing result, capability, authority or irreducible user action. Resume from fresh evidence when the blocker clears; do not restart completed effects.

Communicate the objective, consequential plan changes, decisions requiring input, exact blockers, and verified outcomes concisely. Avoid narrating routine commands or every review and wait.
