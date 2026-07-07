# Problem 443: Quota-pacing (P160 / RFC-046 / ADR-093) shipped without a grounded JTBD → persona → USM → RFC → story lineage — governance artefacts are wrong, orphaned, or missing

**Status**: Open
**Reported**: 2026-07-07
**Priority**: 15 (High) — Impact: 3 (Moderate — a Critical-priority capability shipped mis-grounded and mis-homed across 7 published plugins; adopters inherit an inert/wrong feature; honest verification of P160 is blocked) × Likelihood: 5 (Certain — this is the present state, directly observed) — derived at capture per Step 4a
**Origin**: internal
**Effort**: L — new ratified developer JTBD + proper USM/story-map + RFC-046 lifecycle repair + real story authoring + re-anchor P160/RFC-046. (The consequent own-plugin extraction + adopter-producer shipping are tracked as P160 folded gaps + P444 systemic sibling.)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Quota-pacing (P160 / RFC-046 / ADR-093) was built and released without a grounded problem → JTBD → persona → user-story-map → RFC → story lineage, so its governance artefacts are wrong, orphaned, or missing. User correction 2026-07-07 (verbatim substance): *"the problem doesn't specify the persona it impacts. How can you solve it for the user if you don't know who the user is? Similarly, how can you solve it if you don't understand the JTBD. … if you had done a proper JTBD and USM, you would have seen it was independent of the other USMs and belonged in its own plugin."*

Confirmed lineage defects (all verified against on-disk artefacts 2026-07-07):

1. **No grounding job.** RFC-046 (`jtbd: [JTBD-006]`) and P160 anchor to **JTBD-006 "Progress the Backlog While I'm Away"** — an AFK-only job. But the throttle fires on **ALL** work (interactive + AFK — that was Correction 2's whole point). The capability actually serves a **general developer job that does not exist in `docs/jtbd/`**: *"sustain my Claude token quota across the work week and across all Claude surfaces (Code + chat + cowork)."* A `grep -ri quota|token-budget|sustainab docs/jtbd/` returns nothing — the grounding job was never created. This is precisely why quota-pacing was correctly NOT folded into `/wr-itil:work-problems` (it's broader than AFK), yet no correct JTBD was authored to hold that breadth.

2. **Persona never nailed.** P160 lists 3 personas loosely in its Impact Assessment and cites a **nonexistent** `docs/jtbd/solo-developer/` path (the real directory is `docs/jtbd/developer/`). RFC-046/story lineage does not nail a single persona. The real persona is `developer`.

3. **Orphaned story.** RFC-046 frontmatter `stories: [STORY-039]` and body reference STORY-039 — **no such file exists** (`docs/stories/*/*039*` → empty).

4. **Orphaned / absent story map.** RFC-046 `## Related` cites "STORY-MAP-003 (quota-pace throttle story map, draft)" — **no such file exists** (`docs/story-maps/*/*003*` → empty). RFC-046 frontmatter carries **no story-map trace field at all**.

5. **Lifecycle inversion.** RFC-046 is `status: proposed` while P160 is `Verification Pending` **with a `## Fix Released` section** — shipped, released code and a verifying problem hanging off an **unaccepted** RFC. (JTBD-006 itself is `status: proposed`, though `human-oversight: confirmed` — the RFC builds on a proposed-lifecycle job.)

6. **Consequence — mis-placement.** Because no proper JTBD/USM analysis was done, the capability's independence from the other user-story-maps was missed, and it was mis-placed as a hook **synced verbatim across 7 governance plugins** (`packages/shared/hooks/quota-pace-throttle.sh` → architect/itil/jtbd/risk-scorer/style-guide/tdd/voice-tone) whose canonical home (`packages/shared/`) is **not itself an installable plugin**. A proper USM would have shown it belongs in its **own** plugin (`@windyroad/quota-pacing`?).

## Symptoms

- `grep -ri 'quota\|token budget\|sustainab' docs/jtbd/` → no match (grounding job absent).
- `ls docs/stories/*/*039*` and `ls docs/story-maps/*/*003*` → no match (orphaned references).
- RFC-046 `status: proposed`; P160 `Verification Pending` + `## Fix Released`.
- P160 Related cites `docs/jtbd/solo-developer/JTBD-006-...` — a directory that does not exist.
- Quota-pacing hook present in all 7 `packages/*/hooks/quota-pace-throttle.sh` (byte-identical), none of which is a quota-dedicated plugin.

## Workaround

None — the code path works (for the maintainer, who has the statusline producer wired); the defect is that the governance lineage is wrong, so P160 cannot be honestly verified and the capability cannot be correctly evolved/re-homed until the lineage is repaired.

## Impact Assessment

- **Who is affected**: `developer` persona (primary — the general quota-sustainability job this capability actually serves is undocumented, so the solution was designed without knowing the user); maintainer (the P160 verification is blocked / dishonest); adopters (inherit a mis-homed, inert feature — see P160 folded gaps).
- **Frequency**: Present continuously since the 2026-07-06 release; surfaces on every attempt to verify/evolve/re-home the capability.
- **Severity**: Moderate-to-Significant — no published package is *broken*, but a Critical-priority capability is mis-grounded and mis-homed across the published suite; blocks honest closure of the top-priority P160.
- **Analytics**: Lineage audit 2026-07-07 (this ticket) — 6 confirmed defects listed above.

## Root Cause Analysis

### Preliminary Hypothesis

The JTBD + USM discipline (problem → correct JTBD/persona → user-story-map → RFC → story) was skipped; the fix jumped straight from "user wants pacing" to "ship a synced hook", anchoring opportunistically to the nearest existing JTBD (JTBD-006 AFK) and minting RFC/story/story-map references that were never authored. The systemic "why did nothing catch this" is P444.

### Investigation Tasks

- [ ] Author the missing **developer JTBD** — "sustain Claude token quota across the work week + across all Claude surfaces (Code/chat/cowork)" — via `/wr-jtbd:update-guide`, ratify via `/wr-jtbd:confirm-jobs-and-personas` (ADR-068/P288). **Ratification-gated — surface to user.**
- [ ] Do a proper **USM / story map** for quota-pacing; confirm independence from existing story maps → own-plugin recommendation. **Ratification-gated — surface to user.**
- [ ] Re-anchor RFC-046 + P160 to the new JTBD + `developer` persona; fix the `solo-developer` path error.
- [ ] Author the real **STORY-039** (or renumber to the correct next story id) with problem + JTBD trace per ADR-060 I6/I9; wire it into the story map.
- [ ] Author / correct the **story-map** reference (STORY-MAP-003 or correct id); add the story-map trace to RFC-046 frontmatter.
- [ ] Resolve the **lifecycle inversion**: transition RFC-046 `proposed → accepted` (with the ratified scope) so P160's `verifying`/`Fix Released` no longer hangs off an unaccepted RFC — OR reset P160 out of `verifying` until the lineage is sound (see P160).

## Dependencies

- **Blocks**: P160 (honest verification — cannot close while its lineage is broken).
- **Blocked by**: (none — buildable now; several sub-tasks are ratification-gated on the user).
- **Composes with**: P160 (folded implementation gaps: adopter-inert producer + own-plugin extraction), P404 (systemic gate-gap parent — the lineage invariants only fire at accepted transitions, so the AFK flow shipped this broken lineage; the new dangling-reference + lifecycle-inversion sub-gaps this audit surfaced are folded there), ADR-060 (Problem-RFC-Story lineage invariants), ADR-090 (story/story-map oversight markers).

## Related

- **P160** (`docs/problems/verifying/160-...md`) — the driver capability; its implementation gaps (adopter-inert producer, own-plugin extraction) are folded there per user direction 2026-07-07; this ticket owns the lineage/grounding repair.
- **P404** (`docs/problems/known-error/404-...md`) — systemic gate-gap parent. Reopened 2026-07-05 citing THIS quota-pace iter (RFC-045 task-based + STORY-039 mapless); its ADR-095/096 capture-time gates landed 2026-07-07. The newly-discovered sub-gaps this audit surfaced (dangling story/story-map **reference** validation; RFC-`proposed`-while-linked-problem-`verifying` lifecycle-inversion detection; build-on-unratified-JTBD-at-ship) are folded into P404's Phase-3 residual, not minted as a duplicate sibling.
- **P251** (`docs/problems/known-error/251-...md`) — same class: RFC-first trace invariant not enforced where work actually happens.
- **RFC-046** (`docs/rfcs/RFC-046-...proposed.md`) — the broken RFC (proposed; orphaned STORY-039 + STORY-MAP-003; JTBD-006 anchor).
- **ADR-093** (`docs/decisions/093-mechanical-quota-pace-throttle.proposed.md`) — the throttle mechanics decision (also born `human-oversight: unconfirmed`).
- **JTBD-006** (`docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md`) — the wrong/narrow anchor (AFK-only).
- Hang-off consideration (capture Step 2b): mechanical pre-filter surfaced P160 + P390 as signal-sharing candidates; **PROCEED_NEW per explicit user direction** ("we need problems for all of these"; meta issue kept distinct from P160). Recorded per ADR-026 audit-trail.
- User correction 2026-07-07 (verbatim excerpts in Description) — the driver.
