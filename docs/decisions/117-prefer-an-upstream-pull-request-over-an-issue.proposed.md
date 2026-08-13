---
status: "proposed"
date: 2026-08-08
human-oversight: confirmed
oversight-date: 2026-08-08
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin adopters]
reassessment-date: 2026-11-08
---

# Prefer an upstream pull request over an issue when the upstream accepts pull requests

## Context and Problem Statement

`/wr-itil:report-upstream` can identify that a local problem belongs in another repository, but its only public reporting path is an issue. When a defensible fix is available, an issue leaves the work for the upstream maintainer while a pull request can deliver the fix directly.

The maintainer ratified this decision's substance on 2026-08-08. It was originally recorded as ADR-102 on the unmerged implementation branch, but current `main` already assigns ADR-102 to the canonical story-map renderer. This collision-free record preserves the ratified substance without modifying either ADR-102 or the confirmed decisions it builds on.

## Decision Drivers

- A fix accepted upstream benefits every downstream adopter.
- Most plugin adopters consume dependencies they do not own, so fork-and-pull-request must count.
- Reporting a symptom must remain sufficient; the reporter is not required to author a patch.
- Security disclosures must retain their private routing.
- Unattended work must not push code into a third party's repository.
- Pull-request prose must receive the same external-communications review as issue prose.

## Considered Options

1. **Prefer a pull request when the upstream accepts contributions (chosen)** - deliver a defensible fix directly, including through a fork.
2. **Prefer a pull request only with upstream write access** - simpler, but excludes ordinary third-party contribution.
3. **Keep the issue-only path** - lowest implementation cost, but preserves the one-way reporting queue.
4. **Allow AFK sessions to open pull requests** - higher throughput, but lets an unattended agent publish code under the user's identity.

## Decision Outcome

Chosen option: **Prefer a pull request wherever the upstream accepts them.**

When a local problem's fix belongs upstream, `/wr-itil:report-upstream` prefers a pull request if the upstream accepts contributions. The predicate is contribution acceptance, not write access; fork-and-pull-request is a normal successful path.

The skill reuses discovery it already performs. An archived or disabled repository, or an explicit statement that outside contributions are not accepted, means the issue path. `CONTRIBUTING.md` or a pull-request template is positive evidence. When the signal is absent or ambiguous, the skill defaults to accepting contributions rather than adding a probe or refusing the ordinary fork-and-pull-request path.

The skill files an issue instead when:

1. The upstream does not accept contributions.
2. The fix requires a design decision owned by the upstream maintainers.
3. The ticket is security-classified and must use the existing private disclosure route.
4. No defensible fix is available within three attempts or 20 minutes.

The fourth classification is mechanical and silent. The skill drafts the issue body first, attempts the pull request as an upgrade, and falls back to the drafted issue if patch preparation fails.

Deduplication searches both issues and pull requests and carries the matched artifact kind so an existing pull request receives `gh pr comment` rather than an issue command.

The pull-request body follows the upstream's pull-request template when present. Otherwise it uses a short `What this changes`, `Why`, and `Cross-reference` shape rather than the issue-oriented problem-report template.

Before `gh pr create`, the skill sends the combined title and body through the external-communications and voice-tone evaluators; the command hook independently enforces the body review. The skill also displays the full diff and names the upstream convention files it followed. The remaining absence of policy-aware scoring for a third-party diff is tracked by P497.

Under AFK execution, the pull-request branch degrades to the issue branch and queues the drafted contribution for the interactive return. An unattended session never opens a pull request against a repository the user does not own.

The `## Reported Upstream` section records disclosure path `pull request`. Consumers branch on that value:

- response polling uses `gh pr view`;
- lifecycle updates use `gh pr comment`;
- local closure never runs `gh pr close`;
- legacy tickets with no disclosure path remain issues without an extra probe.

This decision adds behavior alongside ADR-024 and ADR-033. It does not amend their confirmed files.

## Consequences

### Good

- A ready fix can reach all upstream adopters instead of waiting as an issue.
- The path works for third-party dependencies through forks.
- Failed pull-request attempts still produce an issue, so the original report is not lost.
- Existing issue, security, polling, and lifecycle paths remain explicit fallbacks.

### Neutral

- A pull-request report spans two repositories and waits on upstream review.
- Pull-request prose may be reviewed again after an issue-shaped draft because the gate key includes the surface.

### Bad

- Preparing and validating a contribution costs more time and quota than filing an issue.
- No current scorer evaluates a diff against a third party's contribution policy; P497 remains open.
- Operator-level hooks can interfere with work in the upstream checkout.

## Pros and Cons of the Options

### Prefer a pull request wherever the upstream accepts them (chosen)

- Good, because it unblocks repositories we own and genuine third-party dependencies under one rule.
- Good, because fork-and-PR needs no permission we have to negotiate for.
- Good, because the prose gate already covers the new surface with no change.
- Bad, because it commits the loop to a second repository's gates, conventions and release cadence.
- Bad, because it opens a diff surface nothing currently scores.

### Prefer a pull request only where we hold write access

- Good, because it is the smaller change and needs no fork handling.
- Bad, because it makes the feature a no-op for most adopters, who are consumers rather than owners.
- Bad, because it repeats the failure mode ADR-024 already rejected in its Option 4.

### Keep the issue-only path

- Good, because it costs nothing to adopt and the machinery already works.
- Bad, because it preserves a backlog of one-way reports whose ready fixes never land.

### Prefer a pull request and let the AFK loop open it unattended

- Good, because it maximises loop throughput and needs no interactive return.
- Bad, because it lets a prose-only gate authorise code into a third party's repository under our name, which JTBD-006 rules out.

## Confirmation

- The report skill prefers a pull request based on contribution acceptance, not write access.
- All four fallback conditions produce the issue or security path without asking the reporter to write a patch.
- The pull-request path respects upstream templates and displays the outgoing diff.
- AFK execution opens no third-party pull request.
- Poll, catch-up, deduplication, comment, and local-closure behavior distinguish issues from pull requests.
- Legacy tickets with no disclosure path make one issue API call and no probe.
- Behavioral BATS and promptfoo cases cover acceptance, fallback, AFK, security, polling, and lifecycle behavior.

## Reassessment Criteria

Reassess if upstream maintainers consistently prefer issues to unsolicited pull requests, contribution preparation consumes more value than it delivers, or a rejected/reverted contribution demonstrates that P497 must become a precondition.

## Related

- [ADR-024](./024-cross-project-problem-reporting-contract.proposed.md) - existing cross-project reporting contract.
- [ADR-033](./033-report-upstream-classifier-problem-first.proposed.md) - issue-body classifier retained on the issue branch.
- [ADR-116](./116-ratified-decisions-change-only-by-supersession.proposed.md) - confirmed decision files remain unchanged.
- [P497](../problems/open/497-upstream-pull-request-diff-is-unscored.md) - remaining diff-scoring gap.
