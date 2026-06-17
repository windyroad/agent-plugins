# Problem 314: Rework the fix-time RFC-trace gate — wrong lifecycle placement (ADR-072) + hard-block should be auto-create (ADR-073), per corrected Known Error semantics

**Status**: Known Error
**Reported**: 2026-05-26
**Origin**: internal
**Priority**: 8 (Medium) — Impact: 4 x Likelihood: 2 (re-rated 2026-06-10 — design rework + Phase 1 prose alignment landed; residual exposure is Phase 2 implementation riding the held-changeset window)
**Effort**: L (re-rated 2026-06-10 — Phase 2 RFC-005 B-tasks: propose-fix gate relocation + auto-create mechanism + behavioural bats; significant single-plugin change)
**WSJF**: 4.0 ((Severity 8 × Status 2.0) / Effort L (4))

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
- [~] Behavioural bats asserting both invariants. **Partial 2026-06-16 (iter 11)** — predicate fully covered by `check-fix-rfc-trace.bats` (RFC-005 B6 partial); the skill-orchestrated auto-create-fires assertion is not bats-testable (capture-rfc is a Claude skill, not a shell unit) and defers to the B8 forward-dogfood.
- [x] Reconcile B2 (`rfcs:` frontmatter schema) against the shipped derived `## RFCs` section. **Done 2026-06-17 (iter 2)** — RFC-005 B2 marked **done-by-reconciliation**: the literal `rfcs:` problem frontmatter is superseded by the auto-maintained derived `## RFCs` reverse-trace section (single-source-of-truth = RFC `problems:` array, ADR-060 Phase 1 item 10; dual frontmatter rejected as split-source drift). Dogfooded: P314 wired into RFC-005's `problems:` array (the I13 propose-fix gate fired `no-rfc-trace: P314` because RFC-005 — P314's own fix vehicle — did not yet claim it; the framework-correct fix is to wire the existing vehicle's trace edge, NOT auto-create a redundant RFC per ADR-073), then `update-problem-rfcs-section.sh` rendered this ticket's `## RFCs` section. Architect + JTBD gates PASS.

**Phase 2 remaining (RFC-005 B-tasks):** B6 auto-create-fires dogfood assertion, B7 (migration sweep `docs/audits/i13-rollout-survey-*.md`), B8 (forward-dogfood), B9 (wire reassessment criterion into run-retro Step 2b), B10 (held-changeset graduation). **B2-followup (ADR-gate-bearing, deferred to its own edit):** ADR-060 I13 prose still describes the superseded `rfcs:` problem frontmatter "symmetric to I1"; align it to name the derived `## RFCs` section. Touches `docs/decisions/060-*.md` → triggers ADR-077 compendium regen + architect edit-gate re-lock, so it is a separate focused change (mirrors Phase 1's standalone ADR-022 prose-alignment sweep).

**Architect re-review carve-out for this iter (advisory).** The 2026-06-08 iter incorporated the architect's first-pass scope-completeness findings — `transition-problem/SKILL.md` line 19 and `029-diagnose-before-implement.proposed.md` lines 111 + 246 were lifted into the same commit so the operator-facing prose lands consistent in one transition, avoiding the documentation-drift class the rework exists to close.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems. — re-rated 2026-06-10 (8 Medium / L held); auto-transitioned Open → Known Error per corrected semantics (root cause + corrected design recorded in user-ratified ADR-072/073/060; workaround documented — enforcement code not yet shipped so no live behaviour is wrong)
- [x] **Open design question — exact gate placement**: ANSWERED — propose-fix step on a Known Error (no new lifecycle state). Recorded in ADR-072. User-ratified 2026-05-26.
- [x] **Auto-create design**: ANSWERED — auto-create a problem-traced RFC if missing, **everywhere the gate fires** (interactive + AFK). Recorded in ADR-073 (composes with ADR-070 no-decisions + ADR-071 every-fix-via-RFC; the auto-created RFC is a problem-traced skeleton with `stories: []` and no `## Considered Options` block). User-ratified 2026-05-26.
- [x] Rework artifacts: ADR-072 rewritten + renamed (2026-05-26); ADR-073 rewritten + renamed (2026-05-26); ADR-060 I13 rewritten (2026-05-26); RFC-005 + RFC-006 updated (2026-05-26). Phase 1 follow-up (2026-06-08) added: ADR-022 + manage-problem/SKILL.md + transition-problem/SKILL.md + ADR-029 alignment with the corrected Known Error definition (architect + JTBD gates passed).
- [~] **Phase 2 (in progress)** — propose-fix gate relocation + auto-create mechanism shipped 2026-06-16 (iter 11): predicate `check-fix-rfc-trace.sh` + bin shim + bats (RFC-005 B3), manage-problem propose-fix gate (B4), work-problems carve-out (B5). B2 reconciled 2026-06-17 (iter 2 — superseded by derived `## RFCs` section; P314 dogfooded into RFC-005 `problems:`). Remaining: B6 dogfood assertion, B7 migration sweep, B8 forward-dogfood, B9 retro wiring, B10 held-changeset graduation, B2-followup ADR-060 I13 prose alignment.

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
