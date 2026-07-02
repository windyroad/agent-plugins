---
"@windyroad/itil": minor
---

Wire ADR-090 story/map ratification into the story-tier skills (P404 Phase 2). New maps (`capture-story-map`) and stories (`capture-story`) are born `human-oversight: unconfirmed`. `manage-story-map` and `manage-story` gain a `ratify` operation implementing the STORY-022 UX — map first (path + briefing + an AskUserQuestion Ratify/type-something), then each story one at a time — writing `confirmed` + an `oversight-hash` fingerprint via `wr-itil-mark-story-oversight-confirmed`. Reuse offers only ratified stories; re-slicing a map re-opens ratification via the fingerprint.
