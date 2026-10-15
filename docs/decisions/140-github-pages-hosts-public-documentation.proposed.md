---
status: proposed
date: 2026-10-16
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:plan]
informed: []
reassessment-date: 2027-01-16
---

# GitHub Pages hosts the public documentation

> Captured via /wr-architect:capture-adr from the confirmed public documentation
> outcome and reviewed hosting proposal. Final substance remains unratified.

## Context and Problem Statement

The static documentation workspace needs a public HTTPS address that readers
can open and share from phones and desktops. Its source is maintained in the
public GitHub repository. The requested reference project also serves its static
documentation through GitHub Pages.

## Decision Drivers

- Readers need public nested page addresses, assets and browser search.
- Repository maintainers need a hosting route connected to source updates.
- Static documentation needs no application backend or reader account.
- Hosting should fit the repository's existing GitHub delivery environment.

## Considered Options

1. Host the static documentation on GitHub Pages.
2. Leave the built documentation without a public host.

## Decision Outcome

Chosen option: **GitHub Pages hosts the public documentation** at the repository's
default project-site address. The static build choice remains the separate
ADR-139 proposal. Delivery configuration and operational receipts belong to
the delivery plan and problem record.

This proposal may guide authorized implementation. It asserts neither final
human ratification nor successful production use.

## Consequences

### Good

- Public HTTPS pages and assets can be shared without a reader account.
- Hosting uses the repository's existing source and automation environment.
- Static output needs no separate application server to operate.

### Neutral

- Public page addresses include the repository's project-site path.

### Bad

- Documentation availability depends on GitHub Pages and its deployment service.
- Hosting settings and publication permissions become maintained repository state.
- Source updates require successful qualification and deployment before readers see them.

## Confirmation

- [ ] Successful public use demonstrates nested reading, navigation and browser
  search on mobile and desktop at the hosted site.
- [ ] A repository update reaches the public site with traceable source identity.
- [ ] Explicit human ratification of the final hosting decision supports acceptance.

No production-use evidence exists at capture. Local previews and green builds
alone do not satisfy these criteria.

## Pros and Cons of the Options

### GitHub Pages

- Fits the existing repository and static output, with public HTTPS access.
- Adds provider configuration and deployment-service dependence.

### No public host

- Adds no hosting state to maintain.
- Leaves the confirmed public documentation outcome unmet.

## Reassessment Criteria

Reassess if the host cannot serve the required nested pages, assets and search,
or if its availability or repository integration prevents maintained public
documentation. Review by 2027-01-16.
