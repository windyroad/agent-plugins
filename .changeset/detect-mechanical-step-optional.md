---
"@windyroad/itil": patch
---

Detect mechanical-step-framed-as-user-optional in the itil assistant-output-review Stop hook (P403). When a skill contract mandates a mechanical step, re-surfacing it as a user decision — or skipping it on budget-caution grounds — in end-of-turn prose reintroduces the friction the mechanical-stage carve-out (P132 / ADR-044) removes. A new detect_mechanical_optional detector fires a non-blocking nudge only when a step-skip signal, a step reference, and an offloaded-justification closer all co-occur.
