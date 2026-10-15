---
status: accepted
story-id: find-plugin-instructions-on-my-phone
reported: 2026-10-15
decision-makers: [Tom Howard]
problems: [P558]
jtbd: [JTBD-003, JTBD-007]
rfcs: [RFC-107]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-107: Find the plugin and instructions I need on my phone

**Reported**: 2026-10-15
**Problems**: P558
**JTBD**: JTBD-003, JTBD-007
**RFCs**: RFC-107
**Story Maps**: STORY-MAP-008
**Estimated effort**: M - static site, controlled documentation build and verified deployment; provider configuration and browser findings remain uncertain.

## User value

In order to choose and use the guardrails relevant to my work wherever I am
reading, as a developer, I want searchable documentation with shareable plugin
and skill pages and clear installation guidance for my runtime.

## Acceptance criteria

- [ ] Public docs cover getting started, selective plugin discovery, plugin and
  skill reference including outcome-led planning, runtime guidance and updates.
- [ ] Explicit source allowlisting and artifact checks keep internal tickets,
  plans, audits, credentials and unapproved sources out of pages and search.
- [ ] Per-package guidance distinguishes Claude Code default support from
  qualified Codex behavior and preserves current maturity evidence where available.
- [ ] Built-site tests verify repository base paths, direct nested links, assets,
  reading without JavaScript, navigation, search and keyboard behavior.
- [ ] Mobile 320/390 and desktop 1280 viewport checks cover light/dark contrast,
  reflow, visible focus and the main reading/search/navigation journeys.
- [ ] The private website is isolated from plugin validation/npm publication;
  Pages deployment requires passing checks and confines elevated permissions to deployment.
- [ ] The public deployed URL and representative deep-link/search/install-guide
  journeys pass live verification. Repository updates maintain the site.

## Driving problem trace

P558 records the absent public docs journey. Local files, a source commit or a
preview alone cannot satisfy its public-deployment close criteria.

## JTBD trace

JTBD-003 supplies selecting relevant plugins and understanding their maturity.
JTBD-007 supplies maintained guidance across installations. Both jobs and the
developer persona are confirmed; existing STORY-MAP-008 covers choosing plugins.

## Implementation notes

Use a private website/ workspace outside packages/*. Keep the canonical package
sources authoritative; publish only explicitly selected public material. Build
and test safe increments before activation. Record new architectural choices as
proposed; do not assert final ratification or modify existing oversight markers.

## Dependencies

- **Blocked by**: none for bounded foundation work under the assessed proposal;
  public activation waits for its artifact, workflow and journey controls.
- **Blocks**: P558 closure until live acceptance.
