# Changesets Holding Area

> **Blessed by ADR-041** (2026-04-22). This is the authoritative mechanism for the `move-to-holding` remediation class — the orchestrator-supported subset of ADR-041 Rule 2a's closed action-class enumeration. See `docs/decisions/041-auto-apply-scorer-remediations-above-appetite.proposed.md` Rules 2 + 7.

Changesets that are authored against landed commits but are **not yet ready to ship** because they belong to a multi-slice fix whose other slices have not yet landed, OR that have been auto-moved here by the orchestrator under ADR-041 Rule 2 to bring release risk within appetite. Holding them here (outside `.changeset/`) keeps the intent intact without breaking the `changesets/action@v1` Release workflow, which does not tolerate subdirectories under `.changeset/` (`ENOENT` on `.changeset/pending/changes.md` observed 2026-04-22 — the original relocation target).

## When to hold a changeset

A changeset is a candidate for holding in either of two cases:

1. **Multi-slice WIP (user-authored)**: a `minor`/`major` bump that migrates file layout or introduces behaviour whose paired consumer-side hook lives in a slice still pending architect decisions — the P104 "painted into a corner" hazard.
2. **Auto-apply under ADR-041 (orchestrator-authored)**: residual push/release risk is above appetite (≥ 5/25) and the scorer ranks `move-to-holding` as the top remediation. The orchestrator performs the move, re-scores, and proceeds per ADR-041 Rule 2.

## Process

1. Author the changeset against the slice's commits normally in `.changeset/`.
2. When the slice-1-without-slice-N hazard is recognised (user path) OR the orchestrator's auto-apply fires (ADR-041 path), `git mv .changeset/<name>.md docs/changesets-holding/<name>.md`.
3. Reference the holding state:
   - User path: in the parent ticket's `## Fix Strategy` or `## Design Update` section so the reinstate trigger is captured.
   - Auto-apply path: the orchestrator's iteration/skill report logs the move per ADR-041 Rule 6, and this README's "Currently held" section is appended with the parent ticket reference.
4. When the blocking slices land (user path) or the user manually decides to reinstate (auto-apply path), `git mv docs/changesets-holding/<name>.md .changeset/<name>.md` and push. The next Release workflow run picks it up. Move the entry from "Currently held" to "Recently reinstated" in this README with the reinstate date + reason.

## Currently held

*(none currently held)*

## Recently reinstated

- `p100-retrospective-briefing-migration.md` — `@windyroad/retrospective` **minor**. Held during P100 slice 1 pending slice 2. Reinstated 2026-04-22 when slice 2 (SessionStart hook + ADR-040 + stub retirement) landed; scope body expanded to cover slice 1 + slice 2 combined.

## Related

- **ADR-041** (`docs/decisions/041-auto-apply-scorer-remediations-above-appetite.proposed.md`) — authoritative basis. Rule 7 blesses this convention; Rule 2 + Rule 2a define the `move-to-holding` action class the orchestrator auto-applies against this area; Rule 6 mandates the README audit append.
- **P103** (closed by ADR-041) — behavioural driver: orchestrator escalated resolved release decisions instead of auto-applying.
- **P104** (closed by ADR-041) — structural driver: partial-progress painted the release queue into a corner.
- **ADR-018** (Inter-iteration release cadence for AFK loops) — at-or-below-appetite drain. Above-appetite governed by ADR-041.
- **ADR-020** (Governance auto-release for non-AFK flows) — symmetric non-AFK rule. Above-appetite governed by ADR-041.
- **JTBD-006 (Progress the Backlog While I'm Away)** — the persona-job this pattern serves.
- **JTBD-101 (Extend the Suite with New Plugins)** — the plugin-developer pattern: preserve changeset intent across multi-slice work without breaking changesets-CLI semantics.
