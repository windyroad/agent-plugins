---
"@windyroad/architect": minor
---

P339 + P340: `/wr-architect:create-adr` Step 5 now splits the bundled "review pass" `AskUserQuestion` into two separate fires — (5a) substance-confirm fire and (5b) optional draft-quality review fire — closing the bogus-ratification class where a "Yes" answer to a draft-quality question was being treated as substance-ratification and landing the `human-oversight: confirmed` marker on substance the user had never explicitly affirmed (ADR-078 commit 5196e3d exemplar; user correction 2026-05-31 *"I never approved the scripted extraction"* + *"How did that ADR skip ratification?"*).

The new Step 5a encodes the substance-confirmation interaction pattern pinned by user direction 2026-05-31: briefing in main-turn prose BEFORE the `AskUserQuestion` fires; `AskUserQuestion` is option-shaped not yes/no (each considered option is a selectable option); no IDs (`ADR-NNN` / `P-NNN` / `JTBD-NNN` / `RFC-NNN`) as explainers; user can make an informed decision without external document lookup. The born-confirmed marker writes ONLY when the substance-confirm answer selects a specific option matching the draft on disk; mismatch triggers a re-draft + re-fire (not a soft warn-and-proceed). Step 5b (draft-quality review) is separate, optional, and does NOT gate the marker.

ADR-064 § Decision Outcome carries the five interaction-pattern requirements as a 2026-05-31 amendment extending the 2026-05-27 ADR-074 amendment. ADR-066 § Decision Outcome item 5 carries the marker-write-only-on-substantive-answer tightening as a 2026-05-31 amendment. Both amendments retain `human-oversight: confirmed` (mechanism tightening, not substance change). Closes P339 (subsumed) + P340.
