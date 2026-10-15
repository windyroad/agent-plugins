---
status: done
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
**Estimated effort**: M - static site, controlled documentation build and verified public deployment.

## User value

In order to choose and use the guardrails relevant to my work wherever I am
reading, as a developer, I want searchable documentation with shareable plugin
and skill pages and clear installation guidance for my runtime.

## Acceptance criteria

- [x] Public docs cover getting started, selective plugin discovery, plugin and
  skill reference including outcome-led planning, runtime guidance and updates.
- [x] Explicit source allowlisting and artifact checks keep internal tickets,
  plans, audits, credentials and unapproved sources out of pages and search.
- [x] Per-package guidance distinguishes Claude Code default support from
  qualified Codex behavior and preserves current maturity evidence where available.
- [x] Built-site tests verify repository base paths, direct nested links, assets,
  reading without JavaScript, navigation, search and keyboard behavior.
- [x] Mobile 320/390 and desktop 1280 viewport checks cover light/dark contrast,
  reflow, visible focus and the main reading/search/navigation journeys.
- [x] The private website is isolated from plugin validation/npm publication;
  Pages deployment requires passing checks and confines elevated permissions to deployment.
- [x] The public deployed URL and representative deep-link/search/install-guide
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

- **Blocked by**: none; artifact, workflow and public journey controls are verified.
- **Blocks**: none; live acceptance and P558 closure are recorded.


## Delivery evidence

Source `29f566b63b74496fb68bfc3dca5a24e9e2d56c62` passed exact CI
38748545880 and Pages deployment 38750360372. The public site at
<https://windyroad.github.io/agent-plugins/> covers 13 packages and 62 skills
across 80 documentation pages. The actual publication artifact passed 23
unit/artifact/configuration/guard tests and four browser tests.

All 80 public routes returned HTTP 200. Live Chromium 320/390/1280 checks in both
themes and WebKit phone emulation in both themes passed reading, search,
status updates, keyboard/focus, navigation, deep links and installation-guide
journeys. No-JavaScript reading and native mobile navigation passed. Independent
public phone verification passed in both engines. These checks do not establish
physical-device, spoken screen-reader or operating-system clipboard behavior.

The live home hash matches the exact CI artifact; independent review of the
downloaded deployment tar found no private content and confirmed the reference
metadata. Local and CI bytes differ and are not treated as identical. The main-only
Pages environment and actual build/deployment permission logs were inspected.
Maintenance and rollback guidance live in website/README.md.

See [P558 verification](../../problems/closed/558-no-public-searchable-documentation-site-for-plugin-users.md)
and [the terminal plan receipt](../../plans/558-public-documentation-site.md).
