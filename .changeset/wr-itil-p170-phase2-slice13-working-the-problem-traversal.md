---
"@windyroad/itil": minor
---

P170 Phase 2 Slice 13 — working-the-problem traversal rewrite per ADR-060 lines 300-320. Replaces the prior vague "implement the fix following the project's development workflow" with a deterministic Problem → RFC → Story dispatch:

- **`packages/itil/skills/manage-problem/SKILL.md`** § Working a Problem → Known Error subsection: 8-step traversal:
  1. Read problem `## Fix Strategy` → extract referenced RFC IDs (or fall through to legacy direct-implementation path on no-RFC).
  2. For each RFC, read frontmatter `stories:` array (ORDERED). Non-empty → pick first `accepted` or `in-progress` story (skip `done` and `draft`). Empty `stories: []` → atomic-RFC fallback (JTBD-101 friction guard) — per-RFC iter dispatch on RFC body tasks.
  3. Read picked story's `## User value` + `## Acceptance criteria` + `## Implementation notes`.
  4. Implement story scope per project workflow (plan / architect+JTBD review / behavioural tests / ADR-014 single-commit grain).
  5. Commit with `Refs: STORY-<NNN>` trailer (single-trailer vocabulary per ADR-060 line 307 + amendment 2026-05-10 nitpick N2; capture-vs-implementation discrimination on commit-subject prefix not trailer verb).
  6. Story `draft → in-progress` auto-transition on first non-capture commit; `in-progress → done` on all-criteria-ticked + linked RFC closes.
  7. Pick next not-done story from RFC's `stories:` array (or next task for atomic-RFC fallback path); repeat.
  8. When all stories under all referenced RFCs done → include problem doc closure (`git mv` to `.verifying.md`) in final commit per ADR-022.

- **`packages/itil/skills/work-problem/SKILL.md`** § Step 3 Known Error case description updated to forward-point to the manage-problem traversal contract — work-problem (singular) and work-problems (plural AFK orchestrator) both inherit the new traversal via the existing skill split (work-problems Step 3 wraps manage-problem invocation).

**Atomic-RFC fallback path** preserves Phase 1 atomic-fix-adopter behaviour: an adopter who hasn't adopted Phase 2 story tooling has zero new friction; their RFCs continue to ship with `stories: []` and their problems continue to close via per-RFC iter dispatch.

**Legacy direct-implementation path** preserves backwards compatibility with all existing Known Error problems (captured before the RFC framework was Phase-1-graduated) — no Fix Strategy RFC references → direct implementation flow unchanged.

10-test behavioural bats per ADR-052 at `packages/itil/scripts/test/working-the-problem-traversal.bats`: Fix-Strategy section extraction; RFC frontmatter `stories:` array read with ORDERED contract; pick-first-not-done filter naming `accepted`/`in-progress`/`done`/`draft` lifecycle states; atomic-RFC empty-stories fallback (JTBD-101 friction guard); legacy no-RFC direct path; single-trailer vocabulary (`Refs: STORY-NNN` + `Refs: RFC-NNN`); story auto-transition triggers (draft→in-progress on first non-capture commit; in-progress→done on all-criteria-ticked + RFC closed); work-problem forward-pointing to manage-problem. All 10 tests green.

Markdown-only edits — voice-tone-hook-on-HTML blocker from P170 line 297 does NOT apply.
