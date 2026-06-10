# Problem 287: Remove the technical/user-business type classification from problems — redundant with RFC/Story persona-anchoring (amends ADR-060)

**Status**: Closed
**Closed**: 2026-06-10 — prior-session README-cell evidence drain per run-retro Step 4a sub-step 9 (P282): VQ `Likely verified?` cell recorded "yes — observed: regression-guard bats 6/6 green; ADR-060 amendment substance verified in-place; SKILL surface clean of type-axis; zero `**Type**:` body fields" from the 2026-06-02 release session. Recovery: `/wr-itil:transition-problem 287 known-error`.
**Reported**: 2026-05-25
**Known Error**: 2026-06-02 — root cause identified; SKILL/lib/bats removal landing per twice-confirmed user direction (2026-05-25 + 2026-06-02). ADR-060 amendment substance (I12 replacement shape, Phase-4 rework) queued as outstanding_question for user re-confirmation per ADR-074. Verifying transition follows next release.
**Verifying**: 2026-06-08 — all 8 Investigation Tasks closed (SKILL surface clean of type-axis, scripts/lib clean of `lexical_classify_two_sided`, regression-guard bats 6/6 green, ADR-060 amendment substance landed + `human-oversight: confirmed` retained, 347-ticket bulk strip released). Residual `review-problems/SKILL.md` Step 4.5 § 6 prose drift (P287-stale `--no-prompt` defaults-to-type=technical rationale) fixed in this transition commit.
**Priority**: 6 (Medium) — Impact: 2 (Minor — the `type: technical | user-business` tag adds a capture-time AskUserQuestion prompt + gate-enforced schema that the user has judged redundant; carrying redundant classification degrades the schema's clarity but does not break workflow) × Likelihood: 3 (Possible — the type prompt fires on every maintainer-side `/wr-itil:capture-problem`; the redundancy is exercised on every new problem)
**Effort**: M — ADR-060 amendment (in-place or supersede) + capture-problem type-prompt removal + bulk un-migration of `type:` fields + I2/Phase-4 reconciliation + behavioural-test update
**WSJF**: 6/2 = **3.0** (Open multiplier 1.0) — corrected 2026-05-26: Impact 2 × Likelihood 3 = 6, not 5

## Description

Surfaced during the P283 prong-2 ADR-oversight drain (`/wr-architect:review-decisions`, 2026-05-25). When ADR-060 (Problem→ADR→RFC→Story framework) was presented for human-oversight confirmation, the user **confirmed the four-tier framework but amended the problem-level type classification**:

> User direction 2026-05-25 (drain confirm): *"Correct, but no business/technical classification. If that's needed, then it should be a persona classification and that persona is either a customer, a staff user (eg a manager looking at reports) or a software delivery persona (they interact with the software for delivering the software)."*
>
> Clarification 2026-05-25: *"I think the classification is not needed because it's already on the RFC."*

**Decision**: drop the `type: technical | user-business` classification from problem tickets. The classification axis is **redundant at the problem tier** because persona/JTBD-anchoring already lives at the RFC and Story tiers (RFCs are JTBD-anchored; Stories are INVEST-shaped + JTBD-anchored per ADR-060). A problem is *what hurts*; the persona it hurts is captured when the problem is decomposed into an RFC/Story, not duplicated on the problem itself.

If a persona axis is ever wanted, it is **persona-based, not technical/user-business**: `customer` (end-user of the delivered software) | `staff-user` (internal user, e.g. a manager viewing reports) | `software-delivery` (interacts with the software to deliver software — devs/ops). But the primary direction is **remove, don't replace** — the RFC/Story tier already carries it.

ADR-060 is `accepted` and deeply implemented, so this amendment is its own unit of work (not a drain-batch quick edit). ADR-060 is **left unoversighted** until this rework lands and the amended decision is re-confirmed via the asking flow (per ADR-066 — a materially-amended decision clears/withholds the marker until re-confirmation).

## Symptoms

(deferred to investigation)

- `type:` tag woven through ADR-060: Problem-tier definition, the Type-tag schema section (`technical` default | `user-business`), invariant **I2** (uniform ontology — type is "a classification facet, not a workflow split"), **Phase 4** `persona:` + `jtbd:` frontmatter machinery + invariant **I12** (JTBD-as-source-of-truth), and the JTBD-201 (incident-default `type: technical`) / JTBD-301 (no plugin-user-side type selector) driver references.
- Live implementation surfaces carrying the tag: `/wr-itil:capture-problem` Step 1.5 type AskUserQuestion prompt; the one-shot bulk migration that set `type: technical` on existing tickets; the I2 behavioural test (asserts no control-flow branch on `type`); any `**Type**:` body-field on current tickets (this ticket included, per the live schema).

## Workaround

None needed — the redundant tag is inert (does not break workflow). It is a clarity/friction cost, not a defect.

## Root Cause Analysis

### Investigation Tasks

- [x] Decide amendment shape for ADR-060: in-place amendment (the four-tier framework stands; only the type-tag sub-decision is removed) vs supersede. **Done** — in-place amendment landed (commit `54ecf83` `feat(itil): ADR-060 Amendment 2026-06-02 — strike type-tag clauses + I12 derive-then-ratify`); type-tag clauses STRUCK across Decision Outcome item 1, Type-tag schema block, I2 invariant body, Phase-3 P3.1 predicate, Phase-4 P4.2/P4.3 gating, Confirmation criterion 4, Reassessment "Type-tag drift" entry.
- [x] Confirm what "it's already on the RFC" means precisely — verify the RFC/Story tier's JTBD-anchoring fully covers the persona signal the type-tag was approximating. **Done** — Phase 4 I12 derive-then-ratify contract applies to ALL problems (persona + JTBD required on every captured ticket via LLM derivation + user ratification on ambiguity); persona-anchoring lives on problem tickets via the I12 contract, RFCs anchor to JTBDs via I1, Stories are INVEST + JTBD-anchored — no type discriminator needed.
- [x] Reconcile invariant I2: with the type-tag gone, I2's "type is a classification facet not a workflow split" clarifier needs rewording. **Done** — I2 amended (ADR-060 line 109): "ALL problems use the same WSJF formula, the same capture skill, the same lifecycle transitions, the same RFC decomposition path. The type-tag axis is retired; ALL problems are uniform by construction, not by per-type-value uniformity assertion." Enforcement preserved via the renamed `no-type-regression-guard.bats`.
- [x] Reconcile Phase 4: the `persona:` + `jtbd:` frontmatter + I12 currently key off `type: user-business`. **Done** — I12 REPLACED wholesale (ADR-060 line 528) with derive-then-ratify contract applying to ALL problems (no type-keyed gating); P4.2 amended (line 542) so the persona prompt fires UNCONDITIONALLY on derivation-failure (was: only when type resolves to user-business); P4.3 amended (line 544) so persona/JTBD are REQUIRED on ALL problems.
- [x] capture-problem: remove the Step 1.5 type AskUserQuestion prompt (maintainer-side). **Done** (commit `3a0535f`) — Step 1.5 Type classification + Rule 6 row + flag table `--type=` rows + Step 4 template `**Type**:` line + Composition table type-tag row all REMOVED from `packages/itil/skills/capture-problem/SKILL.md`. Plugin-user-side `.github/ISSUE_TEMPLATE/problem-report.yml` unaffected (JTBD-301 firewall preserved).
- [x] Migration: strip `type:` body-fields from existing problem tickets. **Done** (commit `3a0535f`) — `**Type**:` body-field stripped from 347 committed `docs/problems/**/*.md` tickets; regression-guard test `packages/itil/scripts/test/no-type-regression-guard.bats` asserts no committed ticket carries the field (6/6 green); follow-on strip on P349 landed (commit `a5cf0b2`).
- [x] Update the I2 behavioural test. **Done** (commit `3a0535f`) — original `i2-no-type-branching.bats` renamed to `no-type-regression-guard.bats`; tests positive state: no `**Type**:` body field in any committed ticket, no `**Type**:` line in skeleton template, no Step 1.5 Type classification header, no `lexical_classify_two_sided` in shared helper, ADR-017 sync compliance across per-package lib/ copies, no `--type=` flag rows in SKILL.md.
- [x] Re-confirm amended ADR-060 via `/wr-architect:review-decisions` (or create-adr amend flow) → write `human-oversight: confirmed`. **Done** — ADR-060 carries `human-oversight: confirmed` (line 3) + `amendment-driver: P287/ADR-074-substance-confirm` line (line 8) recording the user-ratified substance of the 2026-06-02 amendment.

## Fix Strategy

**Release vehicle**: .changeset/p287-type-classification-retired.md (the primary P287 changeset; the ADR-060 amendment substance ships alongside as `.changeset/adr-060-amendment-i12-derive-then-ratify.md`)

The retirement landed in four commits:

- `3a0535f` `fix(itil): P287 retire technical/user-business type classification from problems` — SKILL surface removal + 347-ticket bulk strip + helper removal + I2 bats rename to no-type-regression-guard.bats
- `54ecf83` `feat(itil): ADR-060 Amendment 2026-06-02 — strike type-tag clauses + I12 derive-then-ratify` — ADR-060 body amendment with strikethrough preservation + I12 replacement
- `d920e2b` `fix(itil): bats fixture sync to ADR-060 Amendment 2026-06-02` — fixture alignment
- `a5cf0b2` `fix(problems): strip Type field from P349 (P287 regression coverage)` — follow-on strip on a single ticket missed by the bulk pass

A residual prose-drift fix on `packages/itil/skills/review-problems/SKILL.md` Step 4.5 § 6 (replacing the "—no-prompt defaults to type=technical" stale rationale with the AFK-marker / I12 derive-then-ratify contract reference) ships in the K→V transition commit alongside this transition.

## Fix Released

Released in `@windyroad/itil@0.46.0` (merge commit `d6cc198`, PR #203, released 2026-06-02; version-packages commit `d37740b`).

Fix summary: retired the `type: technical | user-business` axis across the codebase per twice-confirmed user direction. SKILL surface (capture-problem Step 1.5 + Rule 6 row + `--type=` flag rows + Step 4 template `**Type**:` line + Composition table type-tag row) removed; shared-helper `lexical_classify_two_sided` removed; 347-ticket bulk `**Type**:` body-field strip; I2 behavioural test renamed to `no-type-regression-guard.bats` with positive-state assertions (6/6 green); ADR-060 body amended in-place with strikethrough preservation (Decision Outcome item 1, Type-tag schema, I2 invariant, Phase-3 P3.1, Phase-4 P4.2/P4.3, Confirmation criterion 4, Reassessment Criterion); I12 hard-block REPLACED wholesale with derive-then-ratify contract (every problem capture MUST derive persona + JTBD via LLM analysis; failure/ambiguity → AskUserQuestion proposal; REJECT = no-ticket, ACCEPT/CORRECTIONS = ticket-with-values; AFK callers pre-resolve via `--persona` + `--jtbd` flags or halt-with-stderr-directive); ADR-060 `human-oversight: confirmed` retained (amendment-driver line records user-ratified substance).

Awaiting user verification — the regression-guard bats suite asserts the positive state; user can verify by invoking `/wr-itil:capture-problem` interactively (no Step 1.5 type-classification prompt fires) and by reading `docs/decisions/060-...accepted.md` Amendment 2026-06-02.

Exercise evidence from this session: all 6 P287 regression-guard bats green (`node_modules/.bin/bats packages/itil/scripts/test/no-type-regression-guard.bats` — every assertion PASS); shared `derive-first-dispatch.sh` audited (no `lexical_classify_two_sided`; three surviving helpers `emit_stderr_advisory` / `derive_kebab_slug` / `risk_policy_matrix_lookup` intact); ADR-060 amendment substance verified at lines 18 + 99 + 528 + 542 + 544 + 574 + 603 + 616 + 631; `docs/problems/**/*.md` grep for `**Type**:` returns zero non-history matches; review-problems Step 4.5 § 6 P287-stale prose replaced with AFK-marker / I12 derive-then-ratify contract reference in this transition commit.

Recovery path if rollback needed: `/wr-itil:transition-problem 287 known-error`.

## Dependencies

- **Blocks**: ADR-060 human-oversight confirmation (held until this rework lands per ADR-066).
- **Blocked by**: none — investigation can begin immediately.
- **Composes with**: ADR-060 (the amendment target), ADR-066 (the oversight-marker contract that withheld ADR-060's marker), P170 (the RFC/Story framework implementation), the JTBD persona model (`docs/jtbd/` persona groupings).

## Related

(captured during the P283 prong-2 ADR-oversight drain, 2026-05-25)

- **ADR-060** (`docs/decisions/060-...accepted.md`) — amendment target; the four-tier framework is confirmed, the problem-level type-tag is removed.
- **ADR-066** (`docs/decisions/066-...proposed.md`) — the human-oversight marker; ADR-060 stays unoversighted until this rework re-confirms it.
- **P283** — the oversight-drain mechanism that surfaced this.
- **P248** — sibling WSJF-schema refinement (both touch problem-ticket frontmatter schema; coordinate migrations).
- `packages/itil/skills/capture-problem/` — the Step 1.5 type-prompt removal site.
- `docs/jtbd/` — persona groupings; the candidate home for any persona axis that survives.
