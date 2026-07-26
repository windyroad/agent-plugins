---
status: proposed
rfc-id: generated-output-is-portable-by-default
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P424]
adrs: [ADR-014, ADR-036, ADR-052, ADR-060, ADR-070, ADR-071, ADR-073, ADR-074, ADR-075, ADR-077, ADR-078, ADR-085, ADR-089, ADR-090, ADR-095, ADR-096, ADR-099]
jtbd: [JTBD-303, JTBD-101]
stories: []
---

# RFC-054: Make generated output portable by default

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P424 (governance tooling emits U+2014 em-dashes into generated artefacts, tripping adopter Edit/Write policy hooks on content the adopter cannot edit)
**ADRs**: ADR-014 (governance skills commit their own work), ADR-036 (plugin content ships from the marketplace cache — the reason the adopter has no editable surface), ADR-052 (behavioural tests default), ADR-060 (Problem-RFC-Story framework, I1 problem trace), ADR-070 (RFCs hold no independent decisions), ADR-071 (every fix goes through an RFC), ADR-073 (RFC-first — an approach-choice not covered by the existing corpus needs a ratified ADR before implementation), ADR-074 (confirm a decision's substance before building dependent work), ADR-075 (promptfoo as the behavioural harness for agent-prose verdicts), ADR-077 (decisions compendium as load surface), ADR-078 (compendium Decision Outcome, progressive disclosure — its Confirmation pins the entry shape this RFC changes, and its migration model is why regeneration alone does not reach every adopter entry), ADR-085 (`## Commits` is a git-log-derived view), ADR-089 (every RFC has at least one story), ADR-090 (an RFC may not reference an unratified story), ADR-095 (story-map membership enforced at capture), ADR-096 (a story cannot be implemented while draft), ADR-099 (a changeset describes a fix that exists)
**JTBD**: JTBD-303 (have plugin-generated content respect my project's own conventions), JTBD-101 (extend the suite — secondary, the shipping half)
**Story maps**: STORY-MAP-008 (Have plugin-generated content respect my project's conventions), rib "Portable generated output"

## Summary

A plugin is a guest in the repository that installs it. Several `@windyroad/*` surfaces write
U+2014 em-dashes into content they generate into an adopter's tree — a captured ADR skeleton, a
regenerated decisions compendium, a rendered verification-queue evidence cell, an outbound
audit-log entry. An adopter whose project hard-blocks that character has their own Edit/Write
hook fire, correctly, on text that arrived from a cached plugin they cannot edit. Scrubbing it by
hand is a treadmill, because the next regeneration puts it back.

This RFC is the fix vehicle for P424 (ADR-071 / ADR-073: a fix proposed on a Known Error requires
a problem-traced RFC, authored as a deliberate pre-implementation step). It carries a single
story.

## Driving problem trace

- **P424** (Known Error) — arrived as five inbound reports (#185, #186, #219, #223, #319). Its
  Root Cause Analysis records the emitting loci confirmed by corpus read rather than inferred,
  reproduced in the Scope section below. The precedent is P210, where one em-dash on one surface
  was repaired in isolation and the class it belonged to went unnamed until the five reports
  arrived. That history is why this vehicle is scoped to the class rather than to the five sites.

## Scope

Nothing here lands until STORY-051 is ratified at its `accepted` gate (ADR-090 / ADR-096), which
has no AFK path. That deferral is cadenced, not parked — `/wr-itil:work-problems` Step 2.4 gate
(a) runs `wr-itil-detect-unratified-stories-maps` at every loop end and surfaces STORY-051 for
ratification, and `itil-rfc-oversight-nudge.sh` (SessionStart) counts this RFC in its
every-session unoversighted-RFC nudge on interactive sessions while the `human-oversight:
unconfirmed` marker stands.

### What ships

Generated-output surfaces produce artefacts free of U+2014, and keep producing them on every
regeneration, with a plugin-side regression signal so a newly introduced violating character
fails a check before release rather than in an adopter's session. Per P423 the fix must be a
shipped plugin change reaching installed caches, not a local scrub of this repository's own
artefacts.

### Confirmed emitting loci

**Surface 1, ADR skeleton templates.** `packages/architect/skills/capture-adr/SKILL.md` lines
117-118 emit `**<Chosen option> (chosen)** — <one-line summary>` into every captured ADR.
`packages/architect/skills/create-adr/SKILL.md` lines 173-174 already use ASCII ` - `, which
settles the separator choice as precedent-conformance rather than a fresh decision. Both
templates are LLM-authored below the skeleton.

**Surface 2, decisions compendium.** The load-bearing locus is
`packages/architect/hooks/architect-compendium-update-entry.sh` line 135, whose `claude -p`
prompt pins the entry shape `### ADR-NNN — <title>`; its own prompt prose at lines 137 and 143
also carries the character. `packages/architect/scripts/generate-decisions-compendium.sh` line
261 plus header prose at lines 342, 348, 349 and 351 is the second writer; it is deprecated per
ADR-078 but remains the documented degraded-mode recovery path, so it is in scope and should not
absorb much test surface. Parser compatibility is verified safe: the block matcher, insert pass
and post-condition guard all anchor on `^### ADR-[0-9]+`, and `bid()` does a numeric coercion,
so all are separator-agnostic.

**Surface 3, the P186 evidence-cell wire format** (`yes — observed: <evidence>` / `no — not
observed` / `no — observed regression`). Six itil SKILL render sites keyed by the
`LIKELY-VERIFIED-CELL-SHAPE` marker, plus a **seventh site in a third package** the original
ticket did not name: `packages/retrospective/skills/run-retro/SKILL.md` line 449 parses the cell,
with further dependence at lines 455 and 457. No shipped script parses the cell, so the contract
is prose-and-agent-level. P186's contract lives in a closed ticket and its markers rather than a
decision record, so no ADR amendment is owed there; the closure evidence quoted in
`docs/problems/closed/186-*.md` line 3 becomes historical.

**Surface 4, the outbound-responses audit log.**
`packages/itil/scripts/check-upstream-responses.sh` lines 279, 281 and 283 (file header, written
once on creation) and line 290 (written on every pass).

### Open question: what counts as not emitting

P424's original task line pinned "substitute across the four surfaces" without pinning whether
**interpolated and agent-authored pass-through content** is covered. That distinction decides
whether the adopter's hook actually stops firing, and it is recorded here as open rather than
settled.

- **Option A, template-literal substitution only.** Fix the emitted string constants and add an
  ASCII-separator emission rule to the two ADR templates and the compendium-entry prompt.
  Residual: interpolated values still pass the character through, and the emission rule is an
  instruction to an LLM with no enforcement over the dominant content source.
- **Option B, deterministic sanitisation at the emission boundary.** Everything in A, plus a
  transliteration pass over the bytes immediately before write, so pass-through cannot reach the
  file. Costs fidelity, since em-dashes inside quoted ADR prose get flattened, and carries the
  property that the compendium's LLM author cannot override it.
- **Option C, A plus B plus a one-time migration** of already-generated artefacts, shipped as an
  adopter-reachable migration on the existing pattern (`wr-itil-migrate-problems-layout`,
  RFC-009 T2).

Architect review 2026-07-26 leaned toward Option C. Its rationale is recorded on P424 rather than
re-argued here.

**The answer is recorded in a new ratified ADR before implementation — not in this RFC body and
not in P424.** Per ADR-070 an RFC holds no independent decision, and per ADR-073's third
Confirmation criterion an approach-choice not covered by the existing corpus needs a ratified ADR
first. Option B in particular is an approach-choice, not a mechanical substitution: it introduces
a deterministic transliteration pass over emitted bytes with a stated fidelity trade-off and an
explicit property that the compendium's LLM author cannot override it. No existing ADR covers
that.

### Why the migration leg is not cosmetic

A descriptive note about system behaviour, recorded so it does not fall through the gap between
two of the grounding job's desired outcomes. Under ADR-078 Option 9 the on-edit hook re-authors
only the edited ADR's entry, and ADR-078 line 126 accepts migration-by-edit-cadence explicitly:
nothing forces an adopter to touch ADRs they have no other reason to touch. So sanitisation at
the emission boundary satisfies JTBD-303's second outcome (conformance at every regeneration) but
leaves its fourth (the plugin side yields; the adopter is never left holding a block they cannot
clear) unserved on that surface, because untouched entries are never regenerated. Whichever
option is settled, this residual is either closed by the migration leg or carried as a named
follow-up.

### Amendment obligation

ADR-078's Confirmation criterion (b) at line 134 pins the entry shape `### ADR-NNN — <title>`.
Changing the emitted separator makes that criterion false, so the implementing change carries an
ADR-078 amendment. It cannot ride an AFK commit: ADR-078 is `human-oversight: confirmed`, ADR-066
and P357 bar an AFK substance amendment to it, and editing any `docs/decisions/<NNN>-*.md` drags
in the ADR-077 compendium-refresh obligation plus the P365 truncation hazard on the off-skill
edit path.

### Test and eval surfaces that move in the same change

Four surfaces assert the retired wire format and go RED otherwise:

- `packages/itil/skills/review-problems/eval/promptfooconfig.yaml` lines 522-524. This is the
  ADR-075 surface and carries the **behavioural** assertion ADR-052 prefers.
- `packages/itil/skills/review-problems/test/review-problems-likely-verified-cell-shape.bats`
  lines 209-229, which assert against the **live** `docs/problems/README.md`. That file carries
  148 occurrences of the em-dash cell vocabulary today, so this test forces the scrub position
  into the same change: leave the README alone and the test asserts a retired contract; scrub it
  and the `grep -F` at line 214 goes RED.
- `packages/itil/skills/review-problems/test/review-problems-contract.bats` lines 229 and 231.
- `packages/retrospective/skills/run-retro/test/run-retro-step-4a-prior-session-evidence-drain.bats`
  (14 occurrences).

The two `grep -F` bats files are maintenance of pre-existing structural tests, not new structural
tests. New coverage lands behaviourally: exercise the emitter, read the bytes it wrote.

### Coverage

Behavioural per ADR-052 — generate the artefact and assert on its content. Note the trap in the
obvious version: a "generator output contains no U+2014" assertion over
`generate-decisions-compendium.bats` passes only because its `mk_adr()` helper synthesises
em-dash-free fixture titles. Fixtures must carry the character on the pass-through paths, or the
test certifies a guarantee the fix does not make.

### Release scope

Three packages: `@windyroad/architect`, `@windyroad/itil`, `@windyroad/retrospective`.

## Stories

The machine-read `stories:` array is deliberately empty; the human-readable trace is here.

- **STORY-051** — Have generated content respect my project's conventions. On **STORY-MAP-008**,
  rib "Portable generated output". Status `draft`, `human-oversight: unconfirmed`, estimated
  effort M.

**Empty `stories:` is transient, not the atomic shape.** P424 carries a full per-surface fix
specification, so this RFC is scoped, not pre-scoped. The array is empty only until STORY-051 is
ratified — ADR-090 forbids an RFC referencing an unratified story, and
`wr-itil-check-rfc-stories-ratified` enforces it — and is wired before the `accepted` transition,
where ADR-089's at-least-one-story criterion binds.

<!-- cadence: the empty array is drained at STORY-051's accepted gate, which
     /wr-itil:work-problems Step 2.4 gate (a) surfaces via
     wr-itil-detect-unratified-stories-maps at every loop end, and which
     itil-rfc-oversight-nudge.sh re-surfaces at every interactive SessionStart while
     human-oversight stays unconfirmed. Both are self-firing; neither waits on someone
     remembering to run a command. -->

## Out of scope

- **A fifth emitting surface, and it is a coupled emitter/reader pair.**
  `packages/retrospective/scripts/check-autocreate-rfc-scope.sh` lines 64-66 pin U+2014 as a
  **parse key** matched against the `capture-rfc` emitted skeleton
  (`PLACEHOLDER='deferred — populate at /wr-itil:manage-rfc accepted transition'`). Deferred out
  of this vehicle, which the orchestrator scoped to the four named surfaces. Recorded because the
  coupling is **fail-open**: flip the skeleton without flipping line 66 and the checker silently
  stops matching, with no test catching it. **Both loci must move in the same commit** whenever
  this surface is worked.
  <!-- cadence: named on P424's Known Error body, which /wr-itil:review-problems re-reads at
       every backlog re-rank pass and /wr-itil:work-problems re-ranks at every loop start.
       It rides an open ticket, not an unfired re-entry point. -->
- **Amending ADR-078's Confirmation criterion (b).** Named above as an obligation; it is an
  interactive, ratification-gated edit and cannot ride an AFK commit.
- **Latent weaknesses in the shared story-map style block**, surfaced by the accessibility review
  of STORY-MAP-008 and applying to STORY-MAP-004 through -007 identically: the focus border
  change alone measures 2.55:1 and passes only because the outline does the real work, and the
  `display: contents` swap-trigger comment omits several conditions. Changing them in one map
  would diverge a block the style guide requires be copied verbatim, so they belong in a
  corpus-wide pass with its own ticket.
- **No changeset is authored in this vehicle-authoring commit.** A changeset describing a fix
  that does not yet exist in the package is untruthful release metadata, which is the distinction
  ADR-099 draws. It lands with the code, in the implementation slice.

## Commits

(rendered from `git log --grep "Refs: RFC-054"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no commits yet.)

## Related

- **P424** (driving problem, inbound #185, #186, #219, #223, #319), **STORY-MAP-008** (the map),
  **STORY-051** (the story), **JTBD-303** (the grounding job).
- **P210** — the narrow, already-fixed precedent. One em-dash on one surface, repaired without
  naming the class. The reason this vehicle carries a regression-signal criterion.
- **P423** — the master class: a fix that should govern the plugins or their adopters must land
  as a shipped surface, never as project-local memory. This RFC's scope obeys it.
- **RFC-009** — the nearest thematic sibling, adopter-safe path resolution in shipped skills.
  Same class of "a shipped artefact is wrong outside the source monorepo", different mechanism.
  Architect review ruled against folding P424 into it: RFC-009's implementation is complete and
  awaiting only a lifecycle transition, so it has no live scope to absorb, and grafting a second
  fix epoch onto it would break ADR-085's git-log-derived `## Commits` view.
