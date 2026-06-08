# Ask Hygiene Trail — 2026-06-08 P136 iter

Iter ran under explicit direction: "NEVER call AskUserQuestion. P136 is observation/audit ticket."

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| (none) | — | — | Zero `AskUserQuestion` fires this iter — iter constraint explicit |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Notes:

- Investigation-only iter per orchestrator dispatch (P136 Fix Strategy + ticket line 178: "NOT picked up automatically by `/wr-itil:work-problems` AFK loop"). All per-surface remediation decisions deferred to interactive sessions where ADR-044 deviation-approval `AskUserQuestion` flow can fire correctly.
- Architect and JTBD delegation calls (2× via Agent tool) were framework-mediated edit-gate satisfaction — NOT AskUserQuestion. Gate compliance is mechanical per ADR-044 framework-resolution boundary; review delegation is the mechanical action, not a user-decision surface.
