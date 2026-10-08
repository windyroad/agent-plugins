---
status: done
story-id: classify-deficiencies-before-incident-declaration
reported: 2026-10-08
decision-makers: [Tom Howard]
problems: [P555]
jtbd: [JTBD-001]
rfcs: [RFC-105]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-104: Route initial deficiencies to problem management and service regressions to incident management

## User value

In order to address capability gaps without a restoration process, as a developer, I want initial deficiencies investigated as problems and observed regressions handled as incidents.

## Acceptance criteria

- [x] New incident declarations require an observed interruption or degradation of an existing service with an established prior working baseline.
- [x] Missing or incomplete features, deficiencies present from outset, and initially slow performance route to problem management without incident creation or restoration ceremony.
- [x] An unknown baseline prompts evidence gathering through problem investigation, not an assumed regression.
- [x] A previously fast or working service becoming slow or unavailable retains incident routing, even in an otherwise unfinished product.
- [x] Four behavioral evaluation scenarios run locally and in CI; installed Claude and Codex skill artifacts match the release.

## Driving problem trace

P555 records the human correction after an unfinished website was treated as an incident for initial slowness without evidence of a prior service baseline.

## Dependencies

- **Blocked by**: (none); approval derives from the existing confirmed STORY-MAP-002 backbone.

## Delivery evidence

Implementation 4db9ddba delivered the eligibility contract and four routing evaluations. ITIL 3.0.1 was published through PR526 and installed in Codex and existing Claude registrations. Implementation, preparation, release PR and final merge CI passed; 59 scoped checks and four local routing decisions passed. Installed Codex skills match the published tarball and the Claude skill matches reviewed release source. This completes the story's stated criteria; affected-chat adoption remains on P555's verification queue.

**Done**: 2026-10-08
