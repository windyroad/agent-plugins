---
"@windyroad/itil": minor
---

P170 Phase 2 Slice 8 — `/wr-itil:manage-story` heavyweight story lifecycle skill at `packages/itil/skills/manage-story/SKILL.md` (~310 lines) plus 19-test contract bats. Mirrors manage-rfc shape with story-tier extensions per ADR-060 amendment 2026-05-10 lines 200-253 + 270 + 292.

**Lifecycle**: draft → accepted → in-progress → done → archived (5 states, native per-state subdir layout — no dual-tolerant flat per RFC-002 post-graduation).

**I-invariant enforcement** per ADR-060 lines 248-253:
- I6 (trace-to-problem) — re-validated at every transition; primary capture surface.
- I7 (trace-to-RFC) — hard-block at `manage-story <NNN> accepted` (deferred from capture per ADR-060 line 291).
- I8 (trace-to-story-map) — hard-block at `manage-story <NNN> accepted`.
- I9 (trace-to-JTBD) — re-validated at every transition; primary capture surface.
- I10 (INVEST shape) — hard-block at `manage-story <NNN> accepted` checking all 4 axes: Testable (≥1 acceptance criterion), Valuable (User value statement non-empty), Independent (no Blocked-by-unaccepted refs), Estimable (estimated-effort field set). L/XL stories flagged as decomposition-candidate per ADR-060 line 252 architect-amendment-2026-05-10 nitpick N3 (advisory, not blocking — XL stories may be the right granularity for bounded work).
- I11 (no-WSJF-leak) — argument grammar carries no WSJF token; frontmatter handling carries no WSJF read/write.

**Single-trailer vocabulary** per ADR-060 line 307 + amendment 2026-05-10 nitpick N2: `Refs: STORY-NNN` for all commits (capture, implementation, transition); capture-vs-implementation discrimination via commit-subject prefix (`feat(itil): capture STORY-...` is capture; any other subject is implementation).

**Auto-transition triggers** per ADR-060 line 292:
- draft → in-progress: first commit AFTER capture commit carrying `Refs: STORY-<NNN>` trailer.
- in-progress → done: ALL `- [ ]` lines in `## Acceptance criteria` ticked + linked RFC reaches `closed` status (RFC-side transition triggers a sweep of its `stories:` array).

**Bootstrap-exemption marker** per ADR-060 line 339 + ADR-053 Bootstrapping precedent: one-time `<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->` permitted on bootstrap-migration stories during Slice 15 retrofit; non-bootstrap captures with the marker fail.

**Reverse-trace refresh on 4 parent tiers** at every transition (inline per ADR-014 single-commit grain):
- Problem parents: `update-problem-references-section.sh <problem-file> "Stories"` (Slice 2a)
- JTBD parents: `update-jtbd-references-section.sh <jtbd-file> "Stories"` (Slice 2b)
- RFC parents: `update-rfc-references-section.sh <rfc-file> "Stories"` (Slice 2b + Slice 11)
- Story-map parents: MANUAL placement per Slice 7 architect amend finding 2 — story-maps are HTML with manually-authored `data-story-id` attributes; emit advisory stderr noting unplaced state.

P062 mirror: every transition refreshes `docs/stories/README.md` Story Rankings + Done tables inline.

19-test contract bats (per ADR-052, behavioural for SKILL contract surfaces per P081 + P012 acknowledged limitation) covering: SKILL.md presence + canonical name; I6-I11 invariant declarations (6 tests); I7+I8 accepted-gate firing; INVEST 4-axis check + L/XL decomposition-candidate advisory; auto-transition triggers (draft→in-progress + in-progress→done); bootstrap-exemption marker contract; 4 reverse-trace surfaces (problem/JTBD/RFC + story-map manual-placement carve-out); I11 no-WSJF-leak argument grammar. All 19 green.

Companion to `/wr-itil:capture-story` (lightweight aside surface — Slice 7) per ADR-032 split. Together with Slice 7 + Slice 10 (list-stories) + Slice 9 (reconcile-stories), Slice 8 completes the story-tier MVP.

packages/itil/README.md updated to add the `/wr-itil:manage-story` row to the skills table — closes the P159 JTBD-currency drift gate inline.

Markdown-only edits — voice-tone-hook-on-HTML blocker from P170 line 297 does NOT apply.
