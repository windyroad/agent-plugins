---
status: "proposed"
date: 2026-07-02
human-oversight: confirmed
oversight-date: 2026-07-02
oversight-confirmed-date: "2026-07-02 — batched ratification via AskUserQuestion: user ratified every RFC has ≥1 story; atomic = one full INVEST-traced story (Option A)"
oversight-note: "substance (Option A — an atomic fix's single story is a full INVEST-traced story) user-picked via AskUserQuestion 2026-07-02; born unconfirmed pending the batched ratification pass this session (P348 — a confirmed marker must trace to a same-turn substance-confirm event)"
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-02
amends: [ADR-060, ADR-071]
---

# Every RFC has at least one story

## Context and Problem Statement

ADR-071 made RFC-first unconditional — every fix goes through an RFC, no carve-out, no effort threshold, no "thin" path ("No. Same RFC. Not scaled down. No short cuts." — P311). But ADR-071 kept the **empty `stories: []` shape** as its representation of an atomic (single-commit, non-decomposed) fix, reusing ADR-060's `0..N` story cardinality and its per-RFC-iter fallback.

That empty-stories shape is the last structural residue of the disavowed atomic-fix friction guard: across ADR-060 (cardinality "genuinely 0..N"; the work-problem traversal's `stories: []` fallback branch), the capture-rfc/manage-rfc skills (lazy-empty `## Stories` omission), and four behavioural tests, the empty-stories path is explicitly annotated "JTBD-101 atomic-fix-adopter friction guard" — the reduced-ceremony framing P311 removed as policy, surviving as a *data shape*.

User direction (2026-07-02): **"there should never be an RFC with an empty list."** An RFC is comprised of stories in a user story map (ADR-060); an RFC with zero stories is a vehicle with no cargo. Where should the floor sit, and — if an atomic fix must now carry exactly one story — what shape is that story?

## Decision Drivers

- **Complete the P311 cleanup.** The empty-stories shape is the friction-guard's last residue; removing it finishes what ADR-071 started.
- **A story map with an empty-cardinality node is incoherent** — an RFC *is* its stories; "no stories" is not a decomposition, it's an absence.
- **No shaped exemptions** (P311) — any "lighter path for small fixes" is the class the user disavowed.
- **Uniformity of the traversal** — an empty-stories fallback branch is code + tests that exist only to represent "no decomposition"; a ≥1-story floor deletes the branch.
- **Ceremony cost for one-line fixes** — requiring a fully-traced story for every atomic fix raises capture-time ceremony; this is the trade-off the chosen option accepts.

## Considered Options

1. **The atomic singleton is a full story** — every RFC carries ≥1 story; the atomic fix's single story is a normal story with full traces (I6–I10: problem, RFC, story map, JTBD) and INVEST shape. No exemption, no fallback branch anywhere.
2. **Lightweight singleton** — every RFC carries ≥1 story, but the atomic-singleton story is exempt from the story-map trace (I8) and INVEST-Small. Keeps one-line fixes fast.
3. **Auto-derived singleton** — the framework mints the one story from the problem's fix statement; the user never hand-captures it.

## Decision Outcome

Chosen option: **"The atomic singleton is a full story"** (Option 1), because it is the only option that removes the empty-stories residue *without* re-introducing a shaped exemption. Option 2 re-creates the exact reduced-ceremony carve-out P311 disavowed (now on the story tier instead of the RFC tier). Option 3 hands story authorship to the framework — but auto-made governance artefacts are precisely what ADR-066/068 (P283/P288) lifted to human ratification, so it trades one drift class for another and collides with the sibling USM-ratification decision. Option 1 pays a real ceremony cost on one-line fixes, and the user accepted that cost explicitly under "no short cuts."

**The rule:** an RFC's `stories:` list is **never empty**. Cardinality is **1..N** once a fix is proposed (it may still be empty on a `draft` RFC before the fix is scoped). An atomic single-commit fix is an RFC carrying **exactly one full story** — same INVEST shape and same traces as any story — not an RFC with `stories: []`, and not a thin, scaled-down, or auto-generated variant. This reverses ADR-060's `0..N`/empty-fallback cardinality and reframes ADR-071's atomic representation; both are amended in lockstep (see Related). The empty-stories work-problem traversal fallback is removed.

## Consequences

### Good

- Completes the P311 / ADR-071 cleanup — the friction-guard's last structural residue is gone; there is no shaped exemption anywhere.
- The traversal is uniform: no `stories: []` fallback branch to maintain; the work-problem flow always has ≥1 story to dispatch.
- Every fix — atomic or coordinated — is fully traced (problem → RFC → story map → story), so the reverse-trace re-derives cleanly for all fixes, not just decomposed ones.

### Neutral

- Atomic RFCs go from `stories: []` to `stories: [STORY-NNN]` (one entry). The RFC process is otherwise unchanged.

### Bad

- **A real ceremony increase on one-line fixes**: every atomic fix now mints one fully-traced, INVEST-shaped story where before it shipped with an empty list. Accepted deliberately (user: "no short cuts"). If this friction proves disproportionate for the solo/adopter persona in practice, it is the named reassessment trigger below — but the fix would be to reduce per-story ceremony uniformly, never to re-introduce an atomic exemption.

## Confirmation

- A behavioural test (per ADR-052) asserts an RFC proposed for a fix cannot reach `accepted` with an empty `stories:` list — the empty-list state is rejected, not fallback-dispatched.
- The four bats that currently assert the empty-stories fallback is legal (`rfc-stories-extension.bats`, `working-the-problem-traversal.bats`, `check-rfc-rejected-alternatives.bats`, `list-stories-contract.bats`) are flipped to assert it is rejected, and ride the same implementation slice as the skill changes.
- ADR-060's cardinality clauses and ADR-071's atomic-representation clauses read "≥1 / exactly one story," with no surviving "empty `stories: []`" language.

## Pros and Cons of the Options

### Option 1 — full story (chosen)

- Good: no exemption; uniform traversal; every fix fully traced; finishes the P311 cleanup.
- Bad: real ceremony increase on one-line fixes.

### Option 2 — lightweight singleton

- Good: keeps one-line fixes fast.
- Bad: re-introduces a shaped exemption (I8 / INVEST-Small skip) — the exact reduced-ceremony class P311 disavowed, relocated to the story tier.

### Option 3 — auto-derived singleton

- Good: lowest capture friction.
- Bad: auto-made governance artefact (the class ADR-066/068/P283/P288 lifted to human ratification); collides with the sibling USM-ratification decision, which would then have to ratify a machine-authored story.

## Reassessment Criteria

Revisit if the one-story-per-atomic-fix ceremony measurably harms the solo/adopter persona's throughput (e.g. the trace-violation or capture-abandonment rate on atomic fixes exceeds the JTBD-101 reassessment threshold). The remedy would be to reduce per-story ceremony *uniformly* — never to re-introduce an atomic-fix exemption, which this decision forecloses.

## Related

- **ADR-071** — Every fix goes through an RFC (the parent this completes). This ADR reframes ADR-071's atomic representation from "empty `stories: []`" to "exactly one full story."
- **ADR-060** — Problem-RFC-Story framework. This ADR amends its `stories:` cardinality (`0..N` → `1..N` once a fix is proposed) and removes the empty-stories work-problem fallback (lockstep in-place edits).
- **ADR-070** — RFCs hold no independent decisions (the sibling-amendment precedent: ADR-070/071 amended ADR-060 via new ADRs, keeping the audit trail legible).
- **JTBD-008** — Decompose a Fix Into Coordinated Changes (its "atomic = empty stories" outcome is reframed in lockstep).
- **JTBD-101** — Extend the Suite with New Plugins (its atomic-fix-adopter framing is reframed; the coordination surface scales up, the RFC never scales below one story).
- **P311** — "No short cuts" (the disavowal this completes). **P170** — the driver.
- **Sibling ADR (story-map / story human-oversight — USM ratification)** — composes with this: every RFC has ≥1 story, and those stories must be ratified before the RFC references them.
- **Implementation ticket** (to be logged) — the skill + bats ripple: remove the `stories: []` traversal fallback + `Refs: RFC-NNN` atomic trailer, require ≥1 story in capture-rfc/manage-rfc, flip the four bats. Rides one slice so CI does not go red.
