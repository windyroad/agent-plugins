# Problem 559: Outcome-led planning lacks optional GitHub agent coordination

**Status**: Closed (closed-on-evidence 2026-10-17 - final verification below cites 58 passing cases per runtime, qualified registry artifacts, standalone native reference loading and live documentation. Recovery: rerun /wr-itil:transition-problem 559 known-error to reopen)
**Reported**: 2026-10-16
**Priority**: 6 (Medium) - Impact: 2 × Likelihood: 3
**Origin**: internal
**Effort**: M
**WSJF**: 0.0 - (6 × 0.0) / 2 for Verification Pending; the composed Known Error preflight score is documented below.
**JTBD**: JTBD-008, JTBD-004, JTBD-003
**Persona**: developer

## Description

The published planning skill confirms outcomes and replans increments, but does not offer GitHub Issues as a shared planning vehicle. Contributors lack a reusable outcome → increment with horizon → task protocol for ownership, overlap checks, shared discussion, dependency handoffs and outcome-owner replanning. The user requested this optional capability and its release. Existing local planning must remain usable.

## Symptoms

The planning entrypoint and its package contain no GitHub coordination protocol. A project-specific adaptation exists, but its project rules are not suitable for copying into the public reusable skill.

## Workaround

Agree on coordination manually or maintain a project-specific skill adaptation.

## Impact Assessment

- **Who is affected**: developers coordinating multiple agents, including agents using different GitHub accounts.
- **Frequency**: recurring when shared outcome work spans sessions or contributors; qualitative estimate, no usage measurement.
- **Severity**: Impact 2, Likelihood 3 reflects avoidable duplicate work and missed handoffs without evidence of service interruption.
- **Effort**: M estimate for conditional guidance, compatibility packaging, behavioral qualification and documentation through existing release tooling.

## Root Cause Analysis

The original published workflow defines iterative planning but leaves the shared tracking and contribution protocol unspecified. This is a capability gap, not an interruption of a previously working service.

### Investigation Tasks

- [x] Confirm the user-requested hierarchy, ownership and cross-agent handoff requirements from prior conversation evidence.
- [x] Verify existing package synchronization and runtime projection can carry a conditional reference.
- [x] Qualify optional tracking, scoped contributions and replanning through actual behavioral runs.
- [x] Verify stable registry artifacts, fresh runtime installations and public documentation.

Plan G18 repairs existing planning boundaries exposed by the first actual Claude campaign. Exact G13 CI `38982728285` at `2935c7e1d0642c5f2e7f55f5cb447428bb2ed65f` retains 44 passes, four failures and zero errors. Both missing-JTBD responses improperly proceed on generic go-ahead. A goal playback adds implementation questions and invents an inconsistent date. Independent oracle review finds the fourth row's immediate-planning rationale stronger than its “only after confirmation may” rubric; its unnecessary local tracking question still exposes an existing-default ambiguity. Preserve all failed results and original 48 scenarios/rubrics without rescoring or waiver.

The personal SKILL is clarified first, preserving the pending G16 reference, mode and picker. Canonical/ITIL bodies then synchronize. Clarifications hold dependent implementation for a missing required independent review, preserve stated timing, avoid a design interview during sufficient goal playback, and retain local tracking without evidence of shared coordination value. Existing STORY-108 qualification scope carries this bounded repair; historical P557 completion and broad P459 Known Error remain unchanged. G16's unfinished Codex campaign stopped at exit 130 when trunk failed and receives no qualification credit; its complete source slice remains recoverable. Fresh 48-case Codex and exact-CI Claude qualification are required before restoring later refinements. Patch changesets can combine with the subsequent qualified minor release; no premature stable merge or documentation activation.

G18's fresh Codex campaign retains 47 passes, one failure and zero errors (exit 100). The earlier four boundary cases pass. Independent oracle review confirms that the remaining initial-plan response names inspection targets but explicitly defers discovery's own effort assessment until evidence arrives; its missing qualitative discovery bound fails the existing INVEST requirement. The grader overstates the absence of scope, so no numerical duration or invented estimate is required. G18a clarifies a finite inspection pass, concrete output and stopping condition, with a grounded qualitative effort assessment before execution and later implementation uncertainty kept separate. Preserve the failed execution and every original scenario/rubric. Fresh complete qualification remains required.
## Current refinement scope

The later generic handoff adds actual selected Project field verification, continuous task maintenance and not-planned retirement with preserved acceptance, and bounded coordination reads during active coding. Plan G16b keeps Projects optional and does not add access, standing polling or messaging authority. Personal-first synchronization, the narrowly traced cadence-oracle correction, three additional scenarios and fresh 54-case runtime campaigns precede minor package releases and public documentation. Earlier publication and baseline qualification do not establish these later refinements.

Plan G16c incorporates the later pinned active-work cadence refinement: read relevant increment comments throughout coding and before dependent actions, pushes, scope/ownership changes and handovers; acknowledge handoffs and answer owned-work questions through existing authorized channels; record a bounded active-window cadence and distinguish posting from actual recipient acknowledgement. It adds no permanent poller, wakeup guarantee or messaging authority. The personal reference is updated first while preserving the G18a SKILL, mode and picker; canonical and ITIL references synchronize. The new active-work case is expanded without changing the original scenarios beyond the previously approved waiting-only cadence clause. Fresh 54-case qualification and actual G18a Claude48 plus whole-CI success remain required before integration. Patch and minor changesets will combine through normal versioning; documentation will be rebuilt and rechecked against the new SKILL inputs.

## Dependencies

- **Blocks**: shared optional GitHub planning capability.
- **Blocked by**: none; normal repository review and delivery gates apply.
- **Composes with**: independently installed planning reviewers.

## Related

- P557 / RFC-106 / STORY-106 delivered the original planning capability; preserve their historical completion.
- Capture duplicate check used title keywords outcome, GitHub and coordination. No matching open capability ticket was found.
- Fresh-context hang-off review returned PROCEED_NEW: P070, P207, P220 and P413 share JTBD-004 but concern upstream reporting, labels or polling rather than outcome planning.
- Plan G3: optional GitHub reference, local skill first, standalone/compatibility synchronization, explicit Codex subject/grader, substantive behavior and package checks, stable release, then public documentation activation. Architecture, JTBD and plan risk PASS; forecast residual 4/25. Concrete pipeline assessments remain required.
## RFCs

- RFC-108: Coordinate shared outcomes with optional GitHub Issues, release row on [the developer journey](../../story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html), with STORY-108.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-108 | STORY-108: Coordinate shared outcomes with optional GitHub Issues | done |

## Qualification history

G16c qualification retained 52 passes, two failures and zero errors across 54 Codex cases. Independent TDD review identified a preflight oracle-context error: the response preserved source-required reviews only for a materially revised plan, while rejecting the invented gates. The handoff case exposed ambiguity between stored Blocked status and a current assessment of useful work. G16d clarifies reassessment before assignment release and adds the missing conditional-review context to the preflight rubric. Scenario inputs and negative assertions remain unchanged; the earlier result is not rescored. Fresh complete 54-case qualification in both runtimes remains required.

G16d qualification retained 52 passes, two failures and zero errors. Independent TDD review confirmed two genuine omissions on the projected surface: owner or unresolved-owner records for the current increment and completed task, and agreement/recording of the proposed active-work cadence. G16e clarifies those existing requirements in the reference, preserving every scenario, rubric, model and provider. Earlier results are not rescored; fresh complete runtime qualification remains required.

Reviewed G19a/G16e supersedes the historical separate Claude48-before-integration condition. Final 54-case qualification retains the original scenarios and is required in each runtime before stable release. Source integration follows whole green G19a CI and fresh complete Codex54, enabling CI-authenticated Claude qualification; quota skips earn no behavioral credit.

G16e qualification retained 53 passes, one failure and zero errors (exit 100). Independent TDD review finds that the handoff response leaves bounded checking unspecified while cadence agreement is pending; the grader overstates this as explicit suspension. G16f clarifies that pending agreement does not suspend already-authorized active-work checks or existing action checkpoints. The source correction preserves every scenario, rubric, model and provider. The failed result remains unchanged and complete fresh qualification remains required.


## Fix Strategy

Provide optional GitHub tracking through the existing conditional reference boundary, preserve local planning, synchronize standalone and compatibility surfaces, qualify the actual behavior, then publish through the existing package and documentation workflows. Release vehicle: `.changeset/current-shared-planning.md`, combined with `.changeset/clear-planning-boundaries.md` in the normal version release.

The medium effort rating remains appropriate to the bounded guidance, packaging, behavioral qualification and documentation scope. Impact 2 and Likelihood 3 remain unchanged. The composed Known Error preflight uses multiplier 2.0 and effort weight 2, giving WSJF 6.0 before removing this delivered fix from the development ranking.

## Reproduction and verification

The original published skill omitted the selected GitHub tracking and contribution protocol. The retained behavioral scenarios in `packages/planning/skills/outcome-led-planning/eval/promptfooconfig.yaml` reproduce and verify the capability boundaries. The complete final campaign passes all 58 cases in each runtime across canonical and projected surfaces, bound to the published source. Earlier failures remain retained without rescoring. The existing manual-coordination workaround remains available.

## Fix Released

`@windyroad/planning@0.3.0` and compatibility `@windyroad/itil@3.3.0` were published on 2026-10-17 from `2e53b447baa227c1a25ca7555da37e2e080f04b5` by [release run 39017618182](https://github.com/windyroad/agent-plugins/actions/runs/39017618182/attempts/1). Both registry artifacts pass signatures, attestations, integrity and qualified-source payload comparisons. Fresh standalone planning installation, discovery and complete native reference reading pass in Claude Code and Codex; native ITIL behavior, full runtime parity and live cross-account GitHub effects remain unclaimed.

The personal skill was updated first and remains usable with its original picker and modes. [Documentation source CI 39018647304](https://github.com/windyroad/agent-plugins/actions/runs/39018647304) and [deployment 39019494258](https://github.com/windyroad/agent-plugins/actions/runs/39019494258) succeed at `7c6000227998e78519660e30d32fdcd3483a881e`. Seven served routes match the downloaded workflow artifact. Actual public mobile navigation, keyboard search, focus return, source links and WebKit phone emulation pass; the repository About homepage is correct. The [released coordination guide](https://windyroad.github.io/agent-plugins/outcome-led-planning/) states the qualified behavior and minimum versions.

The release-vehicle helper resolves `.changeset/current-shared-planning.md` to version commit `696e5d3e72d766acdacf0d1f7b4e3420ef170041`, [PR #533](https://github.com/windyroad/agent-plugins/pull/533), merge `2e53b447baa227c1a25ca7555da37e2e080f04b5`, released 2026-10-17. Both composed transition legs have passed; no conditional deferral or upstream-report surface is present.

At the Verification Pending stage, the separate final close verification was awaited. That check is completed below; no additional user confirmation is required for this evidence-authorized close.


## Final verification and evidence-authorized closure

Final close verification on 2026-10-17 returns PASS (`docs/audits/planning-plugin-workspace/github-planning/g40-p559-final-verification.json`). The normal close-block predicate exits 1, meaning clear. All nine qualified behavioral inputs remain unchanged. The installed personal skill and reference still match the qualified canonical files, with modes preserved. Seven current public routes still match the exact qualified Pages artifact byte for byte.

The retained complete campaigns pass 58 source-evaluation cases in each runtime. The actual stable release, both-package signature/provenance/integrity and payload bindings, fresh standalone planning installation/discovery/native complete reference reads, and deployed public journeys are recorded above and in STORY-108's completion evidence. [Release workflow 39017618182](https://github.com/windyroad/agent-plugins/actions/runs/39017618182), [documentation deployment 39019494258](https://github.com/windyroad/agent-plugins/actions/runs/39019494258) and the [live coordination guide](https://windyroad.github.io/agent-plugins/outcome-led-planning/) identify the shipped result. Native ITIL behavior, full parity, physical-device testing and live cross-account GitHub effects remain outside the verified claims.

This closes P559 on its own capability evidence. It does not close broader P459 or ratify proposed ADR-141. Earlier failed campaigns and the manual coordination workaround remain recorded. Recovery: rerun `/wr-itil:transition-problem 559 known-error` to reopen.
