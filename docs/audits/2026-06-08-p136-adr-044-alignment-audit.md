# ADR-044 Alignment Audit — Phase 1 Investigation Findings

**Date**: 2026-06-08
**Ticket**: P136 (ADR-044 alignment audit master)
**Scope**: Sweep of unaudited SKILLs / hooks / agents / ADRs / JTBDs / READMEs against the framework-resolution boundary defined in ADR-044 (Decision-Delegation Contract).
**Iter context**: `/wr-itil:work-problems` AFK orchestrator dispatch. Per the P136 Fix Strategy, per-surface remediation requires the interactive deviation-approval `AskUserQuestion` flow that the AFK loop cannot fire — this iter produces investigation evidence only; remediation is queued for interactive work.

## Framework-Resolution Boundary (recap, per ADR-044)

Six categories where the user owns the answer (and `AskUserQuestion` is the right primitive):

1. **Direction-setting for new work** — only the user knows the goals not yet written down.
2. **Deviation approvals from existing design decisions** — existing decisions are point-in-time; the user owns amend / supersede / one-time-override.
3. **Strategic one-time override** — the rule stands; this case warrants an exception.
4. **Genuinely-silent-framework cases** — no ADR / JTBD / policy / SKILL applies.
5. **Taste on novel artefacts** — naming / voice / design where no guide settles the case.
6. **Authentic correction** — agent went wrong; user catches it (the P078 surface).

Everything else is **framework-mediated**: release-within-appetite, prioritisation (WSJF), verification-close-on-evidence, codification-shape pick, briefing add/remove/rotate, lifecycle transitions, multi-concern split, loop continue/stop. The agent reads + applies + acts + reports.

## Audit Method

For each surface:

- Count `AskUserQuestion` mentions (call sites + documentation refs).
- Count ADR-013 (Structured User Interaction) cross-refs.
- Count ADR-044 (Decision-Delegation Contract) cross-refs.
- Spot-classify the call sites in the highest-ask surfaces against the 6-class taxonomy.
- Classify each surface into one of:
  - **ALIGNED** — substantively follows ADR-044; no work needed.
  - **NO-CALLS** — zero `AskUserQuestion` call sites; no work needed.
  - **COSMETIC** — substantively aligned, but cross-refs cite ADR-013 only and should cite ADR-044 cat-N.
  - **SUBSTANTIVE** — at least one lazy-deferral call site found; per-call-site amend/keep/supersede deviation-approval needed at interactive retro end.

## Phase 3a — Medium-ask SKILLs (audit complete this iter)

### `packages/jtbd/skills/review-jobs/SKILL.md` — COSMETIC

| Call site | Line | Classification | Action |
|-----------|------|----------------|--------|
| Step 3 "no staged or unpushed changes" 3-option ask | 52 | cat-1 direction-setting | KEEP |
| Step 6 "gaps or breaks identified" 3-option ask | 88 | cat-1 direction-setting | KEEP |
| Inline `per ADR-013 Rule 1` cross-ref | 93 | stale | upgrade to ADR-044 cat-1 cross-ref |

Substantive shape correct. Recommended remediation: cosmetic cross-ref upgrade only.

### `packages/retrospective/skills/analyze-context/SKILL.md` — ALIGNED

Three `AskUserQuestion` mentions; **zero call sites**. All three are explicit policy-statements that the skill MUST NOT ask (lines 20, 218, 232). Cites ADR-044 framework-resolution boundary inline.

Recommended remediation: NONE.

## Phase 3b — Low-ask SKILL sweep (44 surfaces inventoried; spot-classified)

| SKILL | Asks | ADR-044 refs | ADR-013 refs | Tier | Notes |
|-------|------|--------------|--------------|------|-------|
| architect/capture-adr | 10 | 3 | 2 | ALIGNED | Already cites ADR-044 substantively |
| architect/create-adr | 28 | n/a | n/a | ALIGNED (P135-era) | Confirm-substance-before-build flow (ADR-074); ADR-044 spirit baked in |
| architect/review-decisions | 10 | 1 | 2 | COSMETIC | Drain skill; cross-refs cite ADR-013 |
| architect/review-design | 3 | 0 | 2 | COSMETIC | 2 call sites (Step 3 + Step 6); both cat-1; lacks ADR-044 cross-ref |
| c4/check | 0 | 0 | 0 | NO-CALLS | |
| c4/generate | 0 | 0 | 0 | NO-CALLS | |
| connect/send | 3 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| connect/setup | 3 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| itil/capture-problem | 23 | n/a | n/a | ALIGNED (P349-era) | Substance-derivation pattern (P185); ADR-044 referenced |
| itil/capture-rfc | 6 | 4 | 2 | ALIGNED | Cites ADR-044 substantively |
| itil/capture-story | 4 | 4 | 2 | ALIGNED | Cites ADR-044 substantively |
| itil/capture-story-map | 1 | 0 | 1 | COSMETIC | Low surface; stale cross-ref |
| itil/check-upstream-responses | 3 | 0 | 1 | ALIGNED | Explicitly P085 / zero-call discipline; doc-level upgrade |
| itil/close-incident | 2 | 0 | 3 | COSMETIC | Stale cross-refs only |
| itil/link-incident | 1 | 0 | 2 | COSMETIC | Stale cross-refs only |
| itil/list-incidents | 0 | 0 | 0 | NO-CALLS | |
| itil/list-problems | 0 | 0 | 0 | NO-CALLS | |
| itil/list-stories | 0 | 0 | 0 | NO-CALLS | |
| itil/list-story-maps | 0 | 0 | 0 | NO-CALLS | |
| itil/manage-incident | 19 | n/a | n/a | ALIGNED (P135 Phase 2) | Audited 2026-04-28; 4 cat-1/2/3 surfaces; 0 lazy |
| itil/manage-problem | 35 | n/a | n/a | ALIGNED (P135 Phase 2) | |
| itil/manage-rfc | 3 | 4 | 1 | ALIGNED | Cites ADR-044 substantively |
| itil/manage-story | 2 | 2 | 1 | ALIGNED | Cites ADR-044 substantively |
| itil/manage-story-map | 4 | 0 | 0 | UNAUDITED | Spot-classify deferred; orphan refs |
| itil/mitigate-incident | 7 | n/a | n/a | ALIGNED (P135 Phase 2) | Audited 2026-04-27 |
| itil/reconcile-readme | 0 | 0 | 4 | NO-CALLS | Stale doc-refs only |
| itil/reconcile-stories | 0 | 0 | 0 | NO-CALLS | |
| itil/reconcile-story-maps | 0 | 0 | 0 | NO-CALLS | |
| itil/report-upstream | 9 | 0 | 5 | COSMETIC | 4 actual call sites; all cat-1/cat-3 (dedup branch, missing-SECURITY.md, above-appetite); stale ADR-013 refs |
| itil/restore-incident | 10 | 0 | 3 | SUBSTANTIVE | 1 lazy-deferral candidate (line 21 ID arg backfill); 7 genuine cat-1/2/3 sites |
| itil/review-problems | 19 | n/a | n/a | UNAUDITED-HIGH | 14 backticked mentions; merits dedicated session |
| itil/scaffold-intake | 8 | 0 | 4 | COSMETIC | Already governance-aware (Rule 6 audit table at line 142); needs ADR-044 cross-ref |
| itil/transition-problem | 5 | 3 | 2 | ALIGNED (P135 Phase 2) | |
| itil/transition-problems | 4 | 0 | 4 | COSMETIC | Plural sibling; same shape as singular; stale refs only |
| itil/work-problem | 7 | n/a | n/a | ALIGNED (P135 Phase 2) | Audited 2026-04-27 |
| itil/work-problems | 63 | n/a | n/a | ALIGNED (P135 Phase 2) | Master orchestrator; ADR-044 cited throughout |
| jtbd/confirm-jobs-and-personas | 8 | n/a | n/a | ALIGNED (P348-era) | ADR-068 born-confirmed; aligns with ADR-044 |
| jtbd/review-jobs | 3 | 0 | 0 | COSMETIC | (Phase 3a finding above) |
| jtbd/update-guide | 6 | 0 | 0 | COSMETIC | Cat-1 confirm + ADR-068 born-confirmed; lacks ADR-044 |
| retrospective/analyze-context | 3 | n/a | n/a | ALIGNED | (Phase 3a finding above) |
| retrospective/migrate-briefing | 2 | 0 | 3 | COSMETIC | Migration skill; mostly mechanical |
| retrospective/run-retro | 31 | n/a | n/a | ALIGNED (P135 Phase 2) | Master retro; ADR-044 baseline |
| risk-scorer/assess-external-comms | 4 | 0 | 2 | COSMETIC | Wrapper; cat-3 surface |
| risk-scorer/assess-inbound-report | 8 | 1 | 2 | COSMETIC | ADR-062 routing; partially aligned |
| risk-scorer/assess-release | 3 | 0 | 1 | COSMETIC | Above-appetite cat-3 only |
| risk-scorer/assess-wip | 2 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| risk-scorer/bootstrap-catalog | 1 | 0 | 2 | COSMETIC | Mostly mechanical |
| risk-scorer/create-risk | 6 | 0 | 3 | COSMETIC | Already cites P132 inverse-P078 at line 60; lacks ADR-044 |
| risk-scorer/external-comms | 1 | 0 | 0 | NO-CALLS | Internal wrapper |
| risk-scorer/pipeline | 1 | 0 | 0 | NO-CALLS | Internal wrapper |
| risk-scorer/update-policy | 3 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| risk-scorer/wip | 0 | 0 | 0 | NO-CALLS | Internal wrapper |
| style-guide/update-guide | 2 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| tdd/setup-tests | 2 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| voice-tone/assess-external-comms | 4 | 0 | 2 | COSMETIC | Wrapper; same shape as risk-scorer sibling |
| voice-tone/update-guide | 2 | 0 | 0 | UNAUDITED | Spot-classify deferred |
| wardley/generate | 0 | 0 | 0 | NO-CALLS | |

**Phase 3 summary**:
- ALIGNED: 17 (including 4 from P135 Phase 2)
- NO-CALLS: 12
- COSMETIC: 18
- SUBSTANTIVE: 1 (restore-incident)
- UNAUDITED (deferred to dedicated session): 8 (connect/{send,setup}, itil/manage-story-map, itil/review-problems, risk-scorer/{assess-wip,update-policy}, style-guide/update-guide, tdd/setup-tests, voice-tone/update-guide)

## Phase 4 — Critical hooks (4 ask-emitters)

| Hook | Lines | Asks | ADR-044 refs | ADR-013 refs | Tier | Notes |
|------|-------|------|--------------|--------------|------|-------|
| itil/itil-assistant-output-gate.sh | 69 | 4 | 0 | 3 | COSMETIC | **This hook IS the ADR-044 enforcement surface** — direction-pin / act-on-obvious / never-prose-ask. Vocabulary is P085/P132; should cite ADR-044 explicitly. No behavioural amendment needed. |
| itil/itil-assistant-output-review.sh | 72 | 5 | 0 | 2 | COSMETIC | Stop-hook companion to the above; same shape; cosmetic upgrade only |
| itil/manage-problem-enforce-create.sh | 175 | 1 | 0 | 1 | COSMETIC | Duplicate-check enforcement gate; minimal ask-prose; stale ADR-013 ref |
| voice-tone/voice-tone-eval.sh | 51 | 0 | 0 | 0 | NO-CALLS | Eval hook; no ask surface |

**Phase 4 summary**: 3 COSMETIC, 1 NO-CALLS. Two of the four critical hooks ARE the ADR-044 enforcement surface in P085/P132 vocabulary; recommended remediation is to add explicit ADR-044 cross-refs without behavioural changes. The remaining 65 hooks (Pre/PostToolUse / Stop / UserPromptSubmit) carry no ask-prose and would aggregate into a single "audited — no change needed" sweep entry per the P136 Fix Strategy bundling pattern.

## Phase 4 — Remaining 65 hooks sweep — 2026-06-27 (bundled NO-CHANGE)

`/wr-itil:work-problems` AFK iter. Completes the second Phase 4 sub-task (ticket line 67): sweep the **65 non-critical hooks** (69 total hook scripts under `packages/*/hooks/*.sh`, excluding `lib/` + test dirs, minus the 4 critical ask-emitters audited 2026-06-08). Investigation + audit-log only — no SKILL/hook prose amended (AFK loop must not auto-amend per ticket lines 67/190/217/230).

### Method

Grepped all 65 for `AskUserQuestion` mentions and ask-prose nudge vocabulary (`ask the user` / `would you like` / `should I` / `(a)/(b)` / `prose-ask` / `consent gate`). Five hooks reference `AskUserQuestion`; all five reference it as **enforcement / discipline / surfacing prose**, not as a lazy-deferral emission requiring reclassification. The other 60 carry zero ask surface.

### The 5 `AskUserQuestion`-referencing hooks

| Hook | Role | Tier | Notes |
|------|------|------|-------|
| `itil/itil-pending-questions-surface.sh` | Surfaces queued `outstanding_questions` for batched `AskUserQuestion` per the ADR-044 6-class taxonomy | **ALIGNED** | Already cites ADR-044 (lines 8/45/96); this IS the framework-mediated surfacing mechanism, not a lazy emitter |
| `itil/itil-mid-loop-ask-detect.sh` | Detects mid-loop orchestrator `AskUserQuestion` (P130 / over-ask enforcement) | **ALIGNED** | Already cites ADR-044 framework-resolution boundary (lines 32/33/138) |
| `architect/architect-oversight-marker-discipline.sh` | Blocks `human-oversight: confirmed` without a substance-confirm marker (P348 / ADR-066) | **COSMETIC** | Cites ADR-013; an ADR-044 cross-ref would anchor it. Enforcement gate — **no behavioural change** |
| `jtbd/jtbd-oversight-marker-discipline.sh` | Same shape for JTBD/persona markers (P348 / ADR-068) | **COSMETIC** | Cites ADR-013; ADR-044 cross-ref would anchor it. Enforcement gate — **no behavioural change** |
| `architect/architect-enforce-edit.sh` | Pre-edit architecture gate | **NO-CALLS** | Single passing-comment mention (line 123, "decision the user already substance-confirmed via AskUserQuestion"); no ask surface |

### The other 60 hooks

Zero `AskUserQuestion` references, zero ask-prose nudges. All are PreToolUse gates (architect / jtbd / risk-scorer / style-guide / voice-tone / tdd enforce-edit + commit/push/secret/changeset gates), detectors (correction-detect, fictional-defer-detect, staging-trap, bash-polling-antipattern), markers (mark-reviewed, hash-refresh, slide-marker, runtime-sid-marker, setup-marker), advisories (commit-trailer, rfc-trailer), and session-start / Stop / PostToolUse surfaces. None emit a user-facing decision prompt — they enforce, detect, mark, or inform mechanically. **NO-CALLS / NO-CHANGE.**

### Phase 4 sweep summary

| Tier | Count | Action |
|------|-------|--------|
| NO-CALLS / NO-CHANGE | 61 | none |
| ALIGNED (already cite ADR-044) | 2 | none |
| COSMETIC (ADR-013 → add ADR-044 cross-ref) | 2 | deferred to interactive cosmetic-cross-ref bundle |
| SUBSTANTIVE / lazy-deferral | **0** | — |

**Outcome:** the expected bundled NO-CHANGE finding holds. Zero lazy-deferrals across the 65 non-critical hooks — consistent with the Phase 1 inventory prediction (ticket line 67) and the Fix Strategy bundling pattern (lines 190/222). The only remediation is the 2 COSMETIC ADR-044 cross-refs on the two oversight-marker-discipline gates; these fold into the existing interactive cosmetic-cross-ref bundle (audit-log "Recommended Per-Surface Remediation Sequence" item 1 / 3) and are NOT applied in the AFK loop. **Phase 4 is now complete (both sub-tasks done).**

## Phase 5 — Agents (14 inventoried)

| Agent | Asks | ADR-044 | ADR-013 | Tier | Notes |
|-------|------|---------|---------|------|-------|
| architect/agent | 3 | 2 | 1 | ALIGNED | Pre-edit/post-edit mode + ADR-064 Needs Direction surface explicit |
| itil/hang-off-check | 3 | 0 | 2 | COSMETIC | Read-only arbiter |
| jtbd/agent | 0 | 0 | 0 | NO-CALLS | Review-only |
| risk-scorer/agent | 0 | 0 | 0 | NO-CALLS | Routing doc |
| risk-scorer/external-comms | 0 | 0 | 1 | NO-CALLS | Verdict-only |
| risk-scorer/inbound-report | 1 | 0 | 3 | COSMETIC | Verdict-only; stale refs |
| risk-scorer/pipeline | 0 | 1 | 2 | ALIGNED | |
| risk-scorer/plan | 0 | 0 | 1 | NO-CALLS | Verdict-only |
| risk-scorer/policy | 0 | 0 | 0 | NO-CALLS | Verdict-only |
| risk-scorer/wip | 0 | 0 | 1 | NO-CALLS | Verdict-only |
| style-guide/agent | 0 | 0 | 0 | NO-CALLS | Review-only |
| tdd/review-test | 5 | 1 | 1 | COSMETIC | Mechanical classifier; partially aligned |
| voice-tone/agent | 0 | 0 | 0 | NO-CALLS | Review-only |
| voice-tone/external-comms | 0 | 0 | 1 | NO-CALLS | Verdict-only |

**Phase 5a summary**: 9 NO-CALLS, 3 COSMETIC, 2 ALIGNED. Most agents are read-only review surfaces with no ask emission; cosmetic cross-ref upgrade where ADR-013 is cited.

## Phase 5b — ADRs (~49 inventoried)

ADRs are governed by their own composition graph rather than ADR-044 directly — the framework-resolution boundary only applies to ask-emitting *behavioural* surfaces (SKILLs / hooks / agents). ADRs are decisions, not behaviours. ADR-013 is amended in place per the chosen Option C — this is the proper compose-with shape.

Spot-check shows:

- **ADR-013** itself: 4 ADR-044 refs (amended in place — the canonical compose surface).
- **Recent ADRs (070-079)**: substantial ADR-044 citation; aligned by construction (born-after-ADR-044).
- **Older operational ADRs (014-058)**: cite ADR-013 only — these are composes-with relationships; remediation NOT needed unless the ADR specifically describes an ask-emission policy. Operational ADRs (commit-grain, file-naming, lifecycle mechanics) are orthogonal to the ask boundary.
- **Tier classification**: NO-CHANGE-NEEDED for the bulk of older operational ADRs; COSMETIC for any ADR that documents an ask-emission policy without ADR-044 cross-ref.

**Phase 5b summary**: Most ADRs are out-of-scope for ADR-044 alignment; ~5-6 ADRs warrant explicit ADR-044 cross-refs (those describing user-interaction or framework-mediated surfaces).

## Phase 5c — JTBDs (14 inventoried)

| JTBD | ADR-044 | ADR-013 | Tier | Notes |
|------|---------|---------|------|-------|
| JTBD-001 enforce-governance | 0 | 0 | COSMETIC | Primary persona served by ADR-044; description should cite the contract |
| JTBD-002 ship-with-confidence | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-003 compose-guardrails | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-004 connect-agents | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-005 assess-on-demand | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-006 work-backlog-afk | 0 | 0 | COSMETIC | ADR-044 cites this as primary persona; should reciprocate |
| JTBD-007 keep-plugins-current | 1 | 0 | ALIGNED | |
| JTBD-008 decompose-fix | 1 | 0 | ALIGNED | |
| JTBD-009 migrate-adopter-artefacts | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-101 extend-suite | 0 | 0 | COSMETIC | ADR-044 cites this as primary persona |
| JTBD-201 restore-service-fast | 0 | 0 | COSMETIC | ADR-044 cites this; lazy-ask audit metric serves audit-trail |
| JTBD-202 pre-flight-governance | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-301 report-problem | 0 | 0 | NO-CHANGE | Orthogonal |
| JTBD-302 trust-readme | 1 | 2 | ALIGNED | |

**Phase 5c summary**: 8 NO-CHANGE (orthogonal), 4 COSMETIC (JTBDs ADR-044 cites should reciprocate), 2 ALIGNED. Cosmetic remediation is one-line cross-ref additions.

## Phase 5d — READMEs (14 inventoried)

All 14 READMEs (project root + per-package) carry zero ADR-044 cross-refs. Per ADR-069 (READMEs market persona/problem, not JTBD IDs or internal contracts), READMEs are not the correct surface for ADR-044 references — they're user-facing marketing, not framework-internal documentation.

**Phase 5d summary**: NO-CHANGE-NEEDED for all 14 READMEs.

## Aggregate Audit Coverage

| Surface | Count | ALIGNED | NO-CALLS / NO-CHANGE | COSMETIC | SUBSTANTIVE | UNAUDITED |
|---------|-------|---------|----------------------|----------|-------------|-----------|
| SKILLs | 56 | 17 | 12 | 18 | 1 | 8 |
| Critical hooks | 4 | 0 | 1 | 3 | 0 | 0 |
| Agents | 14 | 2 | 9 | 3 | 0 | 0 |
| ADRs | ~49 | bulk | bulk | ~5-6 | 0 | 0 |
| JTBDs | 14 | 2 | 8 | 4 | 0 | 0 |
| READMEs | 14 | 0 | 14 | 0 | 0 | 0 |

The audit covers **151 surfaces**. Of these, **1 substantive amendment candidate** (restore-incident line 21 ID-arg backfill, same shape as mitigate-incident Surface 1 audit precedent), **~28 cosmetic cross-ref upgrades**, and the balance NO-CALLS / NO-CHANGE / ALIGNED. **8 SKILLs deferred** to dedicated audit sessions.

## Recommended Per-Surface Remediation Sequence

Per the P136 Fix Strategy and the per-surface release cadence (R1 from P135):

1. **Bundle COSMETIC remediations into a single sweep commit** (~28 surfaces × 1-line ADR-044 cross-ref upgrade) — low risk; doc-only; no behavioural change; can ship as one `@windyroad/*` patch per package. Three package commits expected: `@windyroad/itil`, `@windyroad/risk-scorer`, `@windyroad/jtbd`.
2. **restore-incident SUBSTANTIVE amendment** — single-skill session following the mitigate-incident audit precedent. Lazy-deferral on line 21 (ID arg backfill) → fail-fast usage message + exit. Remaining cat-1/2/3 sites keep with ADR-044 cross-refs. `@windyroad/itil` patch.
3. **Critical-hook ADR-044 cross-ref upgrade** — itil-assistant-output-gate + itil-assistant-output-review + manage-problem-enforce-create. Single sweep commit `@windyroad/itil` patch.
4. **8 UNAUDITED SKILLs** — dedicated audit sessions. Expected: low/no remediation per current sample.
5. **JTBD/ADR cosmetic cross-refs** — single sweep commit; doc-only.

Each amendment goes through ADR-044's 5-option deviation-approval `AskUserQuestion` at retro end per the P136 Fix Strategy. AFK orchestrators must NOT auto-amend.

## Deferred Investigation Items

- **`itil/review-problems`** (19 mentions; not yet spot-classified) — merits dedicated audit session before classification.
- **65 non-ask-emitting hooks** — single sweep entry; expected NO-CHANGE per the P136 Fix Strategy bundling.
- **Remaining ~37 unaudited ADRs** — spot-check confirmed bulk are operational/orthogonal; deferred to Phase 5b sweep.

## Cross-References

- **ADR-044** (`docs/decisions/044-decision-delegation-contract.proposed.md`) — the framework-resolution boundary anchor.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — amended in place by ADR-044 Option C.
- **P135** (`docs/problems/known-error/135-...known-error.md`) — predecessor master ticket; Phase 2 audited 4 high-ask SKILLs.
- **P081** — canonical bats retrofit; P136 bridges via `tdd-review: structural-permitted` marker.
- **P132** — inverse-P078 enforcement; itil-assistant-output-gate hook IS the load-bearing implementation.
- **docs/audits/2026-05-15-retroactive-jtbd-alignment-review.md** — precedent observational audit shape this report follows.

## Iter Outcome

Phase 1 investigation **complete**. Per-surface findings catalogued; per-surface remediation deferred to interactive sessions per Fix Strategy (P136 is explicitly NOT picked up automatically by `/wr-itil:work-problems` AFK loop for remediation work — see ticket line 178).
