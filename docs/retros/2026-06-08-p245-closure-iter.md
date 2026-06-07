# Iter retro — P245 close-as-superseded

**Date**: 2026-06-08
**Scope**: `/wr-itil:work-problems` AFK iter on P245 (AFK iter retro surfaces three hook-vs-SKILL-contract drift observations)
**Iter outcome**: closed; commit `4887a94`; 10th KE→Closed-direct this week under ADR-079 Phase 2 shape 3 (sibling-fix-supersedes)

## What happened

Coordinating ticket P245 bundled three observations; investigation confirmed all three already addressed by sibling fixes shipped this session and earlier:

- **Obs#1** (external-comms key derivation byte-equality) — P010 / ADR-028 amended 2026-05-25. `packages/risk-scorer/hooks/lib/external-comms-key.sh::compute_external_comms_key` is the canonical normalization shared byte-identically between gate (PreToolUse) and mark hook (PostToolUse). For `changeset-author` surface it strips the leading YAML frontmatter block; for all surfaces it rstrips trailing whitespace. Whether the agent wraps body-only or includes frontmatter inside `<draft>`, both sides hash to byte-equal keys. The retry-loop symptom cannot recur. The gate deny message at `external-comms-gate.sh:311` also explicitly tells the agent the body excludes frontmatter for the changeset-author surface.
- **Obs#2** (P165 README refresh on capture) — P262 / P265. `packages/itil/hooks/lib/readme-refresh-detect.sh:149` registers `capture-deferred-readme` in `_README_REFRESH_BYPASS_TRAILERS`; lines 195-197 clear the gate when the registered trailer is present. The `/wr-itil:capture-problem` Step 6 commit subject carries `RISK_BYPASS: capture-deferred-readme`; SKILL's deferred-refresh contract preserved.
- **Obs#3** (P141 changeset-discipline held-area awareness) — P177. `packages/itil/hooks/lib/changeset-detect.sh:209-223` explicitly recognise `docs/changesets-holding/*.md` as a held-window changeset per ADR-042 Rule 7 held-window blessing. A commit shipping `packages/<plugin>/` source + `git mv` of a changeset to the held-area clears the gate in one operation; no 2-commit decomposition required.

Architect PASS (ADR-014 + ADR-022 + ADR-031 conformance; no new ADR warranted). JTBD PASS (developer + tech-lead + plugin-developer personas; JTBD-006 + JTBD-008; closure preserves audit trail). Risk: commit=1 push=0 release=0 (within appetite 4). Commit 4887a94, 3 files changed (+20/-3).

## Briefing Changes

- Added: none — scanned this iter's observations against `docs/briefing/hooks-and-gates.md` Critical Points and per-topic indexes; P353 sibling marker-mismatch + BYPASS_RISK_GATE recovery already documented in the briefing's external-comms gate critical-point line (rotated 2026-06-06). The P245 closure substance (each obs's supersession source) is recorded in the ticket Closure section, not the briefing — supersession events do not generate cross-session learnings.
- Removed: none — scanned for stale items related to P245's three observations; the briefing does not directly reference any of them as live concerns.
- Updated: none.
- README index refreshed: no.

Scanned 6 candidate observations across 3 topic files (hooks-and-gates, releases-and-ci, governance-workflow); 0 accepted.

## Signal-vs-Noise Pass (P105)

AFK iter scope (single-ticket close); no per-entry signal scoring run. Briefing entries cited verbatim in this iter: none (the iter relied on hook source-of-truth reads + ticket bodies + ADR/RFC IDs; no Critical-Points entry was cited as a load-bearing input). Decay-only pass for this iter — no promotions, no demotions, no delete-queue candidates. Full briefing scan deferred to natural-loop-end interactive retro per AFK boundary.

## Verification Candidates

No `.verifying.md` tickets exercised by this iter's tool-call activity. P245 itself was `known-error`, not `verifying`; the close-as-superseded path moves it directly to `closed/` per ADR-079.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| External-comms gate denied on first commit attempt despite both evaluators emitting `EXTERNAL_COMMS_RISK_VERDICT: PASS` (risk) and `EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS` (voice-tone) for the `git-commit-message` surface | Hook-protocol friction | Both PASS verdicts visible in iter tool-call history immediately preceding the BLOCKED response from `git commit`; recovery via `BYPASS_RISK_GATE=1` inline (which DID propagate, despite the deny message's "pre-session env" guidance); second commit attempt landed `4887a94` cleanly | appended to P353 (substance-aware hash + atomic verdict-write fix in flight; another empirical witness; the iter prompt anticipated this exact failure mode and pre-authorized BYPASS_RISK_GATE=1 so no additional friction beyond one retry) |

README inventory currency: not checked (iter-bounded retro; full scan defers to natural-loop-end interactive retro).

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | Iter constraint: "NEVER call AskUserQuestion" pinned in iter prompt; P245 has 0 ADR signals; no genuine ≥2-option substance decision arose during the close-as-superseded path. All decisions were framework-resolved (close-on-evidence per ADR-079 Phase 2 shape 3 + ADR-026 grounding from sibling-fix-supersedes evidence). |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Topic File Rotation Candidates

Not run (iter-bounded retro; budget scan + rotation defers to natural-loop-end interactive retro).

## Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| — | — | — | — | — | none — P353 already in flight covers the only pipeline-instability signal observed this iter; no other codifiable observations |

## Tickets Deferred

None — no observations deferred under any cause.

## Positive observations

- The Step 4b coordinating-ticket scope-narrowing worked exactly as designed: investigation confirmed all three observations addressed → close-as-superseded path applies cleanly without needing to ship any of P245's deferred Phase 2/3 amendments. Coordinating-ticket grain saved three separate close-as-superseded ceremonies.
- The iter prompt's "check whether observations already addressed by subsequent fixes" pre-warning saved investigation time — went directly to the relevant hook files (`compute_external_comms_key`, `_README_REFRESH_BYPASS_TRAILERS`, `docs/changesets-holding/*.md` case branch) without first re-reading the bundled-ticket symptom reports.
- ADR-079 Phase 2 shape 3 (sibling-fix-supersedes) load-bearing across 10 KE→Closed-direct closures this week (P218, P222, P216, P217, P224, P225, P227, P223, P221, P245) — clear pattern signal for upcoming `/wr-architect:review-decisions` ratification per outstanding-question queue #2.

## No Action Needed

- P353 sibling marker-mismatch substance already captured + in-flight; this iter is an empirical witness data-point, not a new ticket source.
- All three P245 bundled observations satisfied at verification by sibling fixes; no follow-up tickets warranted.
