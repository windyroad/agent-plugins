# Problem 298: Plugin-published artifacts should NOT reference internal IDs at all (ADR-055 chose prefixing; strip them instead — they're meaningless to adopters)

**Status**: Open
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — per ADR-055's own analysis, internal-ID references in shipped artifacts cause real adopter failure modes incl. resolving to an UNRELATED same-numbered ADR in the adopter's own tree = confidently-wrong agent behaviour; prefixing reduces collision but still surfaces meaningless tokens to the adopter/agent) × Likelihood: 3 (Likely — 2,880 instances across 81 files in shipped artifacts)
**Origin**: internal
**Effort**: XL — rephrase ~2,880 internal-ID references across 81 shipped-artifact files to express the substance inline (a much larger change than ADR-055's prefix approach); composes with P296 (SKILL.md extraction) which removes many refs as a side-effect
**WSJF**: 9/8 = **1.13** (Open multiplier 1.0)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (2026-05-25). When ADR-055 (plugin-published artefacts use namespace-prefixed permalinks for internal IDs) was presented for human-oversight confirmation, the user **rejected the chosen mechanism**:

> User direction 2026-05-25 (drain): *"I would rather it doesn't actually use the ID at all in published artifacts. They have no meaning outside of this project."*

ADR-055 chose to **keep** the internal IDs (ADR-NNN / JTBD-NNN / P-NNN) in shipped SKILL/agent/hook prose but **namespace-prefix them into permalinks** so they don't collide with the adopter's own IDs. The user wants the stronger fix: **don't reference internal IDs at all in published artifacts** — they carry no meaning to an adopter (who has no access to this repo's `docs/decisions/`, `docs/jtbd/`, `docs/problems/`), so even a prefixed `windyroad/ADR-014` is a meaningless token in adopter-facing prose. Published artifacts should express the **substance** inline ("the architect reviews each edit before it lands") rather than the **reference** ("per ADR-014").

Same family as **P294** (README should market from JTBD, not cite JTBD IDs): adopter-facing content should be self-contained and meaningful, never surface internal project plumbing. ADR-055 is **left unoversighted** (P283/ADR-066 marker withheld) until superseded.

## Symptoms

(deferred to investigation)

- ~2,880 internal-ID references across 81 shipped-artifact files (per ADR-055's `check-internal-id-leaks.sh` survey); `manage-problem` SKILL.md alone carries 121.
- ADR-055's own failure-mode analysis: adopter agent ignores the ref (best case) → surfaces "ADR not found" → resolves to an UNRELATED same-numbered ADR in the adopter's tree and applies wrong semantics (worst case). Prefixing fixes the collision but not the meaninglessness.
- **Adopter reproduction, 2026-08-18:** while reviewing generated plugin content, the architect reported that the plugin cited roughly 31 of its own ADRs, up to ADR-175, but shipped no corpus, so none was readable in the adopter checkout. The current architect package source contains 36 unique `ADR-NNN` tokens across shipped runtime surfaces when test/eval directories are excluded. This is the unresolved-reference failure mode, not a hypothetical detector count.
- **Runtime-generated internal tokens surface in hook deny-message bodies (2026-06-10 witness, home-loan-mcp adopter session).** The `@windyroad/jtbd` plugin's PreToolUse:Edit gate denied an Edit to `docs/jtbd/<persona>/persona.md` with a message naming a marker scheme `/tmp/oversight-confirmed-<sha>-<sid>` where `<sha>` is a hash of the artefact path string. The adopter agent ran `wr-jtbd-mark-oversight-confirmed <path>` with the relative path (matching how the deny-message phrased the helper); the retry failed because the Edit tool's stdin carried the absolute path and rel-vs-abs SHAs differ. The agent had to trial-and-error deduce that the SHA is path-keyed before the helper worked. Concrete trail of opaque markers produced: `/tmp/oversight-confirmed-0bc4e220d529d21e-...`, `/tmp/oversight-confirmed-6052b27c2e39dcd6-...`, `/tmp/oversight-confirmed-66f1a91096c50312-...`. The deny-message named the marker scheme but not its derivation; the adopter had no way to compute or predict the SHA from a path. Same authorial-class as the static-prose surface above — internal tokens (here, runtime-generated path-SHA) leak into the adopter-facing surface with no documented derivation, and the adopter cannot recover without source archaeology.

## Root Cause Analysis

### Investigation Tasks

- [ ] Supersede ADR-055's mechanism: published artifacts MUST NOT reference internal IDs (ADR/JTBD/P/RFC/STORY/R-NNN). Express the substance inline instead. Record the superseding decision via the asking flow.
- [ ] Distinguish **published** (shipped to adopters under `packages/<plugin>/`: SKILL.md, agent.md, hook prose, CHANGELOG) from **source-internal** (docs/decisions, docs/jtbd, docs/problems, retros) — internal IDs are fine in source-internal docs; the ban is on the shipped surface only.
- [ ] Compose with P296 (SKILL.md extraction): moving maintainer-rationale (where most ID refs live) into REFERENCE/source-internal docs removes a large fraction of the shipped-surface refs as a side-effect — sequence P296 first, then sweep the residue.
- [ ] Repurpose the detector: `check-internal-id-leaks.sh` flips from "is it prefixed?" to "is there ANY internal-ID ref in a published artifact?" (a leak detector → CI guard).
- [ ] **Extend the published-artifact ban to runtime-generated internal tokens surfaced in hook deny-message bodies** (2026-06-10 capture absorb; sub-class of the static-prose-token surface). Concrete witness: `@windyroad/jtbd`'s PreToolUse:Edit substance-confirm gate surfaces `/tmp/oversight-confirmed-<sha-of-path>-<sid>` in its deny-message body without surfacing the SHA derivation; adopter agent had to trial-and-error rel-vs-abs paths to find the match. Adopter-facing deny-messages MUST either (a) **express the path-equality constraint in adopter-readable prose** — e.g. "the helper must be invoked with the same path the Edit tool will use; absolute vs relative paths produce different markers" — or (b) **make the helper path-canonicalise** so relative/absolute invocations both succeed (realpath/abspath the input before SHA so both rel and abs produce the same marker). Audit surface: every hook deny-message body under `packages/*/hooks/` that names a `/tmp/<scheme>-<id>` marker should either drop the runtime-ID token from the user-facing copy and instead state the substance ("you must call <helper> first against the artefact path you're about to Edit") or canonicalise the input so the token's derivation no longer leaks as a debug surface.
- [ ] Re-confirm the superseding decision via `/wr-architect:review-decisions`.

## Dependencies

- **Blocks**: ADR-055 human-oversight confirmation (held until superseded).
- **Blocked by**: none. P296 closed 2026-06-10, so the agreed sequencing gate has cleared.
- **Composes with**: P294 (README marketing, no JTBD-ID citation — same adopter-facing-content-should-be-self-contained family), P296 (SKILL.md extraction), ADR-049/051 (plugin-boundary-leakage siblings), P137 (the driver behind ADR-055), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P294** — sibling (README market-from-JTBD, don't cite IDs); same adopter-facing-self-containment principle.
- **P296** — SKILL.md extraction; sequence first (removes many refs).
- **P287 / P289 / P290 / P291 / P292 / P293 / P295 / P297** — sibling drain-surfaced reworks.
- **ADR-055** (`docs/decisions/055-plugin-published-namespace-prefixed-internal-ids.proposed.md`) — the decision to supersede.
- **P137** — the internal-ID-leak driver behind ADR-055.


## Human decision — 2026-07-03 (outstanding-questions drain)

**Confirmed**: supersede ADR-055's ID-prefix mechanism via the asking-flow, sequenced AFTER the SKILL-extraction ticket (P296) lands first. Enforcement-detector flip is P296-gated. Author the supersede ADR once P296 completes.

## Superseding decision drafted - 2026-08-18

P296 is closed. ADR-118 now records the already-pinned direction as an unconfirmed draft: published artefacts express the governing substance inline, do not ship the private decision corpus, and retain internal IDs only on source-side provenance surfaces. Implementation remains gated on explicit ratification of that document.

## Slice landed — 2026-09-19 (publication-boundary guard + three packages cleared)

**Measured state, not the 2026-05-03 baseline.** The old `check-internal-id-leaks.sh` survey counted 2,880 instances across the *source tree*. Counting the *published tarballs* instead — the surface that actually reaches an adopter, per P154 — the real figure at the start of this slice was **846 across 8 of 13 packages**: connect 3, cruise 1, itil 2, voice-tone 24, tdd 31, jtbd 70, risk-scorer 279, retrospective 436. Clean already: agent-plugins, architect, c4, style-guide, wardley. `packages/shared` has no `package.json` and is not an npm package.

**Prior art found before building.** Two near-identical per-package detectors already existed (`packages/architect/scripts/` and `packages/itil/scripts/`), only one of them wired (`check:architect-published-ids`), neither in CI. They are now one repo-level check at `scripts/check-published-internal-ids.sh` with `npm run check:published-ids` and a CI step, and the duplicates are deleted. It keeps the architect perl logic verbatim, including the carve-out that lets `@adr` / `@problem` style structured annotations and leading source comments through — an identifier trailing a self-contained explanation is provenance, not a defect.

**Ratchet, not a big-bang gate.** Packages still carrying identifiers (jtbd, retrospective, risk-scorer, tdd, voice-tone) are listed in `WR_PUBLISHED_IDS_PENDING` and report `PENDING <name> drift=<n>` at exit 0. Only a regression in an already-clean package fails the build. This is a deliberate, recorded deviation from the three-phase advisory-then-blocking rollout: ADR-118's ratified Confirmation pins the blocking form ("a package-content check **fails** when a published runtime artefact contains a source-repository identifier"), the 13-package survey above *is* the measurement phase that rollout asks for, and no currently-drifting package is blocked, so the anti-big-design-up-front concern behind the phased shape is not live. The drift counts stay visible so the remaining 840 can be watched down rather than discovered later.

**Cleared this slice** — cruise (throttle hook). Connect's README lost both of its repo-relative links, which could never resolve from an installed tree, leaving one identifier in its setup skill.

The commit scorer stopped the first draft of this slice at 6 against a Low-5 appetite. The driver was that two of the edited surfaces are prose an LLM loads as instructions — connect's setup skill and itil's hang-off-check agent description — and neither package has a paired eval that would catch the migration dropping substance rather than just the token. Both edits were therefore withdrawn from this slice and their packages stay on the pending list. Any package whose migration touches skill or agent prose needs that eval coverage first; that is now the gate on the remaining slices, not the prose surgery itself.

### Remaining slices

- [ ] connect (1) and itil (2) — one edit each, blocked on eval coverage. Connect needs a step-ordering eval for its setup skill. ITIL needs one asserting the hang-off-check agent still dispatches on its documented trigger and emits both verdict tokens.
- [ ] voice-tone (24) and tdd (31) — smallest remaining, natural next increment.
- [ ] jtbd (70), risk-scorer (279), retrospective (436).
- [ ] Narrow the non-markdown comment carve-out. The detector currently skips *any* leading `#` / `//` / `/*` comment in non-markdown files, which is wider than "structured source annotations". Cruise's leak was caught only because its reference was a trailing comment; the same text one line higher would have passed.
- [ ] `packages/retrospective/scripts/check-internal-id-leaks.sh` still ships to adopters with a `bin/` shim and teaches the superseded namespace-prefix rule, citing the superseded decision in its own body. It is adopter-facing tooling for a rule that no longer applies.
- [ ] Runtime-generated tokens in hook deny-messages (the `/tmp/oversight-confirmed-<sha-of-path>-<sid>` witness above) are untouched by a tarball text scan — they are produced at runtime. Needs its own surface.
