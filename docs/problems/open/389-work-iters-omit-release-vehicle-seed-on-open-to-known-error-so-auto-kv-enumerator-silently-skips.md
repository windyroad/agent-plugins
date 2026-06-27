# Problem 389: work iters omit the `**Release vehicle**` seed on Open→Known Error, so the post-release K→V auto-enumerator silently skips them

**Status**: Open
**Reported**: 2026-06-27
**Priority**: 6 (Medium) — Impact: 2 x Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

When a `/wr-itil:work-problems` iter fixes a Known Error (or transitions Open→Known Error) and authors a `.changeset/*.md`, it does NOT reliably seed the ticket's `**Release vehicle**: .changeset/<name>.md` field (the P330 seed). Consequently, after the orchestrator releases the changeset, the post-release K→V auto-transition enumerator (`wr-itil-enumerate-postrelease-kv-candidates`, P228) calls `wr-itil-derive-release-vehicle <NNN>`, which exits 2 ("no `.changeset/` reference in the ticket") and **silently skips** the ticket. The fix shipped, but the ticket stays Known Error — never auto-transitioned to Verifying.

Witnessed 2026-06-27: iter 4 fixed P385 (Step 3.6 relevance gate) and authored `work-problems-pre-dispatch-relevance-gate.md`, but omitted the seed. After release, the enumerator returned `total=0`; P385 was K→V'd manually (with a backfilled seed) by the orchestrator. The manual catch worked only because the orchestrator happened to know the fix had just shipped — an un-observed iter would have left P385 stranded in Known Error (the exact P228 gap P228 was meant to close).

## Symptoms

- `wr-itil-derive-release-vehicle <NNN>` exits 2 for a Known Error ticket whose fix + changeset were authored by an iter (no `**Release vehicle**` field on the ticket).
- `wr-itil-enumerate-postrelease-kv-candidates` returns `total=0` (or omits the ticket) even though the ticket's fix shipped in the just-released changeset → no auto K→V.

## Workaround

Orchestrator manually backfills the `**Release vehicle**` seed and transitions K→V when it observes the fix shipped (as done for P385 this session). Fails silently when the orchestrator does not independently know the fix shipped.

## Impact Assessment

- **Who is affected**: AFK work-problems runs; ticket lifecycle accuracy / audit trail (JTBD-006).
- **Frequency**: every iter that fixes a KE + authors a changeset without seeding the release-vehicle (observed at least once this session; likely common — the seed step is easy to omit).
- **Severity**: tickets stranded in Known Error after their fix ships; no functional break, but the K→V auto-transition (P228) silently no-ops. Audit-trail degradation.

## Root Cause Analysis

The `**Release vehicle**` seed (P330 contract) is the input the post-release K→V enumerator keys on, but nothing enforces that an iter authoring a changeset for a ticket also writes the seed onto that ticket. The seed is a manual three-touch (P330 names the friction); iters skip it. The enumerator's exit-2 skip is silent by design (conservative), so the omission produces no signal.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Make the seed automatic: when manage-problem / work-problems authors a `.changeset/*.md` for ticket N, write `**Release vehicle**: .changeset/<name>.md` onto ticket N in the same commit (close the P330 three-touch to one-touch)
- [ ] OR: have the K→V enumerator fall back to body-grep for the changeset basename (derive already does a seed-lookup; extend to scan `## Fix Strategy` / `## Fix Released` for a `.changeset/` reference) so an un-seeded-but-referenced ticket still matches
- [ ] Behavioural test: an iter authoring a changeset for ticket N leaves ticket N with a resolvable release-vehicle; post-release enumerator emits it as a KV_CANDIDATE

## Dependencies

- **Blocks**: reliable post-release K→V auto-transition (P228) in AFK runs
- **Blocked by**: (none)
- **Composes with**: P330 (the release-vehicle seed/helper contract — this is the seed-discipline gap downstream of P330's three-touch friction), P228 (the K→V enumerator that silently skips un-seeded tickets), ADR-014 (seed should ride the same commit as the changeset)

## Related

- **P330** (`docs/problems/verifying/...` — derive-release-vehicle seed/helper) — the seed contract; this ticket is the discipline gap (iters omit the seed). If P330's fix was meant to make seeding reliable, this is evidence it's incomplete.
- **P228** — the post-release K→V auto-transition enumerator that silently skips un-seeded tickets (exit 2).
- **P385** (`docs/problems/verifying/385-...`) — the 2026-06-27 witness (iter omitted seed; manual K→V + backfill).
- `packages/itil/scripts/derive-release-vehicle.sh` + `packages/itil/lib/enumerate-postrelease-kv-candidates.sh` — the surfaces.
- Surfaced 2026-06-27 in the work-problems session retro (Step 2b pipeline-instability / Step 4b recurring class).
