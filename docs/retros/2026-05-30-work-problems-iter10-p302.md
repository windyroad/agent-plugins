# Retro — work-problems iter 10 (P302 O→KE)

Date: 2026-05-30
Iter: 10
Scope: P302 (ADR-confirmation summaries should lead with the Decision Outcome, not the meta-framing) Open → Known Error with presentation-rule edits to two oversight-drain skills + agent-interaction briefing note
Session role: AFK iteration-worker subprocess (`claude -p` per P086)
Orchestrator: `/wr-itil:work-problems`

## What changed this iter

- `packages/architect/skills/review-decisions/SKILL.md` Step 3: added `Presentation rule — lead with the Decision Outcome, never with the meta (P302)` subsection between the Options bullets and the closing "genuine human-decision surface" line. Worked bad/good examples grounded in the ADR-045 and ADR-020 2026-05-25 drain re-asks. Cross-references ADR-074 (*name the substance, not the grain*) and ADR-026 (grounding extended to AskUserQuestion `question` text).
- `packages/jtbd/skills/confirm-jobs-and-personas/SKILL.md` Step 3: mirrored `Presentation rule — lead with the job statement / persona definition, never with the meta (P302)` adapted for jobs/personas (lead with job statement / persona definition; persona-cluster meta relegated or omitted).
- `docs/briefing/agent-interaction-patterns.md`: appended one new "What Will Surprise You" bullet — `Decision-confirmation prompts must lead with the substance, not the meta (P302)`. Generalises the rule to any decision-presentation surface (drains + create-adr Step 5 confirm structurally); cross-references both SKILL.md sites.
- `docs/problems/open/302-...md` → `docs/problems/known-error/302-...md` (per-state-subdir rename per ADR-031)
- Ticket Status: `Open` → `Known Error`; RCA confirmed; 3 investigation tasks ticked; Fix Strategy section added; WSJF 4.0 → 8.0 (Known Error multiplier 2.0); `**Origin**: internal` field added per ADR-076
- `docs/problems/README.md`: P302 row moved to TOP of WSJF Rankings (WSJF 8.0 — currently highest in dev-work queue); Last-reviewed line rotated from prior P325 iter-9 fragment to P302 O→KE fragment
- `docs/problems/README-history.md`: prior P325 iter-9 fragment appended as rotated history entry per P134
- `.changeset/p302-decision-confirmation-presentation-rule.md` (new patch changeset for @windyroad/architect; jtbd mirror rides the held `p288-jtbd-persona-oversight.md` changeset's graduation)
- Single commit landed: `d1de917` (`docs(architect,jtbd): P302 known error — lead with Decision Outcome, not meta-framing on confirm-prompt surfaces`)

## Briefing Changes

- Added: 1 — `docs/briefing/agent-interaction-patterns.md` "Decision-confirmation prompts must lead with the substance, not the meta (P302)" bullet (part of the P302 fix payload — codifies the rule for any future decision-presentation surface beyond the two drain skills)
- Removed: none
- Updated: none
- README index refreshed: none (the new bullet lands within the existing "What Will Surprise You" section; topic file's character unchanged)

## Signal-vs-Noise Pass (P105)

Skipped per AFK-iter scope — the iter's tool-call activity cited 0 briefing entries (selection was driven by the orchestrator's task prompt, not briefing signals; the new agent-interaction-patterns entry was created as part of this iter's fix payload, not consumed from prior briefing). Decay (-1) applies to all entries this cycle but classification + persistence deferred to next interactive retro that touches more briefing entries. Same approach as iter-4/5/6/7/8/9 precedent.

## Problems Created/Updated

- **P302** (`docs/problems/known-error/302-adr-confirmation-summaries-should-lead-with-decision-outcome-not-meta-framing.md`): Status Open → Known Error. RCA confirmed (drain skills carried `Question/Context/Options` bullet shape but did NOT direct the `question` field to lead with substance — agent's framing instinct privileged meta-coherence over substance, producing the two ADR-045/ADR-020 re-asks on 2026-05-25). Fix Strategy section added documenting the bounded 3-file prose-only edit + the rationale for NOT touching create-adr Step 5 (its presentation surface differs since the user just authored the decision moments earlier). WSJF 4.0 → 8.0 per Open → Known Error multiplier. Closure (Known Error → Verifying) follows release of `@windyroad/architect@0.12.1` in a later orchestrator pass.

## Tickets Deferred

| Observation | Cause | Citation |
|-------------|-------|----------|
| Tier 3 briefing budget overflow on 4 files persists across iters 7/8/9/10 with no rotation action (recurring-defer pattern P145; mixed sink-vs-non-sink set raising P322 caveat for the 2 archive sinks) | `skill_unavailable` | `check-briefing-budgets.sh` output below in Pipeline Instability; rotation execution exceeds AFK iter scope clamp + the 2 archive sinks trigger P322 caveat against rotating sink files; foreground retro is the correct surface |

## Verification Candidates

(No `.verifying.md` tickets were exercised by this iter's tool-call activity — the iter's scope was narrow to two SKILL.md presentation-rule edits + briefing note + ticket lifecycle. Sub-step 5-7 in-session evidence drain produced no candidates. Sub-step 9 prior-session evidence drain not run — cross-session evidence drain is the orchestrator-end retro's surface per the 134KB Verification Queue evidence in P282.)

## Pipeline Instability

**README inventory currency**: clean (13 packages, 0 drift instances).

**Briefing budgets**: 4 OVERS (none MUST_SPLIT, all between 1.06× and 1.28× threshold; **same set as iter-7/iter-8/iter-9 — 4th consecutive iter to flag without action**):
- `docs/briefing/governance-workflow-archive.md` — 6551 / 5120 (1.28×)
- `docs/briefing/governance-workflow.md` — 5839 / 5120 (1.14×)
- `docs/briefing/hooks-and-gates-archive.md` — 5429 / 5120 (1.06×)
- `docs/briefing/releases-and-ci.md` — 6156 / 5120 (1.20×)

P145 recurring-defer-pattern risk now escalating — 4th consecutive flag with no rotation. P322 caveat applies to the 2 `-archive.md` sinks (re-rotating a sink proliferates siblings for ~zero reader value). The 2 non-archive files (`governance-workflow.md`, `releases-and-ci.md`) are within Branch B fall-through to split-by-date safe default per SKILL.md Step 3, but the orchestrator-end retro or next interactive retro should action — AFK iter scope clamps to P302 work.

**No new pipeline-instability detections this iter** (the iter's bounded prose-only fix exercised normal architect/JTBD/risk-scorer/external-comms gates without friction; all PASS on first pass).

## Topic File Rotation Candidates

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/governance-workflow-archive.md` | 6551 | 5120 | split-by-date (2nd-tier archive — but P322 caveat applies) | flagged (AFK iter scope clamp; 4th consecutive iter; P145 + P322 risks acknowledged) |
| `docs/briefing/governance-workflow.md` | 5839 | 5120 | split-by-date (safe default) | flagged (AFK iter scope clamp; 4th consecutive iter; P145 recurring-defer risk acknowledged) |
| `docs/briefing/hooks-and-gates-archive.md` | 5429 | 5120 | split-by-date (2nd-tier archive — but P322 caveat applies) | flagged (AFK iter scope clamp; 4th consecutive iter; P145 + P322 risks acknowledged) |
| `docs/briefing/releases-and-ci.md` | 6156 | 5120 | split-by-date (safe default) | flagged (AFK iter scope clamp; 4th consecutive iter; P145 recurring-defer risk acknowledged) |

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|-----------|-----------|
| problems | 4036721 | 54.3% | +4707 (vs iter-9 — P302 RCA+Fix-Strategy prose + README rotation) |
| decisions | 1682493 | 22.6% | 0 (no ADR edits this iter) |
| skills | 959925 | 12.9% | +3131 (vs iter-9 — review-decisions Step 3 + confirm-jobs-and-personas Step 3 presentation-rule subsections) |
| hooks | 430293 | 5.8% | 0 |
| memory | 358257 | 4.8% | 0 |
| briefing | 93581 | 1.3% | +1473 (vs iter-9 — agent-interaction-patterns new bullet) |
| jtbd | 46488 | 0.6% | 0 |
| project-claude-md | 4277 | 0.06% | 0 |
| framework-injected | not-measured | — | reason=framework-injected-no-on-disk-source |

THRESHOLD: 10240 bytes (cheap-layer report ceiling per ADR-043).

Top-5 offenders by absolute size: `problems` (4.0 MB), `decisions` (1.7 MB), `skills` (960 KB), `hooks` (430 KB), `memory` (358 KB). All deltas within sub-1% of bucket totals; no anomaly relative to baseline.

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Ask Hygiene (P135 Phase 5 / ADR-044)

Trail file: `docs/retros/2026-05-30-work-problems-iter10-p302-ask-hygiene.md`.

**Lazy count: 0** — no AskUserQuestion fired this iter; AFK orchestrator constraint forbids mid-loop AskUserQuestion (P135 / ADR-044). All decisions framework-resolved or pre-pinned by the orchestrator's selection prompt.

## Codification Candidates

(No new codification candidates this iter — the iter's bounded prose-only fix codified the presentation rule itself into two SKILL.md sites + a briefing entry. The P302 fix IS the codification; no further codify-worthy patterns emerged from this iter's narrow scope.)

## No Action Needed

- Architect verdict PASS (no new ADR — fits cleanly under ADR-066 + ADR-068 + ADR-026 + ADR-013 + ADR-044 envelope; ADR-074 advisory cross-reference added per architect note)
- JTBD verdict PASS (serves JTBD-005 on-demand-governance speed-without-sacrificing-quality, JTBD-006 AFK clear-summary, JTBD-101 clear-patterns-not-reverse-engineering)
- External-comms risk PASS (no Confidential Information classes matched in the changeset draft)
- External-comms voice-tone PASS (changeset-author surface is scope-excluded from VOICE-AND-TONE.md per its own Scope section; courtesy-check found no violations)
- ADR-074 substance-confirm-before-build guard: NO_FIRE — ADR-066 + ADR-068 (the two referenced ADRs) both return `wr-architect-is-decision-unconfirmed` exit=1 (confirmed)
- P063 external-root-cause detection: NO_MATCH (no strict tokens in P302 ticket body — internal observation about agent presentation behaviour, no upstream dependency)
- Pipeline risk: commit=2 / push=2 / release=2 (all within Low appetite of 4; RISK_BYPASS: reducing — closes P302 Known Error remediating the 2 cited re-asks)
- TDD invariant: no implementation file edits (SKILL.md + briefing + ticket prose — config/doc files are always writable per the TDD hook)
