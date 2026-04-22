---
"@windyroad/retrospective": minor
---

P100 slice 1 + slice 2 — surface and structure for cross-session learnings.

**Slice 1 (writer-side, commit 5d367e9):** `run-retro` SKILL.md Steps 1, 3, and 5 updated to target the new tiered briefing layout. Step 1 reads `docs/briefing/README.md` + per-topic files; Step 3 edits per-topic files under `docs/briefing/<topic>.md` and refreshes the README index; Step 5 summary heading renamed to "Briefing Changes" and records per-topic citations.

**Slice 2 (consumer-side, this release):** New `SessionStart` hook `packages/retrospective/hooks/session-start-briefing.sh` with matcher `"startup"` extracts the `## Critical Points (Session-Start Surface)` section from `docs/briefing/README.md` and injects it once per session — so adopters no longer need hand-authored CLAUDE.md pointers to receive cross-session learnings. The transitional `docs/BRIEFING.md` stub from slice 1 is deleted (legacy path retires). Architected as a sibling to ADR-038 (progressive disclosure + once-per-session budget for UserPromptSubmit) via the new **ADR-040 (proposed)** "Session-start briefing surface — SessionStart hook over tiered directory + indexed README", which documents the reuse / net-new boundary against ADR-038 and caps the Tier 1 (boot injection) output at ≤ 2 KB / ≤ 500 tokens.

Closes **P100**.
