# Problem 508: The fix proposal still instantiates a standalone RFC document, after ADR-103 made it a release row

**Status**: Known Error
**Reported**: 2026-08-20
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — **re-rated 2026-08-21 after slice A landed.** Impact unchanged at 4: the writer still mints a document when `/wr-itil:capture-rfc` is invoked directly, and the create gate still permits the write, so the retired artefact is still reachable. Likelihood 5 → 4: the *automatic* path is closed. The propose-fix gate no longer instructs anyone to create a document, at either the interactive or the AFK surface, so the contradictory branch is no longer the shipped default on every RFC-less Known Error — it now needs a direct invocation of the writer to reach.
**Origin**: internal
**Effort**: L — derived at capture. The gate branch is small, but the decision it must implement is not: whether the standalone RFC tier survives at all, what `capture-rfc` becomes, and how a gate that currently allocates an id and writes a file instead draws a row on a map that may not exist yet. Sized level with P506 — both reverse a shipped design premise. **Re-checked 2026-08-21**: still L. Slice A discharged the reader half and the identity allocator; what remains — repointing the writer, withdrawing the create-gate permission without catching lifecycle renames, `manage-rfc`'s disposition, the superseded-by-row derived marker, and the corpus sweep — is not a smaller bucket.
**WSJF**: 8 — (16 × 2.0) / 4 (2026-08-21: re-scored after slice A; Known Error multiplier 2.0, Effort still L — the remaining writer half plus the corpus sweep is not smaller than L)
**JTBD**: JTBD-008 (primary — what vehicle carries a fix proposal and how it traces to its problem is this job's whole statement), JTBD-001 (secondary — two approval surfaces means the automatic one bypasses the human one)
**Persona**: developer

## Description

ADR-103 (accepted 2026-08-07) collapsed the RFC into the story map:

> **A release row is an RFC.** A row is the set of stories that ship together to fix a problem. It carries an `rfc` identity once a problem proposes it […] **Working a problem** now runs: reach Known Error with a root cause and a workaround, then propose the fix as one or more release rows on new or existing maps, recorded on the problem ticket.

The shipped code does not do this. In `@windyroad/itil@1.1.1`, `manage-problem`'s I13 propose-fix gate still runs the pre-ADR-103 path: on a Known Error whose problem no RFC traces, it delegates to `/wr-itil:capture-rfc --fix-time`, which allocates the next RFC id and writes a new `docs/rfcs/RFC-<NNN>-<slug>.proposed.md`. Nothing in that path draws a release row on any map.

So two contradictory fix-proposal mechanisms are live at once, and the one the framework reaches for automatically is the superseded one.

Maintainer direction 2026-08-20, verbatim: *"The fix proposal is supposed to be the rfc row (or rows), not a new doc."*

## Symptoms

- Every RFC-less Known Error that reaches propose-fix mints a standalone RFC document rather than a row.
- Those documents are born `human-oversight: unconfirmed` and ratified at `manage-rfc accepted` — a second approval surface competing with the map that ADR-103 designated as *the* approval surface.
- 54 RFCs currently lack human oversight (SessionStart nudge, 2026-08-20). Some unknown fraction are this mechanism's output.

## Workaround

**No longer needed on the automatic path as of 2026-08-21** — the propose-fix gate now draws the row itself and no longer names any document-creating command. The workaround stands only for a direct `/wr-itil:capture-rfc` invocation, which still writes a document: propose the fix as a row by hand instead.

## Impact Assessment

- **Who is affected**: the maintainer on every fix, and adopters identically once they work a Known Error. The AFK loop dispatches its fix work through this same traversal, so it inherits the behaviour without a separate code path.
- **Frequency**: every RFC-less Known Error reaching propose-fix.
- **Severity**: governance-model divergence rather than breakage. Nothing errors; the framework simply keeps building the artefact its own current decision retired.
- **Analytics**: none. Nothing counts RFC documents created after 2026-08-07.

## Root Cause Analysis

ADR-103 amended ADR-060 and superseded ADR-101, and its Decision Outcome rewrote what "propose the fix" means. The `manage-problem` I13 gate was not brought along. Its prose still cites ADR-071 / ADR-072 / ADR-073 — the decision lineage that predates the collapse — and its no-vehicle branch still names `capture-rfc --fix-time` as "the canonical ADR-070-compliant vehicle".

The gate is not broken against the decisions it cites. It is correct against a superseded lineage, which is the harder failure to see.

### What this ticket must NOT re-litigate

The seven blank RFC skeletons (`RFC-021`, `026`, `029`, `030`, `032`, `033`, `034` — `## Scope` and `## Tasks` still carrying `(deferred — populate at /wr-itil:manage-rfc accepted transition)` while their driving problems are closed or in verification) were **already ruled on**. P314's `## Human decision — 2026-07-03` records the maintainer's call: transition them to reflect shipped state, do not flesh them out, and no policy revisit is needed because the creation process was changed to prevent recurrence — that change being the `--fix-time` flag, which makes `capture-rfc` author a real Scope and Tasks at creation.

Two consequences worth stating plainly:

1. **The blanks are a settled outcome awaiting a lifecycle transition, not neglect.** The remaining work on them is transitioning seven files, which the 2026-07-03 decision already authorised.
2. **`check-autocreate-rfc-scope.sh` does not know that.** It re-flags all seven every retro as the ADR-073 under-scoped signal, and reported `under_scoped=7` again on 2026-08-20 — where it was read as fresh evidence that the reassessment criterion had fired. It had fired, and was answered, in July. The detector has no notion of a ruled-on candidate, so it will keep manufacturing that signal every retro until the seven are transitioned.

The genuinely new ground here is ADR-103 plus the 2026-08-20 direction, not the blanks.

## Direction — 2026-08-20

Both blocking design calls were put to the maintainer and answered. Verbatim: *"No standalone rfc doc. Capture-rfc gets repointed"*.

- **The standalone RFC document tier does not survive ADR-103.** No new `docs/rfcs/RFC-<NNN>-*.md` file is created for a fix proposal.

  **The "read-only history" reading first recorded here was WRONG and is retracted** — see ADR-119, which states it plainly: only 1 of the 60 documents is closed, and 59 carry live, unshipped plans. Freezing them would have silently displaced ADR-085's `## Commits` re-render and ADR-107's derived map list, both driven by shipped scripts. What the decision actually says:

  - no new documents, and **no authored edits**;
  - **derived sections keep re-rendering** (ADR-085, ADR-107) — the corpus is not frozen against machine writes;
  - **lifecycle renames keep working** — `.proposed → .accepted → .verifying` must not be caught by the create-gate withdrawal;
  - **each open proposal re-draws as a row when its problem is next worked** — no migration pass. Maintainer direction: *"You just need to create the rfc rows to fix them and then implement those stories."*
- **`/wr-itil:capture-rfc` is repointed, not retired.** It keeps its name and its invocation surface; what it *writes* changes from a document to a release row on a story map.

This resolves the two tasks that blocked the rest of this ticket. The remaining work is now unblocked, and the substance is settled ahead of it per ADR-074.

**Not yet ratified as an ADR — the state on 2026-08-20, when this section was written.** The direction above was the maintainer's answer to a two-option question, not itself a recorded decision — per P357, applying user direction to a governance artefact does not by itself authorise the oversight marker. The decision was captured as an ADR born `human-oversight: unconfirmed`, to be ratified only once the maintainer saw what the ADR body actually said. **That ratification landed 2026-08-21**: ADR-119 now carries `human-oversight: confirmed`, ratified via `AskUserQuestion` with the inherited-approval consequence stated in the option set. ADR-119 is binding authority from that date; the rest of this section reads as the 2026-08-20 record.

### Live defect surfaced 2026-08-20 — the RFC id allocator already collides

Found while reviewing ADR-119, and independent of it. `capture-rfc` allocates the next RFC id as `max(local, origin) + 1` over `docs/rfcs/RFC-*.md`. That input set cannot see release rows, and rows already hold **RFC-060 through RFC-069**:

```
rows:      RFC-005, 028, 046, 047, 050-054, 056, 057, 060-069
documents: … 058, 059, 067   (max = 067)
allocator: max + 1 = 068  ← a row holds RFC-068
```

**The next `capture-rfc` invocation issues an id a row already owns.** This is live in the working tree now, not a consequence of retiring the tier — retiring it only makes the collision permanent, because `max()` then freezes at 067 and re-issues 068 forever.

Two further observations from the same check:

- The ids missing from `docs/rfcs/` between 060 and 066 are not gaps in a sparse series. Each is held by a row — the two-tiers-one-id-space problem visible in the corpus.
- **RFC-060 is absent from HEAD entirely**, surviving only on branch `worktree-main-clean`, yet a row holds it. A live working-tree scan cannot see it. This is the concrete case ADR-115's never-reuse-ids reasoning anticipates, and it is why the replacement allocator must read git history rather than only the current tree.

Fix locus: `packages/itil/skills/capture-rfc/SKILL.md` § "Compute next RFC ID". Worth fixing ahead of the tier sweep, since it mis-issues today.

### Investigation Tasks

- [x] Decide whether the standalone RFC document tier survives ADR-103 at all — **resolved 2026-08-20: it does not; `docs/rfcs/` becomes historical**
- [x] Decide what `/wr-itil:capture-rfc` becomes — **resolved 2026-08-20: repointed at row-drawing on a map, not retired**
- [x] Record the two decisions above as an ADR — **recorded as ADR-119, born `human-oversight: unconfirmed` on 2026-08-20 and ratified 2026-08-21** (`human-oversight: confirmed`, via `AskUserQuestion`). This task is complete; no ratification remains outstanding on it.
- [ ] Settle what a repointed `capture-rfc` does when the fix needs a map that does not exist yet — ADR-103 queues implementation for a new map because a new map is new substance needing a human, so the repointed skill cannot mint one silently
- [x] Settle whether the RFC id series continues across the tier change, or whether row identities allocate from a fresh series — **one series, one allocator. Landed 2026-08-21 as `packages/itil/scripts/next-rfc-id.sh` + `wr-itil-next-rfc-id`, the single rule that unions documents, rows and full git history and returns highest+1 (never a gap — identities are never reused). `capture-rfc` § "Compute next RFC ID" now calls it instead of scanning `docs/rfcs/`. The live collision is closed: the old rule answered 068, which a row held; the allocator answers 071.** Nine behavioural cases, including an adversarial one that commits a map and then deletes it on the same branch so the identity exists at no ref tip, plus its `--no-git` control proving the history half is doing work rather than the working-tree scan answering by coincidence.
- [ ] Decide what `manage-rfc` becomes — it currently owns the `accepted` ratification of a document tier that is going away, while ADR-103 puts approval on the map
- [x] Rework the I13 no-vehicle branch to propose rows — **landed 2026-08-21.** Branch (b) now draws a release row with `wr-itil-story-map-edit … add-band` + `add-card` on a map that already covers the journey, takes its identity from the allocator, and requires the card's story to name the problem in its own `problems:` list (the row-to-problem link is read through the cards, so a bare row still reads as untraced and the gate loops). It stays silent on that path — drawing a row onto an already-approved map inherits that approval. **The queue condition is derived from the ratification fingerprint rather than enumerated**: queue for a person whenever the draw would change a key in `oversight_map_substance_keys()` (`lib/story-oversight.sh`), which subsumes new-map, new-activity-column AND the `traces` case — a map that covers the journey but does not trace the job the fix's story serves. A separate, non-fingerprint condition queues when the fix approach is a choice no existing decision record covers. Deriving from that one function rather than restating its members means an amendment to the tuple cannot leave the gate behind.
- [ ] Re-check ADR-073's auto-create decision against ADR-103 — it authorises auto-creating a vehicle whose definition has since changed
- [ ] Transition the seven blanks per the 2026-07-03 ruling, so the detector stops re-flagging them
- [ ] Give `check-autocreate-rfc-scope.sh` a way to exclude ruled-on candidates, or retire it if the tier goes
- [ ] Audit the 54 unratified RFCs for how many are this mechanism's post-2026-08-07 output
- [x] **ADR-068 lockstep — amend JTBD-008** (`docs/jtbd/developer/JTBD-008-decompose-fix-into-coordinated-changes.proposed.md`). It still frames the RFC as a document with a `stories:` array, and still carries verbatim the ADR-101 line *"every other map edit still re-opens ratification exactly as before"* which ADR-103 superseded on 2026-08-07. That stale text is not inert: during ADR-119's own JTBD review it caused a reviewer reading it in good faith to raise a blocking objection ADR-103 had already resolved. It is `human-oversight: confirmed` at HEAD, so no nudge fires on it — the downgrade is the undone action. Downgrade to `unconfirmed` and ratify alongside ADR-119. **Already done — verified 2026-08-21 at commit `74df157f`, which carries real body amendments and not just a marker flip; both files read `human-oversight: confirmed` with `oversight-confirmed-date: "2026-08-21 — re-ratified via AskUserQuestion alongside ADR-119"`. Do NOT re-downgrade these: the ratification was legitimately re-earned.**
- [x] **ADR-068 lockstep — amend JTBD-009** (`docs/jtbd/developer/JTBD-009-migrate-adopter-artefacts.proposed.md`) to admit a stop-growing evolution: one whose old artefacts are never rewritten, whose readers stay dual-tolerant indefinitely by design, and where "have I migrated yet?" is not a question an adopter can be behind on because there is no migration command. Its current *"Dual-tolerant fallback is a bridge, not a destination"* outcome rejects exactly the shape this decision needs. Downgrade and ratify alongside ADR-119. **Already done — see the note on the JTBD-008 task above; same commit, same verification.**
- [ ] **Blast radius, re-measured 2026-08-20 (supersedes the first pass; both figures below were wrong).** **60** documents live under `docs/rfcs/` — not 62 — split 48 proposed / 2 accepted / 3 in-progress / 6 verifying / 1 closed. And the sweep is **38 non-test, non-changelog files** under the union predicate (`docs/rfcs/` path OR `capture-rfc` OR `ADR-072|ADR-073`), across three plugins: 34 itil, 2 retrospective, 2 architect. The path-only predicate — which produced the original 24 — yields 30 raw / 28 in-scope and understates the job by a quarter, because it misses every surface that names the mechanism without the path. The path-predicate files are: 8 skills (`capture-rfc`, `manage-rfc`, `capture-problem`, `manage-problem`, `capture-story`, `manage-story`, `list-stories`, `work-problems`, plus `run-retro` in the retrospective plugin), 5 hooks (`itil-rfc-oversight-nudge`, `itil-rfc-trailer-advisory`, `itil-commit-trailer-transition-advisory`, `itil-deferral-cadence-gate`, `manage-problem-enforce-create`), and 8 scripts (`reconcile-rfcs`, `mark-rfc-capture-gate`, `check-rfc-rejected-alternatives`, `evaluate-relevance`, `render-story-map.mjs`, and the three `update-*-references-section` helpers). Retiring the tier is a sweep across all of them, not an edit to one gate. Sequence it so the *writers* stop first and the *readers* keep working against the historical corpus, or the reverse-trace helpers break while 60 documents are still on disk.
- [x] **`check-fix-rfc-trace.sh` is missing from the blast-radius inventory above** — and ADR-119 § "Sequencing — writers stop, readers follow" singles it out as *"the reader that must outlive every writer"*, the load-bearing predicate behind the I13 gate, which must be repointed **in lockstep with or ahead of** `capture-rfc` and must fail **closed** during any transition window. The 8-script path-predicate list names `reconcile-rfcs`, `mark-rfc-capture-gate`, `check-rfc-rejected-alternatives`, `evaluate-relevance`, `render-story-map.mjs` and the three `update-*-references-section` helpers — but not this one. It still answers "does an RFC's `problems:` array name this PID?" by scanning `docs/rfcs/` alone, so it cannot see a release row. Add it to the sweep and give it the row-reading answer path.

- [x] **First live witness — the gate misrouted a real iteration, 2026-08-21 (P463).** Previously this ticket recorded the defect from reading the shipped code. It has now fired in anger. Working P463 (relevance-close evaluator over-fires), the I13 gate ran `wr-itil-check-fix-rfc-trace` against a Known Error with a genuine fix vehicle available and returned `no-rfc-trace: P463 — auto-create a problem-traced RFC via /wr-itil:capture-rfc before fix work`. That directive names an action ADR-119 Clause 1 now bars. The iteration additionally evaluated the P371 existing-vehicle-untraced branch and selected RFC-013 as the vehicle — which would have meant hand-authoring a Phase 4 block into a legacy document, barred by the same decision's "no new documents, and no **authored edits**" clause. **Only the synchronous architect review caught both.** Nothing in the shipped skill, the predicate, or any hook flagged either. The iteration recovered by drawing release row RFC-070 on STORY-MAP-011 instead, but an iteration that skipped the architect gate would have written the barred artefact. This raises the practical severity: the gate does not merely describe the superseded model, it actively routes work into it, and the only thing standing between it and a wrong write is a reviewer that is not mechanically guaranteed to run.

- [x] **The fix surface is wider than the I13 branch.** The pre-ADR-103 lineage is asserted at four sites in `packages/itil/skills/manage-problem/SKILL.md` — the lifecycle prose at line 51, the lifecycle **table** at line 58, the I13 gate at line 185, and the closing lifecycle recap at line 680 — each stating that the fix proposal "produces the RFC per ADR-072". Reworking only the gate would leave three sites teaching an agent the superseded model. Sweep all four, and grep the wider corpus for the same phrasing before assuming they are the only ones.

## Slice A landed — the readers, 2026-08-21

**What shipped.** Release row **RFC-071** on STORY-MAP-002 (activity `decompose`), carrying **STORY-065**. Drawing that row left the map's stored ratification fingerprint unchanged (`ratified: true` before and after), which is the inherited-approval property ADR-119 was ratified on, exercised rather than asserted. The gate now reads this very ticket as traced.

The slice is deliberately the **reader** half. ADR-119's sequencing rule is that no writer may stop before its readers can answer from rows, and repointing the reader to the UNION of both tiers is a strict widening — nothing that read as traced yesterday reads as untraced today — so it is the only half that is safe to land alone.

- `packages/itil/scripts/next-rfc-id.sh` (new) + `wr-itil-next-rfc-id` shim + 9 behavioural cases. The single identity allocator.
- `packages/itil/scripts/story-map-query.mjs` — new `find-problem <P-NNN>` operation. Returns `{hits, unanswerable}` rather than a flat array, deliberately diverging from `find-story`/`find-rfc`, because the obvious test on a flat array is `length > 0` and that would read "this map cannot answer" as a trace hit. Fail-closed had to be the shape, not a convention the caller remembers. Both halves of cannot-answer report: a missing authored island and a missing derived island. 6 new behavioural cases.
- `packages/itil/scripts/check-fix-rfc-trace.sh` — the union reader. Third optional `<maps-dir>` argument so every case drives a fixture corpus instead of the live one. 20 behavioural cases, all passing a fixture maps-dir; the previous suite left it defaulting, so its negative cases were reading this repository's own corpus.
- Prose repointed: `manage-problem` (4 sites), `work-problems` (the AFK carve-out), `transition-problem`, `run-retro`.
- Both stale eval cases repointed from `--fix-time` to `add-band`/`add-card`, with `--fix-time` as the negative anchor.
- `capture-rfc` § "Compute next RFC ID" now calls the allocator. This changes which identity the writer stamps, NOT what it writes — the writer repoint is still ahead.

**ADR-119's Confirmation criterion "no shipped surface still teaches the document model" is discharged**, run as the three separate assertions it specifies rather than one conjoined command: root exists (PASS), a planted known-positive is found (PASS — so the search is not broken), corpus returns nothing (PASS).

**Where the "halts" criterion actually lives, and why the exit code is what it is.** ADR-119 says an untraced problem "halts". That is discharged at the **skill layer, not the exit code**, and the split is deliberate:

- Untraced but drawable → **exit 0** with a directive. The caller resolves this itself with no person involved, so a refusal exit would be theatre. The halt is real but it lives in the skill: fix work does not begin until the row exists.
- A map edited without being re-rendered → **exit 3**. Fail-closed. Answering "no row proposes this" from a map that cannot say would draw a duplicate over one that may already exist. Mechanical: the caller re-renders and asks again, and nobody is asked about it — a condition a renderer clears must not become a question.
- No story maps in the repository at all → **exit 3**. Drawing the first map for a journey decides what that journey is, so it needs a person. The caller records ONE item and moves to the next problem; it does not halt the loop, or an adopter with no maps would see every known error refuse and read it as the loop mysteriously stopping.

Recorded here rather than as an amendment to ADR-119, which is ratified and changes only by supersession.

### Remaining — the writers, and the corpus

- [ ] **Repoint what `/wr-itil:capture-rfc` writes** — document → release row. Its name, entry point, problem-trace contract and (as of this slice) its identity rule are already correct; what it writes is not. This is the writer stop, and the reader is now ahead of it.
- [ ] **Withdraw the create-gate permission for a new RFC document** in `packages/itil/hooks/lib/create-gate.sh` (`check_rfc_capture_gate()` / `mark_rfc_capture_complete()`), which is what makes the no-new-documents clause structural rather than advisory. **The withdrawal must discriminate creation from lifecycle**: a `.proposed → .accepted → .verifying` rename presents as a Write to a new path, and catching it would make 59 live documents untransitionable.
- [ ] **Decide what `manage-rfc` becomes** — it owns the `accepted` ratification of a tier that is closing, while approval now lives on the map. Its derived `## Commits` re-render must keep working either way.
- [ ] **Settle what a repointed `capture-rfc` does when the fix needs a map that does not exist yet.** The I13 gate now answers this (queue one item, carry on), but the standalone skill invoked directly still needs the same answer.
- [ ] **A document whose problem has re-drawn as a row renders as superseded-by-row** — machine-written from the row's own trace, never hand-authored, so it breaks no rule. Without it the corpus accumulates permanently-`proposed` files whose work shipped elsewhere while `reconcile-rfcs`, `itil-rfc-trailer-advisory` and `itil-commit-trailer-transition-advisory` keep treating them as live plans.
- [ ] **Give `check-autocreate-rfc-scope.sh` a way to exclude ruled-on candidates, or retire it.** Its prose in `run-retro` is corrected — it now says the population is closed and can only shrink, so a steady count reads as a queue to drain rather than fresh evidence — but the detector itself still has no notion of a ruled-on candidate.
- [ ] **Transition the seven blanks** per the 2026-07-03 ruling, which is what actually stops the detector re-flagging them.
- [ ] **Audit the unratified RFC population** for how many are this mechanism's post-2026-08-07 output.
- [x] **ADR-068 lockstep — JTBD-006 and JTBD-002 amended and downgraded 2026-08-21.** Both carried the "Amendment 2026-07-26" clause conditioning unattended acceptance on *"Where the project has opted in"*. ADR-103 superseded that outright on 2026-08-07, dropped the opt-in protection knowingly, and removed the machinery — the config key it points at survives only in a changelog. Slice A is what made the staleness bind rather than merely sit there: the I13 gate now draws a row and inherits map approval on every untraced Known Error, at the AFK surface, unconditionally, so the job a reviewer opens to answer "may the loop do this unattended?" was answering with a precondition nobody could satisfy. Both clauses are now struck through with a supersession banner in the shape JTBD-008 models, and both files read `human-oversight: unconfirmed`.
  - **Re-ratification is the part still owed.** It is queued for the next interactive `/wr-jtbd:confirm-jobs-and-personas` drain — the salvage session that wrote the amendment was non-interactive, so no `AskUserQuestion` was available and writing a confirmed marker would have been the P348 hollow-marker bug (ADR-066 P348 AFK fallback). From the moment this lands, the ADR-109 build-upon guard fires on any further change citing JTBD-006 or JTBD-002 by name — including the writer half, which touches the AFK surface and will cite JTBD-006. That is the forcing function working, not something to route around. STORY-065's own tertiary cite of JTBD-006 is knowingly grandfathered: it predates the downgrade by being in the same commit as it, and the story's primary trace is JTBD-008, which stays ratified, so the I9 invariant rests on ratified ground either way.
- [ ] **Three derived-table staleness items, for `reconcile-stories` regeneration rather than hand edits**: STORY-013's title still reads document-shaped against its own row-shaped acceptance criteria, and its old wording is carried into JTBD-001's and JTBD-008's derived tables. Seven further files outside slice A's scope still render STORY-MAP-002 under its old title (`docs/problems/verifying/{170,251,314,390}`, `docs/problems/open/399`, `docs/problems/closed/371`, `docs/stories/draft/STORY-040`) — most are frozen snapshots inside verifying or closed tickets, so the class closes on regeneration rather than a sweep. (The STORY-015 title and the STORY-MAP-002 map title in JTBD-006 / JTBD-008 were both discharged 2026-08-21 in the slice-A commit — a discharged item left on a remaining list is the same in-good-faith stale-text hazard this ticket exists to document.)

### Enumeration — the full surface set, re-derived from source 2026-08-21

**35** non-test, non-eval, non-changelog files match the union predicate (`docs/rfcs/` path OR `capture-rfc` OR `ADR-072|ADR-073`) across three plugins. Slice A touched 8 of them plus 3 new files. The remaining 27 are readers of the historical corpus that keep working unchanged, or writers still to be repointed:

- **itil skills**: `capture-rfc`*, `manage-rfc`, `capture-problem`, `manage-problem`*, `capture-story`, `manage-story`, `list-stories`, `reconcile-stories`, `capture-story-map`, `transition-problem`*, `work-problems`*
- **itil hooks**: `itil-rfc-oversight-nudge`, `itil-rfc-trailer-advisory`, `itil-commit-trailer-transition-advisory`, `itil-deferral-cadence-gate`, `manage-problem-enforce-create`, `lib/create-gate.sh`
- **itil scripts**: `check-fix-rfc-trace`*, `next-rfc-id`†, `story-map-query`*, `reconcile-rfcs`, `mark-rfc-capture-gate`, `check-rfc-rejected-alternatives`, `detect-unoversighted-rfcs`, `evaluate-relevance`, `reconcile-stories`, `render-story-map.mjs`, and the three `update-*-references-section` helpers
- **itil other**: `.claude-plugin/plugin.json`, `README.md`
- **retrospective**: `skills/run-retro`*, `scripts/check-autocreate-rfc-scope.sh`
- **architect**: `agents/agent.md`, `scripts/sync-codex-skills.mjs`
- **evals** (outside the file count): `manage-problem`*, `work-problems`*, `capture-rfc`

`*` touched this slice; `†` new this slice.

One correction to ADR-119's own sequencing note: it claims the `--include='*.sh'` on its cleanliness grep covers `check-autocreate-rfc-scope.sh`. It does not — that script contains neither phrase at HEAD. What the `.sh` include actually caught was `check-fix-rfc-trace.sh`, which is why leaving the detector out of this slice is safe.


## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — the two blocking design calls were answered 2026-08-20; see Direction above)
- **Composes with**: P314, P457, P170

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over four candidates; none carries this root cause, and no ticket in the corpus that cites ADR-103 is an I13 or fix-vehicle ticket.

- **P314** (`docs/problems/verifying/314-…md`) — the ticket that *established* the mechanism this one says ADR-103 superseded; its RFC-005 B-tasks all shipped. Absorbing this would grow a shipping ticket's scope to include the invalidation of its own design. Its 2026-07-03 human decision is the ruling quoted above, and stands.
- **P371** (`docs/problems/closed/371-…md`) — closed and verified 2026-07-24. Its root cause is *which* RFC the gate traces to (wire an existing vehicle rather than mint a duplicate); this one is *what an RFC now is*. Orthogonal to the artefact's shape.
- **P457** (`docs/problems/open/457-…md`) — mirror image: ratification ordering on story maps, where a human is asked to approve placeholder text. Shares the skeleton-artefact signal, different defect. Sibling for a `/wr-itil:review-problems` cluster pass rather than a parent.
- **P170** (`docs/problems/known-error/170-…md`) — the RFC tier's origin ticket. This is the reconciliation of what it built with ADR-103's collapse, not a further phase of building it.
- **ADR-119** (`docs/decisions/119-a-fix-proposal-draws-a-release-row-never-a-document.proposed.md`) — **the decision this ticket produced**, and the authority for everything in the Direction section above. Read it before implementing: it retracts the "read-only history" clause, narrows the supersession to ADR-070 and ADR-072 in part, and decides the id-allocation source. Born unconfirmed 2026-08-20; **ratified 2026-08-21** and binding from that date.
- **ADR-103** (`docs/decisions/103-a-release-row-is-the-rfc-and-the-map-is-the-approval-surface.proposed.md`) — the decision the gate contradicts.
- **ADR-107** (`docs/decisions/107-a-story-maps-rfc-list-is-derived-from-its-release-rows.proposed.md`) — derives a map's RFC list from its rows, reinforcing that the row carries the identity.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-065 | STORY-065: A fix proposal draws a release row, not a document | accepted |
