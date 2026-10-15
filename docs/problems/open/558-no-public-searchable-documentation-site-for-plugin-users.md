# Problem 558: No public searchable documentation site for plugin users

**Status**: Open
**Reported**: 2026-10-15
**Priority**: 8 (Medium) - Impact 2 × Likelihood 4. Readers must navigate repository Markdown or local paths to find plugin and skill guidance on phones; broader demand has not been measured.
**Origin**: internal
**Effort**: M - reuse static documentation tooling, qualify content and deploy through repository automation.
**WSJF**: 4 - (8 × Open multiplier 1.0) / 2
**JTBD**: JTBD-003, JTBD-007
**Persona**: developer

## Description

A developer choosing and using Windy Road Agent Plugins has no public docs site
with search, mobile reading and shareable plugin and skill pages. A local skill
path cannot be opened from an iPhone, and GitHub Markdown does not supply the
requested documentation journey. This is missing functionality, with no observed
interruption of an established docs service.

The user confirmed a public site comparable to Em See Pea's navigation, search
and mobile reading, covering plugin and skill discovery and accurate Claude
Code/Codex installation guidance, maintained from this repository. Deadline:
end of Sunday 18 October 2026, Australia/Sydney.

## Workaround

Read the public package README and skill sources on GitHub. These links are
shareable but do not provide the requested searchable documentation website.

## Root Cause Analysis

Documentation is distributed across package sources without a public static
site, a controlled content build or a deployment/verification workflow.

## Investigation Tasks

- [x] Confirm the requested objective and deadline with the user.
- [x] Inspect the reference site architecture and current repository boundaries.
- [x] Review the plan against architecture, jobs and risk policy.
- [x] Build a private website workspace outside plugin package directories.
- [x] Qualify selected public content, search, runtime guidance and accessibility locally; exact trunk CI and live acceptance remain separate gates.
- [ ] Deploy the approved artifact and verify live mobile and desktop journeys.

## Close criteria

The public deployed site supports reading, plugin/skill discovery, shareable deep
links, search and runtime-specific installation guidance. Verify key journeys on
mobile and desktop, source-to-site maintenance and deployment controls. Build,
CI, deployment and live journey evidence are distinct. Do not close on a local
preview or a published workflow alone.

## Dependencies

- **Blocked by**: controlled site build, content qualification and deployment.
- **Composes with**: existing plugin installation and documentation sources.

## Related

Fresh hang-off review returned PROCEED_NEW. P152 addresses documentation-currency
nudges, P493 docs-only CI cost and P524 disclosure in ticket history; none covers
creating the requested public documentation website. The public build must not
expose that history or other internal planning sources.

## RFCs

- RFC-107: Find plugin documentation from any device, on STORY-MAP-008.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-107 | STORY-107: Find the plugin and instructions I need on my phone | accepted |
