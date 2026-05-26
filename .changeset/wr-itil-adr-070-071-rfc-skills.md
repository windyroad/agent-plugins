---
"@windyroad/itil": patch
---

Align the RFC skills (`/wr-itil:capture-rfc`, `/wr-itil:manage-rfc`) with the ratified ADR-070 (RFCs hold no independent decisions) + ADR-071 (every fix goes through an RFC, unconditionally).

Strike the residual atomic-fix carve-out framing — the "JTBD-101 atomic-fix-adopter friction guard / capture-rfc never auto-fires on atomic captures / RFC ceremony only fires on opt-in invocations" language. Under ADR-071 every fix goes through an RFC; an empty `stories: []` array is a structural state (an RFC not decomposed into stories), not a reduced-ceremony or "thin" path. The RFC skills are invoked deliberately rather than auto-fired because RFC scope is direction-setting (ADR-073), not because atomic fixes skip ceremony.

Add explicit guidance to `/wr-itil:manage-rfc` that an RFC body carries no "Considered Options / Alternatives Rejected" section — per ADR-070 every contested choice among ≥2 viable options is recorded as an ADR and referenced in the RFC's `adrs:` frontmatter, never re-argued in the RFC body.
