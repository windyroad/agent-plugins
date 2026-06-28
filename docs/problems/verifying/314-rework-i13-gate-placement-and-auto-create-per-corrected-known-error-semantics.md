# Problem 314: Rework the fix-time RFC-trace gate — wrong lifecycle placement (ADR-072) + hard-block should be auto-create (ADR-073), per corrected Known Error semantics

**Status**: Verification Pending
**Reported**: 2026-05-26
**Origin**: internal
**Priority**: 8 (Medium) — Impact: 4 x Likelihood: 2 (re-rated 2026-06-10 — design rework + Phase 1 prose alignment landed; residual exposure is Phase 2 implementation riding the held-changeset window)
**Effort**: L (re-rated 2026-06-10 — Phase 2 RFC-005 B-tasks: propose-fix gate relocation + auto-create mechanism + behavioural bats; significant single-plugin change)
**WSJF**: 4.0 ((Severity 8 × Status 2.0) / Effort L (4))

## Fix Released

<!-- no-changeset-reference -->
Released across the held-changeset window; the P314 fix shipped incrementally over multiple `@windyroad/itil` versions rather than a single changeset, so `wr-itil-derive-release-vehicle` has no single `.changeset/<name>.md` to cite (exit 2 — manual citation per ADR-049 routing).

- **Core gate** (RFC-005 B3/B4/B5 — the I13 propose-fix RFC-trace gate that auto-creates a missing RFC, the two corrections this ticket scopes): released in `@windyroad/itil@0.50.3` (commit `d6447b3`).
- **Phase 1 prose alignment** (Known Error semantics): commit `8a2fb20`.
- **B9 retro-wiring** (`check-autocreate-rfc-scope.sh` advisory): released in `@windyroad/retrospective@0.25.0`.
- **B10 held-changeset graduation**: empirically complete — `ls .changeset` clean (no held changesets), local `@windyroad/itil` == published `0.55.0`. Both transition-readiness conditions the ticket named are now met (B2-followup landed 2026-06-27; B10 graduated).

**Fix summary**: the fix-time RFC-trace gate now fires at the propose-fix step on a Known Error (ADR-072, not `Open → Known Error`) and auto-creates a problem-traced RFC when one is missing, everywhere the gate fires (ADR-073, never hard-blocks). Predicate `check-fix-rfc-trace.sh` (exit-0-never-block) + bin shim + 11/11 green bats; gate wired into both `manage-problem` and `work-problems` SKILLs; auto-create branch dogfooded end-to-end on P361 (RFC-026↔P361).

Awaiting user verification.

## Description

The `/wr-architect:review-decisions` drain of ADR-072 + ADR-073 (the F1/F4 extractions from RFC-005, created this session) surfaced **two user rejections** that together require reworking the fix-time RFC-trace gate design. Both ADRs were left **unoversighted** (no marker written); this ticket scopes the rework.

### Correction 1 — Known Error semantics (rejects ADR-072's gate placement)

User correction 2026-05-26 (verbatim): *"You've got the process wrong. A problem becomes a known error when we have a documented workaround and root cause. Once it's known error then we can propose a fix which would result in an RFC."*

Corrected lifecycle semantics:
- A problem reaches **Known Error** on **root cause identified + documented workaround** — NOT on "fix strategy known / work is real" (the wrong framing ADR-072 + RFC-005 F1 used).
- The **fix is proposed AFTER Known Error**, and proposing the fix is what **produces the RFC**.

Therefore the RFC-trace gate **must not** fire at the `Open → Known Error` transition (a problem reaches Known Error with no fix and no RFC yet). It must fire **when a fix is proposed / fix work commences on a Known Error**. ADR-072's chosen placement (`Open → Known Error`) is wrong; RFC-005 F1's three options were evaluated against a wrong model.

### Correction 2 — auto-create, not hard-block (rejects ADR-073), everywhere

User correction 2026-05-26 (verbatim): *"No, it's supposed to create the RFC if it's missing"* + scope answer *"Everywhere the gate fires"*.

ADR-073 chose **hard-block + skip-to-next** (orchestrator) on the ADR-044-cat-1 rationale that RFC scope is direction-setting and must stay with the user. The user reverses this: a missing RFC for a mandatory-RFC fix (ADR-071) should be **auto-created** (a problem-traced RFC — its scope IS the fix it traces, so auto-creating it is instantiating the mandatory vehicle, not inventing direction), **at every fix-time surface** — the AFK orchestrator dispatch AND the interactive `/wr-itil:manage-problem` + commit-hook gate. A missing RFC is never a block; the framework always creates it.

## Symptoms

- ADR-072 (`docs/decisions/072-...proposed.md`) records a gate placement (`Open → Known Error`) built on a wrong Known Error model.
- ADR-073 (`docs/decisions/073-...proposed.md`) records a hard-block stance the user reversed to auto-create-everywhere.
- ADR-060 invariant **I13** (added this session) encodes both errors: "trace-to-RFC at fix-time … before the `Open → Known Error` transition … hard-block … orchestrator hard-blocks per ADR-073."
- RFC-005 F1/F3/F4/F5 + B2–B10 task decomposition all assume the `Open → Known Error` placement + hard-block enforcement.

## Workaround

The I13 enforcement code (RFC-005 B2–B10) has not shipped yet — it rides the held-changeset window — so no live behaviour is wrong; only the recorded design is. Rework before that enforcement is built.

## Impact Assessment

- **Who is affected**: the (not-yet-built) fix-time gate; any future implementation of RFC-005 B2–B10 would build the wrong placement + wrong behaviour.
- **Frequency**: one-shot design rework (blocks correct I13 implementation).
- **Severity**: Moderate — recorded-design error in accepted-framework territory (ADR-060 I13); high drift cost if implemented as-is.

## Confirmed design (2026-05-26 — user-ratified via /wr-architect:review-decisions)

The substantive decisions are now human-confirmed (the P315 lesson applied — confirm substance before building):

- **Lifecycle (corrected)**: `Open → Known Error → Verifying → Closed`. "Fix Released" is NOT a separate state — releasing the fix IS the `Known Error → Verifying` transition (ADR-022). (User: *"there's no difference between fixed released and verifying"*.)
- **Known Error** = root cause identified + documented workaround. No fix, no RFC yet.
- **Gate placement (ADR-072 corrected)**: the RFC is created/required at the **propose-fix step on a Known Error** — a `/wr-itil:manage-problem` propose-fix action — NOT at `Open → Known Error` and NOT a new lifecycle state. The RFC is the fix-proposal artifact. (User confirmed Option A.)
- **Gate behaviour (ADR-073 corrected)**: when the propose-fix gate fires with no RFC, **auto-create a problem-traced RFC** (skeleton tracing the problem; scope = the fix; composes with ADR-070 no-decisions + ADR-071 every-fix-via-RFC) — NOT hard-block. **Everywhere the gate fires** (interactive `/wr-itil:manage-problem` AND the AFK `/wr-itil:work-problems` orchestrator). (User confirmed auto-create + "everywhere".)
- **ADR-044 note**: this overrides the ADR-073-original cat-1 rationale (RFC scope is direction-setting → user must author). User direction: auto-creating a problem-traced RFC is instantiating the mandatory vehicle (scope = the fix), not inventing direction.

## Resolution — design rework complete (2026-05-26)

The **design** rework is done (committed this session); the gate **implementation** remains RFC-005's B-tasks (held-changeset window).

- **ADR-072** rewritten + `git mv` to `072-rfc-required-at-fix-proposal-on-a-known-error` — placement = propose-fix step on a Known Error (conforms to ADR-022); born-confirmed (user-ratified substance).
- **ADR-073** rewritten + `git mv` to `073-fix-time-gate-auto-creates-missing-rfc` — auto-create a problem-traced skeleton RFC everywhere the gate fires; born-confirmed; includes the ADR-044 cat-1 reclassification (auto-creating the ADR-071-mandated vehicle is framework-mediated, not direction-setting; no `amends:`).
- **ADR-060 I13** rewritten (propose-fix placement + auto-create-everywhere), plus the frontmatter `amendment-driver` + the "Amendment 2026-05-26 (ADR-070/071)" blockquote corrected.
- **RFC-005** mechanism prose corrected throughout (Summary/Scope/B-tasks: propose-fix gate + auto-create, not Open→Known-Error hard-block).
- **RFC-006** (verifying): forward-pointer note added (its records are as-shipped; P314 + the rewritten ADRs are the current design).
- Architect PASS on the rework (pre-edit review of the user-ratified design); ADR-052 rejected-alternatives lint clean across the corpus.

**Remaining (not this ticket — RFC-005 scope):** build the propose-fix gate + auto-create mechanism (RFC-005 B2–B10), which rides the held-changeset window. This ticket's design-rework is complete.

### Phase 1 follow-up (2026-06-08) — upstream-prose alignment

The 2026-05-26 design rework above corrected the substantive ADRs (ADR-072 / ADR-073) + the framework invariant (ADR-060 I13) + the implementation RFCs (RFC-005 / RFC-006) but left an inconsistency in the **upstream lifecycle ADR** (ADR-022) and the **operator-facing SKILL.md prose** that still encoded the pre-correction "root cause confirmed, fix path clear" framing. A `/wr-itil:work-problems` iter sweep on 2026-06-08 closed this gap:

- **ADR-022** — Known Error definition aligned (line 18 Context + line 70 Scope), added an `## Amendment 2026-06-08 (P314) — Known Error semantics corrected` block citing the user correction verbatim + the composition with the P143 fold-fix amendment, flipped `human-oversight: confirmed` → `unconfirmed` per ADR-066 substance-change marker clearance (Decision Outcome literal unchanged; Scope sub-section reframed).
- **`packages/itil/skills/manage-problem/SKILL.md`** — Known Error prose aligned at lines 51 (Closing problems), 58 (Problem Lifecycle table), 85 (WSJF Status Multiplier rationale), 170 (Known Error work-flow header), 667 (Step 7 transition prose). No Step or behavioural changes.
- **`packages/itil/skills/transition-problem/SKILL.md`** — `known-error` destination description aligned at line 19.
- **`docs/decisions/029-diagnose-before-implement.proposed.md`** — two quoted citations of ADR-022's prior framing aligned (lines 111 + 246) with `(amended 2026-06-08 per P314)` tags. ADR-029 Decision Outcome unchanged; oversight marker preserved.
- **`docs/decisions/README.md`** — compendium regenerated per ADR-077 (picks up the ADR-022 oversight flip + new related-ADR cross-references).

**Phase 2 (RFC-005 B-tasks scope, held-changeset window):**

- [x] Implement the propose-fix gate relocation (RFC-trace gate at the propose-fix step on a Known Error, not `Open → Known Error`). **Done 2026-06-16 (iter 11)** — `wr-itil:manage-problem` Known Error fix-implementation traversal runs the I13 gate as a preamble (RFC-005 B4).
- [x] Implement the auto-create-on-missing-RFC mechanism, everywhere the gate fires. **Done 2026-06-16 (iter 11)** — load-bearing predicate `check-fix-rfc-trace.sh` (+ bin shim) detects a missing trace + emits an auto-create directive (never blocks, exit 0); the create delegates to `/wr-itil:capture-rfc` (RFC-005 B3); covers both interactive (manage-problem) and AFK (work-problems delegates through manage-problem; second carve-out added to the no-`capture-*`-mid-iter prohibition) — RFC-005 B5.
- [x] Behavioural bats asserting both invariants. **Done 2026-06-18 (iter 6)** — RFC-005 B6 closed. Predicate half fully covered by `check-fix-rfc-trace.bats` (11/11 green, re-verified iter 6 — exit-0-never-block contract + PID-boundary); the skill-orchestrated auto-create-fires half (not bats-testable — capture-rfc is a Claude skill, not a shell unit) discharged by the B8 forward-dogfood (iter 4, RFC-026↔P361 end-to-end). Effort-level coverage (a) + I2 uniformity (d) hold structurally — the predicate carries no effort or `type:` branch.
- [x] Reconcile B2 (`rfcs:` frontmatter schema) against the shipped derived `## RFCs` section. **Done 2026-06-17 (iter 2)** — RFC-005 B2 marked **done-by-reconciliation**: the literal `rfcs:` problem frontmatter is superseded by the auto-maintained derived `## RFCs` reverse-trace section (single-source-of-truth = RFC `problems:` array, ADR-060 Phase 1 item 10; dual frontmatter rejected as split-source drift). Dogfooded: P314 wired into RFC-005's `problems:` array (the I13 propose-fix gate fired `no-rfc-trace: P314` because RFC-005 — P314's own fix vehicle — did not yet claim it; the framework-correct fix is to wire the existing vehicle's trace edge, NOT auto-create a redundant RFC per ADR-073), then `update-problem-rfcs-section.sh` rendered this ticket's `## RFCs` section. Architect + JTBD gates PASS.

**Phase 2 remaining (RFC-005 B-tasks):** B10 (held-changeset graduation — RELEASE action; held-window gate empirically satisfied and changesets already published 0.50.3/0.25.0, but formally confirming/closing B10 is the orchestrator's call, not an iter-worker's). All other B-tasks discharged: **B2-followup done 2026-06-27 (this iter)** — ADR-060 I13 prose aligned to name the auto-maintained derived `## RFCs` body section (single-source = RFC `problems:` array) in place of the superseded `rfcs:` problem frontmatter "symmetric to I1"; architect PASS + JTBD PASS; marker kept `human-oversight: confirmed` (documentation-reality alignment of an already-B2-reconciled/shipped mechanism, NOT an ADR-066 substance change — contrast Phase 1's ADR-022 Known-Error-semantic flip). Compendium README unchanged (entry carries title/status/oversight, none touched) — count held at 84, no regen. Architect advisory noted (non-blocking, pre-existing, out of B2-followup scope): line 602 Confirmation criterion 3 frames the `## RFCs` trace mechanism as commit-trailer parsing vs the `problems:`-array SSOT — a follow-up reconciliation candidate, not introduced by this edit. **B6 done 2026-06-18 (iter 6)** — predicate bats green + B8 dogfood closes the auto-create-fires harness-gap; **B8 done 2026-06-18 (iter 4)** — RFC-026↔P361 forward-dogfood; **B9 done 2026-06-18 (iter 5)** — `check-autocreate-rfc-scope.sh` advisory wired into run-retro Step 2b, @windyroad/retrospective@0.25.0 shipped; **B7 done 2026-06-17 (iter 3)** — migration sweep at `docs/audits/i13-rollout-survey-2026-06-17.md`: 5 Known-Error tickets carry a proposed fix with no RFC trace (P080/P179/P305/P357/P361, all auto-create candidates), 7 are KE with no fix proposed yet, 4 traced; B8 dogfood candidate P361; rollout posture = no bulk back-fill (gate-on-next-touch). With B6 + B2-followup closed, the only remaining item is B10 (orchestrator-owned RELEASE/graduation confirmation). **Transition readiness:** per the 2026-06-18 lifecycle assessment, the `Known Error → Verifying` transition becomes a clean candidate once B2-followup lands (now done) AND B10 graduation is orchestrator-confirmed — held at Known Error this iter (iter-worker boundary; B10 confirmation is the orchestrator's call).

### Phase 2 lifecycle assessment (2026-06-18 iter 6) — transition deferred, not forced

With B6 closed this iter, the **core P314 fix is functionally complete and user-verifiable** (the ADR-022 "Fix Released" substance): the I13 propose-fix RFC-trace gate that auto-creates a missing RFC (the two corrections this ticket scopes — propose-fix placement per ADR-072, auto-create-not-block per ADR-073) is **shipped end-to-end** — gate code (B3/B4/B5) live in `@windyroad/itil@0.50.3` (CHANGELOG d6447b3), B9 retro-wiring live in `@windyroad/retrospective@0.25.0`, and the B8 forward-dogfood proved the auto-create branch end-to-end on P361 (RFC-026↔P361). No held changesets remain (`ls .changeset` clean; local == published).

**Decision: keep at Known Error this iter — do NOT force the `Known Error → Verifying` transition.** Two genuinely-remaining items keep the transition premature: (1) **B10 held-changeset graduation** is still `[ ]` and is an orchestrator-owned RELEASE/graduation action explicitly outside iter scope — although empirically the held-window gate ("B6 bats green + B8 dogfood close") is now satisfied and the changesets appear already applied (0.50.3 / 0.25.0), formally confirming/closing B10 is the orchestrator's call, not an iter-worker's; (2) **B2-followup** leaves the ADR-060 I13 framework-invariant prose still misdescribing the shipped derived-`## RFCs` reality (`rfcs:` frontmatter "symmetric to I1") — transitioning to verifying while the very invariant the fix implements has stale documentation would be transition-ahead-of-implementation. The transition becomes a clean candidate once B10 graduation is orchestrator-confirmed and B2-followup lands (its own ADR-gate-bearing iter).

**Architect re-review carve-out for this iter (advisory).** The 2026-06-08 iter incorporated the architect's first-pass scope-completeness findings — `transition-problem/SKILL.md` line 19 and `029-diagnose-before-implement.proposed.md` lines 111 + 246 were lifted into the same commit so the operator-facing prose lands consistent in one transition, avoiding the documentation-drift class the rework exists to close.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems. — re-rated 2026-06-10 (8 Medium / L held); auto-transitioned Open → Known Error per corrected semantics (root cause + corrected design recorded in user-ratified ADR-072/073/060; workaround documented — enforcement code not yet shipped so no live behaviour is wrong)
- [x] **Open design question — exact gate placement**: ANSWERED — propose-fix step on a Known Error (no new lifecycle state). Recorded in ADR-072. User-ratified 2026-05-26.
- [x] **Auto-create design**: ANSWERED — auto-create a problem-traced RFC if missing, **everywhere the gate fires** (interactive + AFK). Recorded in ADR-073 (composes with ADR-070 no-decisions + ADR-071 every-fix-via-RFC; the auto-created RFC is a problem-traced skeleton with `stories: []` and no `## Considered Options` block). User-ratified 2026-05-26.
- [x] Rework artifacts: ADR-072 rewritten + renamed (2026-05-26); ADR-073 rewritten + renamed (2026-05-26); ADR-060 I13 rewritten (2026-05-26); RFC-005 + RFC-006 updated (2026-05-26). Phase 1 follow-up (2026-06-08) added: ADR-022 + manage-problem/SKILL.md + transition-problem/SKILL.md + ADR-029 alignment with the corrected Known Error definition (architect + JTBD gates passed).
- [x] **Phase 2 (complete — transitioned Known Error → Verifying 2026-06-28)** — propose-fix gate relocation + auto-create mechanism shipped 2026-06-16 (iter 11): predicate `check-fix-rfc-trace.sh` + bin shim + bats (RFC-005 B3), manage-problem propose-fix gate (B4), work-problems carve-out (B5). B2 reconciled 2026-06-17 (iter 2 — superseded by derived `## RFCs` section; P314 dogfooded into RFC-005 `problems:`). B7 migration sweep done 2026-06-17 (iter 3 — survey at `docs/audits/i13-rollout-survey-2026-06-17.md`; 5 gate-firing tickets, B8 candidate P361, no bulk back-fill). B8 forward-dogfood done 2026-06-18 (iter 4 — RFC-026↔P361 end-to-end). B9 retro wiring done 2026-06-18 (iter 5 — `check-autocreate-rfc-scope.sh` advisory in run-retro Step 2b; @windyroad/retrospective@0.25.0 shipped). B6 behavioural bats done 2026-06-18 (iter 6 — predicate bats 11/11 green + B8 dogfood discharges the auto-create-fires harness-gap). B2-followup done 2026-06-27 (iter — ADR-060 I13 prose aligned to the derived `## RFCs` section; architect + JTBD PASS; marker kept confirmed as documentation-reality alignment). B10 held-changeset graduation confirmed complete 2026-06-28 — `ls .changeset` clean, local `@windyroad/itil` == published `0.55.0`; both transition-readiness conditions met (B2-followup landed + B10 graduated), so transitioned Known Error → Verifying. All B-tasks discharged.

## Dependencies

- **Blocks**: correct implementation of RFC-005 B2–B10 (the I13 enforcement code).
- **Composes with**: ADR-070/071 (parent decisions — unchanged), ADR-060 I13 (rewrite target), RFC-005 (adjust), RFC-006 (the implementation RFC — this is its follow-on correction), ADR-044 (the cat-1 rationale ADR-073 leaned on, now overridden by user direction), P251/P310.

## Related

- **ADR-072 / ADR-073** — rejected at the 2026-05-26 `/wr-architect:review-decisions` drain; left unoversighted; superseded/rewritten by this rework.
- **RFC-006** — the ADR-070/071 implementation RFC; this is the corrective follow-on (the gate design it carried via ADR-072/073 + I13 was wrong).
- captured via /wr-architect:review-decisions Reject/supersede path, 2026-05-26.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-005 | accepted | RFC-first trace invariant not enforced at fix-time |
