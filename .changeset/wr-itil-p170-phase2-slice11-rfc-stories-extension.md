---
"@windyroad/itil": minor
---

P170 Phase 2 Slice 11 — RFC frontmatter `stories:` extension per ADR-060 amendment 2026-05-10 (lines 255-270 + 296). The RFC tier now carries a forward-reference to the INVEST-shaped stories that implement it; the array is ORDERED (execution sequence) and 0..N cardinality (empty = atomic RFC, JTBD-101 friction guard).

Three coordinated edits land together:

- **`docs/rfcs/README.md` § RFC frontmatter shape**: adds `stories: [STORY-<NNN>, ...]` field with 0..N + ORDERED contract; field-semantics table row names the atomic-fix-adopter empty-array case + Slice 13 working-the-problem traversal dependency.
- **`docs/rfcs/README.md` § RFC body structure**: adds `## Stories (Phase 2 — maintained)` body section spec — auto-rendered from frontmatter `stories:` in execution sequence; lazy-empty when the array is empty (atomic-RFC absence-as-signal for the working-the-problem fallback).
- **`packages/itil/skills/capture-rfc/SKILL.md`**: Step 1 parse-arguments extended with optional `--stories STORY-NNN,STORY-NNN,...` flag (forward-reference permitted at capture; existence check deferred to `manage-rfc accepted`). Step 5 frontmatter template adds `stories: [...]` field. Step 6 invokes `update-rfc-references-section.sh "$rfc_file" "Stories"` when `--stories` was provided, rendering the new RFC's own `## Stories` body section before commit.
- **`packages/itil/skills/manage-rfc/SKILL.md`**: Step 7 (status transitions) gains a "Forward trace — `## Stories` body section (Phase 2)" subsection invoking `update-rfc-references-section.sh "$rfc_file" "Stories"` on every lifecycle transition. Idempotent + lazy-empty per the Slice 2a/2b contract. Composes with the existing `## Story Maps` refresh.

7-test behavioural bats at `packages/itil/scripts/test/rfc-stories-extension.bats` per ADR-052: frontmatter spec presence + ORDERED-cardinality contract; Slice 2b helper acceptance of populated `stories: [STORY-001, STORY-002]` AND empty `stories: []` (atomic-RFC JTBD-101 friction guard); SKILL.md presence of the load-bearing identifiers (`--stories STORY-`, `stories:`, `update-rfc-references-section.sh ... Stories`) in both capture-rfc + manage-rfc. All 7 tests green.

Unlocks Slice 15 (bootstrap migration of RFC-001 + RFC-002 frontmatter `stories:` populated with their ordered slice IDs) by giving the schema + skill surfaces something to write into. Composes with Slice 7 (`capture-story` emits stories whose frontmatter cross-references the parent RFC) + Slice 10 (`list-stories --rfc RFC-<NNN>` reads the same array in execution order to drive the per-RFC ordered display).

Markdown-only writes — voice-tone-hook-on-HTML blocker from P170 line 297 does NOT apply.
