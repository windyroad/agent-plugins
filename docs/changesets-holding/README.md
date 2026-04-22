# Changesets Holding Area

> **Status: provisional.** This pattern is under active investigation via **P103** and **P104**; do not rely on it surviving their resolution. P104's Investigation Tasks explicitly include "Consider promoting this session's ad-hoc convention to an orchestrator-blessed convention". If it is blessed, it will be documented in a new ADR (candidate ADR-039) that amends ADR-018 / ADR-020's above-appetite branch. Until then, this README captures the current mechanics for this repo only.

Changesets that are authored against landed commits but are **not yet ready to ship** because they belong to a multi-slice fix whose other slices have not yet landed. Holding them here (outside `.changeset/`) keeps the intent intact without breaking the `changesets/action@v1` Release workflow, which does not tolerate subdirectories under `.changeset/` (`ENOENT` on `.changeset/pending/changes.md` observed 2026-04-22 — the original relocation target).

## When to hold a changeset

A changeset is a candidate for holding when its package bump would ship a change that makes architectural sense only as part of a larger multi-slice fix whose other slices have not yet landed — the P104 "painted into a corner" hazard. The canonical example: a `minor` bump that migrates file layout for one plugin, where the paired consumer-side hook lives in a second slice that is still pending architect decisions.

## Process

1. Author the changeset against the slice's commits normally in `.changeset/`.
2. When the slice-1-without-slice-N hazard is recognised, `git mv .changeset/<name>.md docs/changesets-holding/<name>.md`.
3. Reference the holding state in the parent ticket's `## Fix Strategy` or `## Design Update` section so the reinstate trigger is captured.
4. When the blocking slices land, `git mv docs/changesets-holding/<name>.md .changeset/<name>.md` and push. The next Release workflow run picks it up.

## Currently held

- `p100-retrospective-briefing-migration.md` — `@windyroad/retrospective` **minor**. Writer-side migration to `docs/briefing/` tree. Held pending P100 slice 2 (SessionStart hook + sibling ADR + helpfulness loop + stub retirement). Reinstate when slice 2 commits land.

## Related

- **P103 (work-problems escalates resolved release decisions)** — behavioural companion. Orchestrator should auto-apply scorer's top-ranked remediation including this holding pattern, rather than escalating to `AskUserQuestion`.
- **P104 (partial-progress paints release queue into corner)** — structural companion. The root cause; holding is the workaround. P104's fix strategy is to constrain `partial-progress` so the holding area is rarely needed.
- **ADR-018 (Inter-iteration release cadence for AFK loops)** — defines drain-within-appetite / skip-above-appetite branches. Holding-area pattern is a third branch not yet documented.
- **ADR-020 (Governance auto-release for non-AFK flows)** — similar contract; same amendment candidate.
- **JTBD-006 (Progress the Backlog While I'm Away)** — the persona-job this pattern serves.
- **JTBD-101 (Extend the Suite with New Plugins)** — the plugin-developer pattern: preserve changeset intent across multi-slice work without breaking changesets-CLI semantics.
