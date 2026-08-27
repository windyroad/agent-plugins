---
status: accepted
story-id: publish-packages-without-expiring-secrets
reported: 2026-08-28
decision-makers: [Tom Howard]
problems: [P284]
rfcs: [RFC-073]
jtbd: [JTBD-002]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-067: Publish packages without expiring secrets

## User value (INVEST Valuable)

In order to ship releases without credential-expiry outages, as a maintainer, I want npm to trust the exact GitHub Actions workflow that publishes each package instead of relying on a long-lived repository secret.

## Acceptance criteria (INVEST Testable)

- [ ] Stable and preview packages publish from the single `.github/workflows/release.yml` workflow through npm Trusted Publishing/OIDC.
- [ ] The workflow uses a supported Node and npm version, requests `id-token: write`, and contains no npm token secret references.
- [ ] A regression check fails if a second publish workflow or long-lived npm token reference returns.
- [ ] The previously unpublished package versions publish with npm provenance and the fixed risk-scorer version is installed from npm.
- [ ] Obsolete GitHub npm secrets and npm access tokens are removed after OIDC publication succeeds.

## Driving problem trace

P284 recurred when the replacement npm token expired, again masking an unauthorized write as E404 and leaving package versions committed but unpublished.

## JTBD trace

- **JTBD-002**: the maintainer can ship with confidence because the release identity is short-lived, repository-bound, and verified by the registry.

## Implementation notes

ADR-122 selects one workflow because npm permits one trusted GitHub Actions publisher per package. Keep stable and preview publication in that workflow and remove the token fallback.

## Dependencies

- **Blocks**: canonical publication of the versions committed by release PR #451.
- **Blocked by**: npm Trusted Publisher configuration for all published `@windyroad/*` packages.

## Related

- STORY-MAP-002 - Take a problem from noticed to resolved
- RFC-073 - Publish packages without expiring secrets
- P284 - Release pipeline E404 on unauthorized npm writes
