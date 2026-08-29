# Problem 525: An agent-invented carve-out leaves our own tracker issues open forever

**Status**: Verification Pending
**Reported**: 2026-08-26
**Priority**: 16 (High) — Impact: 4 (Significant — our issue tracker stops reflecting reality; every inbound report that reaches evidence-based closure stays open indefinitely, and nothing enumerates it) × Likelihood: 4 (Likely — fires on every inbound-reported ticket that closes on agent evidence)
**Origin**: corrective-feedback (user, 2026-08-26)
**Effort**: M
**WSJF**: 16 — (16 × 2.0) / 2
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

P519 landed a carve-out on `main` in commit `471e3205` but has not been published: `@windyroad/itil` remains at 2.0.0 and the pending Version Packages PR #451 targets 2.1.0. The change says that when a problem ticket closes on the agent's own cited evidence rather than the reporter's confirmation, `/wr-itil:update-upstream` posts a lifecycle comment and does **not** run `gh issue close` — on either the outbound leg (an issue we filed elsewhere) or the inbound leg (an issue someone filed on our own repo).

The user rejected this directly on 2026-08-26: *"well that is shite. It needs to close the gh issue"*.

The carve-out is wrong, and the reasoning that produced it does not survive inspection:

1. **Its authority was never ratified.** It was built on P500, which carries `**Origin**: internal` — agent-captured, never confirmed by the maintainer. An agent invented the constraint and then a later agent implemented it as though it were settled policy.
2. **P519 removed the promise the guard existed to honour.** The same change struck "we'll close this issue after your confirmation OR after a 14-day quiet period" from the comment templates, because no sweep ever delivered the quiet period (P520). Having removed the published promise, the guard protecting it had nothing left to protect.
3. **Closing is not destructive.** GitHub permits anyone to reopen. "Closed" on a maintainer's tracker states what the maintainer believes, not what the reporter has agreed.
4. **The alternative is unbounded growth.** Reporters frequently do not return — JTBD-301's own persona constraint is that "reporting is incidental". An issue that only the reporter can close therefore stays open forever, and the tracker degrades for everyone browsing it.

P520 was captured to build a quiet-period sweep that would eventually close these. If the close simply happens, most of P520 dissolves.

## Symptoms

- An inbound-reported ticket reaches `.closed.md` locally; the originating issue on our own repo stays open with only a comment.
- Nothing local enumerates the ticket afterwards — it has left the Verification Queue.
- The tracker accumulates open issues for problems we consider resolved.

## Workaround

Close the issue by hand after an evidence-authorised local close.

## Impact Assessment

- **Who is affected**: anyone reading our issue tracker, including prospective reporters who see stale open issues; maintainers who lose tracker fidelity.
- **Frequency**: every inbound-reported ticket closing on agent evidence.
- **Severity**: no shipped code misbehaves; the cost is a tracker that stops telling the truth.

## Root Cause Analysis

Two compounding failures. An unratified agent-captured ticket (P500) was treated as settled policy by a later agent. Then P519 struck the published promise that was the guard's only justification, without re-examining whether the guard should survive it — so the change shipped internally inconsistent.

### Investigation Tasks

- [x] Establish the maintainer's direction: close provenance-proven GitHub issues on our own tracker after an evidence-backed local close; leave foreign issues open on our evidence alone; fail closed for unresolved, discussion, and advisory origins; keep pull requests comment-only. ADR-121 ratifies that direction.
- [x] Implement ratified ADR-121: close only provenance-proven issues on this repository after evidence-backed local closure; fail closed when the channel cannot be proved; leave foreign issues open unless the upstream party confirms closure; keep pull requests comment-only.
- [x] Guard the inbound close with exact repository, issue-channel, and local-ticket provenance from the committed cache.
- [x] Re-point P500 to foreign-tracker authority and re-scope P520 to the remaining direct evidence-close paths that skip reporter lifecycle updates.
- [x] Update the paired promptfoo cases — they currently assert the carve-out and will fail correctly once it is reversed. Covers `update-upstream` (the inbound case inverted; the outbound case's rubric widened to accept tracker ownership as the primary reason) and `transition-problem` (its P519 case describes a ticket carrying BOTH an inbound Origin and a `## Reported Upstream` entry, so under I7 its blanket "the upstream issue is NOT closed" rubric would fail a leg-correct answer — split by leg).
- [x] Check channel and security scope. Security advisories use a separate `ghsa_id` path and are unreachable from the numeric issue dispatcher. GitHub discussions do share numeric IDs with issues, so `#NN` alone is unsafe and every inbound issue mutation needs a unique issue-channel cache proof.

Raised by the architect and JTBD gates while landing the skill change, and deferred here rather than guessed — each needs the maintainer, so none could be discharged in an AFK session:

- [x] Draft and ratify ADR-121, recording the considered options and the maintainer's “Owned issues only” selection.
- [x] Align STORY-066, STORY-031, STORY-MAP-002, and STORY-MAP-004 with ADR-121; reuse RFC-072 and STORY-066 rather than adding duplicate delivery artefacts.
- [x] Amend STORY-031 and STORY-MAP-004 so confirmation authorizes closure only on a foreign tracker; preserve their existing value statements.
- [x] Reuse the existing RFC-072 / STORY-066 delivery row and add P525's trace rather than creating a duplicate release vehicle.

## Governance prerequisites incomplete — DO NOT CLOSE

- [x] ADR-121 receives valid structured ratification against its rendered option set.
- [x] The cache-proven issue guard, story trace, generated maps, behavioural evals, and corrected changesets land together and pass the targeted verification suite.
- [x] The fix is published and verified before this ticket leaves Known Error.

## Fix Released

Released in `@windyroad/itil@2.1.0` (merge commit `cf5cf39a0f6623eb4ccaf434e6239f2d641d0ea8`, PR #451, released 2026-08-27).

The inbound lifecycle-update path now closes provenance-proven issues on this repository after evidence-backed local closure while leaving foreign tracker state to its maintainer.

Awaiting user verification.

Exercise evidence: npm reported `@windyroad/itil@2.1.0` published at `2026-08-28T11:15:05.325Z`; the tagged 2.1.0 artefact contains the owned-issue close path; and `bats packages/itil/skills/update-upstream/test/update-upstream-contract.bats` passed 41/41 on 2026-08-29.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P500 (the unratified premise), P520 (the sweep that mostly dissolves), P519 (shipped the carve-out)

## Related

- **P519** (known-error) — landed the carve-out in `471e3205`; its release remains pending in Version Packages PR #451.
- **P500** (known-error, `Origin: internal`) — the unratified ticket the carve-out was built on. Its premise is what the maintainer rejected.
- **P520** (open) — the quiet-period sweep, captured to eventually close these issues. Largely moot if the close is immediate.
- **JTBD-301** — "reporting is incidental" is the persona constraint that makes waiting for the reporter a losing strategy.
- **ADR-117** — the pull-request carve-out (comment, never close). Genuinely different: we cannot close someone else's PR, whereas we can close an issue on our own tracker.

## Stories

- [STORY-066 — A fix I can prove works gets closed without me](../../stories/accepted/STORY-066-a-fix-i-can-prove-works-gets-closed-without-me.md)

## Fix Strategy

**Release vehicle**: .changeset/close-inbound-issues-on-our-own-tracker.md
