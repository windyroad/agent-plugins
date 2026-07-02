---
"@windyroad/itil": minor
---

Add ADR-090 lazy-fingerprint drift-invalidation for story/map ratification (P404 Phase 2). A story or story-map is ratified only when it carries `human-oversight: confirmed` AND an `oversight-hash` fingerprint matching its current content; any edit drifts the hash and re-opens ratification (no live hook — the same hash-the-artefact approach as the external-comms gate). New `wr-itil-mark-story-oversight-confirmed` writes the marker + fingerprint (markdown frontmatter or HTML meta); the detector and the RFC-accept ratified-stories gate are now drift-aware via a shared lib.
