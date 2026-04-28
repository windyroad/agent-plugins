# Context Usage (Cheap Layer) — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P140 Phase 1)

Per ADR-043. Cheap-layer measurement; static-budget-bounded ~2.5 KB output ceiling. Read-only observability — no trim decisions.

## Per-bucket measurement

| Bucket | Bytes | % of total | Δ vs prior |
|--------|-------|------------|------------|
| problems | 1,953,541 | 49.7% | not measured — no prior snapshot in `docs/retros/*-context-analysis.md` |
| decisions | 814,344 | 20.7% | not measured — first measurement this project |
| skills | 571,978 | 14.6% | not measured — first measurement this project |
| hooks | 248,546 | 6.3% | not measured — first measurement this project |
| memory | 170,470 | 4.3% | not measured — first measurement this project |
| briefing | 79,878 | 2.0% | not measured — first measurement this project |
| jtbd | 25,127 | 0.6% | not measured — first measurement this project |
| project-claude-md | 4,277 | 0.1% | not measured — first measurement this project |
| framework-injected | not measured | — | reason=framework-injected-no-on-disk-source |

**Total measured**: 3,868,161 bytes
**Threshold (cheap-layer report ceiling)**: 10,240 bytes — this report fits well under

## Top-5 offenders

1. **problems** — 1,953,541 bytes (49.7%) — measured by `packages/retrospective/scripts/measure-context-budget.sh` walking `docs/problems/*.md` (per ADR-026 grounding). Driven by accumulated WSJF backlog + Verification Queue narrative density per P062.
2. **decisions** — 814,344 bytes (20.7%) — measured by walking `docs/decisions/*.md`. ADR corpus has grown to 47+ decisions.
3. **skills** — 571,978 bytes (14.6%) — measured by walking `packages/*/skills/*/SKILL.md` + REFERENCE.md surfaces.
4. **hooks** — 248,546 bytes (6.3%) — measured by walking `packages/*/hooks/*.sh` + helpers + tests.
5. **memory** — 170,470 bytes (4.3%) — measured by walking the user's auto-memory directory.

## Affordances

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

This is the first cheap-layer measurement persisted to `docs/retros/`; subsequent runs will produce delta-vs-prior. No deep-analysis recommendation fires this run (no prior snapshot to compute delta from).

<!-- context-snapshot: hooks=248546 skills=571978 briefing=79878 decisions=814344 problems=1953541 jtbd=25127 project-claude-md=4277 memory=170470 total=3868161 threshold=10240 retro-iter=p140-phase-1 -->
