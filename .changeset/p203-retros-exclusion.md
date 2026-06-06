---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
---

Exempt `docs/retros/` from architect + JTBD edit-enforce gates (P203).

The ask-hygiene + run-retro narrative trail under `docs/retros/` (written by
`/wr-retrospective:run-retro` Step 2d + Step 5) is not load-bearing
architecture or user-job content. Both gates were firing BLOCKED on every
retro append, forcing two subagent round-trips for a routine narrative
artefact. Mirrors the existing peer-plugin-policy exemptions for
`docs/problems/`, `docs/jtbd/`, `docs/briefing/`, `docs/story-maps/`, and
`docs/stories/`. Behavioural bats coverage added in both
`architect-enforce-scope.bats` and `jtbd-enforce-scope.bats`.
