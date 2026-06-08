# Ask Hygiene — 2026-06-09 P175 iter

Per ADR-044 6-class authority taxonomy + Step 2d Ask Hygiene Pass.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | No `AskUserQuestion` calls in orchestrator main turn this iter (iter prompt explicitly forbids per P083 / P175 iter prompt body). |

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

This iter ran as an AFK `claude -p` subprocess dispatched by the `/wr-itil:work-problems` orchestrator. The iter prompt body explicitly forbids `AskUserQuestion` per ADR-013 Rule 6 + P083 + P352 queue-and-continue universal AFK default. Zero main-turn calls observed.

Sub-agent delegations (architect, jtbd-lead, voice-tone, risk-scorer) ran their own internal logic and returned structured verdicts; their internal flow is not counted at the orchestrator-main-turn ask-hygiene surface.

Per `wr-retrospective:check-ask-hygiene.sh` R6 numeric gate (P135 / ADR-044 Reassessment Trigger): trail file emitted; cross-session trend evaluated by the next retro.
