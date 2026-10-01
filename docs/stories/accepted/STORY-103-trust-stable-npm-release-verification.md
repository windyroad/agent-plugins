---
status: accepted
story-id: trust-stable-npm-release-verification
reported: 2026-10-01
decision-makers: [Tom Howard]
problems: [P541]
jtbd: [JTBD-001, JTBD-007]
rfcs: [RFC-104]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-103: Trust stable npm release verification

## User value

In order to keep a successful release from leaving the pipeline red and blocking the next delivery, as a plugin developer, I want the release workflow to distinguish npm propagation delay from a real publication failure.

## Acceptance criteria

- [ ] Post-publish verification rechecks unresolved packages against the online registry within one shared, bounded release window and succeeds once every intended `latest` tag matches.
- [ ] A persistent mismatch fails within that one window regardless of the number of packages, with an accurate distinction between an absent published version and a version present without the expected `latest` tag.
- [ ] Behavioural tests cover late propagation, multiple unresolved packages, and both failure messages.
- [ ] Pre-publish collision checks still reject an immutable version that exists without the expected `latest` tag.

## Driving problem trace

P541 records repeated release failures after successful npm publication because the current verifier waits only 30 seconds per package for tag propagation. Release run 36803247881 is a further witness; its rerun passed after all five expected tags appeared.

## JTBD trace

JTBD-001 calls for governance that supports safe delivery without false blocks. JTBD-007 calls for installed plugins to stay current after publication.

## Dependencies

- **Blocked by**: (none)
