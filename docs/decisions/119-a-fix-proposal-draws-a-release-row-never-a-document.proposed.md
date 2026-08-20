---
status: "proposed"
date: 2026-08-20
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
problems: [P508]
supersedes: ["ADR-070 (in part — the RFC-body shape and the RFC↔ADR trace edge)", "ADR-072 (in part — the artefact the propose-fix gate checks for)"]
reassessment-date: 2026-11-20
---

# A fix proposal draws a release row, never a document

> Captured via /wr-architect:capture-adr (foreground-lightweight aside-invocation per ADR-032, derived-substance amendment 2026-07-06 / RFC-045). Section content was derived by the capturing agent from the in-session decision context; human-oversight: unconfirmed until ratified at the /wr-architect:review-decisions drain.

## Context and Problem Statement

ADR-103 (2026-08-07) collapsed the RFC into the story map: *"A release row is an RFC… propose the fix as one or more release rows on new or existing maps."* The map became the approval surface.

The shipped code never followed. In `@windyroad/itil@1.1.1`, `manage-problem`'s I13 propose-fix gate still runs the pre-ADR-103 path: on a Known Error whose problem no RFC traces, it delegates to `/wr-itil:capture-rfc --fix-time`, which allocates an RFC id and writes a new `docs/rfcs/RFC-<NNN>-<slug>.proposed.md`. Nothing in that path draws a row on any map.

Two contradictory fix-proposal mechanisms have therefore been live since 2026-08-07, and the one the framework reaches for automatically is the superseded one. The consequence is not cosmetic: the documents it mints are born `human-oversight: unconfirmed` and ratified at `manage-rfc accepted`, a second approval surface competing with the map ADR-103 designated as *the* one. A fix proposed as a document never reaches the map at all — so it lands on neither the approval a human gave nor the queue that routes new substance to them.

ADR-103 displaced this vehicle shape without naming ADR-070 or ADR-072 in its `supersedes:` list. That omission is why both mechanisms stayed live: nothing marked the old one as displaced, so nothing prompted the sweep. This ADR closes that debt.

Surfaced 2026-08-20 while diagnosing an unrelated adopter complaint; captured as P508.

## Decision Drivers

- ADR-103 is ratified and names the row as the RFC. The framework contradicting its own current decision is the defect, independent of which mechanism reads better.
- Two live approval surfaces means the automatic one bypasses the human one — a governance hole, not redundancy.
- ADR-103's own reasoning against a two-artefact convention: *"a convention between two artefacts is a sync obligation, which is what the previous two de-duplications removed."*
- ADR-073 already anticipated this rework. Its Decision Outcome holds `capture-rfc --fix-time` *"pending rework to author the RFC as a pre-implementation story map (not a fix-time Scope/Tasks byproduct), and to route option-bearing fixes through a ratified ADR."* Clause 2 below is the **first** half arriving; the option-bearing-routing half stays held.
- 60 documents exist under `docs/rfcs/`, and only **one** is closed. 48 are `proposed`, with 2 accepted, 3 in-progress and 6 verifying. Whatever is decided must not strand live plans.
- `capture-rfc` is a known invocation surface carrying the ADR-060 I1 mandatory problem-trace contract.

## Considered Options

1. **Retire the document tier; repoint `capture-rfc` at row-drawing (chosen)** — no new document for a fix proposal; `capture-rfc` keeps its name and entry point and changes what it writes.
2. **Retire the tier and retire `capture-rfc` outright** — rejected: discards a known entry point and its trace contract, and forces every call site and adopter onto a new surface at the same moment the artefact changes.
3. **Keep both tiers with a sync convention** — rejected on ADR-103's own grounds: if a row and a document must always agree, one of them is derived, which is the collapse ADR-103 already made.
4. **Do nothing** — rejected: leaves the superseded mechanism as the automatic default, still routing fix proposals away from the approval surface.

## Decision Outcome

Chosen option: **"Retire the document tier; repoint `capture-rfc` at row-drawing"**.

**Clause 1 — no new fix-proposal document.** A fix proposal creates no new file under `docs/rfcs/`. The existing 60 documents are not deleted, not migrated in a batch, and not frozen against machine writes; they simply stop being the thing a fix proposal creates.

**Clause 2 — `capture-rfc` is repointed, not retired.** It keeps its name, its invocation surface, and its mandatory problem-trace contract. What it writes changes from a document to a release row on a story map. This **partially** discharges the hold ADR-073 placed on `--fix-time`.

### What "the tier closes" does and does not mean

The clause put to the maintainer on 2026-08-20 read *"read-only history"*, and that was wrong on the facts. Only 1 of 60 documents is closed; 59 carry live, unshipped plans. Their content is not waste and is not stranded.

- **No new documents, and no authored edits.** Nobody hand-writes a new `## Scope` into a legacy file.
- **Derived sections keep re-rendering.** ADR-085 has `manage-rfc` and `reconcile-rfcs` re-render `## Commits` from the git log; ADR-107 has each legacy file carry a derived list of the maps covering it. Both are machine-maintained views, not authored substance, and both continue. A blanket read-only rule would have silently displaced two ratified decisions it never named.
- **A document whose problem has re-drawn is marked as such — derived, never authored.** Otherwise the corpus accumulates permanently-`proposed` files whose work shipped as rows elsewhere, while `reconcile-rfcs.sh`, `itil-rfc-trailer-advisory.sh` and `itil-commit-trailer-transition-advisory.sh` keep treating them as live plans. A document whose problem is now named by a row renders as **superseded-by-row**, machine-written from the row's own trace, on the same footing as the derived sections above — so it needs no authored edit and breaks no rule.
- **An open proposal re-draws as a row when its problem is next worked** — no migration pass, no big-bang. This is ADR-103's own clause, carried verbatim: *"Only **open** problems need updating, and only as they are worked."* Maintainer direction 2026-08-20: *"You just need to create the rfc rows to fix them and then implement those stories."* The legacy document remains readable as input to drawing that row.

### Supersession — narrow and named

- **ADR-070** in part: the "no Considered Options block in an RFC body" criterion and its enforcing check `check-rfc-rejected-alternatives.sh` (both vacuous once there is no body), plus the clause giving an RFC an ADR trace. ADR-106 forecloses the row or map carrying a decision trace and homes it on the story's `adrs:` field; that is where it goes.
- **ADR-072** in part: only the reading that the RFC must pre-exist *as a document*. The propose-fix **placement** — the gate fires after Known Error — stands unchanged.
- **ADR-071 is NOT superseded.** It is vehicle-neutral; every fix still goes through an RFC, and the RFC is now a row. Its one document-shaped clause was already superseded by ADR-089.
- **Neither ADR-070 nor ADR-072 is renamed to `.superseded.md`.** Partial supersession leaves a decision in force — ADR-043, ADR-047, ADR-060, ADR-064, ADR-066, ADR-068 and ADR-098 all remain in-force after being superseded in part. Renaming them would strand principles this ADR deliberately preserves.
- **ADR-073 is NOT superseded — it is PARTIALLY discharged.** It held `--fix-time` pending two things: authoring the RFC as a pre-implementation story map, *and* routing option-bearing fixes through a ratified ADR. This ADR delivers the first. The second is precisely the deferred question below — what happens when a proposal needs a new map, column or ADR — so it **remains held** until that is answered. Cited as authority, not displaced.

### Identity allocation

A row's `rfc` identity is allocated by scanning **row identities across all maps, including git history**, not by `max()` over `docs/rfcs/RFC-*.md`. `capture-rfc` today derives the next id from that directory scan (`SKILL.md` § "Compute next RFC ID") using `max(local, origin) + 1` over `docs/rfcs/RFC-*.md`. That input set cannot see rows, and rows already hold **RFC-060 through RFC-069** — so the allocator returns **068, which a row holds**.

**The collision is not prospective. It is live in the working tree today**, before any of this ships, and it is an existing defect this decision surfaces rather than a cost this decision creates (recorded as such on P508). Once the tier stops growing, `max()` freezes at 067 and re-issues 068 indefinitely.

The seven ids missing from `docs/rfcs/` between 060 and 066 are not sparseness — each is held by a row. That is the two-tiers-one-id-space problem sitting visibly in the corpus. Git history is included for the reason ADR-115 gives: **RFC-060** is absent from HEAD entirely — it survives only on the `worktree-main-clean` branch — yet a row holds it, so a live scan alone would re-issue it. Ids are never reused.

### Sequencing — writers stop, readers follow

**The inventory's selection predicate matters more than its count.** Keying on the literal path `docs/rfcs/` systematically misses surfaces that reference the *mechanism* without the path. Re-derive it from the union of three predicates — the path, `capture-rfc`, and `ADR-072|ADR-073` — and state the in-scope count separately from the raw grep count. The path predicate alone yields 30 raw / 28 in-scope (the two CHANGELOGs are release history). The union adds at least `hooks/lib/create-gate.sh`, `skills/capture-story-map/SKILL.md`, `skills/transition-problem/SKILL.md`, `.claude-plugin/plugin.json`, and `README.md` in itil, plus `capture-rfc/eval/` harness files and `packages/architect/agents/agent.md` and `scripts/sync-codex-skills.mjs`.

Classified by role:

- **The one minting writer**: `capture-rfc`. It stops minting first.
- **The reader that must outlive every writer**: `check-fix-rfc-trace.sh`, the load-bearing predicate behind the I13 gate (`manage-problem/SKILL.md` § "I13 propose-fix RFC-trace gate"). It answers *"does an RFC's `problems:` array name this PID?"* by scanning `docs/rfcs/`. Under the row model that answer comes from rows' `problems`/`rfc` keys. **It must be repointed in lockstep with, or ahead of, the writer.** Repoint the writer first and every Known Error reads "no RFC trace" and the loop hard-stops on everything; loosen it to compensate and the gate this ADR promises to preserve fails open. During any window, it must fail **closed** — a missing trace halts rather than proceeds.
- **Other writers to legacy files** (derived-view renderers, which continue per Clause 1): `update-rfc-commits-section.sh`, `reconcile-rfcs.sh`, `update-problem-rfcs-section.sh`.
- **Other readers**: `detect-unoversighted-rfcs.sh`, `itil-rfc-oversight-nudge.sh`, `itil-rfc-trailer-advisory.sh`, `itil-commit-trailer-transition-advisory.sh`, `itil-deferral-cadence-gate.sh`, `manage-problem-enforce-create.sh`, `evaluate-relevance.sh`, `mark-rfc-capture-gate.sh`, `check-autocreate-rfc-scope.sh`, `reconcile-stories.sh`, `render-story-map.mjs`, the three `update-*-references-section` helpers, and the skills `manage-rfc`, `manage-problem`, `capture-problem`, `capture-story`, `manage-story`, `list-stories`, `reconcile-stories`, `work-problems`, and `run-retro`.
- **Also in scope, outside the file count**: `docs/rfcs/README.md` is a spec surface (lifecycle index and frontmatter shape, cited by `capture-rfc`), and three `eval/promptfooconfig.yaml` suites — `manage-problem`, `work-problems`, `capture-rfc` — assert `--fix-time` behaviour and go stale.

**The rule, not a slogan**: no reader may be repointed before the predicate it depends on, and no writer may stop before its readers can answer from rows.

### Enforcement

`manage-problem-enforce-create.sh` currently *permits* `Write` to `docs/rfcs/RFC-*.proposed.md` under the P119 create-gate widening, via `check_rfc_capture_gate()` / `mark_rfc_capture_complete()` in `packages/itil/hooks/lib/create-gate.sh` — the lib is where the predicate lives and is where the change lands. That permission is withdrawn, and the equivalent create-gate must cover the map write instead. Withdrawing it is what makes Clause 1 structural rather than advisory.

**The withdrawal discriminates creation from lifecycle.** What is refused is the creation of a **new RFC id** under `docs/rfcs/`. Edits to existing documents and their lifecycle renames — `.proposed.md` → `.accepted.md` → `.verifying.md` — must keep working, because a rename presents as a Write to a new path and `manage-rfc`'s disposition is deferred below. Without that discrimination the 59 live documents become untransitionable for an open-ended window.

### The ≥1-card floor

ADR-089 requires every RFC to carry at least one story, confirmed against document lifecycle (*"cannot reach `accepted` with an empty `stories:` list"*). The row model has no `accepted` transition and no `stories:` array. Restated: **a release row carrying an identity has at least one card; an identified row with no cards is a defect on the same footing as ADR-107's Untraced badge.** ADR-089 is not superseded — its floor is preserved with a row-model criterion.

### The legacy corpus's oversight

The 54 unoversighted RFCs are **not** silenced on the grounds that history needs no ratification. That argument would be false here: 59 of the 60 documents carry live, unshipped plans, and retiring the signal over them would answer P508's own symptom by deleting the evidence rather than the defect.

The correct argument is narrower and rests on the decision above. An unshipped proposal needs no ratification **of its own**, because its substance is ratified on the map when its problem is next worked and the row is drawn — one ratification, on the surface ADR-103 names, rather than two on competing ones. So the exclusion is scoped to what is genuinely settled, which is three groups rather than one:

  - the one **closed** document;
  - each **proposed** document as its problem re-draws it as a row;
  - and the **11 whose work already shipped under the document model** — 6 verifying, 2 accepted, 3 in-progress. These never convert: their fix is already out, so their problems transition to closed without a row ever being drawn. Their plans were executed, so there is nothing left for a ratification to bite on. Without this group the count could not reach zero at all — they would sit in it permanently.

That keeps the count falling by conversion rather than by definition, so it can still reach zero, and it does not train the reader to ignore a live signal — the failure ADR-113 was written to avoid.

### Approval, and what is genuinely still open

The approval question is **already answered** and is not deferred: map ratification ratifies its rows, per ADR-103 reinforced by ADR-110 and ADR-111. Leaving it open would re-open the second-approval-surface hole this ADR exists to close.

Genuinely open, recorded on P508: what `capture-rfc` does when the fix needs a map that does not yet exist (ADR-103 § Decision Outcome ("Working a problem now runs") *queues* implementation when a proposal needs a new map, a new activity column, or a new ADR, because those are new substance needing a human — so the skill must queue, not mint), and `manage-rfc`'s disposition as a skill now that the tier it transitions is closing.

### Lockstep amendments this decision requires

- **JTBD-008** still describes the RFC as a document with a `stories:` array and anchors its Related decisions to the ADR-060/071 lineage. It also still asserts the ADR-101 rule verbatim — *"every other map edit still re-opens ratification exactly as before"* — which ADR-103 superseded on 2026-08-07. That stale text is not bookkeeping: during this ADR's own JTBD review it caused a reviewer reading it in good faith to raise a blocking objection that drawing a fix-proposal row would re-open the map's ratification, an objection ADR-103 had already resolved and which the reviewer withdrew on checking `story-oversight.sh` (the `SUBSTANCE` tuple omits `releases`, and an empirical hash test left a ratified map's fingerprint unchanged across a new rfc-bearing row). Amend under ADR-068 lockstep, downgrade `human-oversight` to `unconfirmed`, and ratify alongside this ADR.
- **Adopter migration (JTBD-009) — this evolution has no adopter transformation, and that needs saying rather than assuming.** 38 shipped files carry the mechanism under the union predicate (34 itil, 2 retrospective, 2 architect), so adopters have their own trees minted by the shipped gate. But there is nothing for a migration command to transform: the tier stops growing, readers resolve from rows, and an adopter's legacy documents stay readable exactly as this repo's do — each converting when its own problem is next worked. Shipping a `wr-itil-migrate-*` shim with no artefact to rewrite would be the ceremony JTBD-009's One-command outcome rejects.

  That is a real tension with that job, not an exemption from it. JTBD-009's second outcome is titled *"Dual-tolerant fallback is a bridge, not a destination"*, and per-problem re-draw is problem-paced, so an adopter never reaches a moment where migration is done — which collides with its *"I never have to remember 'did I migrate this project yet?'"* outcome. **Lockstep-amend JTBD-009** to admit a stop-growing evolution: one whose old artefacts are never rewritten, whose readers stay tolerant indefinitely by design, and where "have I migrated?" is not a question the adopter can be behind on because there is no migration to be behind on. Downgrade to `unconfirmed` and ratify with this ADR, as for JTBD-008.

### Dependency note — the approval surface's own-bytes gap

The `developer` persona requires an artefact to be readable from its own bytes. Story maps link a shared `../story-map.css`, and on 2026-08-09 a map opened away from its directory ran its value clauses together. ADR-105 fought this on the markup dimension and *deliberately* kept the stylesheet shared (`render-story-map.mjs` § `ensureSharedAssets()`, whose own comment states the full trade-off: the grid is committed into each map "so that a map can be read with no script engine", and "the stylesheet staying shared is what keeps that affordable"). That residual is not this ADR's to fix — the constraint was ratified 2026-08-09, two days after ADR-103 made the map the approval surface — but this ADR widens its blast radius to every fix proposal, including AFK-generated ones. Resolved as a new decision under P484's investigation tasks, per P479 and P483; not a blocker here.

## Consequences

### Good

- One fix-proposal mechanism, and it is the one the ratified decision names.
- Every automatic fix proposal lands on the map, which is where approval lives — but by **inheritance, not by a fresh approval event**, and this is the operative consequence of clauses 1 and 2 together. Drawing an rfc-bearing row on a ratified map leaves its oversight hash unchanged (Confirmation, below), so the row inherits an approval given earlier for a journey drawn before this fix existed. What keeps that honest is ADR-103 § Decision Outcome ("Working a problem now runs") escape valve: a proposal needing a **new map, a new activity column, or a new ADR** is new substance and *queues* for a human instead. So the guarantee is "a fix either fits an approved journey or waits for one" — not "a human approves every fix". An AFK loop drawing fix proposals onto ratified maps with no new human event is the honest reading, and it is what ratifying this ADR agrees to.
- No sync obligation between a row and a document.
- `capture-rfc`'s name, entry point and trace contract survive the change.
- ADR-073's held `--fix-time` mechanism is half discharged rather than left wholly pending; its option-bearing-routing half is now the only thing still holding it.
- 59 live plans are neither stranded nor force-migrated; each converts when its problem is next worked.

### Neutral

- `docs/rfcs/` stays on disk, stays linked, and keeps its derived sections current. Readers see no immediate change.
- ADR-071 and ADR-089 keep their floors; only their vehicle assumptions are restated.

### Bad

- A 38-file sweep with a hard ordering constraint, difficult to land in one commit. That is the union-predicate count of non-test, non-changelog code across **three** plugins — 34 itil, 2 retrospective, 2 architect. The narrower path-only predicate yields 30 raw / 28 in-scope and understates the job by a quarter; risk-scorer is genuinely out, appearing only via its changelog.
- A reader of the legacy corpus must know a document dated after 2026-08-07 is the output of a superseded mechanism. Nothing in the documents says so.
- The id allocator must be rewritten before the repoint can ship, so clause 2 has a prerequisite that clause 1 does not. Note this prerequisite is **not a cost of this decision** — the allocator already collides today; the decision merely makes the collision permanent instead of intermittent if left unfixed.
- Two ratified artefacts (JTBD-008, and the ADR-105 stylesheet residual) need follow-up work this decision creates but does not perform.

## Confirmation

Behavioural, per ADR-052:

- Working a Known Error with no traced RFC produces a **release row on a story map** and creates **no new file under `docs/rfcs/`**.
- A `Write` to a new `docs/rfcs/RFC-*.md` is **refused** by the create gate.
- `ls docs/rfcs/RFC-*.md | wc -l` does not increase. The count at capture is 60.
- `check-fix-rfc-trace.sh` answers from row identities: a problem named by a row's `problems` key reads as traced; one named nowhere reads as untraced and **halts**.
- Allocating an identity for a new row never returns an id any row holds, in the working tree or in git history.
- A map's stored oversight hash is unchanged by drawing a new rfc-bearing release row on it.
- No shipped surface still teaches the document model. Three separate assertions, in order — a single conjoined command is not acceptable here, because `test -d packages && grep …` **short-circuits to empty output on a missing root**, which reads as "returns nothing" and passes. That is the exact vacuous pass the guard was added to prevent, spelled differently:
  1. **Root exists**: `test -d packages` — asserted on its own, and must pass.
  2. **Known-positive control**: plant a line matching the predicate, run the search, assert it is **found**. A search that cannot find a planted match is broken regardless of what it reports about the corpus.
  3. **Corpus is clean**: `grep -rlE 'produces the RFC|ADR-073 auto-create' packages/ --include='*.md' --include='*.sh' | grep -v CHANGELOG` returns nothing.

  The predicate matches the bare `produces the RFC` form because the I13 gate prose in `manage-problem/SKILL.md` § "I13 propose-fix RFC-trace gate" omits the trailing "per ADR-072" and names `ADR-073 auto-create` in its own heading — the most load-bearing stale line, and the one a narrower grep leaves green. `--include='*.sh'` is present so `check-autocreate-rfc-scope.sh`, named for the auto-create scope, is covered by the assertion rather than only by the sweep.
- The derived sections still re-render: `manage-rfc` on a legacy file refreshes its `## Commits` without hand-editing.

## Pros and Cons of the Options

### Retire the tier; repoint `capture-rfc` (chosen)

- Good, because it removes the contradiction at source rather than reconciling two artefacts.
- Good, because it partially discharges ADR-073's standing hold with the vehicle-shape half of the rework that ADR named.
- Bad, because it needs a 38-file sweep with an ordering constraint and an id-allocator rewrite first.

### Retire the tier; retire `capture-rfc`

- Good, because no skill is left whose name implies a retired artefact.
- Bad, because it discards the ADR-060 I1 trace contract and changes every call site at once.

### Keep both tiers with a sync convention

- Good, because nothing breaks today.
- Bad, because it re-creates the sync obligation ADR-103 removed and leaves the bypass live.

### Do nothing

- Good, because it costs nothing now.
- Bad, because the superseded mechanism stays the automatic default.

## Reassessment Criteria

- A real fix arrives whose shape cannot be expressed as a release row on any map.
- The "new map needs a human" queue fires so often that automatic fix proposals routinely halt, making the gate advisory in practice.
- The closed tier proves to need active maintenance beyond its derived sections — for example if the trace helpers cannot resolve against it.
- Row-identity allocation proves to collide despite the git-history scan.

## Related

- **ADR-103** — the decision this implements; its `supersedes:` omission is the debt this closes.
- **ADR-107** — derives a map's RFC list from its rows; its legacy-file consequence is preserved here.
- **ADR-073** — partially discharged, not superseded: this is the vehicle-shape half of the rework it held `--fix-time` for; the option-bearing-routing half remains held.
- **ADR-085** — the derived `## Commits` view that keeps re-rendering into legacy files.
- **ADR-089** — ≥1-story floor, restated for rows rather than superseded.
- **ADR-106** — homes the decision trace on the story, which is where ADR-070's RFC↔ADR edge goes.
- **ADR-115** — the never-reuse-ids reasoning the row allocator adopts.
- **ADR-116** — partial supersession is permitted and precedented; the `(in part — <scope>)` form follows ADR-108 through ADR-115.
- **P508** — the driving problem, carrying the sweep tasks and the two genuinely-open questions.
- **P484** — where the shared-stylesheet own-bytes residual is resolved, as a new decision.
- **P357** — why this ADR is born `human-oversight: unconfirmed`. The maintainer's direction was eight words; the "read-only history" reading the capturing agent inferred from them was **wrong on the facts** and was corrected on review. What stands is the narrower clause above, and it needs ratifying on its own terms.
