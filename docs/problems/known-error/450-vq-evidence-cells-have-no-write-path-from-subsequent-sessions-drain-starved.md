# Problem 450: Verification Queue evidence cells are never populated from subsequent-session exercises, so the run-retro Step 4a auto-drain never fires

**Status**: Known Error
**Reported**: 2026-07-15
**Priority**: 12 (High) — Impact: 3 (Moderate — the verification pipeline's automated drain is structurally starved; downstream queue grew to 47 tickets requiring a manual 4-agent triage to close 30; this repo's queue sits at ~190 with the same dynamic) × Likelihood: 4 (Likely — continuous: every verifying fix exercised in a later session fails to get its cell updated) — derived at capture per Step 4a
**Origin**: inbound-reported (#323)
**Effort**: L — re-rated M → L 2026-07-26 at the Known Error transition (P047 live-estimate discipline). The capture-time M assumed a single write-path sub-step. Root-cause confirmation plus the architect and JTBD reviews expanded the fix to: a new ratified ADR for the storage locus (blocking — see Fix Strategy), a withhold taxonomy separating mechanical from judgment holds, release-marker binding on persisted evidence, the anti-laundering guard re-key, a targeted-row-rewrite constraint for read-cost, a third retro-summary outcome, and six behavioural assertions. Under the ticket-body storage option it also carries a problem-ticket data-model addition plus render changes in two skills.
**WSJF**: 6 — (12 × 2.0) / 4 (Known Error multiplier applied 2026-07-26; effort re-rated M → L in the same pass, so the score is unchanged at 6.0 and the queue position holds)
**JTBD**: JTBD-006 (secondary: JTBD-001) — re-anchored 2026-07-26 per `wr-jtbd:agent` review. JTBD-001's outcomes are per-edit review mechanics (every edit reviewed, under 60 seconds); a verification-queue drain is neither an edit nor a review gate. JTBD-006 matches near-literally: *"the loop drains … queues … so risk never silently accumulates across AFK iterations"*, *"Problems requiring my judgment (verification …) are queued for my return, not guessed at"*, and the persona constraint *"does not trust the agent to make judgment calls (verify fixes work)"* — which is exactly what the Finding 3 laundering path violates. JTBD-001 retained as the secondary audit-trace facet.
**Persona**: developer — confirmed (not `plugin-developer`: the pain is running the lifecycle and watching the queue never drain, which is the `developer` persona; that the fix locus is shipped SKILL code is a fact about the fix, not the job).

## Description

The Verification Queue evidence-first cells (the `Likely verified?` column in `docs/problems/README.md`, canonical P186 values) are never populated with a `yes — observed:` value from subsequent-session live exercises. The run-retro Step 4a prior-session evidence drain (sub-step 9, P282) fires ONLY on rows whose cell already reads `yes — observed:`, but nothing writes that value when a later session or published edition exercises a verifying fix. Result: verifying tickets sit indefinitely — the downstream queue accumulated to 47 before a manual evidence-triage drain (four parallel read-only agents) closed 30 on 2026-06-28; the automated drain never triggered because every cell read `no (not observed)`.

The producer gap is the missing half of the P186 evidence-first design: P186 shipped the cell shape and the drain consumes it, but no mechanism writes the observed-evidence value between reviews. (Witnessed in this repo too: the 2026-07-15 review pass had to derive 7 close-on-evidence verdicts from scratch because no cell carried evidence despite months of live exercise.)

## Symptoms

- Every VQ row reads `no — not observed` regardless of how often the fix has been exercised since release.
- run-retro Step 4a sub-step 9 scans find zero `yes — observed:` rows across multiple retros and close nothing.
- Queue drains happen only via manual evidence-triage passes.
- **2026-07-26 (P425 iter) — a populated evidence cell is necessary but not sufficient; there is a second, downstream reason the drain does not fire.** Step 4a sub-step 9 found exactly one `yes — observed:` row across 129 `verifying/` tickets: P164 (octal-eval bug in the next-ID formula). Its cell carries real prior-session evidence — *"2026-07-15 iter — capture-story Step 3 formula ran in the field with octal-sensitive local_max=044; `10#` guard yielded STORY-045"* — so the write-path defect this ticket describes was, for that one row, already solved. The drain still did not close it, because the same cell pins a precondition: *"Close held this iter only because the V→Closed upstream lifecycle dispatch (inbound #273 + outbound) was banned by the orchestrator's external-comms constraint — close at next session WITH the dispatch."* This iteration declined the dispatch for the same reason (posting to a public upstream issue is an outbound action an AFK iter is not authorised to take unprompted), so the close was held a **second** consecutive time for an identical cause. That is a self-firing-cadence gap in the shape memory `feedback_automatic_cadence_or_it_doesnt_happen` describes: the close is gated on an action every AFK iteration will keep declining, so nothing will ever fire it. Sub-step 9's contract has no vocabulary for this state — its three outcomes are dispatch success / dispatch failure / dispatch unavailable, and "evidence sufficient but closure gated on an outbound comms action the current run cannot authorise" is none of them, so the row silently persists with no recorded reason. Two candidate shapes, both unpinned: give sub-step 9 a fourth outcome (`blocked-on-outbound-dispatch`) that surfaces the row for the next *interactive* session rather than re-deciding it every AFK run; or decouple the local V→Closed transition from the upstream courtesy update so the ticket closes and the outbound dispatch queues separately. Note the adjacency to P455 (no evidence-append mode for already-upstream-reported tickets) — same outbound-dispatch-in-AFK boundary, different lifecycle moment.

## Workaround

Run a manual evidence-triage drain when the queue grows: read each verifying ticket's `## Fix Released` section, gather observable evidence (fix on disk + exercised by a later session / test suite / installed version), batch-close the evidenced ones (the downstream 2026-06-28 drain and this repo's 2026-07-15 review-pass closes are worked examples). Conservative bar: close only on observed proof.

## Impact Assessment

- **Who is affected**: developer persona — every suite adopter running the verification lifecycle.
- **Frequency**: continuous.
- **Severity**: Moderate — automated drain defeated; manual triage cost recurs.
- **Analytics**: downstream repo tracked as P106; this repo's VQ ≈190 rows, all `no — not observed` before 2026-07-15.

## Root Cause Analysis

**Confirmed 2026-07-26** (AFK iter, P450). Three findings, each grounded in an observable census of this repo — no inference.

### Finding 1 — the cell census confirms the drain is input-starved

`docs/problems/README.md` Verification Queue (lines 112-241) holds **129 rows**. Exactly **one** (`P164`) carries a `yes — observed:` cell; the other **128 read `no — not observed`**. Reproduction (runnable, no fixture needed):

```bash
sed -n '/^## Verification Queue/,/^## Inbound Upstream Reports/p' docs/problems/README.md \
  | grep -c '^| P'              # 129 rows
sed -n '/^## Verification Queue/,/^## Inbound Upstream Reports/p' docs/problems/README.md \
  | grep -c 'yes — observed'    # 1
```

run-retro Step 4a sub-step 9 filters to rows whose cell begins `yes — observed:` (sub-step 9b). Its input set is 1 of 129 — the drain is not broken, it is **starved**.

### Finding 2 — every codified cell write is a close-time audit annotation, never a producer

`git log -S "yes — observed" -- docs/problems/README.md` returns **37 commits** across three months. Reading their subjects and diffs, they partition into exactly two shapes, neither of which is a producer for the drain:

- **Close/transition/review commits** (the overwhelming majority — `docs(problems): close …`, `batch transition …`, `review — re-rank priorities`, `reconcile README …`): these write the evidence string into the ticket's **Closed-section** row as an audit annotation *at the moment of closing*. The cell is written after the close decision, so it can never be the drain's input — the row has already left the Verification Queue.
- **The K→V transition path itself** (`manage-problem` Step 7 P062 block, mirrored in `transition-problem` / `transition-problems` / `review-problems` / `reconcile-readme` / `list-problems`) writes the literal default `no — not observed` on every Known Error → Verification Pending render, and **no later surface ever revisits that cell**.

So the producer half of P186's evidence-first design was never built. The consumer (sub-step 9) and the default-writer (K→V render) both exist; the write-on-later-exercise path between them does not.

**Clobber hypothesis excluded** (architect review, ADR-029 diagnose-before-implement). `git log -S` is a pickaxe on occurrence *count*, so it is symmetric — it also returns commits that REMOVED an occurrence. The competing hypothesis was that a producer did write cells and a later README regeneration reset them to `no — not observed`, which would be a different defect with a different fix. Discriminator run 2026-07-26 over all 37 commits, looking for any hunk where a Verification Queue row transitions `yes — observed:` → `no — not observed`:

```bash
for sha in $(git log -S "yes — observed" --format=%H -- docs/problems/README.md); do
  git show "$sha" -- docs/problems/README.md | awk '
    /^-\| P/ && /yes — observed/ { match($0,/\| P[0-9]+/); minus[substr($0,RSTART,RLENGTH)]=1 }
    /^\+\| P/ && /no — not observed/ { match($0,/\| P[0-9]+/); id=substr($0,RSTART,RLENGTH); if (minus[id]) print id }'
done | sort -u
```

**Zero hits.** No cell has ever been clobbered from evidence-bearing back to `no — not observed`. The state is pure starvation, not write-then-reset. Finding 2 stands.

### Finding 3 — the one informal producer observed in the wild is the dishonest one, and it laundered a close

Commit `6681fd8e` (`fix(tests): make oversight/scaffold-nudge bats suites hermetic … (P391)`) wrote `yes — observed: 30/30 GREEN under exported guard … in-session 2026-06-28` onto P391's row — from the **same session that shipped the fix**. P391 was subsequently closed on 2026-07-04 by the sub-step 9 drain (commit `5333952c`).

This is a laundering path, and it defeats sub-step 8's whole purpose. Sub-step 8 correctly rules that *"a session cannot verify its own fix … subsequent-session exercise is the meaningful signal."* But sub-step 9's same-session exclusion (sub-step 9c) keys off **when the `.verifying.md` rename was committed**, not **when the cell was written**. A session that ships a fix, renames to verifying, and writes its own evidence cell is excluded from closing *that* session — and then any later session's drain sees a prior-session rename, passes the exclusion, and closes on same-session evidence one session late.

**Design constraint this imposes**: the write path must be **subsequent-session-only at the point of writing**, and sub-step 9c's exclusion must key off the cell-write provenance rather than the rename date. A producer that does not carry this constraint would industrialise the P391 laundering across all 129 rows.

### Finding 4 — even a correctly-populated cell is not being drained

P164's cell was hand-written by the 2026-07-15 review pass and reads, in part: *"Close held this iter only because the V→Closed upstream lifecycle dispatch … was banned by the orchestrator's external-comms constraint — close at next session WITH the dispatch."* Eleven days and several retros later the row is still in the queue. This is the honest, in-scope case the producer should serve — evidence collected, close legitimately withheld for an orthogonal reason — and it demonstrates the shape is useful. (Not closed in this iter: the same external-comms dispatch constraint still applies.)

### Where the write belongs

Sub-step 4 categorises each verifying ticket into three buckets. The evidence collected in sub-step 3 is discarded in every path except an immediate successful close:

- **"Exercised successfully in-session" → close dispatched and succeeded** — evidence is annotated onto the Closed row. Correct today; no change.
- **"Exercised successfully in-session" → close did NOT complete** — sub-step 7 records `dispatch-failed:` / `dispatch-unavailable:` in the *transient retro summary table* and the citation is lost at session end. P164's "close held for an orthogonal blocker" is the same shape. **This is the gap.**
- **"Not exercised in-session"** — nothing to write; correctly silent.
- **Same-session verifyings (sub-step 8)** — excluded at categorisation, so they never reach a persist path. This is what keeps the fix honest: the laundering hole in Finding 3 is closed by construction, because the persist path sits *downstream* of sub-step 8's exclusion.

### Investigation Tasks

- [x] Design the evidence write-path: a new run-retro Step 4a sub-step (**persist-on-non-close**) that writes the already-collected sub-step 3 citation into the ticket's VQ `Likely verified?` cell as `yes — observed: <citation>` whenever sub-step 4 categorised the ticket as exercised-successfully but the close did not complete. No new hook, no new detector, no new script — the evidence is already gathered and already ADR-026-grounded; today it is thrown away into a transient table.
- [x] Keep the honesty bar: the citation written is verbatim the sub-step 3 citation (tool invocation + observable outcome per ADR-026); no age, no inference, no fabrication. The path sits downstream of sub-step 8, so same-session evidence can never reach it. Sub-step 9c's same-session exclusion additionally needs re-keying from rename-date to cell-write provenance (Finding 3) or the existing laundering path stays open.
- [x] Create reproduction test — the census one-liner under Finding 1 is the runnable reproduction of the starved state. Behavioural bats coverage over the persist path + the anti-laundering guard is decomposed into the fix vehicle (ADR-052 / P081 — behavioural, not structural grep on SKILL prose).

## Fix Strategy

Two coupled changes to `packages/retrospective/skills/run-retro/SKILL.md` Step 4a:

1. **Persist-on-non-close sub-step** — when sub-step 4 places a ticket in the "Exercised successfully in-session" bucket and the sub-step 5 close dispatch does not complete (sub-step 7 `dispatch-failed` / `dispatch-unavailable`, or the close is withheld for an orthogonal blocker as witnessed on P164), write the sub-step 3 citation into the ticket's `docs/problems/README.md` VQ `Likely verified?` cell as `yes — observed: <citation>`. This makes the next session's sub-step 9 drain fire on genuine, subsequent-session evidence.
2. **Anti-laundering guard on sub-step 9c** — re-key the same-session exclusion from "`.verifying.md` rename committed this session" to the cell's write provenance, so a fix-shipping session that hand-writes its own evidence cell (the `6681fd8e` → `5333952c` P391 path) cannot be drained one session later.

Behavioural coverage per ADR-052: the persist path fires on the exercised-but-not-closed bucket and is silent on the not-exercised bucket; the guard rejects a cell written by the fix-shipping session. Structural grep on SKILL.md prose is not acceptable coverage (P081).

**Held this iter (ADR-096).** Both changes are shippable SKILL code. Under ADR-071 / ADR-089 / ADR-095 / ADR-090 / ADR-096 the fix must travel through an RFC + a story-map-anchored story, and implementation requires the story at `accepted` — a gate whose human ratification has no AFK path. This iter authors the vehicle and holds the code; the ratification is queued.

### Open decision blocking the fix strategy — where the evidence is stored (architect review 2026-07-26)

The architect review returned **ISSUES FOUND with a NEEDS DIRECTION** item that changes the fix strategy above from settled to contingent. The naive design (write the README cell) stores durable state in a **rendered projection**:

- ADR-031 line 48 names `docs/problems/README.md` the *"canonical rendered index"* — the per-state ticket files are the source of truth. ADR-085 re-pins that principle by explicit citation and rejected its own Option 1 precisely because it stored state in the view.
- Every other Verification Queue column derives from the ticket body (ID, Title, `Released`, `Fix summary`). `Likely verified?` alone derives from nothing; it survives only because README regeneration is an in-place LLM edit that happens to leave untouched rows alone.
- `manage-problem` Step 7 instructs a regeneration to *"reflect the new filename set"* and documents `no — not observed` as the default for newly-released tickets — so the render path is documented to be able to reset a cell the producer wrote.
- `reconcile-readme.sh` is read-only by design, and ADR-022's Confirmation item 3 explicitly excludes this cell from the P118 reconciliation invariant — so drift in this store is undetectable by construction.
- The anti-laundering guard needs write **provenance**, which a markdown cell cannot carry without git archaeology over a 134 KB file — the same proxy-signal defect class the guard exists to fix.

The cell is *already* narrative-only state (ratified in passing by P186, acknowledged by ADR-022). What the fix would introduce is the **escalation** — promoting an incidentally-narrative cell into the durable store of record for an automated close decision. That is an approach-choice no existing ADR covers, so per ADR-073's Confirmation (*"A fix whose approach-choice is not covered by existing ADRs has a new ratified ADR before implementation"*) this fix needs a **new ratified ADR**, not just an RFC.

The three options, recorded verbatim for the ratification drain:

- **Option A — evidence lives in the rendered index.** The `Likely verified?` cell becomes the store of record; a new producer writes it. Cheapest to build, no data-model change, reuses the shape the existing consumer already reads. Costs: the store sits in a file every ADR-031 consumer treats as a projection; durability depends on LLM in-place edit fidelity; reconciliation is documented not to check it; the guard must reconstruct provenance by git archaeology.
- **Option B — evidence lives in the ticket body; the cell is rendered from it.** A `## Verification Evidence` section in `docs/problems/verifying/<NNN>-<slug>.md` holds one entry per observation: the verbatim ADR-026 citation, the date, the observing session's identity, and the release marker it evidences. The cell becomes a projection — `yes — observed: …` iff at least one entry's session differs from the fix-shipping session. Costs: a data-model addition to the ticket contract (ADR-022 / ADR-031 territory) and a render-path change in `manage-problem` + `review-problems`. Buys: the store is reconcilable, survives regeneration, restores the ADR-031 / ADR-085 derived-view invariant, gives run-retro a clean itil delegation target matching its line-408 ownership boundary, and turns the anti-laundering guard from a heuristic into a field read.
- **Option C — ship A now, relocate later.** Buys the drain a producer immediately; costs hardening a second consumer against a store intended to move. Per the no-shortcuts correction recorded on P311, this is the shape that tends to become permanent.

**Architect's advisory lean: Option B** — ADR-085 shows the same principle being pinned for the sibling RFC surface eight weeks ago on the same ADR-031 driver, and Option B is the only option under which the guard stops being a proxy.

**This decision is NOT guessed at.** It is a genuine ≥2-option decision whose substance determines the story's acceptance criteria almost entirely (Option A = write a cell; Option B = new ticket-body section + render changes across two skills). Building the story on an unratified pick is the exact P315 failure (dependent work built on a born-`proposed` decision the user later rejected → P314 rework). Queued to `outstanding_questions`; the story is deliberately NOT authored this iter.

### Further review findings folded into the vehicle scope

From the architect review:

- **Evidence must bind to the release it evidences.** A persisted citation is grounded at capture but becomes a standing claim once it crosses sessions. A ticket that flips back to `known-error` under the regression bucket and is re-released returns to `verifying` carrying a cell that evidences the *previous* fix — and sub-step 9c's guard will not catch it under either keying, because the cell's provenance session genuinely is a prior one. The record must carry the release marker (already extracted by sub-step 2) and the drain must reject evidence older than the current `## Fix Released` marker.
- **Behavioural coverage additions (ADR-052):** (4) the persisted value survives a README regeneration — this is the assertion that discriminates between Option A and Option B, and under Option A it is expected to be the hard one to make green; (5) evidence predating the current release marker does not close.
- **The anti-laundering guard needs no ADR of its own.** Its intent is already ratified by sub-step 8's *"a session cannot verify its own fix"* rule carried by ADR-022's lifecycle semantics. Re-keying a guard from a broken proxy to the correct signal is a bug fix, not a new decision.
- **Ownership:** run-retro Step 4a is the right **detector** and the wrong **writer** — its own line 408 boundary says it *"does not rename, edit the Status field, or commit"*. The write belongs on an itil surface. The ownership answer falls out of the storage answer.
- **ADR-090 / ADR-089 constraints on the vehicle:** author the story but do NOT wire it into the RFC's `stories:` until ratified (ADR-090); an RFC proposed for a fix may not reach `accepted` with an empty stories list (ADR-089) — so the RFC stays non-`accepted` this iter. Consistent with the code hold, not a deadlock.

From the JTBD review (verdict PASS):

- **Define the withhold taxonomy — scope refinement, must be resolved in the RFC.** `dispatch-failed` and `dispatch-unavailable` are mechanical transport failures where persisting is unambiguously right. *"Close withheld for an orthogonal blocker"* is not a defined state in the current SKILL and as written is broad enough to include a close a human deliberately held pending judgment. Persisting `yes — observed:` indiscriminately there would let the next session's drain silently convert a human hold into an auto-close — crossing JTBD-006's *"does not trust the agent to make judgment calls"* constraint. P164 is the benign end (held for a mechanical external-comms dispatch ban, its own text saying *"close at next session WITH the dispatch"*); the malign end is a hold whose reason is "the user should look at this".
- **Retro-summary surface.** JTBD-006 requires the return summary to show "what remains". `## Verification Candidates` needs a third outcome distinct from *closed* and *dispatch-failed-and-lost*: "evidence persisted → will drain next session". Omitting it understates the queue's real state.
- **Cell-write provenance must be git-derivable**, not a self-attested in-file marker the same session could forge — JTBD-006's audit-trail constraint.
- **Read-cost at scale.** The queue is 129 rows and P282 records this table hitting 134 KB and blowing the 25K-token Read cap. The persist mechanism must be a targeted row rewrite, not a whole-file read-modify-write, or Step 4a degrades as the queue grows.
- **Story-map home:** reuse the existing `STORY-MAP-002` A5 activity ("Land, release & verify → adopter value") alongside STORY-023 — no new map needed (ADR-095 satisfied by reuse). That map carries an `oversight-hash`; adding a card invalidates it under ADR-090 and queues a re-ratification. Expected born-unconfirmed AFK consequence, recorded not gated.

### Why the alignment argument holds

The persist → next-session-drain chain does **not** expand the agent's judgment authority past the persona constraint: sub-step 5 already establishes close-on-evidence as a framework-resolved silent action (P135 / ADR-044) with a documented reversible recovery path. The persist path only makes an already-authorised decision survive a transport failure — provided the withhold taxonomy above keeps judgment holds out of it.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P375 (named-re-entry vs self-firing cadence — class-adjacent instance: the drain exists but its input producer never fires), P186 lineage (closed — shipped the cell shape this ticket's producer feeds), P463 (relevance-close evaluator over-fires — same evidence-vs-inference honesty concern: P463 is a consumer reading a citation as proof of shipping, this ticket is a producer that must never write a citation it has not observed), P438 (evidence-cell-drain deviation)

## Related

- Upstream issue #323 (inbound; reporter's downstream ticket P106).
- **Upstream report pending** -- false positive; detection misfire. The P063 strict-token scan matches the words "external" (in "external-comms constraint") and the `@windyroad/...` package pattern in this ticket's Root Cause Analysis, but the root cause is wholly internal — `packages/retrospective/skills/run-retro/SKILL.md` Step 4a, our own code. There is no external dependency to report. (The `**Origin**: inbound-reported (#323)` field records the *inbound* direction — someone reported this to us — which is the opposite of an external root cause.)
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P375's ratified fix (authoring-time deferral-cadence gate) creates no evidence producer and its own sibling-survey warns against rollup absorption; P414 is the wrap deferring a mechanical rotation (different step/defect); P433 is a close-time completeness scan, upstream of which rows never become closeable here.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-055 | proposed | Verification-evidence write path for the run-retro Step 4a prior-session drain |
