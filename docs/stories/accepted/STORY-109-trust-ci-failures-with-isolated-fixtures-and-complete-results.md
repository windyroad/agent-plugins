---
status: accepted
story-id: trust-ci-failures-with-isolated-fixtures-and-complete-results
reported: 2026-10-16
decision-makers: [Tom Howard]
problems: [P459]
jtbd: [JTBD-001, JTBD-008, JTBD-101]
rfcs: [RFC-109]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-109: Trust CI failures with isolated fixtures and complete results

**Reported**: 2026-10-16
**Problems**: P459
**JTBD**: JTBD-001, JTBD-008, JTBD-101
**RFCs**: RFC-109
**Story Maps**: STORY-MAP-002, activity `implement`
**Estimated effort**: S, bounded existing evaluation driver, result transport and CI artifact changes.

## User value

In order to diagnose CI failures without confusing hypothetical proposals with the plugin repository, as a developer, I want isolated evaluation fixtures and complete model responses and grading results when checks fail.

## Acceptance criteria

- [ ] The Claude architect evaluation uses the existing isolated fixture repository, exact agent prompt and model, and read-only fixture inspection without ambient settings, hooks or MCP configuration.
- [ ] Existing agent suites and CI skill checks retain complete structured responses and grading results in designated audit JSON artifacts, excluding credentials, environment dumps and runtime configuration.
- [ ] Behavioral checks exercise subprocess isolation, result transport and serialization, and preserve nonzero provider and evaluation failures; existing scenarios, assertions, model roles and retry policies remain unchanged.
- [ ] A meaningful new source revision passes the exact required CI, including the original incident eligibility group; a passing execution does not explain the unavailable first failing response.

## INVEST assessment

This independently testable developer-tool repair restores meaningful evaluation context and diagnostics. Means remain negotiable within those evidence requirements. Scope is small and bounded to existing drivers, command transport, CI outputs and behavioral checks. Native generation remains subject to model quota; provider rejection is not passing evidence. No production agent, skill, hook or authority changes are included.

## Driving problem trace

P459 already records the same unique-primary-key over-fire case and missing full failure evidence. The current two failed attempts expose these remaining mechanisms without proving that every failure is sampling variance.

## JTBD trace

JTBD-001 requires trustworthy governance evidence. JTBD-008 keeps this repair separate from the planning capability. JTBD-101 requires meaningful contributor validation.

## Implementation notes

Plan G6a passed independent architecture, JTBD and plan-risk review. Preserve STORY-101's model-pinning scope. Use existing fixture data and read-only tools, retain all current oracles and nonzero outcomes, and upload only designated result JSON. No unchanged-revision retry is included.

## Dependencies

- **Blocked by**: none.
- **Blocks**: final planning capability publication while required trunk CI is failed.
