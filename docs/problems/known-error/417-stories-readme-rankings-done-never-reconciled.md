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

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Run `/wr-itil:reconcile-stories` to rebuild the Rankings/Done sections from on-disk state — done 2026-07-26, commit `c74c3b1a`; detector now exits 0
- [x] Reconcile the RFC index the same way — done 2026-07-26 (see § Reconcile pass 2026-07-26)
- [x] Confirm the story-map index — `wr-itil-reconcile-story-maps docs/story-maps` already exits 0; the P430 iter's hand back-fill holds
- [ ] Decide whether the three non-problem tiers need a refresh-on-create/transition path in manage-story / manage-rfc / manage-story-map (mirroring P094/P062) or a periodic reconcile cadence, so the indices stay current without a manual reconcile — **queued, not decided**; see § Deferred work
- [ ] Fix the two `reconcile-rfcs.sh` detector defects recorded below — **queued**; see § Deferred work
- [ ] Score the 42 unranked RFCs — **queued**; see § Deferred work

## Reconcile pass 2026-07-26

First full reconcile of the story and RFC tiers. Two commits, one per tier (ADR-014 per-tier grain, architect-directed).

**Story tier** (commit `c74c3b1a`) — `docs/stories/README.md`: STORY-045 added to Story Rankings; the twelve terminal stories in `docs/stories/done/` back-filled into the Done table, replacing the bootstrap placeholder; stale scaffold-only prose retired at three sites (the "run manage-story review once the skill ships" pointer, the "scaffold-only until Slice 4" status paragraph, and the "Done backfill remains outstanding debt" note under Rankings). `## Stories` reverse-trace refreshed mechanically via the shipped ADR-060 Slice-2b helpers on 14 problem tickets, 4 RFCs and 4 JTBD files. `wr-itil-reconcile-stories docs/stories docs/problems docs/rfcs docs/jtbd` now exits 0.

**RFC tier** — `docs/rfcs/README.md`: the 42 on-disk RFCs absent from the index added as a new `### Unranked` subsection of RFC Rankings; RFC-037 added to the Verification Queue; RFC-025 added to Closed; the five ranked rows re-sorted into the `(WSJF desc, ID asc)` ladder the file documents at its own `TIE-BREAK-LADDER-SOURCE` marker (RFC-050's recorded 8.0 had been sitting below RFC-049's 4.5); stale scaffold prose retired at two sites; the tier table's Story row corrected from "(Phase 2 — deferred)" to the shipped `docs/stories/<state>/` lifecycle. `## RFCs` reverse-trace refreshed mechanically on P012, P069, P160, P191, P359, P404, P443.

Nothing was synthesised. The Unranked block carries no WSJF, Severity or Effort column at all — those are `/wr-itil:manage-rfc review` Step 9c's to assign, and inventing them inside a reconcile pass would be the ADR-026 grounding violation. Status is sourced from the filename suffix, not frontmatter; all 54 RFCs were scanned for suffix-vs-frontmatter divergence and none was found.

### Root cause confirmed, and it is wider than the stories tier

The asymmetry hypothesised in § Symptoms holds. `docs/problems/` has the P062/P094/P118 refresh-on-every-transition contract wired into its skills and its reconciler exits clean; the other three tiers have reconcilers but no refresh contract, so their indices only move when a human remembers to run the reconcile. That is the automatic-cadence-or-it-doesn't-happen failure, not three independent lapses.

### Finding: a fifth drift class no reconciler detects

STORY-018, STORY-019, STORY-023, STORY-026 and STORY-027 carry `status: done` in YAML frontmatter while their files sit in `docs/stories/draft/`. `wr-itil-reconcile-stories` compares README tables against the containing subdirectory, and reverse-trace sections against frontmatter — it never compares frontmatter `status:` against the subdirectory, so it reports neither. The two surfaces consequently disagree in the repo right now: Rankings renders these five as `draft` (filesystem truth) and the parent `## Stories` sections render them as `done` (frontmatter truth). Repair means either a lifecycle move or a frontmatter edit, both of which `/wr-itil:manage-story` owns and `/wr-itil:reconcile-stories` explicitly disowns. Documented inline in `docs/stories/README.md` under `## Done` so the disagreement is visible rather than latent. The RFC tier was scanned for the same class and is clean.

### Finding: two `reconcile-rfcs.sh` detector defects

Both confirmed against source by the architect, not taken on report. Neither is repaired here — both are code changes, and a code change in an AFK iter hits the ADR-096 story-ratification wall with no AFK path.

1. **Unanchored Closed-section grep.** `packages/itil/scripts/reconcile-rfcs.sh:120` locates the Closed section with `grep -n '^## Closed' "$README" | head -1`. That prefix-matches the RFC-body-structure TEMPLATE heading `## Closed scope (required when Status reaches closed)` — which lives inside a fenced ```markdown block — ahead of the real `## Closed` section. Two consequences: `CLOSED_START` lands near the top of the file so `extract_section_ids` sweeps the Rankings and Verification Queue tables into the Closed bucket, and `VQ_END` collapses below `VQ_START` so the Verification Queue extraction range is empty and check (2) never runs at all.
2. **Reverse-trace parser reads the wrong column.** `reconcile-rfcs.sh:276` uses `awk -F'|' '{print $3}'` to pull the claimed status out of a parent ticket's `## RFCs` row. The shipped `wr-itil-update-*-references-section` helpers emit `| ID | Title | Status |`, so field 3 is the **Title**. The parser then compares a title string against a lifecycle suffix. The helpers' status column was verified against filesystem truth for all 7 affected rows and is correct in every case, so the on-disk data is right and only the detector is wrong.

### Residual detector output after the pass — every line is a defect artefact

`wr-itil-reconcile-rfcs docs/rfcs docs/problems` still exits 1 with 66 lines. **Do not read this as unrepaired drift, and do not claim the reconciler is clean.** Decomposition:

- **42 `MISSING RFC-NNN wsjf-rankings` lines: cleared.** Zero remain. The `### Unranked` block was placed between the ranked table and `## Verification Queue` precisely so those IDs bucket as rankings coverage.
- **53 `MISMATCH RFC-NNN closed:` lines: all bogus,** from defect 1 sweeping the Rankings + VQ tables into the Closed bucket. Zero of the 53 name an RFC that is genuinely `closed` on disk. The count rose from ~10 because defect 1 amplifies against a larger index, not because drift grew.
- **6 `MISSING RFC-NNN verification-queue` lines: all bogus,** from defect 1 emptying the VQ extraction range. All six RFCs (001, 002, 004, 006, 007, 037) ARE listed in the Verification Queue table. Adding RFC-037 correctly did not clear its line, and will not until defect 1 lands.
- **7 `STATUS_MISMATCH` lines: all bogus,** from defect 2 reading the Title column. Their `claims=` values are visibly title text rather than lifecycle statuses.

### Deferred work

Each item names a self-firing trigger class per ADR-087 rather than a re-entry point, so it does not rot the way P375 documents. The class for all four is the **ADR-084 SessionStart deferral census**.

1. **Refresh-on-create/transition for the three non-problem tiers** — wire the P062/P094 contract into `manage-story`, `manage-rfc` and `manage-story-map`, or give the tiers a cadenced reconcile. This is the ticket's remaining design question and the actual fix for the root cause; the reconcile pass above is symptom repair. SKILL change, so it needs the RFC → story-map → story chain and a human ratification.
2. **`reconcile-rfcs.sh` detector defect 1** (unanchored `^## Closed` grep). Anchor the match, skip fenced blocks, or take the last match rather than the first.
3. **`reconcile-rfcs.sh` detector defect 2** (reverse-trace column index). Align the parser with the helpers' `| ID | Title | Status |` emission, or key on the header row rather than a fixed field number.
4. **Score the 42 unranked RFCs** via `/wr-itil:manage-rfc review` Step 9c, so the `### Unranked` block does not become a permanent parking lot. Visibility landed first by design; scoring is the second half.

Items 2 and 3 are the same file and the same class and should ride one vehicle.

## Fix Strategy

**Shape**: script + skill-contract wiring (Option 3 — Other codification shape). Two parts.

**Part 1 — one-shot reconcile: DONE 2026-07-26.** Story and RFC indices rebuilt from on-disk state across two commits; story-map index already clean. See § Reconcile pass 2026-07-26.

**Part 2 — the actual fix, still open.** Wire a refresh-on-create/transition path into `manage-story`, `manage-rfc` and `manage-story-map` (the P094/P062 pattern already proven on the problems tier) OR give the three tiers a cadenced reconcile, so their indices do not silently re-drift. A governance index with no automatic cadence never stays current — part 1 buys a clean slate and nothing more, and without part 2 the corpus drifts straight back. Note the framing widened during the reconcile: this is not a stories-tier defect but a missing contract shared by all three non-problem tiers. Blocked on human ratification (SKILL change → RFC → story-map → story → ADR-096 accepted gate).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P409 (RFC-side `stories: []` back-fill — surfaced this defect), P170 (RFC-Story framework umbrella)

## Related

Captured via `/wr-itil:capture-problem` while working P409. Hang-off-check subagent dispatch was skipped: the mechanical pre-filter found 19 candidates sharing signal (`docs/stories/README`, `reconcile-stories`, `docs/problems/README`, `docs/rfcs/README`) — over the 5-candidate latency cap — so per the capture-problem sub-step 2b short-circuit the candidate set is deferred to `/wr-itil:review-problems` for cluster-time re-evaluation. The scope is genuinely distinct: P409 back-fills RFC `stories:` arrays; this ticket is about the stories README index never being reconciled. Not a sub-concern of P170 (that ticket is the framework-existence umbrella, long since delivered).
