# Problem 399: ADR-073 fix-time auto-create emits a SKELETON RFC; it should author the RFC fully

**Status**: Open
**Reported**: 2026-06-28
**Priority**: 12 (High) — Impact: 4 x Likelihood: 3 (user-directed; the recurring under-scoped-RFC population observed 5× on 2026-06-28)
**Origin**: corrective-feedback (user, 2026-06-28 — ratified at the work-problems loop-end decision surface)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

ADR-073 ("Fix-time gate auto-creates a missing RFC, everywhere") currently mandates that the I13 propose-fix gate, on firing against a Known Error with no RFC trace, auto-creates a **skeleton** RFC: per ADR-073 line 35, "a skeleton tracing the problem, scope = the fix, no story decomposition (`stories: []`), carrying **no decisions**." The intent was that the skeleton is "instantiating the vehicle, not inventing direction" — to be fleshed out later.

In practice this produces **systematically under-scoped RFCs**: across 2026-06-28, 6 of 7 auto-created skeleton RFCs (RFC-028/029/030/032/033/034) traced problems whose fixes had already SHIPPED while the RFC `## Scope` stayed the empty `capture-rfc` placeholder — the "flesh it out later" step never self-fires (a P375 cadence-rot instance). The skeleton was observed/queued as ADR-073's own reassessment trigger 5× in one session (P314/P367/P375/P381/P376 iters).

**User direction (2026-06-28, verbatim sense):** *"It's not supposed to create the RFC skeletons. It's supposed to do the full work … it's supposed to properly create the RFC's, rather than a skeleton."* — i.e. when the I13 gate auto-creates an RFC at fix-time, the framework must **author the complete RFC** from the already-traced problem context (a real `## Scope`, the approach/decision, and the task decomposition), NOT emit an empty placeholder. The scope is derivable from the problem ticket + the fix being proposed, so authoring it fully is framework-mediated work (consistent with ADR-073's own "the scope is the already-traced problem's fix" rationale), not new direction-setting.

## Symptoms

- Auto-created RFCs (RFC-028..034 this session) carry placeholder `## Scope` / empty decision sections while their traced fixes shipped.
- "Flesh out later via /wr-itil:manage-rfc" never self-fires (P375 cadence-rot) → permanent under-scoping.

## Workaround

(none — needs the mechanism fix)

## Impact Assessment

- **Who is affected**: plugin-developer (RFC trace quality / JTBD-008 every-RFC-traces-a-real-design) + adopters reading RFCs to understand a change's design. The trace invariant (ADR-071/ADR-060) is satisfied structurally but hollow.
- **Frequency**: every fix-time auto-create (multiple per AFK session).
- **Severity**: no functional break, but the RFC corpus fills with hollow placeholders that defeat the trace's purpose.

## Root Cause Analysis

ADR-073's chosen option deliberately scoped auto-create to a **skeleton** (no scope authoring, `stories: []`, no decisions) to stay clear of the ADR-044 cat-1 direction-setting boundary. The user's direction reclassifies *authoring the full RFC from the traced problem* as framework-mediated (the direction — every fix gets an RFC — is already pinned by ADR-071; the scope is derivable), so the skeleton carve-out is too thin.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Amend ADR-073: auto-create authors a FULLY-SCOPED RFC (populated `## Scope`, approach, task decomposition derived from the problem + proposed fix), not a skeleton — architect review + user ratification (P357). Reconcile with the ADR-044 cat-1 boundary. **Done 2026-06-28** — ADR-073 amended in place (Decision Outcome + Confirmation + Consequences + ADR-044 reclassification paragraph flipped in lockstep); `human-oversight: confirmed → unconfirmed` (substance changed; post-change ratification queued for next interactive drain per P357/ADR-066 — AFK has no post-change AskUserQuestion). Architect PASS, JTBD PASS.
- [x] Rework the auto-create mechanism (the I13 gate's `/wr-itil:capture-rfc` invocation in manage-problem + the work-problems iter-prompt auto-create clause) to author the full RFC at fix-time rather than a placeholder. **Done 2026-06-28** — both surfaces now invoke `/wr-itil:capture-rfc --fix-time`.
- [x] Update `/wr-itil:capture-rfc` (or the fix-time path) so the LLM authors scope/approach/tasks from context. **Done 2026-06-28** — new `--fix-time` flag; Step 5 authors `## Scope` + `## Tasks` from the traced problem's RCA + Fix Strategy.
- [x] Behavioural test: an auto-created RFC has a non-placeholder `## Scope` + task list. **Done 2026-06-28** — paired promptfoo eval case in `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` (Tier-A `--fix-time` anchor; R009 prose-surface floor).
- [ ] **Deferred (tracked as RFC-005 B11):** ADR-060 I13 prose alignment (line ~110 still says "skeleton… fleshed out later") — a separate focused ADR edit (touching `docs/decisions/060-*.md` trips the multi-decision-file architect-gate deadlock + ADR-077 compendium regen; same posture as RFC-005 B2-followup). Closes the invariant-vs-decision contradiction; ADR-073 is the authoritative substance (ADR-031) meanwhile.
- [ ] **Deferred (tracked as RFC-005 B11):** Backfill the 6 under-scoped RFCs created this session (RFC-028/029/030/032/033/034) — flesh out via `/wr-itil:manage-rfc` or supersede.

## Fix Strategy

The fix mechanism IS RFC-005's B11 task — RFC-005 ships the B3/B4/B5 fix-time auto-create mechanism this ticket refines, so P399 is wired into RFC-005's `problems:` array as the existing fix vehicle (P371 existing-vehicle-untraced sub-case (a) — wired, not auto-created). See [RFC-005](../../rfcs/RFC-005-rfc-first-trace-invariant-not-enforced-at-fix-time.accepted.md) B11.

**Core slice landed 2026-06-28** (this iter): ADR-073 amendment + `--fix-time` flag on capture-rfc + I13 gate rework (manage-problem + work-problems) + paired promptfoo eval + changeset (@windyroad/itil). **Deferred:** the ADR-060 I13 prose alignment + the 6-RFC backfill (both tracked on RFC-005 B11). The ticket stays Open until the deferred items drain.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: ADR-073 (the decision amended), ADR-071 (RFC-mandatory invariant), ADR-072 (gate placement), ADR-044 (cat-1 boundary reclassification), P371 (existing-vehicle-trace branch — sibling I13 refinement), P375 (the "flesh out later never fires" cadence-rot that makes skeletons permanent), P251 (trace invariant).

## Related

Ratified at the 2026-06-28 `/wr-itil:work-problems` loop-end decision surface (the ADR-073 reassessment question, surfaced 5× across P314/P367/P375/P381/P376 iters that session). User overrode the offered "keep skeletons as living docs" option: the auto-create must do the full RFC work.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-005 | accepted | RFC-first trace invariant not enforced at fix-time |
