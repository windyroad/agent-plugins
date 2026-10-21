---
status: "proposed"
date: 2026-10-22
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:plan]
informed: []
reassessment-date: 2027-01-22
---

# Owned context for isolated tabletop skill evaluations

> Captured via /wr-architect:capture-adr. Substance was derived from the in-session decision context; human-oversight remains unconfirmed until ratification through /wr-architect:review-decisions after successful actual production-use evidence is available.

## Context and Problem Statement

[ADR-075](075-promptfoo-agent-prose-verdict-eval-harness.proposed.md) requires appended system context for skill evaluations so their sessions can traverse the skill graph. The planning tabletop evaluator instead disables tools, MCP servers and caller settings, supplies a simulated reference date and asks for described decisions. Its subject appends that contract to native context, while its grader owns its system context. Three graded responses resolved Friday against the process date rather than the supplied simulated date. This establishes a context asymmetry; it does not establish the model's internal cause or a product calendar defect.

## Decision Drivers

- Subject and grader need a consistent, controlled simulated context.
- Evidence about actual skill-graph and native execution must retain its runtime context.
- Existing fixtures, grading criteria, authority boundaries and architecture history must remain intact.

## Considered Options

1. **Owned context for isolated tabletop evaluations (chosen)**: supply the complete evaluator contract as the subject's system prompt within this evaluation class.
2. **Appended context for every skill evaluation (rejected for this class)**: preserve native context even when tools and graph traversal are disabled.

## Decision Outcome

Chosen option: **"Owned context for isolated tabletop evaluations"**, because this evaluation class needs control of its simulated context and does not execute a skill graph.

This proposal takes precedence over only ADR-075's SKILL-provider append rule for isolated, tool-free simulated tabletop evaluations. Their subject uses the owned system contract, with its supplied fixture and skill instructions. ADR-075's appended-context rule remains applicable to actual skill-graph execution; native execution retains its native runtime context. ADR-075's ratified body remains unchanged.

This is a proposed scoped exception under [ADR-136](136-implementation-against-proposed-adrs.proposed.md). Authorized implementation can test it while its status remains proposed and its human oversight unconfirmed.

## Consequences

### Good

- Subject and grader can use the same controlled simulated context.
- The boundary between tabletop reasoning and actual runtime evidence is explicit.

### Neutral

- The existing harness, role models, fixtures and grading criteria remain in use.

### Bad

- Isolated outputs cannot establish actual graph traversal or native execution.
- Owning the context does not guarantee that a model follows every instruction; observed failures still need diagnosis.

## Confirmation

Confirmation requires actual maintainers to use controlled tabletop results alongside separately verified native evidence in real plugin maintenance and delivery. The selected context and reported evidence limits must remain accurate in that operational use. No successful actual production-use evidence is recorded at capture. Local tests, CI and synthetic evaluations alone do not satisfy this confirmation or grant acceptance.

## Pros and Cons of the Options

### Owned context for isolated tabletop evaluations

- Good, because the evaluator controls the simulated context consistently.
- Bad, because the result has narrower runtime fidelity and cannot prove native or graph behavior.

### Appended context for every skill evaluation

- Good, because native context remains available for skill-graph traversal.
- Bad, because isolated simulated fixtures retain ambient context that can conflict with the supplied reference state.

## Reassessment Criteria

Reassess if controlled fixture context still diverges, the isolated class needs actual graph traversal, or tabletop evidence is mistaken for native execution evidence.
