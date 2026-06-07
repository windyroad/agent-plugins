# Iter retro — P222 closure (work-problems AFK)

**Date**: 2026-06-08
**Iter**: P222 closure (work-problems orchestrator)
**Scope**: single-iter; P222 KE→Closed-as-Superseded + P326 evidence append.

## Iter outcome

Closed P222 (manage-problem skill should auto-commit ticket file changes — likely resolved by ADR-014) as superseded by ADR-014. Verification at closure confirmed every manage-problem write path commits per ADR-014 single-commit grain — Step 5 (new), Step 6 (update, with P094 README refresh on ranking-bearing fields), Step 7 (transitions, all four lifecycle hops), Step 11 (commit gate via `wr-risk-scorer:pipeline` + `wr-risk-scorer-restage-commit` P326 wrapper). `packages/itil/skills/capture-problem/SKILL.md` Step 6 mirrors the pattern. The "update-ticket sub-flow" the ticket named does not exist as a separate skill — it is the inline Step 6 update flow in manage-problem, which IS covered. No code change in the closure transition; KE→Closed direct per ADR-079 lifecycle extension.

**ADR-079 ratification caveat (architect-flagged 2026-06-08)**: this closure cites ADR-079 (Evidence-based relevance-close pass) as the load-bearing authority for the KE→Closed-direct lifecycle hop. ADR-079 is recorded `proposed` at `docs/decisions/079-evidence-based-relevance-close-pass.proposed.md` and does NOT carry `human-oversight: confirmed` in its frontmatter. The ADR body itself acknowledges this explicitly (line 12): *"this ADR is recorded `proposed` with a pre-pinned decision but WITHOUT human review of the alternatives — MUST NOT be promoted to `accepted` until it has been through a `/wr-architect:create-adr` (or equivalent) `AskUserQuestion` review-and-confirm pass."* This iter is the FIFTH KE→Closed-as-Superseded case this week (P216 / P292 / P217 / P218 / P222) building on the unratified ADR-079 — past the P218 retro's "before a fifth case lands" threshold. The orchestrator constraint forbid AskUserQuestion this iter, so the ratification drain is queued at orchestrator level (mirrors the existing system-reminder #2 entry at session start so the user receives the drain prompt at loop end; queueing a second entry would be redundant).

Commit (closure): `7be3cc0` (work tree clean post-closure-commit; pre-existing untracked retro files unrelated to this iter).
Commit (evidence append): `f4714a9` (P326 evidence append per architect-directed routing; see Pipeline Instability table).

## Briefing Changes

- Added: none — scanned "What You Need to Know" + "What Will Surprise You" sections in `hooks-and-gates.md`, `governance-workflow.md`, and `agent-interaction-patterns.md` for P222-relevant additions; ADR-014 single-commit grain (governance skills commit their own work) is already established framework with full SKILL-prose coverage. The fifth-in-a-week KE→Closed-as-Superseded cadence is itself a noteworthy operational signal but it is implicit in the existing ADR-079 entry and the per-iter retro trail — no new durable cross-session learning surfaced.
- Removed: none — scanned for staleness against this iter's evidence; ADR-014 / ADR-022 / ADR-079 / P062 / P094 / P057 / P326 entries remain accurate (per scan against the per-section text of the three topic files above; zero accepted-staleness candidates).
- Updated: none — Critical Points entries on the load-bearing release path are unchanged by this iter (closure was scoped to verifying SKILL-prose coverage of an already-ratified ADR, not modifying release mechanics).

Scan summary: 0 add candidates accepted (of ~3 considered: fifth-KE→Closed-cadence cited above + new wrapper symptom + retro-cadence per-iter pattern — all rejected as either implicit in existing entries or session-local), 0 remove candidates accepted (of ~5 considered against the three topic files), 0 update candidates accepted.

## Signal-vs-Noise Pass (P105)

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|-----------|-----------|----------------|----------|
| ADR-014 "governance skills commit their own work" single-commit grain | `docs/briefing/governance-workflow.md` (implicit via SKILL-prose) | 0 | +2 | signal | Cited verbatim as the supersession authority in P222 closure body + commit message + Closed README row; verification touched all five write-path call sites (Step 5 / Step 6 / Step 7 transitions / Step 11 / capture-problem Step 6). |
| P057 staging trap (git mv stages rename only, post-Edit re-stage required) | `docs/briefing/README.md` Critical Points | n/a (Critical Points) | n/a | signal | Cited as the post-Edit re-stage rule in P222 closure body Step 7 description; reinforced by the iter's own `git add docs/problems/closed/222-...md` after the Edit of the moved file. |
| `wr-risk-scorer-restage-commit` helper P326 wrapper contract | `docs/briefing/releases-and-ci.md` (implicit via SKILL-prose lines 999-1003) | 0 | +1 | signal | Used live to land closure commit `7be3cc0` AND evidence-append commit `f4714a9`. The rename-source-rejection symptom observed on first call (recovered in one retry) was captured to P326 per architect routing — see Pipeline Instability table. |
| ADR-079 evidence-based-relevance-close-pass (unratified `proposed`) | `docs/briefing/governance-workflow.md` (implicit via Closed README rows) | 0 | +2 | signal | Cited as the lifecycle-extension authority for the KE→Closed-direct transition. The unratified status of the ADR was the architect's first ISSUES FOUND finding on the proposed retro (see Pipeline Instability table). Ratification drain queued at orchestrator level (system-reminder #2 entry at session start). |

**Critical Points changes**: none. P222 closure reinforced existing entries; no new candidate cleared the +3 promotion threshold.

**Delete queue**: empty.

**Budget overflow**: not triggered.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| `wr-risk-scorer-restage-commit` helper rejects rename-source path in the `-- <paths>` list. Iter passed all four staged paths (M README, M README-history, A closed/222, D known-error/222) but the helper's `git add` of the deleted source failed with `fatal: pathspec 'docs/problems/known-error/222-...md' did not match any files` since `git mv` had already removed the working-tree file. Recovered in one retry by removing the source path. The staged deletion was already in the index from `git mv`, so the second invocation succeeded as `7be3cc0`. | Skill-contract violations | First `wr-risk-scorer-restage-commit -m '...' -- <four-paths>` call: exit 128 with `fatal: pathspec ... did not match any files`. Second call with three-paths (excluding deleted source): exit 0, commit `7be3cc0` landed. Both invocations in this iter's bash history. SKILL-prose-vs-wrapper-contract gap: `packages/itil/skills/manage-problem/SKILL.md` Step 11 line 995 instructs "git add all created/modified files — including any file renamed via `git mv` that was then modified by the Edit tool" — implying both rename endpoints — but the wrapper requires only the destination. | **Appended evidence to P326** via inline manage-problem update flow (commit `f4714a9`). Architect-directed routing per the P222 retro ISSUES FOUND verdict; sibling-retro precedent: P217 retro line 36 "Append evidence to P353" + P218 retro line 36 same shape. Three mitigation options recorded on P326 for the next iter to evaluate evidence-based: (a) SKILL prose clarification; (b) wrapper-side rename-source filtering via `git diff --cached --diff-filter=R`; (c) behavioural fixture pinning whichever option lands. |
| Architect ISSUES FOUND on the proposed P222 retro: (i) building closure on unratified ADR-079 (now five-cases-deep dependency mass); (ii) the proposed retro's invented "single-iter friction under recurring-class threshold" carve-out for the wrapper observation — which inverted the P342 trust-boundary taxonomy (Step 4b Stage 1 line 466 names hook misbehaviour as a recurring class-of-behaviour MUST mechanical-auto-ticket). | Subagent-delegation friction (review surface working as designed; finding was real defect on proposed retro) | Architect verdict in P222 closure iter retro re-review at conversation turn ~28. Both findings resolved in this iter: (i) ADR-079 ratification caveat recorded above + drain queued at orchestrator level (mirrors existing system-reminder #2 entry); (ii) wrapper observation routed to P326 evidence append (commit `f4714a9`). Architect re-PASSed the revised retro. | Record in retro only — both findings are recoverable in-iter; architect re-review on the revised retro is the verification path. No new ticket — both surface friction classes are already tracked (ADR-079 ratification by the queued deviation-approval; P342 trust-boundary by the named ticket; manage-problem Step 11 line 995 SKILL prose clarification by the P326 evidence append mitigation option (a)). |

README inventory currency: clean (13 packages). No skill-inventory drift detected via `wr-retrospective-check-readme-jtbd-currency` (TOTAL packages=13 drift_instances=0).

External-comms gate did NOT misfire this iter — no external-comms surface invoked (docs/problems/ closure does not draft external prose). The P353 recurrence observed in the P217 iter retro earlier today did not re-fire here because this iter touched no external-comms surface.

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total | Δ vs prior (P217 iter snapshot earlier today) |
|--------|-------|-----------|-----------------------------------------------|
| problems | 4641499 | 53.8% | +17163 (P218 + P216 + P217 + P222 closures + P326 evidence append) |
| decisions | 1865947 | 21.6% | +991 |
| skills | 1138700 | 13.2% | +7218 |
| hooks | 493926 | 5.7% | 0 |
| memory | 408850 | 4.7% | 0 |
| briefing | 98947 | 1.1% | 0 |
| jtbd | 55461 | 0.6% | 0 |
| project-claude-md | 4277 | 0.05% | 0 |
| framework-injected | not measured — framework-injected-no-on-disk-source | — | — |

Top-5 offenders: problems (4.6 MB) / decisions (1.9 MB) / skills (1.1 MB) / hooks (494 KB) / memory (409 KB). Per-bucket THRESHOLD bytes=10240 (per-file static budget, not aggregate).

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer). Delta column citations are intra-session against the P217 iter retro snapshot; no canonical cross-session snapshot trailer detected in `docs/retros/*-context-analysis.md`.

## Ask Hygiene (P135 Phase 5 / ADR-044)

No `AskUserQuestion` calls fired in this iter — orchestrator constraint explicitly forbid them ("NEVER call AskUserQuestion") and every framework-resolved decision (closure transition via ADR-022/ADR-079; commit-gate via wr-risk-scorer:pipeline; architect-directed evidence routing to P326; ADR-079 ratification queued at orchestrator level) was either mechanical or AFK-queued per ADR-013 Rule 6.

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Verification Candidates

None — this iter did not exercise any `.verifying.md` ticket's fix beyond the meta-case of P326 itself. The P326 evidence append observed a NEW failure mode of the Verifying wrapper, not a successful exercise — by Step 4a categorisation this is "Exercised with regression" (the wrapper's failure pattern surfaced a contract gap), which routes to evidence-append on the same ticket rather than close-candidate. The append landed as commit `f4714a9`.

## Topic File Rotation Candidates

Not measured this iter — Step 3 made zero topic-file edits, so the Tier 3 budget pass has nothing to act on. No `OVER` or `MUST_SPLIT` lines surface for files that were not touched and remain at prior known sizes.

## Codification Candidates

No codification candidates surfaced this iter. The `wr-risk-scorer-restage-commit` rename-source-path friction was routed to **P326 evidence append** (the existing ticket covering this wrapper) per architect-directed routing; Stage 1 mechanical-auto-ticket discharged via the evidence-append commit `f4714a9` rather than a new-ticket creation (Step 4b Stage 1 line 458: "if a matching ticket exists: route the detection through Step 4 as an **update** (append new evidence to the existing ticket's `## Symptoms` or `## Root Cause Analysis` section via the manage-problem update path)"). Three mitigation options recorded on P326 for the next P326 iter's evidence-based pick:
- (a) Amend `packages/itil/skills/manage-problem/SKILL.md` Step 11 line 995 to clarify rename-destination-only convention (Shape: Skill improvement stub).
- (b) Amend `wr-risk-scorer-restage-commit` to filter rename-source paths via `git diff --cached --diff-filter=R --name-status --raw` (Shape: script).
- (c) Add a behavioural fixture to `packages/risk-scorer/scripts/test/restage-commit.bats` covering rename-source-and-destination both passed (Shape: test fixture).

Empty Codification Candidates table proper — omitted per Step 5 template guidance.

## Tickets Deferred

(none — every observation reached the Step 4b mechanical-auto-ticket path or its evidence-append variant.)

## No Action Needed

- The closure transition itself — P222 transitioned cleanly via the ADR-079 KE→Closed direct path, mirroring P216 / P292 / P217 / P218 precedents earlier this week.
- The architect + JTBD gates on the ticket closure — skipped per `docs/problems/` exclusion list in both gate prose; no review round-trips paid for the docs-only ticket closure or the P326 evidence append.
- The commit gate via `wr-risk-scorer:pipeline` — returned PASS on both commits with commit=3/25 (P222 closure) and commit=1/25 (P326 evidence append), both well within appetite; landed via `wr-risk-scorer-restage-commit` (first call required one retry for rename-source-rejection symptom; recorded to P326).

## Notes

- P222 is the **fifth** KE→Closed-as-Superseded case this week (P216 / P292 / P217 / P218 / P222), all riding the (unratified) ADR-079 lifecycle extension. Past the P218 retro's "before a fifth case lands" threshold. The architect re-review explicitly noted: *"the threshold the P218 retro proposed has now been crossed, which strengthens the case for the user prioritising the ratification at loop end rather than deferring further."* Each closure cites a ratified ADR (ADR-009 / ADR-014 / ADR-050 Option C) as the supersession authority + provides specific in-SKILL-prose evidence + records a `Reversible via /wr-itil:transition-problem <NNN> known-error` recovery path. The pattern is operational, predictable, and self-documenting — but the lifecycle-extension authority (ADR-079) is itself unratified, which the architect surfaced as the proposed retro's first ISSUES FOUND finding and re-flagged in the re-review's PASS advisory. Ratification drain is queued at orchestrator level (system-reminder #2 at session start).
- `wr-risk-scorer-restage-commit` rename-source-path edge case is the only meaningful operational observation from this iter — routed to P326 evidence append per architect direction. The SKILL-prose-vs-wrapper-contract gap is a structural cause; three mitigation options are recorded on P326 for the next iter's evidence-based pick.
- All four upstream issues (#61, #77, #78, #79) on `windyroad/agent-plugins` now have matching local closures and should be closed with the same resolution bodies; deferred to a foreground session per the orchestrator-owns-drain constraint.
- Architect re-review advisory (non-blocking) on compendium refresh discipline: the queued ADR-079 ratification drain WILL touch ADR-079's frontmatter (`human-oversight: confirmed` insertion + `oversight-date:` add) and MUST regenerate `docs/decisions/README.md` per ADR-077 (Decisions Compendium routine load surface). Skill-driven (`/wr-architect:review-decisions`) regeneration is automatic; manual ratification must run `wr-architect-generate-decisions-compendium && git add docs/decisions/README.md`.
