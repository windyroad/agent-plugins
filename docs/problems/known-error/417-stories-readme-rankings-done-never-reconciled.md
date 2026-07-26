# Problem 417: docs/stories/README.md Rankings/Done never reconciled — stale for the whole corpus

**Status**: Known Error
**Reported**: 2026-07-04
**Priority**: 8 (Medium) — Impact: 2 (Minor — stale story ranking cache; misleads story-tier consumers) × Likelihood: 4 (Likely — the whole corpus is stale now and drifts with every story change) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: S — /wr-itil:reconcile-stories already ships; wire the cadence + refresh the header prose
**WSJF**: 16 — (8 × 2.0) / 1 (2026-07-26 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; multiplier 1.0 → 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

`docs/stories/README.md` "Story Rankings" and "Done" sections are still the bootstrap placeholder ("Empty — no stories captured yet") — stale for the entire ~30-story on-disk corpus, even though `manage-story` and `reconcile-stories` have shipped. The P062/P094 refresh-on-create+transition contract that keeps `docs/problems/README.md` and `docs/rfcs/README.md` current is not being applied to the stories tier: no session has ever populated the stories README rankings/done tables. `wr-itil-reconcile-stories docs/stories` confirms pervasive drift (nearly every story STALE in rankings, plus corpus-wide MISSING_REVERSE_TRACE). Surfaced 2026-07-04 working P409 (needed to add 3 new draft stories; reconcile showed the README was never reconciled). Distinct from P409 (which is the RFC-side `stories: []` back-fill) and from P170 (the umbrella framework ticket).

## Symptoms

- 2026-07-26 (P430 iter): the drift is not confined to the stories index — the same never-reconciled shape holds across all three non-problem tiers. `wr-itil-reconcile-rfcs docs/rfcs` reported 9 `MISMATCH` rows (RFC-001/002/004/006/007 recorded `closed` while on-disk state is `verifying`; RFC-005 and RFC-036 recorded `closed` vs `accepted`; RFC-046 and RFC-049 vs `in-progress`) plus 3 `MISSING` rows. `wr-itil-reconcile-stories docs/stories` reported a dozen-plus `STALE` rows. `wr-itil-reconcile-story-maps docs/story-maps` reported all five maps missing from the README — its Rankings table literally read "(Empty — no story maps captured yet)" while four maps had been on disk for weeks. Contrast with `wr-itil-reconcile-readme docs/problems`, which exits clean: the problems tier has the P062/P094/P118 refresh-on-every-transition contract wired into its skills, and the other three tiers do not. That asymmetry looks like the root cause rather than three independent lapses. The story-map Rankings table was back-filled by hand in that iter's commit; the RFC and story indices were left drifting because the fix belongs here, not inline.

## Workaround

None needed — the stale README does not block story-tier work (the on-disk story files are the source of truth; the README is a derived index). The inconsistency is that the index lies about what stories exist.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

The stories README header still carries the pre-manage-story scaffold prose ("This directory is scaffold-only until P170 Phase 2 Slice 4 ships /wr-itil:capture-story + /wr-itil:manage-story" and "Run /wr-itil:manage-story review to refresh once the manage-story skill ships"). Those skills have since shipped, but no refresh-on-create/transition path was wired for the stories tier the way P094 (refresh-on-create) and P062 (refresh-on-transition) wire the problems and RFC tiers, so the Rankings/Done sections were never populated from on-disk state.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Run `/wr-itil:reconcile-stories` to rebuild the Rankings/Done sections from on-disk state
- [ ] Decide whether the stories tier needs a refresh-on-create/transition path in manage-story (mirroring P094/P062) or a periodic reconcile cadence, so the README stays current without a manual reconcile

## Fix Strategy

**Shape**: script + skill-contract wiring (Option 3 — Other codification shape). Two parts: (1) a one-shot `/wr-itil:reconcile-stories` run to rebuild the current Rankings/Done tables; (2) wire a refresh-on-create/transition path into `manage-story` (the P094/P062 pattern already proven on the problems and RFC tiers) OR a cadenced reconcile so the stories README does not silently re-drift — a governance-index-with-no-automatic-cadence never stays current (see the automatic-cadence-or-it-doesn't-happen principle).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P409 (RFC-side `stories: []` back-fill — surfaced this defect), P170 (RFC-Story framework umbrella)

## Related

Captured via `/wr-itil:capture-problem` while working P409. Hang-off-check subagent dispatch was skipped: the mechanical pre-filter found 19 candidates sharing signal (`docs/stories/README`, `reconcile-stories`, `docs/problems/README`, `docs/rfcs/README`) — over the 5-candidate latency cap — so per the capture-problem sub-step 2b short-circuit the candidate set is deferred to `/wr-itil:review-problems` for cluster-time re-evaluation. The scope is genuinely distinct: P409 back-fills RFC `stories:` arrays; this ticket is about the stories README index never being reconciled. Not a sub-concern of P170 (that ticket is the framework-existence umbrella, long since delivered).
