---
status: "proposed"
date: 2026-08-27
human-oversight: confirmed
oversight-date: 2026-08-27
oversight-note: "2026-08-27 - Tom Howard selected 'Owned issues only' from the rendered options: close both issue directions on evidence; close neither on evidence; or close only cache-proven owned GitHub issues. The selected option keeps foreign issues open on local evidence, fails closed for ambiguous or non-issue inbound channels, and keeps pull requests comment-only."
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: [Windy Road plugin users, Windy Road plugin developers]
reassessment-date: 2026-11-27
supersedes: ["ADR-024 (in part - issue lifecycle closure authority)"]
---

# Owned tracker issues close on evidence

## Context and Problem Statement

The lifecycle-update skill receives an untyped `inbound-reported (#NN)` origin for reports discovered from GitHub issues and discussions. Treating `#NN` as an issue without provenance can mutate an unrelated issue whose number collides with a discussion. Separately, evidence-backed local closure needs different authority on a tracker this project owns and a tracker maintained by another party.

The existing cross-project reporting contract closes inbound and outbound issues without distinguishing tracker ownership or proving that an inbound number denotes a GitHub issue. This decision replaces only that closure-authority portion of the contract.

## Decision Drivers

- Never mutate an external system from an ambiguous identifier.
- Keep this project's issue tracker consistent with evidence-backed local state.
- Respect another maintainer's authority over their tracker.
- Preserve reporter-visible lifecycle comments and reopen paths.
- Keep pull-request handling comment-only.

## Considered Options

1. **Close only provenance-proven owned GitHub issues on evidence** - require one exact committed issue-channel cache record for the current repository, issue number, and local ticket; close that issue after the gated lifecycle comment. Leave foreign issues open on local evidence alone, but allow the upstream party's confirmation to authorize closure. Fail closed for unresolved, discussion, advisory, repository-mismatched, or ambiguous provenance. Pull requests remain comment-only. **Draft selection.**
2. **Close issues in both directions on evidence** - close owned and foreign issues whenever the local ticket closes, while leaving pull requests comment-only.
3. **Close neither direction on evidence** - post lifecycle comments but require an external person's confirmation before closing either an owned or foreign issue.

## Decision Outcome

Draft chosen option: **Close only provenance-proven owned GitHub issues on evidence.**

Before any inbound `gh issue view`, `gh issue comment`, or `gh issue close`, the lifecycle-update path must resolve the current repository and require exactly one record under `github-issues:<current-repository>` in the committed upstream cache where `number` equals the inbound origin number and `matched_local_ticket` equals the current problem ticket. Zero or multiple matches, a different repository, a discussion or advisory channel, or any other unresolved provenance returns `inbound-channel-unresolved` and performs no issue mutation.

After that guard and the existing external-communications gates, an evidence-backed local close also closes the proven issue on this project's tracker. The reporter can reply or reopen if the problem persists.

For an issue on another maintainer's tracker, local evidence alone authorizes a lifecycle comment but not closure. Confirmation from that upstream party may authorize closure; their word supplies the missing authority. Pull requests are always comment-only.

## Consequences

### Good

- Issue-number collisions cannot mutate an unrelated issue.
- Owned issue state reflects evidence-backed local resolution.
- Foreign tracker state remains under its maintainer's control.

### Neutral

- An inbound lifecycle update now depends on the committed discovery cache as provenance evidence.
- Discussion and advisory lifecycle updates need their own typed dispatch paths.

### Bad

- A valid issue with missing or stale cache provenance remains untouched until discovery repairs the record.

## Confirmation

- A behaviour test proves that one exact `github-issues:<current-repository>` cache match permits the inbound comment and evidence-backed close.
- A behaviour test proves that a discussion with the same number as an issue returns `inbound-channel-unresolved` and performs no `gh issue` mutation.
- Zero, multiple, repository-mismatched, advisory, and non-matching-ticket records fail closed before every inbound issue read, comment, or close.
- An evidence-backed close comments on but does not close a foreign issue; upstream-party confirmation permits closure.
- Pull-request targets never execute a close command.
- Published plugin instructions state these rules without source-repository identifiers.

## Pros and Cons of the Options

### Close only provenance-proven owned GitHub issues on evidence

- Good: aligns mutation authority with tracker ownership and proves the target's channel first.
- Bad: adds a cache-provenance precondition to inbound lifecycle updates.

### Close issues in both directions on evidence

- Good: keeps every linked tracker aligned with local state automatically.
- Bad: writes closure to another maintainer's tracker without their decision.

### Close neither direction on evidence

- Good: never treats local evidence as authority over an external issue.
- Bad: leaves this project's resolved issues open indefinitely when reporters do not return.

## Reassessment Criteria

Reassess if the origin field becomes channel-typed, the cache schema changes, GitHub provides a unified lifecycle primitive across issues and discussions, or operational evidence shows the fail-closed guard routinely blocks valid issue updates.

## Related

- ADR-024 - the cross-project problem-reporting contract superseded here only for issue lifecycle closure authority.
- ADR-062 - the multi-channel inbound discovery pipeline that writes the provenance cache.
- ADR-116 - confirmed decisions change through supersession rather than amendment.
- P525 - the corrective-feedback problem that exposed the unsafe and over-broad closure rule.
