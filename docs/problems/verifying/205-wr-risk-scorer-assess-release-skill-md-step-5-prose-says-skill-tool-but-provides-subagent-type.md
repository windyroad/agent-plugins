# Problem 205: wr-risk-scorer:assess-release SKILL.md step 5 prose says "Skill tool" but provides subagent_type

**Status**: Verifying
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `wr-risk-scorer:assess-release` SKILL.md step 5 contains a contract violation in its delegation prose. The text reads *"Invoke the pipeline subagent via the `Skill` tool"* but provides `subagent_type: wr-risk-scorer:pipeline` (an Agent-tool parameter, not a Skill-tool parameter). Following the prose verbatim with the Skill tool fails because there is no SKILL named `wr-risk-scorer:pipeline` — only the AGENT subagent_type carries that identifier.

The same prose-vs-parameter contradiction appeared in `assess-wip` step 3 (`subagent_type: wr-risk-scorer:wip`) and `assess-external-comms` step 4 (`subagent_type: wr-risk-scorer:external-comms`), and a hedged "Skill / Agent tool" wording appears in `assess-inbound-report`.

## Workaround (pre-fix)

Recognise the mismatch and use the Agent tool with `subagent_type: wr-risk-scorer:pipeline`. The prose intent is the Agent tool; the "Skill tool" naming is the documentation defect.

## Impact Assessment

- **Who is affected**: every agent or maintainer following the SKILL.md verbatim. JTBD-301/JTBD-302 trust contract violated.
- **Frequency**: every `/wr-risk-scorer:assess-release` invocation.
- **Severity**: Moderate (verbatim-following fails; recoverable by recognising intent).

## Root Cause Analysis

The user ratified Option A on 2026-06-07: make REALITY match ADR-015's Confirmation (which names the Skill tool literally). For each governance scoring/review agent currently invoked via the Agent tool, provide an INVOKABLE SKILL wrapper named with the same identifier (e.g. `wr-risk-scorer:pipeline`) so the consumer SKILLs can call `skill: wr-risk-scorer:pipeline` matching ADR-015 verbatim.

### Investigation Tasks

- [x] Re-rate Priority and Effort — deferred; Priority/Effort retained pending next /wr-itil:review-problems.
- [x] Fix `packages/risk-scorer/skills/assess-release/SKILL.md` step 5 prose — changed parameter to `skill: wr-risk-scorer:pipeline`; new wrapper SKILL `packages/risk-scorer/skills/pipeline/SKILL.md` provides the Skill-tool surface.
- [x] Audit other SKILL.md files for the same prose-vs-parameter mismatch — found and fixed `assess-wip` (step 3) and `assess-external-comms` (step 4); created wrapper SKILLs `wip/` and `external-comms/`.
- [x] Behavioural test guard added — `packages/risk-scorer/skills/assess-release/test/assess-skills-delegate-via-skill-tool.bats` (18 tests pass).
- [x] ADR-002 inventory tree refreshed.

### Slice 1 done (2026-06-07)

Slice 1 wraps the risk-scorer trio (`pipeline`, `wip`, `external-comms`). Consumer SKILLs (`assess-release`, `assess-wip`, `assess-external-comms`) flipped to `skill:` delegation. Wrapper SKILLs created at `packages/risk-scorer/skills/{pipeline,wip,external-comms}/SKILL.md`.

### Phase 2 — queued

The full migration of all six governance agents named in ADR-015's Scope table is queued as a follow-on:

- `wr-risk-scorer:inbound-report` (assess-inbound-report consumer SKILL — currently uses hedged "Skill / Agent tool" wording).
- `wr-architect:agent` (review-design consumer SKILL — wraps the architect agent).
- `wr-jtbd:agent` (review-jobs consumer SKILL — wraps the jtbd agent).

Phase 2 is tracked here; will be lifted to a separate ticket if WSJF priority warrants. Mixed state in the interim: 3 of 6 SKILL contracts now match ADR-015 Confirmation verbatim; 3 remain via Agent tool with the historical contradiction. No regression — Phase-1 consumers route correctly; Phase-2 consumers still work via the existing Agent-tool workaround.

### Outstanding sub-decisions queued

- Naming convention reconciliation — the wrapper SKILLs (`pipeline`, `wip`, `external-comms`) use noun-only names matching ADR-015 Confirmation literal text. This deviates from ADR-010's `<verb>-<noun>` convention. Either (a) amend ADR-010 to permit noun-only names for agent-wrapper SKILLs, or (b) rename wrappers to `score-pipeline` / `score-wip` / `review-external-comms-draft` and amend ADR-015's Confirmation accordingly. Captured for future ADR work.
- Dual-surface architecture — the wrapper-SKILL-around-agent pattern is novel relative to ADR-011 (which wraps SKILL around agent for discoverability, not for Skill-tool routing from peer SKILLs). May warrant a new ADR documenting the canonical surface, drift prevention between wrapper and agent, and test responsibility (currently tests assert the wrapper-to-agent contract structurally; behavioural verification via promptfoo is queued under ADR-075).

## Dependencies

- **Composes with**: ADR-015 (governance skills delegate to subagent / skill fallback), ADR-051 (README-content-currency — extends to SKILL.md prose).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/110
- **Pipeline classification**: JTBD-aligned (JTBD-301/JTBD-302/JTBD-101); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.
