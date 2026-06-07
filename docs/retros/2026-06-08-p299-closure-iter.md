# Iter retro — P299 closure (ADR-034 supersession)

**Iter scope**: AFK `/wr-itil:work-problems` iter; ticket P299; outcome verifying via in-place ADR-034 supersession to ADR-030 amendment 2026-05-25.
**Commit**: `0a58fa5` (`chore(decisions): supersede ADR-034 by ADR-030 amendment 2026-05-25 (P299)`).
**Risk**: commit=3/25 within Low appetite (4/25); no push, no release.

## Briefing Changes

- Added: none — Critical Points already carries the global-cache fact (`The plugin install cache is GLOBAL/shared across projects ... refreshing it from one project advances the version for every project ... Drove the 2026-05-25 /install-updates simplification`). The post-supersession state matches what the briefing already encoded; ADR-034 retirement is the executed consequence of an already-captured learning, not a fresh observation.
- Removed: none — scanned `docs/briefing/{plugin-distribution-cache-mechanics,governance-workflow,hooks-and-gates,releases-and-ci,afk-subprocess,agent-interaction-patterns}.md` per-section; no entries referenced ADR-034 by ID; 0 accepted candidates for removal.
- Updated: none — no entries materially changed by ADR-034 retirement (the global-cache entry already names the executed simplification; no rewriting needed).
- README index refreshed: none — Critical Points section unchanged.

## Signal-vs-Noise Pass (P105)

Scanned Critical Points + topic-file entries against this iter's tool-call activity:

| Entry | Topic file | Old score | New score | Classification | Citation |
|-------|-----------|-----------|-----------|----------------|----------|
| Plugin install cache is GLOBAL/shared across projects | README.md Critical Points | n/a (no comment block) | +2 | signal | Cited verbatim in the ADR-034 SUPERSEDED blockquote justification + drove the entire iter's supersession premise. |
| Multi-decision-file changes DEADLOCK the architect edit-gate | README.md Critical Points | n/a | +2 | signal | Anticipated when planning the two-decision-file edit (ADR-034 + ADR-030); avoided by batching architect review into one delegation up front per ADR-030 amendment 2026-05-25 architect-PASS pattern. No deadlock fired this iter. |
| `git mv` + `Edit` + `git add` requires re-stage after the Edit | README.md Critical Points | n/a | +2 | signal | Followed for `34-*.proposed.md` → `.superseded.md` rename + subsequent frontmatter Edit; `git add` re-staged before commit. No content leak. |

**Critical Points changes**: none. All entries continued to earn their slot this iter.

**Delete queue**: empty.

**Budget overflow**: not triggered.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| External-comms gate fired on git commit even though risk-pipeline verdict was already in cache and PASS-equivalent | Hook-protocol friction | `git commit` BLOCKED message: *"git-commit-message draft has not been reviewed by wr-risk-scorer:external-comms"*; the prior `wr-risk-scorer:pipeline` agent invocation produced `RISK_SCORES: commit=3 push=0 release=0` + `RISK_BYPASS: reducing` at session position 11 but did not satisfy the external-comms marker key; required a second `wr-risk-scorer:external-comms` delegation with the verbatim `<draft>` payload. | recorded in retro only — already covered by `P353` sibling-class umbrella (Hash-marker brittleness umbrella class root cause closed); the P192 followup question in `outstanding-questions.jsonl` already names this exact PostToolUse:Agent hook firing residue. No new ticket. |

README inventory currency: clean (13 packages, drift_instances=0).

## Topic File Rotation Candidates (P099 Branch B)

5 files OVER threshold (5120 bytes), all < 2× ceiling (Branch B, not MUST_SPLIT):

| Topic file | Bytes | Threshold | Proposed rotation | Decision |
|------------|-------|-----------|-------------------|----------|
| `docs/briefing/releases-and-ci.md` | 7091 | 5120 | split-by-date (safe default) | deferred — iter scope is P299 closure (single-ADR supersession); cross-cutting Tier 3 rotation across 5 files is dedicated-retro / closure-iter work, not per-iter work. Flagged for next standalone retro or AFK rotation pass. |
| `docs/briefing/afk-subprocess.md` | 6564 | 5120 | split-by-date | deferred — same. |
| `docs/briefing/agent-interaction-patterns.md` | 5994 | 5120 | split-by-date | deferred — same. |
| `docs/briefing/governance-workflow.md` | 5839 | 5120 | split-by-date | deferred — same. |
| `docs/briefing/hooks-and-gates.md` | 5419 | 5120 | split-by-date | deferred — same. |

(Anti-pattern check: this is NOT "deferred to next interactive retro" — it is `cause: iter_scope_boundary` — same trust-boundary as Step 4b Stage 1's `skill_unavailable` fallback. The iter retro narrative IS the durable surface; the candidates are captured on disk with mechanical rotation shape pre-selected so a standalone retro can execute without re-scanning.)

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total |
|--------|-------|------------|
| problems | 4,723,849 | 53.4% |
| decisions | 1,870,986 | 21.1% |
| skills | 1,149,728 | 13.0% |
| hooks | 496,202 | 5.6% |
| memory | 408,850 | 4.6% |
| briefing | 99,887 | 1.1% |
| jtbd | 55,461 | 0.6% |
| project-claude-md | 4,277 | 0.05% |

THRESHOLD: 10,240 bytes (cheap-layer report ceiling, not on-disk bucket ceiling).

No prior snapshot delta — measurement is per-retro snapshot; deep-layer `/wr-retrospective:analyze-context` is the cross-snapshot-trend surface (not invoked this iter — iter scope).

## Verification Candidates

None this iter — iter scope was a fresh supersession, not exercising prior `.verifying.md` tickets.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

(Iter ran AFK with zero `AskUserQuestion` calls — orchestrator constraint `NEVER call AskUserQuestion` honoured. Architect+JTBD verdicts gathered via `Agent` delegations; risk gates via `Agent` delegations + Skill invocations.)

## Problems Created / Updated

- **P299** — Open → Verifying. All 4 Investigation Tasks marked complete with substance; 3 Verification Criteria added.

## Tickets Deferred

None.

## Codification Candidates

None this iter — supersession executed entirely against existing framework (ADR-066 post-supersede pattern + ADR-077 compendium-refresh discipline + ADR-030 supersession blockquote precedent from 6 prior ADRs). No new framework signal observed.

## No Action Needed

- ADR-077 compendium-refresh ran cleanly via `packages/architect/scripts/generate-decisions-compendium.sh` (70 in-force + 9 historical, with ADR-034 moving to historical automatically per filename-suffix detection).
- ADR-066 frontmatter vocabulary respected on first try after architect surfaced the constraint (dropped invented `superseded-confirmed` value; used `superseded-by: "ADR-030"` scalar form matching ADR-041 precedent).
- ADR-030 amendment 2026-05-25 line 153 dangling reference annotated inline; no full-file rewrite needed because the surrounding clause was already inside a `[RETIRED 2026-05-25]` strikethrough block.
- Architect 5-issues-found verdict resolved 100% within one Agent delegation cycle — no marker-vs-file deadlock, no TTL expiry, no re-review round-trip required.
