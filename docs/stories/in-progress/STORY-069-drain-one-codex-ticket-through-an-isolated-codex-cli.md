---
status: in-progress
story-id: drain-one-codex-ticket-through-an-isolated-codex-cli
reported: 2026-08-29
decision-makers: [Tom Howard]
problems: [P529]
jtbd: [JTBD-006]
rfcs: [RFC-075]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-069: Drain one Codex ticket through an isolated Codex CLI

**Reported**: 2026-08-29
**Problems**: P529
**JTBD**: JTBD-006
**RFCs**: RFC-075
**Story Maps**: STORY-MAP-002
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to keep progressing the governed problem backlog when Codex CLI capacity is available, as a developer leaving the loop to work while I am away, I want each Codex iteration to run as one isolated `codex exec` process in the exact checkout and return a trustworthy summary to the outer orchestrator.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] The installed Codex `/wr-itil:work-problems` contract dispatches exactly one selected ticket through a nested `codex exec` in the exact checkout, while the canonical Claude Code `claude -p` branch and ADR-094 remain unchanged.
- [x] The nested command receives the selected ticket and checkout explicitly, loads the required governance hooks/plugins, exports the AFK suppression guards, preserves unrelated work, and runs the iteration retro before returning.
- [x] The nested Codex writes its final `ITERATION_SUMMARY` to the `codex exec` final-output file; JSONL is consumed separately for progress and error metadata, including quota-versus-non-quota classification.
- [x] Clean-state recovery is path-scoped and fail-closed: coherent work from the one ticket may be recovered, while ambiguous or unrelated dirty state halts without a broad reset.
- [x] A behavioural installed-artifact test launches a real outer Codex with a fake nested `codex` first on `PATH` and a fail-fast fake `claude`; it asserts the nested process receives P529 and the exact checkout, emits JSONL, writes the final-output summary, and the outer Codex consumes sentinel `ITERATION_SUMMARY` fields.
- [x] A patch changeset for `@windyroad/itil` ships the Codex runtime correction.

## Driving problem trace (required — I6 invariant)

- **P529** — installed `@windyroad/itil` 2.1.0 forbids nested `codex exec`, so the Codex drain cannot use refreshed Codex CLI quota even though its one-ticket isolation contract still needs a fresh runtime boundary.

## JTBD trace (required — I9 invariant)

Serves JTBD-006 — progress the backlog while I am away. The isolated process keeps each iteration bounded to one ticket, and the consumed summary preserves the audit trail the returning developer needs.

## Implementation notes (optional)

- Implement only the Codex projection/adapter under ADR-083. Do not change `packages/itil/skills/work-problems/SKILL.md`, its Claude Code dispatch, or ADR-094.
- Preserve ADR-032 iteration isolation and lifecycle ownership, plus ADR-019 exact-checkout and unrelated-work recovery constraints.
- Use the installed-package smoke surface; test behaviour through the packed artifact rather than asserting on source prose.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- RFC-075 — *Use available Codex capacity for isolated backlog iterations*, the release row on STORY-MAP-002 activity D, *Implement the changes*.
- Architecture review PASS, 2026-08-29: ADR-083, ADR-032, ADR-019, ADR-103; ADR-094 unchanged.
