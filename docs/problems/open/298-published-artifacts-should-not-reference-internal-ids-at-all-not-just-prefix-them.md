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
- **Blocked by**: best sequenced after P296 (SKILL.md extraction removes many refs).
- **Composes with**: P294 (README marketing, no JTBD-ID citation — same adopter-facing-content-should-be-self-contained family), P296 (SKILL.md extraction), ADR-049/051 (plugin-boundary-leakage siblings), P137 (the driver behind ADR-055), P283/ADR-066 (the drain that surfaced this).

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain)

- **P294** — sibling (README market-from-JTBD, don't cite IDs); same adopter-facing-self-containment principle.
- **P296** — SKILL.md extraction; sequence first (removes many refs).
- **P287 / P289 / P290 / P291 / P292 / P293 / P295 / P297** — sibling drain-surfaced reworks.
- **ADR-055** (`docs/decisions/055-plugin-published-namespace-prefixed-internal-ids.proposed.md`) — the decision to supersede.
- **P137** — the internal-ID-leak driver behind ADR-055.
