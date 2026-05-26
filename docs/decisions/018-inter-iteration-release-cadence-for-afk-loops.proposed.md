---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-26
date: 2026-04-18
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-07-18
---

# Inter-iteration release cadence for AFK loops

## Context and Problem Statement

`/wr-itil:work-problems` and any future AFK orchestrator (e.g. a hypothetical
`/wr-itil:work-incidents`) iterate through a backlog without supervision. Each
iteration may produce a commit + changeset. The current orchestrators have no
inter-iteration release step, so unreleased changesets accumulate silently
across iterations.

Observed 2026-04-18 (P041): four scorer-prompt fixes shipped in a single AFK
loop accumulated four patch changesets. The commit-risk score reached 4/25
(at appetite per `RISK-POLICY.md`) on the fourth iteration, but the loop
continued into a fifth. The user had to interrupt with "make sure you release
to avoid going over risk appetite. I shouldn't have to tell you this".

The risk-scorer framework already surfaces the cumulative push/release risk
via `wr-risk-scorer:assess-release` (ADR-015). What is missing is the
orchestrator-level response to that signal — a rule that says when the
queue must be drained before continuing.

## Decision Drivers

- **Lean release principle (ADR-014)**: governance skills commit their own
  work; the natural extension is that AFK orchestrators release their own
  work when the queue accumulates.
- **WIP commit verdict (ADR-016)**: the WIP layer is already enforced; the
  unreleased layer is not.
- **Pure-scorer contract (ADR-015)**: scoring logic lives in the scorer
  skills; orchestrators must delegate, not re-implement.
- **Non-interactive authorisation (ADR-013 Rule 6)**: a release action is
  policy-authorised when residual risk is within appetite per
  `RISK-POLICY.md`, so no `AskUserQuestion` is required for the release
  itself.
- **JTBD-006 (Progress the Backlog While I'm Away)**: the user expects
  cumulative risk to be managed, not silently accumulated, while AFK.
- **Operator trust**: the user has had to manually intervene to force
  releases; this erodes trust in the orchestrator.

## Considered Options

1. **Risk-driven cadence** — release when accumulated commit/push/release
   risk reaches appetite (4/25 per `RISK-POLICY.md`)
2. **Fixed cadence** — release every N iterations (e.g. every 3rd
   iteration)
3. **Batch cadence** — release only at AFK loop end (current de facto
   behaviour)

## Decision Outcome

Chosen option: **"Risk-driven cadence"**, because it reuses the existing
risk framework (no new threshold to maintain), aligns with the appetite
already specified in `RISK-POLICY.md`, and produces the smallest releases
that still respect the lean release principle. Fixed cadence is brittle
(N=3 may be too few or too many depending on change size); batch cadence
is the failure mode this ADR is intended to fix.

**Mechanism**:

- After each successful commit in an AFK iteration, the orchestrator MUST
  invoke `wr-risk-scorer:assess-release` (subagent_type
  `wr-risk-scorer:pipeline`, or fallback to skill
  `/wr-risk-scorer:assess-release` per ADR-015) to score the cumulative
  pipeline state.
- If the returned `push` or `release` score is at or above the appetite
  threshold (4/25, "Low" band per `RISK-POLICY.md`), the orchestrator MUST
  drain the queue before starting the next iteration:
  - Run `npm run push:watch` (push + wait for CI).
  - If `.changeset/` is non-empty, run `npm run release:watch` (merge the
    release PR + wait for npm publish).
  - Resume the loop only after the release lands on npm.
- If `release:watch` fails (CI failure, publish failure), stop the loop
  and report the failure in the AFK summary. Do not retry non-interactively.
- Scope is **cross-cutting**: this rule applies to any AFK orchestrator,
  not just `/wr-itil:work-problems`. Orchestrator skills MUST cite ADR-018
  in their SKILL.md.

**Non-interactive authorisation**: per ADR-013 Rule 6, `npm run push:watch`
and `npm run release:watch` are policy-authorised actions when the
risk-scorer reports residual risk within appetite. No `AskUserQuestion` is
required for the release itself. The fail-safe applies only when residual
risk is above appetite or when CI/publish fails.

### Amendment 2026-04-22 — Above-appetite behaviour governed by ADR-042

The Mechanism above covers the at-or-below-appetite drain path (≤ 4/25). Above-appetite behaviour (push or release ≥ 5/25) is superseded by **ADR-042 (Auto-apply scorer remediations to reach within appetite — never release above)**. The orchestrator MUST auto-apply scorer remediations incrementally until residual risk is within appetite, OR halt the loop per ADR-042 Rule 5 if the scorer cannot produce a convergent plan. The orchestrator MUST NOT release above appetite under any circumstance. See `docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md` for the full rule set (Rules 1–7), the open vocabulary (Rule 2a), the Verification Pending carve-out (Rule 2b), and the halt-on-exhaustion semantics (Rule 5).

This amendment replaces the prior implicit "skip the drain, user resolves on return" behaviour. The at-or-below-appetite drain mechanism documented above is unchanged.

### Amendment 2026-05-15 — Graduatable held-changeset disjunct (ADR-061 Rule 8)

The Mechanism above predicates the release-watch step on `.changeset/` non-empty. This amendment adds a symmetric disjunct per **ADR-061 (Dogfood graduation criteria for held changesets — symmetric risk balance drives the reinstate decision)** Rule 8 so the drain wakes when graduation-eligible material exists in `docs/changesets-holding/` even when `.changeset/` is empty. The combined amended drain condition reads:

```
Drain when: pipeline residual ≤ 4/25 AND
            (.changeset/ non-empty OR
             docs/changesets-holding/ contains entries that satisfy ADR-061 Rule 1
             AND are not VP-blocked per ADR-061 Rule 2)
```

The Mechanism's release-watch bullet ("If `.changeset/` is non-empty, run `npm run release:watch`") is amended to read: *"If `.changeset/` is non-empty OR `docs/changesets-holding/` contains entries that satisfy ADR-061 Rule 1 graduation criterion AND are not VP-blocked per ADR-061 Rule 2, run `npm run release:watch`. Graduatable held entries are first reinstated to `.changeset/` via `git mv` per ADR-061 Rule 6 audit-trail discipline (the iteration / skill report logs the pre-apply / post-apply scores, the evidence-artefact citation, the resolved problem-ticket ID + Priority value, and the graduation class)."*

Rationale: I002 (2026-05-11, `docs/incidents/I002-release-pressure-and-wip-limit-controls-not-firing.restored.md`) observed the silent-stop failure mode — ADR-042 Rule 2/6 auto-apply moved every changeset to holding, leaving `.changeset/` permanently empty and silencing `release:watch` AND `push:watch` for 4 days while the held cluster grew 3 → 13. Adding the graduatable-holding disjunct closes the empty-conjunct coupling at the drain-condition layer; the symmetric never-hold-below-graduation-threshold invariant (ADR-061 Rule 1) ensures held entries become graduation-eligible when release-risk decays at or below problem-ticket Priority.

The at-or-below-appetite drain mechanism is otherwise unchanged. Above-appetite behaviour remains governed by ADR-042 per the 2026-04-22 amendment. P162 (`docs/problems/open/162-codify-dogfood-graduation-criteria-with-counterfactual-risk-assessment-for-held-changesets.md`) Phase 4 lands this amendment.

### Amendment 2026-05-18 — Drain trigger is releasable material, not residual band (P250)

The original Mechanism predicates the drain on residual risk reaching the appetite band ("If the returned `push` or `release` score is at or above the appetite threshold (4/25, 'Low' band per `RISK-POLICY.md`), the orchestrator MUST drain the queue"). This codifies an accumulation-permitted-below-threshold semantic that violates the user's release principle and the symmetric-balance principle established in ADR-061 Rule 1. P250 (2026-05-17, `docs/problems/open/250-work-problems-step-6-5-within-appetite-no-drain-clause-defers-low-risk-releases-encoding-accumulation.md`) captures the user's verbatim direction: *"You don't want to accumulate risk. If it's low risk, you should release."*

The amended drain condition reads:

```
Drain when: pipeline residual ≤ 4/25 AND
            (any unpushed commits on HEAD..origin/<base> OR
             .changeset/ non-empty OR
             docs/changesets-holding/ contains entries that satisfy ADR-061 Rule 1
             AND are not VP-blocked per ADR-061 Rule 2)

No drain when: pipeline residual ≤ 4/25 AND empty queue
               (no unpushed commits AND no .changeset/ entries AND
                no graduation-eligible held entries)
               — literally nothing to release; the genuine no-op fast-path.

Above-appetite (≥ 5/25): route to ADR-042 auto-apply (unchanged).
```

The Mechanism bullet that previously read *"If the returned `push` or `release` score is at or above the appetite threshold (4/25, 'Low' band per `RISK-POLICY.md`), the orchestrator MUST drain the queue before starting the next iteration"* is amended to read: *"If the residual score is within appetite (≤ 4/25) AND there is releasable material in the queue (any unpushed commits, `.changeset/` non-empty, or graduation-eligible held entries per ADR-061 Rule 1), the orchestrator MUST drain the queue before starting the next iteration. If the residual is within appetite AND the queue is empty, no drain is needed (literally nothing to release). Above-appetite states (≥ 5/25) route to ADR-042 per the 2026-04-22 amendment."*

Rationale: the at-appetite-only-drain semantic encoded "accumulate until the safety band is breached" as policy. Under repeated low-risk iterations the agent silently accumulated unreleased changesets across multiple iters, then required a re-score round-trip (~$0.15-0.30 each) to detect the threshold breach, then drained a larger cumulative batch with a larger cumulative risk envelope. The amended trigger collapses this to "release every iter that produces releasable material, when residual is within appetite" — the smallest, freshest releases that still respect the never-release-above-appetite invariant. The Above-appetite branch (ADR-042) remains the safety gate; the within-appetite branch is now an action gate driven by *presence of releasable material*, not by residual reaching a band threshold.

ADR-061 Rule 1 alignment: ADR-061's symmetric-balance principle (`release-risk ≤ problem-ticket Priority` → release/graduate) is the parent principle this amendment realises at the release-cadence surface. The accumulation-permitted-below-threshold semantic was a direct violation of that principle on the `/wr-itil:work-problems` Step 6.5 surface.

P250 Phase 1 lands this amendment alongside the SKILL.md Step 6.5 amendment and bats coverage. Sibling P246 / P247 / P234 / P145 / P148 remain Open for their respective SKILL surfaces (meta-class consistency tracked via run-retro pattern detection, not through this ADR's scope).

## Consequences

### Good

- Unreleased risk never silently accumulates across AFK iterations.
- Releases are small and frequent, preserving the lean-release principle.
- The user no longer has to monitor the AFK loop to force a release.
- The release decision is delegated to the scorer (single source of truth).

### Neutral

- AFK loops take longer per iteration when a release fires (push wait + CI
  + npm publish — typically 1–3 minutes).
- The orchestrator is no longer purely "iterate until done"; it interleaves
  iterate + release.

### Bad

- A flaky CI or npm publish can stall the loop. Mitigated by the fail-safe
  (stop and report) — the user can resume after fixing CI.
- Cross-cutting rule means every existing AFK orchestrator skill needs an
  inter-iteration release step added (currently only `/wr-itil:work-problems`
  exists, so the migration is small).

## Confirmation

Compliance is verified by:

1. **Source review**: every AFK orchestrator skill in `packages/*/skills/`
   that loops over a backlog has an inter-iteration release step that
   delegates to `wr-risk-scorer:assess-release` (or its pipeline subagent
   equivalent) and acts on the returned `push`/`release` scores.
2. **Test**: a bats test asserts `packages/itil/skills/work-problems/SKILL.md`
   references both `assess-release` and `release:watch` in its
   inter-iteration logic.
3. **Behavioural**: an AFK loop that accumulates four patch changesets
   triggers a release before starting the fifth iteration. Verifiable
   manually by inspecting the commit/release log of any extended AFK run.

## Pros and Cons of the Options

### Risk-driven cadence (chosen)

- Good: reuses existing scorer; no new threshold; aligned with `RISK-POLICY.md`.
- Good: small frequent releases preserve audit trail and lean release.
- Bad: per-iteration scorer call adds latency (~1s per iteration).

### Fixed cadence (every N iterations)

- Good: simple to reason about; no scorer dependency.
- Bad: N=3 is arbitrary — three large changes may exceed appetite, three
  trivial changes may release too aggressively.
- Bad: requires a new constant to maintain, separate from `RISK-POLICY.md`.

### Batch cadence (release at end)

- Good: zero latency overhead.
- Bad: this is the failure mode P041 documents — exactly the silent
  accumulation we want to prevent.
- Bad: concentrates release risk at end-of-loop where it is most likely to
  fail and least visible.

## Reassessment Criteria

Revisit this decision if:

- The risk-scorer framework changes substantially (e.g. ADR-015 superseded).
- The lean-release principle is dropped or amended (ADR-014 superseded).
- The number of AFK orchestrator skills grows past 3 — at that point a
  shared helper skill may make more sense than per-skill inter-iteration
  steps.
- Operational data shows the per-iteration scorer latency is unacceptable
  in practice.
