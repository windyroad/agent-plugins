# Problem 557: No published skill supports outcome-led iterative planning

**Status**: Closed (closed-on-evidence 2026-10-15 - published `@windyroad/itil@3.1.0`, integrity-verified registry artifact and successful fresh native Claude Code/Codex invocations; see Verification. Recovery: rerun `/wr-itil:transition-problem 557 known-error` to reopen)
**Reported**: 2026-10-15
**Priority**: 10 (High) - Impact 2 × Likelihood 5. The development workflow cannot be reused through the published plugin because the capability is absent from its package.
**Origin**: internal
**Effort**: M - reuse the ITIL distribution path, qualify both skill projections, then publish and verify installation.
**WSJF**: 0 - Closed multiplier 0
**JTBD**: JTBD-008, JTBD-005
**Persona**: developer

## Description

Developers want an agent to keep a clear result objective, execute one detailed
Now release increment, retain provisional Next increments and high-level Later
direction, then verify, learn, replan and obtain architecture, JTBD and risk assessment
of each revised plan until the objective is achieved.

The reusable contract was created and tested as a personal skill. Reporting that
local artifact as the completed delivery omitted the expected repository,
publication and installed-plugin stages. At capture the published ITIL package
lacked the capability, so other installations could not discover or invoke it.

## Symptoms

- The planning workflow must be re-explained in individual chats.
- A local skill passes format and scenario checks but is absent from npm.
- Local creation is mistaken for completion of the expected plugin delivery.

## Workaround

The capability is available in `@windyroad/itil@3.1.0`. The actively used
personal skill was updated first and remains available; it matches the
released contract apart from its invocation name, with UI metadata preserved.

## Impact Assessment

- **Who is affected**: developers seeking reusable, adaptive delivery planning.
- **Frequency**: every installation of the package at capture lacked this skill;
  demand beyond the observed request has not been measured.
- **Severity**: development-workflow capability gap; no prior service regression,
  data loss or credential exposure observed.
- **Analytics**: one directly observed delivery request and correction.

## Root Cause Analysis

The initial delivery selected a personal skill directory as its endpoint rather
than completing the repository's established plugin distribution workflow.
At capture there was no canonical ITIL skill source or release vehicle for this
capability. The repair adds both and omits capture-specific delegation only
from the new planning skill; existing capture skills retain that behavior.

### Investigation Tasks

- [x] Identify the missing published surface and compare local and package scope.
- [x] Confirm ITIL ownership and the existing ratified story-map journey.
- [x] Capture the problem-traced release row and delivery story before implementation.
- [x] Qualify canonical and generated behavior, packing and isolated installation.
- [x] Verify publication and the installed skill from the exact released artifact.

## Close criteria

The stable npm package contains the canonical and Codex skill projections;
fresh installation exposes the new invocation; behavioral trials exercise the
planning/replanning and completion boundaries without unrelated delegation.
Local checks, implementation CI, publication and installed exercise must be
reported as distinct evidence.

## Dependencies

- **Blocks**: reusable plugin distribution of outcome-led planning.
- **Blocked by**: none; release-row/story capture, qualification, publication
  and fresh installed exercise are complete.
- **Composes with**: P554's implementation-first, release-preparation-later boundary.

## Related

- JTBD-008 (Decompose a Fix Into Coordinated Changes).
- JTBD-005 (Invoke Governance Assessments On Demand).
- Captured through the ITIL problem flow. Title and path searches found no
  existing ticket covering this absent skill; general skill-testing and
  story-map-rendering tickets describe different capabilities.

## RFCs

- RFC-106: Plan toward a verified outcome, on [the existing developer journey](../../story-maps/draft/STORY-MAP-002-take-a-problem-from-noticed-to-resolved.html).

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-106 | STORY-106: Keep my objective clear while I deliver, learn and replan | done |

## Fix Released

`@windyroad/itil@3.1.0`, release PR [#528](https://github.com/windyroad/agent-plugins/pull/528),
commit `d1f4a081194d69a99195694fdf1c55cdea0e144a`. The published skill establishes
and confirms a SMART objective, then uses INVEST-shaped Now increments,
provisional Next/Later and architecture, JTBD and risk review of each plan.

## Verification

- Implementation `d605e6c42ecc9f7ce516d5e643f6ffa1412e24f5` passed exact
  CI [38652395169](https://github.com/windyroad/agent-plugins/actions/runs/38652395169)
  before the separate cumulative changeset-only release preparation.
- Qualification passed 22 actual model scenarios across both projections and
  nine targeted harness/pack/install checks. The repaired two multi-turn
  interviews each produced three distinct exchanges. Invalid earlier interview
  evidence was excluded; the unchanged skill contract was re-exercised.
- Publication workflow [38656992826](https://github.com/windyroad/agent-plugins/actions/runs/38656992826)
  and release-merge CI [38656992744](https://github.com/windyroad/agent-plugins/actions/runs/38656992744)
  passed. Later CI quota preflights supply no additional model evidence.
- The fetched registry tarball matched npm SRI; fresh isolated installation
  exposed the skill in both runtimes. Claude Code 2.1.296 registered the exact
  installed 3.1.0 plugin and command. Codex 0.162.0 read the exact installed
  3.1.0 skill. Both native invocations exited successfully, played back the
  SMART goal and waited for confirmation before planning or implementation.
- [The terminal plan receipt](../../plans/557-outcome-led-planning.md) preserves
  artifact and native-transcript hashes, runtime session identifiers and the
  observed boundaries. These smoke trials do not prove live reviewer dispatch
  or hot-reload in already-running chats.

## History

- 2026-10-15 - Captured the missing published capability and accepted its
  problem-traced STORY-106/RFC-106 delivery vehicle on the existing ratified map.
- 2026-10-15 - Updated the actively used personal skill first, then integrated,
  qualified and released the canonical plugin contract.
- 2026-10-15 - Closed on the stated published-artifact and installed-exercise
  criteria. No further speculative increment is needed for this objective.
