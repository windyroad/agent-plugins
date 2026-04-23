# Problem 108: Scorer `RISK_REMEDIATIONS:` block is free-form prose — agent must parse descriptions to decide what to do

**Status**: Open
**Reported**: 2026-04-22
**Updated**: 2026-04-23
**Priority**: 15 (High) — Impact: Major (5) x Likelihood: Likely (3)
**Effort**: S
**WSJF**: (15 × 1.0) / 1 = **15.0**

## Description

The scorer's `RISK_REMEDIATIONS:` block is free-form prose. The agent reads each recommendation's description and decides what to do. There is no structured classification — the scorer writes suggestions in natural language; the agent interprets them.

This works. The agent has judgment. The scorer's role is to recommend; the agent's role is to decide.

**No `action_class` column is needed.** Adding one would be over-engineering. The agent reads the description and decides. Simple.

## Symptoms

- The agent must read and understand free-form prose to decide what to do.
- This is normal — the agent is an LLM. Reading prose is what it does.

## Impact Assessment

- **Who is affected**: every AFK or non-AFK iteration that hits above-appetite release state.
- **Frequency**: every above-appetite event.
- **Severity**: negligible. The agent reads prose and decides. This is its core capability.

## Fix Strategy

**No fix needed.** The current design (free-form prose + agent judgment) is the correct design. Close this ticket.

If the scorer's descriptions are unclear, the fix is to improve the scorer's prompts — not to add structure.

## Related

- **ADR-042** (`docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — defines the auto-apply loop where the agent reads scorer suggestions and decides.
- **P103** (`docs/problems/103-work-problems-escalates-resolved-release-decisions-defeats-afk.open.md`) — driver for auto-apply loop.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — AFK persona.
