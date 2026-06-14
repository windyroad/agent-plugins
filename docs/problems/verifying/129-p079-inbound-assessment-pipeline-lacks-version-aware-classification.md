# Problem 129: P079 inbound assessment pipeline lacks version-aware classification — already-fixed-in-newer / recurred / still-active branches

**Status**: Verification Pending
**Reported**: 2026-04-26
**Origin**: internal
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M (L → M re-rated 2026-06-10 per the ticket's own revision condition — Phase 1 LANDED 2026-06-09, Phase 2 recurrence-class lifecycle is now the only outstanding work) — assessment-pipeline classifier extension + recurrence-class lifecycle semantics + integration with closed-ticket history search + bats coverage.
**WSJF**: 12.0 — (12 × 2.0 Known Error) / M (2) — re-rated 2026-06-10: P079 no longer active (contributes 0 transitive); prior 2026-05-23 rating used Open multiplier 1.0 + L bound by P079. Phase 1 closed the "already-fixed leak" symptom; "recurrence-class invisibility" + "triage skew" symptoms remain open under Phase 2.

## Description

P079 (`docs/problems/079-no-inbound-sync-of-upstream-reported-problems.open.md`) ships an assessment pipeline that processes each inbound report through JTBD-alignment + dual-axis risk evaluation + safe-and-valid / above-threshold / clear-malicious paths (per the 2026-04-26 user direction recorded in P079's "User direction (2026-04-26 interactive AskUserQuestion resolution)" section). The pipeline as currently scoped does NOT include a **version-comparison step** that asks two cross-cutting questions before opening a fresh local problem ticket:

1. **Has this bug already been fixed in a newer version of our plugin than the reporter is on?** If so, the right action is "upgrade to vX.Y.Z" pushback, not opening a new local ticket. Without this branch, the pipeline opens duplicate tickets for issues already shipped fixed.
2. **Did we previously close a ticket against this same bug shape, but the bug surfaced again in a newer version?** That's a regression — the right action is to link the new report to the prior closed ticket, mark it as a recurrence, and route through a recurrence-handling path that surfaces the regression to the maintainer for re-investigation.

Today (and as P079 is currently scoped) the pipeline treats every inbound report as a fresh problem candidate. It does not consult the local closed-ticket history. It does not compare reporter-claimed-version against shipped-version. It does not detect recurrence shape against historical fix bodies.

User direction (2026-04-26, verbatim): *"hey, I just remembered for the reporting upstream, it needs to include version information if it doesn't already and then when we are receiving problems from downstream, we need to consider if the issue has already been fixed in a newer version or if it's recouured in a newer version, etc"*. This ticket captures the **inbound half** — what the receiving pipeline does with version info on a report. The **outbound half** (what reports carry as version info) is captured separately as P128 (companion ticket; strict block per the dependency direction).

This ticket is the **second carve-out from P079**, mirroring the carve-out shape P123 (blocked-user list) established. Like P123, P129 is pre-implementation scope-shaping on a parent (P079) that has not yet shipped. Carving here avoids retrofitting documentation onto a landed implementation.

## Symptoms

- **Already-fixed leak**: a downstream adopter on `@windyroad/itil@0.18.0` files a report describing a bug that's already fixed in `@windyroad/itil@0.20.0`. Pipeline (as currently scoped) opens a fresh local ticket. Maintainer triages, discovers the duplication, closes the new ticket, replies to reporter telling them to upgrade. Net friction: one wasted local ticket + one round-trip + one closed ticket cluttering the closed-ticket history.
- **Recurrence-class invisibility**: a downstream adopter on `@windyroad/itil@0.21.0` files a report whose bug shape matches a closed ticket against `@windyroad/itil@0.15.0`. Pipeline (as currently scoped) opens a fresh local ticket as if it were a new issue. The link to the prior closed ticket is missed; the regression analysis ("what did we change between 0.15.0 and 0.21.0 that could have brought this back?") doesn't fire because the maintainer has no ambient signal that this is a regression.
- **Triage skew**: maintainer's WSJF ranking treats every inbound report as Likelihood-Likely (4) by default. Without the recurrence-vs-net-new distinction, regressions don't get the priority bump they warrant (regressions are higher-likelihood-of-recurrence than net-new bugs because the underlying surface has a known-fragile history).
- **Audit trail gap**: closing a ticket as "duplicate of already-fixed-in-vN" by hand each time is policy-by-discipline, not contract. Different sessions handle the same shape inconsistently.

## Workaround

Maintainer, before opening a local ticket from an inbound report, manually:
1. Reads reporter's claimed version (today: from a freeform `environment` textarea, often missing).
2. Greps `docs/problems/*.closed.md` for similar bug-shape descriptions.
3. Cross-references the closed ticket's released-fix-version (today: usually a commit SHA in `## Fix Released`, requires manual lookup of which package version that SHA shipped in).
4. Compares against reporter's version. Three branches:
   - Reporter's version < first-fix-version → upgrade pushback.
   - No matching closed ticket OR reporter's version ≥ first-fix-version → open a fresh ticket.
   - Reporter's version ≥ first-fix-version AND a matching closed ticket exists → recurrence; manually link.

Error-prone, slow, doesn't scale beyond a single maintainer, and the comparison step requires the reporter's version to actually be present in the report (which P128 closes).

## Impact Assessment

- **Who is affected**:
  - **plugin-user (`JTBD-301` — get heard upstream)**: receives wrong response when their issue is already fixed (a fresh ticket eventually closed, instead of an immediate upgrade pointer). Latency to resolution extends; clarity drops.
  - **plugin-developer (`JTBD-101` — extend the suite)**: sees the same regression-class issues appearing without recurrence framing; spends investigation effort re-deriving root causes that prior closed tickets already documented.
  - **tech-lead (`JTBD-201` — restore service fast with audit trail)**: regression detection is invisible until manual cross-reference; audit trail loses the "this came back" signal needed for post-incident root-cause analysis. Critical when a regression precedes a production-class incident.
  - **solo-developer (`JTBD-001` — governance without slowing down)**: every inbound report requires manual closed-ticket-history grep and version-comparison work the assessment pipeline could automate.
- **Frequency**: every inbound report. Scales with adoption.
- **Severity**: Moderate (3) — non-catastrophic but systemic friction that compounds with closed-ticket-history depth. Higher leverage as the closed-ticket history grows; today the suite has ~70 closed tickets, growing weekly.
- **Likelihood**: Likely (4) — no enforcement today; the user's direction explicitly named both branches as missing. Every report passes through this gap.
- **Analytics**: N/A today. Post-fix candidate metrics: (1) percentage of inbound reports classified as already-fixed-in-newer (proxy for upgrade-pushback efficiency), (2) percentage classified as recurrences (proxy for regression-detection coverage), (3) maintainer time-per-inbound-report (qualitative).

## Root Cause Analysis

### Structural

P079's user-direction (2026-04-26) named the assessment pipeline's required steps:

1. JTBD alignment classifier
2. Risk assessment of the request itself (info-extraction / backdoor / malicious-code)
3. Risk assessment of fixing the reported problem
4. Above-threshold path → pushback comment (P064-gated risk + P038-gated voice-tone)
5. Clear-malicious path → close + add to blocked-user list (P123 carve-out)
6. Safe-and-valid path → create local problem ticket + acknowledgement comment

**No step in this list compares the reporter's version against shipped fixes.** Step 6 unconditionally creates a local ticket. The pipeline as scoped is "either malicious / above-threshold / safe-and-valid" — no fourth axis for "safe-and-valid BUT already fixed" or "safe-and-valid AND a regression of a prior fix".

The closed-ticket-history (`docs/problems/*.closed.md`) carries fix-release information in `## Fix Released` sections (per ADR-022) — release marker (version, commit SHA, or date) + fix summary. That data is the parse surface a version-aware classifier would need; today nothing reads it programmatically.

### Why it wasn't caught earlier

P079's interactive direction-pin (2026-04-26) focused on the malicious-vs-safe binary because the user's primary concern at that moment was attack-surface filtering (info-extraction, backdoor requests, malicious-code injection). The version-comparison axis is a different kind of filtering — it's about historical context, not adversarial intent — and didn't surface in the same direction round.

The user remembered the concern on 2026-04-26 (verbatim): *"hey, I just remembered ... when we are receiving problems from downstream, we need to consider if the issue has already been fixed in a newer version or if it's recouured in a newer version, etc"*. P079's existing user-direction-already-pinned scope captures everything except this version-comparison branch. Carving P129 out of P079 (rather than amending P079's open-ticket scope further) keeps each ticket's effort estimate honest and lets the carve-outs ship independently if priority differs.

### Candidate fix shape

**Option A — Extend P079's classifier with a version-comparison step + Option B for recurrence semantics.**

1. **Insert a new step between P079's Step 1 (JTBD alignment) and Steps 2-3 (risk assessment)**: the version-comparison step. Reads reporter's claimed version (parsed from the inbound report's `## Versions` section per P128's schema) AND walks `docs/problems/*.closed.md` looking for fix bodies whose `## Fix Released` marker resolves to a version ≥ reporter's-version.

2. **Three classification outcomes** the user named:

   - **Already-fixed-in-newer-version**: pipeline halts the safe-and-valid path. Generates a pushback comment ("upgrade to vX.Y.Z; this issue was fixed in <closed-ticket-id>"). Pushback comment goes through external-comms gates (P064 risk + P038 voice-tone) per P079's existing comment-gate plumbing.
   - **Recurred-in-newer-version**: pipeline routes to a recurrence-handling path. Links the new report to the prior closed ticket. Creates a recurrence-class artefact (see Option B below for shape choice).
   - **Still-active-in-current-version**: pipeline continues to the standard safe-and-valid path → create fresh local ticket + acknowledgement.

3. **Closed-ticket-history matcher**: the version-comparison classifier needs a way to match a new inbound report against historical closed tickets. Options:
   - Reuse P070's LLM semantic-match infrastructure (an inline LLM check comparing the inbound report body against each candidate closed ticket's description+root-cause+fix sections). Cheap given the closed-ticket-history size today; may need pre-filter as the corpus grows.
   - gh-search-style keyword pre-filter (cheap, high recall) followed by LLM semantic match (high precision) on the candidates. Mirrors P070's two-stage shape but on internal corpus rather than upstream issues.

   Architect call at implementation time. Lean: two-stage with keyword pre-filter + LLM semantic match — same shape as P070 for skill-cohort consistency.

**Option B (companion to Option A) — Recurrence-class lifecycle**:

When a recurrence is detected, the pipeline needs somewhere to record the recurrence. Two candidate shapes:

- **Option B-1**: New lifecycle status `.recurred.md` (peer of `.open.md` / `.known-error.md` / `.verifying.md` / `.closed.md` per ADR-022). The closed ticket stays closed; a NEW ticket gets the `.recurred.md` suffix linking to the original. Lifecycle: `.recurred.md` → `.known-error.md` → `.verifying.md` → `.closed.md` (treated as a fresh investigation pass with prior-fix lineage).
- **Option B-2**: Append a `## Recurrences` section to the existing closed ticket, listing each recurrence event as a sub-entry (date, reporter, new-version, link-to-new-incident-ticket). Closed ticket stays closed; recurrence is documented in-place. The new investigation work spawns a fresh `.open.md` ticket marked as a recurrence in its `## Description` section but lifecycle-wise indistinguishable from any other open ticket.

**Lean direction (per architect verdict 2026-04-26)**: Option B-2. Reasons:
- Doesn't expand the ADR-022 suffix vocabulary (load-bearing across `manage-problem`, `manage-incident`, `work-problems`, README rendering).
- Composes cleanly with ADR-031 (`docs/problems/` directory layout proposed migration) — a `## Recurrences` appendage section behaves identically across flat-layout and per-state-subdirectory layouts.
- Mirrors ADR-024 Step 7's `## Reported Upstream` "appendage section" pattern — both treat closure-state tickets as receiving structured appendages without status changes.
- Architect call stays open at implementation time — the leaning is recorded but not pinned.

**Bats coverage**: assessment-pipeline classifier behaviour tests (per ADR-037 + P081 — behavioural over structural):
- Synthetic inbound report with version < closed-ticket fix-version → assert pushback path fires; no new local ticket; comment body asserts upgrade phrasing.
- Synthetic inbound report with version ≥ closed-ticket fix-version + matching bug-shape → assert recurrence path fires; assert appendage to closed ticket OR new `.recurred.md` ticket per chosen shape; assert linkage in both directions.
- Synthetic inbound report with no matching closed ticket → assert standard new-ticket path fires unchanged.

### Investigation Tasks

**Phase 1 — already-fixed-in-newer branch (LANDED 2026-06-09 in `packages/itil/skills/review-problems/SKILL.md` Step 4.5e Step 1 + new Step 4b)**:

- [x] Architect review: Phase 1 shape confirmed 2026-06-09 — Step 4b sub-branch is correct wiring locus; `already-fixed-in-newer` cache classification token is within SKILL-prose scope per ADR-014 (no ADR-062 amendment required); upgrade-pushback is a **sub-shape of the existing `fix released` verdict** (not a 6th verdict-shape row) surfaced at inbound-discovery time; version-extraction stays inline in SKILL.md prose under ADR-075 SKILL-prose harness scope (no premature helper-script extraction).
- [x] JTBD review: Phase 1 PASS 2026-06-09 — JTBD-301 outcome row 6 satisfied (upgrade-pushback IS the predictable verdict, sub-shape of "fix released"; no local ticket is correct because no investigation is needed); persona-fit confirmed for plugin-user (concrete `@windyroad/<pkg>@<fix-version>` upgrade target + "file a new report" escape hatch + reporter-readable `P<NNN>` audit-trail anchor symmetric with 4.5d duplicate verdict); heuristic-miss fallback safe for JTBD-001 (no silent loss).
- [x] Compose with P128's schema: `## Versions` section parse surface (`- Local plugin: @windyroad/<pkg>@<version>`) gives the classifier enough info; fail-soft `cache_audit_note: phase1-version-missing` handles unparseable / absent rows.
- [x] Compose with P079's pipeline: Step 4b integration seam wired at the JTBD-alignment ↔ risk-assessment seam (between Step 1 and Step 2); comment-gate plumbing (P064 + P038) rides the same path as Step 4 above-threshold-pushback.
- [x] Closed-ticket-history matcher: reuses P070 semantic-comparator infrastructure (the same comparator invoked at 4.5d) walked against `docs/problems/closed/*.md`. Best-effort fix-version extraction from `## Fix Released` section in priority order (a) explicit `@windyroad/<pkg>@X.Y.Z`, (b) `vX.Y.Z` adjacent to "released" / "shipped" / "fixed in", (c) commit SHA → first publishing changeset. Fail-soft via `cache_audit_note: phase1-fix-version-extraction-failed-P<NNN>`.
- [x] Phase 1 classifier shipped: Step 1's three outcomes wired — `already-fixed-in-newer` → Step 4b upgrade-pushback; `recurred-in-newer-version` → DEFERRED to Phase 2 via `cache_audit_note: phase2-recurrence-deferred-bug-shape-match-against-P<NNN>` (Phase 2 backfill anchor); `still-active` → continue to step 2.
- [x] Bats coverage extended per ADR-037 + P081: 9 new behavioural anchors added to `packages/itil/skills/review-problems/test/inbound-discovery-contract.bats` covering Phase 1 contract, fail-soft fallbacks, Step 4b upgrade-pushback, anti-leakage (P229), gate-denial sub-branch.
- [x] Promptfoo eval extended per ADR-075 SKILL-prose harness: new test case in `packages/itil/skills/review-problems/eval/promptfooconfig.yaml` covering Step 4b upgrade-pushback comment body (Tier A regex + Tier B llm-rubric on concrete upgrade target naming, matched closed-ticket P-id disclosure, escape-hatch preservation, framework-vocab anti-leakage).

**Phase 2 — recurrence-class lifecycle (DEFERRED — separate iter):**

- [ ] Architect: confirm Option B-2 (`## Recurrences` appendage section on closed tickets) vs. B-1 (new `.recurred.md` suffix). Lean per 2026-04-26 architect verdict: B-2 (doesn't expand ADR-022 suffix vocabulary; composes cleanly with ADR-031; mirrors ADR-024 Step 7 `## Reported Upstream` appendage shape).
- [ ] Implement recurrence-class branch: when Step 1 detects matched closed-ticket + reporter-version ≥ fix-version (regression), route to recurrence-handling path; append to matched closed ticket's `## Recurrences` section AND open a fresh `.open.md` ticket marked as recurrence in `## Description`.
- [ ] Drain `phase2-recurrence-deferred-bug-shape-match-against-P<NNN>` cache_audit_note entries accumulated during Phase 1; backfill as recurrence entries on the matched closed tickets.
- [ ] Triage skew remediation: regression-class WSJF Likelihood bump per the "regressions are higher-likelihood-of-recurrence than net-new bugs" rationale.
- [ ] End-to-end test: synthetic inbound report against synthetic adopter project; cover regression-of-recurrence (a recurred ticket later closed and recurred again).
- [ ] Compose-with-but-don't-bundle: defer to architect on whether to extract a shared classifier component for `/wr-itil:report-upstream`'s outbound-side dedup (P070). Cross-skill sharing has surface but does NOT belong in P129's scope (architect verdict 2026-04-26 unchanged).
- [ ] Update P079's pipeline documentation (P079 already closed; this becomes ADR-062 § Reassessment cross-reference if Phase 2 lands after ADR-062 ratifies).

## Fix Strategy

**Phase 1 — already-fixed-in-newer branch (SHIPPED).** Implemented as `/wr-itil:review-problems` Step 4.5e Step 1 version-aware classifier + new Step 4b upgrade-pushback sub-branch (commit `46e562fe`, 2026-06-09). Extends the ADR-062 step-1 inbound-discovery carve-out; consumes P128's `## Versions` schema (`- Local plugin: @windyroad/<pkg>@<version>`); rides the ADR-028 external-comms gates; preserves the ADR-044 category-4 mechanical-stage carve-out (classifier + verdict comment fire silently; user attention surfaces only at the external-comms gate). 9 behavioural bats + 1 promptfoo eval; architect + JTBD PASS 2026-06-09.

**Phase 2 — recurrence-class lifecycle (DEFERRED — separate iter).** Recurrence detection (regression of a prior closed-ticket fix) + the Option B-2 `## Recurrences` appendage shape remains carved out as future work — see `### Investigation Tasks` Phase 2 above. This K→V transition covers **Phase 1 only**; Phase 2 is a future amendment, not in scope of this verification.

**Release vehicle**: .changeset/p129-phase1-already-fixed-in-newer.md (Phase 1; shipped in `@windyroad/itil@0.49.0`).

## Fix Released

**Phase 1 — already-fixed-in-newer branch** shipped in **`@windyroad/itil@0.49.0`** (Minor Change; Phase 1 commit `46e562fe` 2026-06-09, version-packages commit `57d2b12d`; published on npm and present in current `@windyroad/itil@0.49.5`). The `/wr-itil:review-problems` Step 4.5e classifier now recognises a downstream report filed against a version older than the one that already fixed the bug and posts an upgrade-pushback comment (concrete `@windyroad/<pkg>@X.Y.Z` target + matched closed-ticket `P-id`) instead of opening a duplicate local ticket; it falls through to the standard pipeline when the reporter version or the matched fix-version cannot be parsed (no reports silently dropped).

**Scope of this verification: Phase 1 ONLY.** Phase 2 — recurrence-class lifecycle (regression detection + the Option B-2 `## Recurrences` appendage) — remains **DEFERRED future work**. Do **NOT** close this ticket on Phase 1 verification alone: Phase 2 must either ship or be re-captured as standalone scope before closure (P184 lost-work guard). The `cache_audit_note: phase2-recurrence-deferred-bug-shape-match-against-P<NNN>` entries accumulating during Phase 1 are the Phase 2 backfill anchor.

Awaiting user verification: on the next `/wr-itil:review-problems` pass over inbound reports, an already-fixed-in-newer report should produce an upgrade-pushback comment naming the concrete fix-version and matched closed-ticket P-id, and NO fresh local ticket.

## Dependencies

- **Blocks**: (none) — no other open ticket lists P129 in `Blocked by`.
- **Blocked by**: P079 (parent — pipeline must exist before this carve-out can extend it), P128 (companion — version-comparison classifier requires the inbound report to carry parsable version info per P128's schema; strict block, not just compose-with), P038 (voice-tone gate on external comms — pushback-comment path goes through this gate; P079's pipeline is already blocked-by P038, so the dependency rides through P079), P064 (risk-scoring gate on external comms — same pushback-comment path goes through this gate; rides through P079).
- **Composes with**: P070 (`.verifying.md` — semantic-comparator infrastructure could be reused for closed-ticket-history matching), P123 (sibling carve-out from P079's clear-malicious branch — no functional overlap but shares the carve-out shape precedent), ADR-022 (lifecycle suffix vocabulary — Option B-2 leans toward NOT expanding this), ADR-024 (outbound contract — `## Reported Upstream` appendage pattern is the precedent for `## Recurrences`), ADR-031 (directory layout — closed-ticket-history matcher must support both flat and per-state-subdirectory layouts), ADR-036 (downstream scaffolding — the inbound-report Versions schema this ticket consumes propagates through scaffolded intakes), ADR-037 (bats doc-lint — new classifier contracts require coverage)

## Related

- **P128** (`docs/problems/128-report-upstream-report-body-lacks-consolidated-versions-section.open.md`) — companion ticket; outbound half of the same 2026-04-26 user direction. Strict block per dependency direction (this ticket needs P128's schema to parse reporter-version reliably).
- **P079** (`docs/problems/079-no-inbound-sync-of-upstream-reported-problems.open.md`) — parent surface; the assessment pipeline this carve-out extends. Carve-out shape mirrors P123's precedent.
- **P123** (`docs/problems/123-blocked-user-list-mechanism-for-inbound-report-management.open.md`) — sibling carve-out from P079; established the carve-out-pre-implementation precedent.
- **P070** (`docs/problems/070-report-upstream-does-not-check-for-existing-upstream-issues.verifying.md`) — semantic-comparator infrastructure that the closed-ticket-history matcher could reuse. Cross-skill sharing deferred to implementation-time architect call (P129 stays inbound-only per architect verdict 2026-04-26).
- **P064** (`docs/problems/064-no-risk-scoring-gate-on-external-comms.known-error.md`) — risk-gate the pushback-comment path consumes. Inherited transitively through P079.
- **P038** (`docs/problems/038-no-voice-tone-gate-on-external-comms.open.md`) — voice-tone gate the pushback-comment path consumes. Inherited transitively through P079.
- **P080** (`docs/problems/080-no-bidirectional-update-of-upstream-reported-problems.open.md`) — bidirectional-update sibling concern (outbound-lifecycle-update direction); composes loosely.
- **ADR-014** — governance skills commit their own work; the implementation work this ticket captures lands per ADR-014.
- **ADR-022** — lifecycle suffix-based status; Option B-2 leans toward extending the "Allowed optional appendages" enumeration (no new suffix). Option B-1 amends the suffix vocabulary; choose carefully.
- **ADR-024** — outbound contract; `## Reported Upstream` appendage section is the precedent shape for `## Recurrences`.
- **ADR-031** — `docs/problems/` directory layout; closed-ticket-history matcher must support both flat layout (current) and per-state-subdirectory layout (proposed).
- **ADR-033** — outbound report-body classifier; this ticket's pipeline consumes the schema ADR-033 emits on the outbound side (mirror direction).
- **ADR-036** — downstream scaffolding; the version-info schema this ticket consumes propagates through scaffolded intakes.
- **ADR-037** — bats doc-lint; new classifier contracts require behavioural coverage per P081.
- **JTBD-001** (solo-developer — governance without slowing down; eliminates manual closed-ticket-history grep + version-comparison effort)
- **JTBD-101** (plugin-developer — extend the suite by composing with P079's pipeline)
- **JTBD-201** (tech-lead — restore service fast with audit trail; recurrence detection is the missing regression-signal layer)
- **JTBD-301** (plugin-user — get heard upstream; right response when issue is already-fixed-in-newer is upgrade pushback, not a fresh ticket round-trip)
