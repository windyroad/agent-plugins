---
"@windyroad/architect": patch
---

fix(architect): fail-closed post-condition guard on the compendium-update-entry hook (P367)

The `architect-compendium-update-entry` PostToolUse hook now verifies that its
re-author of `docs/decisions/README.md` changed only the edited ADR's entry. Before
patching it snapshots the ADR-id set, the `## ` section-header count, and a full
backup; after patching it asserts the id-set is preserved (plus exactly the edited
id when the ADR is new), the edited id appears once, and the section count is
unchanged. On any deviation — a dropped entry (silent tail truncation) or a
spurious id/section injected by a malformed subprocess emit — it restores the
original README, warns in degraded mode, and does not stage, rather than shipping a
corrupted compendium. Same non-blocking contract as the existing subprocess-failure
path (ADR-078 criterion l).
