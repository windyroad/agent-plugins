---
"@windyroad/itil": minor
---

P170 Phase 2 Slices 3 + 4 + 5 + 6 — story-map tier MVP (4 skills + reconcile script + bin shim) per ADR-060 amendment 2026-05-10 + encoding amendment 2026-05-12. Mirrors the story-tier MVP (Slices 7-10) at the story-map tier with HTML encoding adjustments.

**Slice 3: `/wr-itil:capture-story-map`** (lightweight aside) — `packages/itil/skills/capture-story-map/SKILL.md`. Mandatory positional `<problem-trace> <jtbd-trace> <description>` with I3 + I4 hard-block. HTML skeleton at `docs/story-maps/draft/STORY-MAP-NNN-<slug>.html` per ADR-060 § Phase 2 encoding amendment 2026-05-12 lines 381-435. Inline `max(local, origin) + 1` STORY-MAP-NNN ID allocation per ADR-019 collision-guard. Reverse-trace `## Story Maps` section refresh on driving problem + JTBD files via Slice 2a/2b helpers. Deferred `docs/story-maps/README.md` refresh. 11 behavioural bats green.

**Slice 4: `/wr-itil:manage-story-map`** (heavyweight lifecycle) — `packages/itil/skills/manage-story-map/SKILL.md`. Lifecycle: draft → accepted → in-progress → completed → archived (5 states). I3+I4 re-validated at every transition; I5 no-WSJF-leak enforced at argument grammar + frontmatter level. Backbone × ribs × slices authoring guidance at accepted transition (AskUserQuestion taste class). P062 README refresh inline. Reverse-trace refresh on driving problems + JTBDs via "Story Maps" section helpers; NO reverse-trace on the map HTML file itself (slice cards' `data-story-id` attributes are authored manually per architect Slice 7 amend finding 2). 11 contract bats green.

**Slice 5: `/wr-itil:reconcile-story-maps`** (trio per ADR-049) — `packages/itil/scripts/reconcile-story-maps.sh` (~110 lines, executable, exit 0/1/2 per ADR-040), `packages/itil/bin/wr-itil-reconcile-story-maps` (bin shim), `packages/itil/skills/reconcile-story-maps/SKILL.md` (~90 lines agent-applied-edits wrapper). FS truth across 5 lifecycle subdirs; MISSING/STALE drift detection against README. No Rankings table (I5 — story-maps are planning artefacts, not work items). 7 behavioural bats green.

**Slice 6: `/wr-itil:list-story-maps`** (read-only display) — `packages/itil/skills/list-story-maps/SKILL.md`. Lifecycle-grouped tables for 5 subdirs; no WSJF column (I5); HTML `<meta>` block parse target via xmllint with grep fallback. No `--rfc` filter mode (story-maps aren't per-RFC scoped — they're journey-context lenses on the story corpus per ADR-060 line 317). 7 contract bats green.

**Together with Slices 7-10 (story tier)**, Slices 3-6 complete the Phase 2 story-map + story tier MVP. The voice-tone-hook-on-HTML blocker from P170 line 297 closed via Slice 14's in-session unblock path (`docs/VOICE-AND-TONE.md` + `docs/STYLE-GUIDE.md` policy files + wr-voice-tone:agent + wr-style-guide:agent PASS verdicts → review-gate markers set).

packages/itil/README.md updated with 4 new skill rows (capture-story-map, manage-story-map, reconcile-story-maps, list-story-maps) — closes P159 JTBD-currency drift gate inline.

Net: 4 SKILL.md files + 4 bats fixtures + 1 reconcile script + 1 bin shim + 1 README update. 36 bats tests total (11 + 11 + 7 + 7) across the 4 slices.
