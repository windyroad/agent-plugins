---
"@windyroad/itil": patch
---

Fix-time RFC auto-create now authors a fully-scoped RFC, not a skeleton (P399).

When the I13 propose-fix RFC-trace gate auto-creates a missing RFC (a Known
Error with no fix vehicle), it now authors a populated `## Scope` (the fix
being proposed plus implementation approach) and a real `## Tasks`
decomposition from the already-traced problem's RCA + Fix Strategy — instead
of emitting an empty `capture-rfc` placeholder that the "flesh out later" step
never self-fired to fill (the P375 cadence-rot that left auto-created RFCs
systematically under-scoped). A new `--fix-time` flag on `/wr-itil:capture-rfc`
drives the full authoring; the gate prose in `/wr-itil:manage-problem` and
`/wr-itil:work-problems` invokes it. ADR-073 amended (skeleton → full-scope
authoring; ADR-044 cat-1 boundary reclassification: full-scope authoring of the
ADR-071-pinned mandatory vehicle is framework-mediated, the scope is derived
from the traced problem, not direction-setting).
