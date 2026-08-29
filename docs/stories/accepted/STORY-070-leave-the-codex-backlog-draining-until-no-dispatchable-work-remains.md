---
status: accepted
story-id: leave-the-codex-backlog-draining-until-no-dispatchable-work-remains
reported: 2026-08-29
decision-makers: [Tom Howard]
problems: [P528]
jtbd: [JTBD-006]
rfcs: [RFC-076]
story-maps: [STORY-MAP-011]
estimated-effort: S
---

# STORY-070: Leave the Codex backlog draining until no dispatchable work remains

**Reported**: 2026-08-29
**Problems**: P528
**JTBD**: JTBD-006
**RFCs**: RFC-076
**Story Maps**: STORY-MAP-011
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to trust that an unattended Codex backlog drain will not stop early, as a developer leaving `/wr-itil:work-problems` running while I am away, I want the drain to use Codex's persisted Goal tools and stop only when no dispatchable work remains.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] The installed Codex `/wr-itil:work-problems` contract creates or reuses a persisted Goal carrying ADR-094's canonical backlog-drain completion condition before the loop starts.
- [ ] The Codex orchestrator reads the persisted Goal at every continue-or-stop decision and keeps it active while dispatchable work remains.
- [ ] The Codex orchestrator clears the persisted Goal only after the final summary prints a fresh Step 2.4 Gate (0) table with zero dispatchable tickets followed by `ALL_DONE`, or another canonical terminal condition is reached.
- [ ] The installed Codex drain does not instruct the agent to invoke a fictional `/goal` command or follow the Claude Code Goal URL.
- [ ] The canonical Claude Code source retains its `claude -p` dispatch and `/goal` branch unchanged.
- [ ] A generator-exercising behavioural test protects the installed Codex contract, and a patch changeset ships the correction for `@windyroad/itil`.

## Driving problem trace (required — I7 invariant)

- **P528** — the wholesale Codex `work-problems` overlay carries only a passive conditional Goal sentence, so every Codex AFK drain loses ADR-094's external loop anchor even though Codex exposes persisted Goal tools.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006 — progress the backlog while I am away. The persisted Goal keeps the unattended Codex loop anchored to the objective Gate (0) stopping evidence instead of the orchestrator's own unsupported stop judgement.

## Implementation notes (optional)

- Implement only the Codex projection overlay under ADR-083. Do not change `packages/itil/skills/work-problems/SKILL.md`, its Claude Code `claude -p` dispatch, or its `/goal` branch.
- Reuse ADR-094's completion condition verbatim and use the native persisted Goal tools exposed to the running Codex agent; do not invent a `/goal` command.
- Exercise the generator and assert against the built Codex artifact.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- RFC-076 — *Keep the Codex backlog drain running until no dispatchable work remains*, the release row on STORY-MAP-011 activity D, *Close it out*.
- Architecture review PASS, 2026-08-29: ADR-083, ADR-094, ADR-044, ADR-013, ADR-019, and ADR-103; no new decision required.
