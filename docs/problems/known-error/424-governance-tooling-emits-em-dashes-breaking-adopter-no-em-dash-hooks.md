# Problem 424: Governance tooling emits U+2014 em-dashes in generated output, breaking adopter no-em-dash Edit/Write hooks

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#185, #186, #219, #223, #319)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 6.0.
**WSJF**: 6 — (12 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-303 (secondary: JTBD-101)
**Persona**: plugin-user

> JTBD/persona re-anchored 2026-07-26 by `wr-jtbd:agent` review. The AFK auto-capture defaults (`JTBD-101` / `plugin-developer`) were provisional per P395. The affected human is an **adopter** whose own project policy is violated by content they did not author and cannot edit, which is the `plugin-user` persona (`docs/jtbd/plugin-user/persona.md` line 16 names "hooks firing on their own edits" as the interaction surface). No documented job covered "generated output respects the adopter project's own content conventions", so JTBD-303 was authored as the grounding job in the same commit, born `human-oversight: unconfirmed`.

## Description

Multiple `@windyroad/*` tooling surfaces emit U+2014 em-dashes into generated artefacts. Adopter projects that enforce a no-em-dash policy via an Edit/Write hook then have those hooks fire on plugin-generated content the adopter cannot edit (the content ships from the cached plugin, per ADR-036). Cluster of inbound reports, one root cause + one fix pattern (substitute U+2014 → ASCII separator).

## Symptoms

Per-surface (each an investigation task):
1. architect `capture-adr` / `create-adr` SKILL.md skeleton templates carry U+2014 in template literals (#185, #223).
2. `wr-architect-generate-decisions-compendium` emits U+2014 in ADR header / chosen-option summary lines (#219, #223).
3. P186 evidence-cell canonical wire format uses a U+2014 separator across the six itil SKILL render sites keyed by the `LIKELY-VERIFIED-CELL-SHAPE` marker (#186).
4. `check-upstream-responses` writes a U+2014 into the audit-log heading, tripping the gate every Step-0d pass (#319).

## Impact Assessment

- **Who is affected**: adopters running a no-em-dash Edit/Write policy; every regen re-introduces the character they must scrub.
- **Frequency**: every ADR capture / compendium regen / upstream-response poll / VQ render.
- **Severity**: High — plugin-generated content violates adopter policy with no adopter-side remedy (must ship upstream per P423).

## Root Cause Analysis

Root cause confirmed to exact loci 2026-07-26 (AFK iteration; architect + JTBD review). The emitting sites are literal U+2014 separators in emitted string constants, plus LLM-authored pass-through content on three of the surfaces. Status advanced Open → Known Error on that basis.

### Confirmed emitting loci

**Surface 1 — ADR skeleton templates.**
- `packages/architect/skills/capture-adr/SKILL.md` lines 117-118: the Considered Options template rows emit `**<Chosen option> (chosen)** — <one-line summary>` into every captured ADR.
- `packages/architect/skills/create-adr/SKILL.md` lines 173-174 **already use ASCII** ` - `. That is the established in-corpus convention and settles the separator choice as precedent-conformance, not a fresh decision.
- Both templates are LLM-authored below the skeleton, so a template-literal fix alone leaves the authoring agent free to emit em-dashes into the body.

**Surface 2 — decisions compendium.**
- `packages/architect/hooks/architect-compendium-update-entry.sh` line 135: the `claude -p` prompt pins the entry shape `### ADR-NNN — <title>`. This is the **live** writer under ADR-078 Option 9 and the load-bearing locus. Its own prompt prose at lines 137 and 143 also carries U+2014.
- `packages/architect/scripts/generate-decisions-compendium.sh` line 261 (`### ADR-${id} — ${title}`) plus file-header prose echoed at lines 342/348/349/351. This script is DEPRECATED per ADR-078 (line 46 says so) but remains the documented degraded-mode recovery path, so it is still in scope. Do not over-invest test surface here.
- **Parser compatibility verified safe**: the block matcher, insert pass and post-condition guard all match `^### ADR-[0-9]+` (lines 121, 167, 177, 195, 222, 240, 246), and `bid()` at line 119 does `sub(/^### ADR-/,"",s); return s+0` — numeric coercion, separator-agnostic.
- **The compendium never self-heals.** ADR-078 line 126 accepts migration-by-edit-cadence, and under Option 9 the hook re-authors only the edited ADR's entry. An adopter's `docs/decisions/README.md` therefore retains em-dash entries indefinitely for every ADR they do not otherwise touch. An emission-only fix does not close the adopter symptom on this surface.

**Surface 3 — P186 evidence-cell wire format** (`yes — observed: <evidence>` / `no — not observed` / `no — observed regression`).
- Six itil SKILL render sites keyed by `<!-- LIKELY-VERIFIED-CELL-SHAPE: evidence-based per P186 -->`: `review-problems` (x2), `manage-problem` (x4), `list-problems`, `transition-problem`, `transition-problems`, `reconcile-readme`.
- **A seventh site exists in a third package**, not previously listed: `packages/retrospective/skills/run-retro/SKILL.md` line 449 **parses** the cell (*"cell value begins with `yes — observed:`"*), with further dependence at lines 455 and 457. So the changeset is **three packages** — `@windyroad/architect`, `@windyroad/itil`, `@windyroad/retrospective` — not two.
- `reconcile-readme.sh` does not parse the cell (agent-applied edits), and no shipped script greps the cell vocabulary. The contract is prose-and-agent-level, not script-level.
- No ADR amendment needed: P186's contract lives in a closed ticket plus the markers, not a decision record. Note that `docs/problems/closed/186-*.md` line 3 quotes the old vocabulary as its closure evidence; that citation becomes historical.

**Surface 4 — outbound-responses audit log.**
- `packages/itil/scripts/check-upstream-responses.sh` lines 279/281/283 (file header, written once on creation) and line 290 (`## ${NOW_ISO} — Outbound response check pass`, written on **every** pass) into `docs/audits/outbound-responses-log.md`.

### Blocking conditions surfaced by review

- **ADR-078 Confirmation criterion (b) pins the old shape.** `docs/decisions/078-compendium-decision-outcome-progressive-disclosure.proposed.md` line 134 literally specifies `### ADR-NNN — <title>`. Flipping the emitted separator makes that criterion false, so the change carries an ADR-078 amendment obligation. The amendment must NOT ride an AFK commit: ADR-078 is `human-oversight: confirmed`, an AFK iter cannot ratify a substance change to it (ADR-066 / P357), and touching any `docs/decisions/<NNN>-*.md` drags in the ADR-077 compendium-refresh obligation plus the P365 truncation hazard on the off-skill edit path.
- **Four test/eval surfaces go RED and must move in the same change**:
  - `packages/itil/skills/review-problems/test/review-problems-likely-verified-cell-shape.bats` lines 209-229 assert against the **live** `docs/problems/README.md`, which carries **148** occurrences of the em-dash cell vocabulary today. Leave the README un-scrubbed and the test asserts a retired contract; scrub it and the `grep -F` at line 214 goes RED. Either way this test moves, which forces the scrub decision into the same change.
  - `packages/itil/skills/review-problems/test/review-problems-contract.bats` lines 229/231.
  - `packages/itil/skills/review-problems/eval/promptfooconfig.yaml` lines 522-524 assert the em-dash cell shape in expected output. This is the ADR-075 promptfoo surface and the **behavioural** counterpart ADR-052 prefers; prefer landing the behavioural assertion here and treat the `grep -F` bats edits as maintenance of pre-existing structural tests rather than new structural tests.
  - `packages/retrospective/skills/run-retro/test/run-retro-step-4a-prior-session-evidence-drain.bats` (14 occurrences).
- **Interpolated pass-through is not covered by a template-literal fix.** Live evidence from the committed compendium: line 84 renders `**Chosen:** Chosen option: **"Option B — Sync script + CI drift check"**`, where the em-dash comes from ADR-017's *body*, not from the generator's header line; line 116 is LLM-authored prose carrying several. The same shape holds for the P186 cell (`<evidence>` is agent-written prose) and the audit log (ticket titles pass through). This is the open scope question below.

### Fifth surface, deliberately deferred, and it is a coupled pair

`packages/retrospective/scripts/check-autocreate-rfc-scope.sh` lines 64-66 pin a U+2014 as a **parse key** matched against the `capture-rfc` emitted skeleton:

```
PLACEHOLDER='deferred — populate at /wr-itil:manage-rfc accepted transition'
```

Not expanded into here (the orchestrator scoped this iteration to one coherent commit over the four named surfaces). Recorded because the coupling is fail-open: if a later commit flips the `capture-rfc` skeleton without flipping line 66, the checker silently stops matching and no test catches it. **Both loci must move in the same commit** whenever surface 5 is worked.

### Investigation Tasks

- [x] Confirm the emitting loci to file and line across the four named surfaces (done 2026-07-26; see above).
- [x] Verify parser compatibility for each substitution before proposing it (done: compendium matchers separator-agnostic; no shipped script parses the P186 cell).
- [x] Enumerate the test/eval surfaces the substitution turns RED (done: four, listed above, spanning two packages).
- [x] Anchor to a documented job and persona (done: JTBD-303 authored, `plugin-user`).
- [ ] **Settle the open scope question below.** Queued to `outstanding_questions` for the maintainer; not self-picked (ADR-044).
- [ ] Substitute U+2014 → ASCII separator across the four surfaces per the ratified option; update the four test/eval surfaces in the same change.
- [ ] Amend ADR-078 Confirmation criterion (b) to the new entry shape, in an interactive session (ratification-gated; not AFK-landable).
- [ ] Ship as an adopter-facing plugin change (not a local scrub) per P423 — the fix must reach installed caches. Changeset spans `@windyroad/architect`, `@windyroad/itil`, `@windyroad/retrospective`.

### Open scope question (queued, not self-picked)

The ticket's original task line pinned "substitute across the four surfaces" but did not pin whether **interpolated pass-through content** is covered. That distinction decides whether the adopter's hook actually stops firing.

- **Option A — template-literal substitution only.** Fix the emitted string constants and add an ASCII-separator emission rule to the two ADR templates and the compendium-entry prompt. Cheap, mechanical, one commit. Residual: interpolated values still carry em-dashes through, and the emission rule is an LLM instruction with no enforcement over the dominant content source.
- **Option B — deterministic sanitisation at the emission boundary.** Everything in A, plus a transliteration pass on the bytes immediately before write (in `architect-compendium-update-entry.sh` after the `.result` extraction, and in the generator's emission block), so pass-through cannot reach the file. Structurally guarantees the adopter symptom is closed; costs fidelity (em-dashes inside quoted ADR prose get flattened) and cannot be overridden by the compendium's LLM author.
- **Option C — A + B + one-time migration of already-generated artefacts** (`docs/decisions/README.md`, the 148 `docs/problems/README.md` VQ cells, `docs/audits/outbound-responses-log.md`), shipped as an adopter-reachable migration on the existing pattern (`wr-itil-migrate-problems-layout`, RFC-009 T2). The only option under which an adopter who installs the fix stops **seeing** the character rather than stops **accruing** it.

Architect advisory lean (2026-07-26): **Option C**, with B as the guarantee and the migration as a separate story under the same RFC and map. Rationale: #219 and #223 are compendium reports, i.e. the surface where pass-through dominates, so Option A leaves a residual the reporters observe immediately. Option A also cannot honestly satisfy a "generator output contains no U+2014" test — that assertion passes only because `generate-decisions-compendium.bats` `mk_adr()` synthesises em-dash-free fixture titles; run it against the real corpus and it fails.

## Fix Vehicle

- **RFC-054** — carries the full per-surface fix specification, the ADR-078 amendment obligation, the test/eval migration list, and the three scope options.
- **STORY-051** — the implementing story, born `human-oversight: unconfirmed`.
- **STORY-MAP-008** — Have plugin-generated content respect my project's conventions.

Nothing implements until STORY-051 is ratified at its `accepted` gate (ADR-090 / ADR-096), which has no AFK path. The deferral is cadenced: `/wr-itil:work-problems` Step 2.4 gate (a) runs `wr-itil-detect-unratified-stories-maps` at every loop end, and `itil-rfc-oversight-nudge.sh` re-surfaces the RFC at every interactive SessionStart while `human-oversight: unconfirmed` stands.

## Dependencies

- **Composes with**: P210 (already-fixed work-problems AFK-fallback-marker em-dash — the precedent/pattern), P423 (fixes must be adopter-facing, not memory/local scrub).
- **Blocked on**: ratification of STORY-051 (ADR-096); the maintainer's answer to the open scope question above.

## Related

- Inbound issues #185, #186, #219, #223, #319. Precedent: P210 (narrow, already-fixed instance).
- **JTBD-303** — grounding job, authored 2026-07-26 alongside this ticket's fix vehicle.
- **P465** — that the code permits mechanically accepting a story is tracked there; not exploited here.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-054 | proposed | Make generated output portable by default |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-051 | STORY-051: Have generated content respect my project's conventions | draft |
