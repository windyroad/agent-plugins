---
"@windyroad/itil": minor
---

Autonomous backlog loops no longer nudge you to capture a correction you never made. The capture-on-correction detector was content-only, so a machine-authored iteration prompt carrying an ordinary imperative like "DO NOT skip the gate" tripped it — nearly every unattended iteration emitted the full block at an absent user, spending context on a nudge nobody could act on.

The loop now tells the detector when it authored the prompt, through a new `WR_SUPPRESS_CORRECTION_DETECT=1` environment variable that any orchestrator can set. That follows the same dispatcher-asserts-provenance pattern as four existing guards, rather than having the hook guess from content. Only the literal value `1` suppresses; `0`, `true` and empty all leave the detector firing. A real correction is typed into your own session, where the guard is unset, so corrections you actually make are unaffected.
