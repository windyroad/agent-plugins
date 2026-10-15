---
status: proposed
date: 2026-10-15
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:plan]
informed: []
reassessment-date: 2027-01-15
---

# Astro Starlight builds the public documentation

> Captured via /wr-architect:capture-adr. Derived from the confirmed docs-site
> objective and reviewed design; final substance remains unratified.

## Context and Problem Statement

Developers need searchable, mobile-readable public documentation for selecting
and using the plugin suite. Existing package sources are useful references but
are not a documentation website. The requested reference, Em See Pea, uses Astro
and Starlight for a static documentation interface.

## Decision Drivers

- Readers need navigation, search, mobile reading and stable page addresses.
- The site must remain maintainable in this repository.
- Documentation tooling must not become an installable plugin or alter runtime behavior.
- Existing public source and confidentiality boundaries remain binding.

## Considered Options

1. Astro with Starlight in a private website workspace.
2. Continue linking directly to repository Markdown without a documentation site.

## Decision Outcome

Chosen option: **Astro with Starlight in a private website/ workspace outside packages/***.
Use its standard documentation interface and static output. The workspace is
explicitly registered at the root and is not an npm plugin. Canonical package
sources remain authoritative; only selected public material may enter the site.

This proposal may guide authorized implementation. It does not assert human
ratification or acceptance. Hosting configuration and delivery order belong to
separate decisions and delivery records, respectively.

## Consequences

### Good

- Navigation, search and responsive documentation patterns reuse a maintained tool.
- Static output needs no application backend or reader account.
- The private workspace avoids plugin directory assumptions.

### Neutral

- Public guides and selected source references remain different documentation surfaces.

### Bad

- The repository gains documentation dependencies and build maintenance.
- Theme defaults still need actual browser and accessibility verification.
- Source changes can invalidate links or claims unless the build checks them.

## Confirmation

- [ ] Successful actual public use demonstrates readers can open nested pages,
  navigate and find plugin or skill guidance through search on mobile and desktop.
- [ ] Repository changes update this static documentation without changing
  installed plugin behavior.
- [ ] Explicit human ratification of the final substance supports acceptance.

No production-use evidence exists at capture.

## Pros and Cons of the Options

### Astro with Starlight

- Reuses the reference project's documentation architecture and standard controls.
- Adds a static build and dependency lifecycle that this repository must maintain.

### Repository Markdown only

- Adds no build or hosting maintenance.
- Leaves the confirmed searchable docs-site outcome unmet.

## Reassessment Criteria

Reassess if the framework prevents accessible core journeys, controlled source
selection or compatible repository builds, or if static output cannot serve the
confirmed documentation outcome. Review by 2027-01-15.
