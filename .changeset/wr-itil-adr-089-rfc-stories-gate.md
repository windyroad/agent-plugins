---
"@windyroad/itil": minor
---

Enforce ADR-089 (every RFC has at least one story) at the RFC acceptance gate. `manage-rfc`'s `proposed → accepted` transition now hard-blocks an RFC whose `stories:` frontmatter is empty (`stories: []`) or missing, via the new `wr-itil-check-rfc-has-stories` predicate. The prior empty-stories fallback is removed — an atomic fix is an RFC with exactly one full story; an empty `stories:` is permitted only on a draft RFC before the fix is scoped. (P404 / RFC-037 Phase 1.)
