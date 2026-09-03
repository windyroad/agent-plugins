# Ask Hygiene — 2026-09-04 (merge-guard scoping + reconciler ID clashes)

Per ADR-044 (Decision-Delegation Contract) and run-retro Step 2d. One `AskUserQuestion` call this session.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Foreign refs | direction | `Gap: genuine ≥2-option decision, framework cannot resolve, about to be built on (ADR-074)` — the architect returned an explicit `[Needs Direction]` finding on how a ticket renumber should treat references held by other artefacts, enumerated four options with an advisory lean, and stated the choice was the user's. Ratified decisions and generated story-map renders sit on either side of the boundary, so ADR-116 and ADR-102/104/105 constrain the answer without settling it. The renumber implementation was the dependent work about to be built. |

**Lazy count: 0**
**Direction count: 1**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

Decisions deliberately NOT asked, and why each is framework-resolved:

- Which ID the renumber allocates — ADR-019 fixes it at `max(local, origin) + 1`.
- Which claimant keeps the number — user direction mid-session ("you can use main git history to find the winner if it's ambiguous") pinned it; the first-add commit on the resolved base ref is the mechanism.
- Every risk-scorer remediation (the promptfoo eval, the macOS timeout bound, the configurable release-branch prefix) — RISK_REMEDIATIONS are a task list carrying score deltas toward the user's own appetite. Surfacing one as a question asks the user to authorise a fix for their own policy.
- Whether to capture P534 and P535, and whether to fold the verdict-casing finding into P468 rather than capture a sibling — Step 4b Stage 1 ticketing is mechanical, and the hang-off arbitration is a framework-mediated subagent verdict.
- The Tier 3 rotation pass and the signal-vs-noise classifications — silent agent action per ADR-044's framework-resolution boundary.
