# Problem 161: Advisory-then-escalate may be over-applied as the default for drift-class detectors generally; load-bearing-from-the-start may be the better default

**Status**: Open
**Reported**: 2026-05-04
**Priority**: 6 (Moderate) — Impact: Moderate (3) x Likelihood: Possible (2)
**Origin**: internal
**Effort**: M — observation-only ticket; no immediate fix. Required work is *waiting* for 2-3 more drift-class detectors to arrive following the load-bearing-from-the-start shape, then deciding whether a meta-rule / meta-ADR is warranted.

**WSJF**: (6 × 1.0) / 2 = **3.0**

> Surfaced 2026-05-04 by P159's amendment to ADR-051. Filed as the sibling out-of-scope observation P159 explicitly carved out (per the orchestrator framing for P159's Phase 1 iter). Captures the broader question P159 surfaced but did not resolve.

## Description

ADR-040 / ADR-013 Rule 6 / P099 / P134 / P145 / P148 / ADR-051 Phase 1 (original) all follow the **advisory-then-escalate** pattern: ship a detector / hook / signal as exit-0 advisory in Phase 1; escalate to load-bearing only if drift accumulates without correction across N consecutive observation windows. The pattern's rationale is sound for **design-question** and **policy-class** signals: give the rule time to socialise; don't pre-commit to enforcement before the detector has been empirically validated; preserve fail-safe non-blocking behaviour when in doubt.

P159 surfaced an empirical observation that the pattern may be **over-applied** for **drift-class** detectors. Drift class is distinct from design-question / policy class on three axes:

1. **Mechanical detection**: drift is structurally bounded — code drifted from docs, README missing a JTBD anchor, citation pointing to a non-existent file. The detector's correctness is verifiable against synthetic fixtures; the rule the detector enforces is not subjective.
2. **No socialisation period needed**: the rule is "don't ship inconsistent state". There's no "socialise" phase because the rule isn't a recommendation — it's a structural invariant.
3. **Gradualism re-creates the failure mode**: an advisory consumed at retro time is consumed *after* the contributor has already committed the drift. The whole point of the detector is to catch the drift; advisory-then-escalate gradualism means the detector exists but never catches anything, because consumers see drift only after it's shipped.

P159's amendment to ADR-051 ships the load-bearing-from-the-start variant for the JTBD-anchored README rule. The empirical question this ticket queues: **is this the right default for drift-class detectors generally, or is it specific to the JTBD-anchored README case?**

## Symptoms

- ADR-051 Phase 1 (original) shipped advisory-only; user correction (*"the drift detector shouldn't be part of the retro. It should be something we are always running and fixing"*) drove the load-bearing-from-the-start amendment under P159.
- The user-correction friction was avoidable if the original ADR-051 had defaulted to load-bearing for the drift class. The advisory-first decision was made by analogy to design-question precedents (P099 / P134 / P145 / P148), not by analysis of the drift-class shape.
- Recent drift-class detectors filed since 2026-04 follow the advisory-first default by inertia: P099 (briefing-budget detector), P134 (skill-md-budget detector), P145 (briefing-budget bin shim), P148 (tarball-shipped-shims detector), P099 (internal-id-leak detector), ADR-051 (JTBD-anchored README detector). Each shipped exit-0 advisory in Phase 1.
- None of those detectors have escalated to Phase 2 load-bearing in their reassessment windows yet, because the user-correction-driven adjustment that reaches Phase 2 hasn't surfaced for any of them. P159 is the first.

## Workaround

None — observation-only ticket. The current default (advisory-then-escalate) continues to apply for drift-class detectors filed before the meta-rule (if any) is codified. Each new detector author can evaluate whether their detector is drift-class vs design-question class and choose the load-bearing-from-the-start direction explicitly when appropriate, citing ADR-051's amended Decision Driver "Load-bearing-from-the-start for drift class" as precedent.

## Impact Assessment

- **Who is affected**: future drift-class detector authors (plugin-developer persona — JTBD-101 "clear patterns, not reverse-engineering"); plugin-user persona transitively (a load-bearing detector closes the failure mode at the closest enforcement surface, advisory-only leaves the failure mode open).
- **Frequency**: each new drift-class detector filed encounters the question. Recent rate: ~1 per AFK loop session. If 2-3 more arrive following the load-bearing-from-the-start shape, the meta-rule warrants codification.
- **Severity**: Moderate (3) — design-pattern miscalibration. Bounded by: each detector author can deviate from the default per architect review.
- **Likelihood**: Possible (2) — at the current rate of new drift-class detectors, the question will recur within a few sessions.

## Root Cause Analysis

### Preliminary Hypothesis

Advisory-then-escalate is the right default for **design-question** signals (where the rule is being socialised, where empirical validation is needed before enforcement, where fail-safe non-blocking matters). It was adopted for drift-class signals by analogy / inertia, not by analysis. The drift-class shape (mechanical detection + no socialisation period + gradualism re-creates the failure mode) suggests load-bearing-from-the-start is the better default for the class.

### Investigation Tasks (deferred — observation-only ticket)

- [x] Wait for 2-3 more drift-class detectors to arrive following the load-bearing-from-the-start shape (the originating instance is P159; the meta-rule needs at least 2-3 instances to confirm the pattern). **Threshold met 2026-06-08**: empirical audit found 5+ additional drift-class invariant-enforcement gates shipped load-bearing-from-the-start since 2026-05-04 — see Observation Log 2026-06-08 below.
- [ ] Architect review on whether to codify a meta-rule. Possible shapes:
  - **Option M1**: A new ADR amending ADR-013 Rule 6 to carve out drift-class from advisory-then-escalate.
  - **Option M2**: A new ADR-NNN "Drift-class detectors default to load-bearing-from-the-start" with the empirically-derived class definition (mechanical detection + no socialisation period + gradualism re-creates failure mode).
  - **Option M3**: No meta-ADR — keep the per-detector decision in each ADR, with the load-bearing-from-the-start direction explicitly named as precedent in each new drift-class ADR's Decision Drivers.
- [ ] If M1 or M2 chosen: revisit existing advisory-only drift-class detectors (P099 / P134 / P145 / P148) and decide whether each needs a Phase 2 escalation push earlier than the current "drift_instances ≥ N across M consecutive windows" trigger.

### Observation Log 2026-06-08 — empirical audit findings

Audit of drift-class invariant-enforcement gates shipped since 2026-05-04 (when P161 was filed). Looking for instances that match P161's three-axis drift-class definition (mechanical detection + no socialisation period + gradualism re-creates failure mode) AND ship the load-bearing-from-the-start shape rather than advisory-then-escalate.

**Originating instance** (the one P159 surfaced):

1. **ADR-051 → ADR-069: skill-inventory-drift commit-hook** (`packages/retrospective/hooks/retrospective-readme-jtbd-currency.sh`). Pre-commit gate denies when a `packages/<plugin>/skills/<name>/` directory is missing from that plugin's README. Mechanical detection (directory naming); no socialisation period (the rule is "don't ship inconsistent inventory"); gradualism would re-create the failure (advisory consumed at retro means drift already shipped). ADR-069 supersession 2026-05-25 narrowed scope from JTBD-ID anchor to skill-inventory only but retained the load-bearing-from-the-start gate shape — and explicitly named principle (b) "Load-bearing-from-the-start for drift class" as a carried-forward Decision Driver. **The principle is now a binding precedent live in ADR-069 line 22.**

**Subsequent instances since 2026-05-04** (load-bearing-from-the-start, drift-class shape):

2. **ADR-060 I1 (trace-to-problem at capture-rfc)** (accepted 2026-05-12; load-bearing PreToolUse gate on `/wr-itil:capture-rfc`). Hard-block when an RFC is captured without a `--problem` flag; bounded-escape at irreversible lifecycle transitions. Mechanical detection (frontmatter `problems:` array presence); no socialisation period (orphan RFCs are structurally meaningless); gradualism would re-create the failure (an advisory consumed at retro would let orphan RFCs accumulate). ADR-060 line 58 explicitly cites ADR-069 (carrying forward ADR-051) as the precedent for "load-bearing-from-the-start for drift class".

3. **ADR-060 I13 (RFC required at fix-proposal on a Known Error)** (added 2026-05-26; load-bearing structural auto-create at fix-proposal). Rather than block on missing RFC, the framework auto-creates a problem-traced skeleton RFC — structural elimination of drift. Mechanical detection (RFC presence at fix-proposal); no socialisation period (rule is unconditional per ADR-071); gradualism would re-create the failure (an advisory would let unmediated fixes ship).

4. **ADR-078 + `architect-compendium-refresh-discipline.sh`** (PreToolUse pre-commit pairing-assertion). Every commit that edits a `docs/decisions/*.md` body MUST also edit `docs/decisions/README.md`. Mechanical detection (staged-file pairing); no socialisation period (compendium drift was empirically demonstrated by P337 at 57% of the corpus); gradualism re-creates the failure (a drift-detector CI run after merge means the inconsistency already shipped). ADR-078 line 57 explicitly chose Option 9 because "it eliminates drift by structural construction (every body edit triggers a same-hook README write)". The "drift by structural construction" framing is the same principle.

5. **P165 + `itil-readme-refresh-discipline.sh`** (PreToolUse commit-gate). Denies a commit that updates a ticket body without staging the matching `docs/problems/README.md` refresh. Mechanical detection (staged-file pairing — ticket body + README); no socialisation period (the README is the WSJF surface, drift means stale rankings); gradualism re-creates the failure (drift accumulates faster than retro cadence catches it).

6. **ADR-066 + `architect-oversight-marker-discipline.sh`** (PreToolUse Edit-gate). Denies an Edit that writes `human-oversight: confirmed` to an ADR file without a session-local substance-confirm evidence marker. Mechanical detection (frontmatter field write paired with `/tmp` marker presence); no socialisation period (substance-confirmation evidence is binary); gradualism would re-create the P340-class "born-confirmed marker without substance" failure mode (P339/P340 captured the case where a marker was written on draft-acceptance without substance-confirm).

7. **ADR-068 + `jtbd-oversight-marker-discipline.sh`** (PreToolUse Edit-gate; sibling shape). Same shape applied to JTBDs and personas. Same drift-class fit (mechanical pairing detection; binary substance-confirm; gradualism re-creates the over-marker-write failure).

**Pattern observation**: the load-bearing-from-the-start shape appears to be the systematic choice for drift-class invariants where the cost of advisory-then-escalate is "shipped-then-detected" — which IS the failure mode the gate exists to prevent. Two distinct mechanism shapes emerge:

- **Structural elimination** (ADR-060 I13 auto-create; ADR-078 pre-commit pairing): the framework prevents the drift state from being representable rather than detecting after the fact.
- **Pre-commit deny** (ADR-051/ADR-069; ADR-060 I1; P165; ADR-066; ADR-068): the gate blocks the commit that would introduce drift; recovery is to fix-and-retry.

Both are load-bearing-from-the-start. Both are appropriate. The choice between them appears driven by whether the drift state can be auto-corrected (favours structural elimination) or requires human input (favours pre-commit deny).

**Counter-cases checked**: advisory-only detectors shipped since 2026-05-04 — `itil-fictional-defer-detect.sh` (P234), `itil-mid-loop-ask-detect.sh` (P132 Phase 2b), `itil-bash-polling-antipattern-detect.sh` (P232), `risk-scorer-scaffold-nudge.sh` (P297 Phase 1), `architect-oversight-nudge.sh` (ADR-066 nudge layer), `jtbd-oversight-nudge.sh` (ADR-068 nudge layer). These are NOT drift-class under P161's definition — they are **behavioural-pattern detectors** (fictional defer, mid-loop ask, polling antipattern) or **scaffold nudges** that signal a missing setup step. They sit in the design-question / policy class — socialisation matters; advisory-then-escalate is the right shape. The contrast supports P161's hypothesis: the class boundary holds empirically.

**Conclusion / next interactive turn**: the meta-rule is now empirically validated. The class boundary holds. The meta-ADR codification options (M1 / M2 / M3) need substance-confirm from the user before drafting per ADR-074 (confirm-decision-substance-before-building-dependent-work). This iter does NOT mint a meta-ADR autonomously — the chosen shape is queued as an outstanding_question for the next interactive turn.

### Re-surface 2026-06-27 — decision still blocked; re-queued through the AFK cadence

`/wr-itil:work-problems` AFK iter re-selected P161 (top actionable WSJF 3.0). Freshness check: no M1/M2/M3 meta-ADR exists (newest ADR is 086); no ticket edit since the 2026-06-08 audit commit; the audit's class-boundary finding and 7-instance evidence base remain current. The investigation is **done** — nothing to add to it.

The only remaining work is the genuine **direction** decision (M1 vs M2 vs M3), which the framework cannot resolve and ADR-074 forbids building on without user substance-confirm. The 2026-06-08 conclusion "queued … for the next interactive turn" has not fired in ~19 days — "next interactive turn" names a re-entry point but is **not a self-firing cadence**, so the decision simply sat. Correcting that this iter: the decision is re-queued through the AFK loop's `outstanding_questions` surface (the actual cadence that reaches the user at loop end), not left as a passive in-ticket note. No fix forced; no meta-rule invented.

**Recommendation** (architect-class judgment, NOT a chosen direction): **M2** (new dedicated ADR-NNN with the empirically-derived class definition) appears the cleanest fit because (a) the class definition is non-trivial and earns its own anchor, (b) carving out ADR-013 Rule 6 (M1) loses the Rule 6 fail-safe semantics for the design-question class that still needs it, (c) per-detector citation (M3) re-creates the inertia failure mode P161 surfaced — new authors default to the precedent they have rather than the one they should look up. But the choice is genuinely the user's per ADR-074.

## Fix Strategy

Phase 1: observation-only — keep this ticket open as a tracking surface for the next drift-class detector authoring decision. Each new drift-class detector's ADR can cite this ticket + ADR-051's amended Decision Driver as guidance.

Phase 2: codification (deferred to a separate iter once 2-3 more drift-class detectors arrive following the load-bearing-from-the-start shape). At that point, architect review chooses M1 / M2 / M3.

Phase 3: retroactive review of advisory-only drift-class detectors (deferred — only relevant if M1 or M2 lands).

## Dependencies

- **Blocks**: (none — observation-only ticket; no downstream work depends on its resolution)
- **Blocked by**: (none — but Phase 2 codification is gated on the arrival of 2-3 more drift-class detectors following the load-bearing-from-the-start shape; counter accumulates with each future drift-class ADR that explicitly chooses load-bearing-from-the-start over advisory-then-escalate; originating instance is P159)
- **Composes with**: P159, ADR-051 (superseded by ADR-069, which carries the load-bearing-from-the-start-for-drift-class principle forward), ADR-040, ADR-013 Rule 6

## Related

- [P159](159-jtbd-currency-detector-should-be-load-bearing-commit-hook-with-auto-fix-not-retro-advisory.open.md) — originating observation; ADR-051 amendment that introduced the load-bearing-from-the-start direction for one drift-class detector.
- [ADR-051](../decisions/051-jtbd-anchored-readme-with-drift-advisory.superseded.md) — superseded 2026-05-25 by ADR-069, which carries the load-bearing-from-the-start-for-drift-class principle forward; amended 2026-05-04 by P159 to ship load-bearing-from-the-start; new Decision Driver "Load-bearing-from-the-start for drift class" names this ticket as the meta-question surface.
- [ADR-040](../decisions/040-session-start-briefing-surface.proposed.md) — declarative-first / advisory-then-escalate pattern. ADR-040 is the pattern ADR; the question this ticket queues is whether the pattern's universality should be revisited for drift class.
- [ADR-013 Rule 6](../decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — non-interactive fail-safe / advisory-then-escalate. Sibling pattern surface.
- [P099](099-no-context-budget-or-budget-tracking-mechanism.verifying.md) — advisory-only briefing-budget detector. Drift-class candidate for retroactive load-bearing-from-the-start review if M1 or M2 lands.
- [P134](134-skill-md-runtime-budget-not-mechanically-checked.verifying.md) — advisory-only skill-md-budget detector. Drift-class candidate.
- [P145](145-briefing-budget-detector-cant-resolve-via-bash-tool.verifying.md) — advisory-only briefing-budget bin shim. Drift-class candidate.
- [P148](148-tarball-shipped-shims-not-checked-against-bin-config.verifying.md) — advisory-only tarball-shipped-shims detector. Drift-class candidate.
- [JTBD-101](../jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md) — clear patterns, not reverse-engineering. The meta-rule (if codified) serves this job.

## Change Log

- 2026-05-04: Initial filing. Surfaced as the sibling out-of-scope observation P159's Phase 1 iter explicitly carved out per orchestrator framing. Observation-only ticket; deferred resolution until 2-3 more drift-class detectors arrive following the load-bearing-from-the-start shape.
- 2026-06-08: Empirical audit run during `/wr-itil:work-problems` AFK iter. Threshold met: 5+ drift-class invariant-enforcement gates (ADR-060 I1, ADR-060 I13, ADR-078, ADR-066, ADR-068, P165) shipped load-bearing-from-the-start since 2026-05-04, plus the carry-forward ADR-051→ADR-069 originating instance. Two distinct mechanism shapes identified (structural elimination vs pre-commit deny). Counter-cases checked: advisory-only detectors shipped in the same window are behavioural-pattern / scaffold-nudge class, not drift-class — the class boundary holds. Meta-rule codification queued for next interactive turn (M1 / M2 / M3 substance-confirm per ADR-074); architect-class recommendation **M2** logged but choice deferred to user. No meta-ADR drafted this iter.
- 2026-06-27: Re-surfaced during `/wr-itil:work-problems` AFK iter. Freshness check confirms the audit is still current (no M1/M2/M3 meta-ADR exists; newest ADR is 086; ticket untouched since the audit). Investigation remains complete — nothing to add. The blocker is the genuine direction decision (M1/M2/M3), un-resolvable by the framework per ADR-074. Recognised that "next interactive turn" is a named re-entry point, not a self-firing cadence, so the decision sat ~19 days; re-queued through the AFK loop's `outstanding_questions` surface to reach the user at loop end. No fix forced; no meta-rule invented.
