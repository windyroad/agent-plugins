# Problem 544: Briefing topic-file entries decay toward deletion because they are never loaded — Step 1.5 cannot tell "not useful" from "not delivered"

**Status**: Open
**Reported**: 2026-09-04
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5. Impact 3: the defect sits in a shipped plugin surface (`wr-retrospective` 0.25.0) and its effect is the silent deletion of correct, load-bearing operational guidance from every adopter's briefing tree. Band fit is between RISK-POLICY level 2 (dev tooling affected, installed plugins unaffected — false here, the mechanism ships) and level 4 (installed plugins degrade developer workflow); rated to the lower of the two plausible bands rather than the higher, because no skill fails to load and no hook misfires — the pass runs correctly and returns a wrong answer. Likelihood 5: all three band triggers hold — known gap, no control in place, and a previously observed failure mode with a dated worked example (ADR-076 inbound-report evidence).
**Origin**: inbound-reported (#473)
**Effort**: M — the `rediscovered` classification is a scoring-table edit inside run-retro Step 1.5, but the decay exemption changes what decay *measures* (staleness vs. filing location) and interacts with ADR-040's tier model, so that half warrants a design record.
**WSJF**: 7.5 — (15 × 1.0) / 2
**JTBD**: (new job for the `developer` persona — elicitation queued; see Related)
**Persona**: developer

## Description

`wr-retrospective:run-retro` Step 1.5 scores every briefing entry each retro: **signal +2** when the entry "was cited, paraphrased, or acted on during this session", **noise −1** when it "was loaded into context but not cited or acted on", and **decay −1** applied to all entries every cycle. Entries promote into the `docs/briefing/README.md` Critical Points roll-up at `>= +3` and route to the delete queue at `<= −3`.

The session-start surface loads only the roll-up. `packages/retrospective/hooks/session-start-briefing.sh` extracts the `## Critical Points (Session-Start Surface)` section of `docs/briefing/README.md` and emits only that. No topic file under `docs/briefing/` is ever read.

So a topic-file entry cannot earn signal, because it is not in context and therefore cannot be cited, while decay debits it every cycle. Its score falls monotonically toward the delete queue, driven by **where the entry is filed** rather than by whether it is true or useful.

### Why it matters most at the worst moment

When a later session independently hits the precise failure an existing entry documents, and pays the full cost that entry would have prevented, the event is at once the strongest evidence the entry is valuable and direct proof it was never delivered. The scoring table cannot express that. The closest available classification is `signal`, worth +2, netting +1 after decay, from a base that has been decaying for months.

### Inbound report body (verbatim)

> ## What happens
>
> Step 1.5 of `wr-retrospective:run-retro` scores every briefing entry each retro: **signal +2** when the entry "was cited, paraphrased, or acted on during this session", **noise -1** when it "was loaded into context but not cited or acted on", and **decay -1** applied to all entries every cycle. Entries promote into the README Critical Points roll-up at `>= +3` and route to the delete queue at `<= -3`.
>
> The session-start surface loads only the roll-up. `hooks/session-start-briefing.sh` reads `docs/briefing/README.md` and emits only its "Critical Points" section. No topic file under `docs/briefing/` is ever loaded.
>
> So a topic-file entry cannot earn signal, because it is not in context and therefore cannot be cited, while decay debits it every cycle. Its score falls monotonically toward the delete queue, driven by where the entry is filed rather than by whether it is true or useful.
>
> ## Why it matters most at the worst moment
>
> When a later session independently hits the precise failure an existing entry documents, and pays the full cost that entry would have prevented, the event is at once the strongest evidence the entry is valuable and direct proof it was never delivered. The scoring table cannot express that. The closest classification is signal, worth `+2`, netting `+1` after decay, from a base that has been decaying for months.
>
> ## Worked example
>
> In an adopter repository, a briefing entry documenting a gate trap was written on 2026-07-03 after a session spent significant time on it. By 2026-08-30 it carried `signal-score: -1`; two more decay cycles would have put it in the delete queue. On 2026-09-04 a session hit the same trap and spent three blocked attempts finding the cause by reading the hook source.
>
> Honest scoring for that retro: `-1 + 2 (signal) - 1 (decay) = 0`. Still below the `+3` that would have put it in the roll-up, where it would have been read before the cost was paid. The entry that had cost two sessions the same way sat closer to deletion than to promotion.
>
> ## Suggested fix
>
> Two candidates, not mutually exclusive.
>
> 1. Add a `rediscovered` classification to the Step 1.5 table, scoring high enough to clear `+3` in one cycle, on the grounds that the event proves value and non-delivery simultaneously.
> 2. Exempt never-loaded entries from decay, so decay measures staleness rather than filing location.
>
> The workaround in the meantime is to promote by hand, which works but is undocumented, depends on an agent noticing, and leaves the recorded score contradicting the placement.
>
> Observed on `wr-retrospective` 0.25.0.

## Symptoms

- Topic-file entries carry monotonically declining `signal-score` values regardless of whether their content is still true.
- An entry documenting a real trap reaches the delete queue while a session is independently re-paying the cost that entry would have prevented.
- The recorded score contradicts the entry's placement after a manual promotion, because hand-promotion does not reset the score.

## Workaround

Promote the entry into the Critical Points roll-up by hand. This works, but it is undocumented, depends on an agent noticing the entry matters, and leaves the recorded score contradicting the placement.

## Impact Assessment

- **Who is affected**: every adopter running `run-retro` against a briefing tree with topic files — which is the documented steady state after Tier-3 rotation splits content out of the roll-up.
- **Frequency**: every retro cycle, for every topic-file entry. The decay is unconditional.
- **Severity**: silent loss of correct guidance. The mechanism deletes the entries it was built to preserve, and the deletion looks like ordinary curation.
- **Analytics**: one dated worked example in the inbound report — entry written 2026-07-03, at `signal-score: -1` by 2026-08-30, cost re-paid 2026-09-04 across three blocked attempts.

## Root Cause Analysis

Step 1.5's scoring model assumes the entries it scores were in context during the session. That assumption holds for the Critical Points roll-up, which the SessionStart hook emits, and fails for every topic file, which nothing loads. The `noise` classification encodes the assumption explicitly — "loaded into context but not cited" — so an entry that was never loaded has no correct classification available, and falls through to bare decay.

The conflation is therefore structural rather than a tuning error: no choice of numeric weights repairs it while "was it cited?" remains the only positive signal and "was it delivered?" is unobservable to the pass.

P105 (the ticket that introduced the signal-vs-noise pass) recorded this as an unresolved design question at authoring time and shipped anyway — its Q3 answer reads "**Open**: exact numeric values for signal/noise vs decay to achieve the intended monotonicity". This ticket answers that question with evidence: the monotonicity is not a weighting problem.

### Investigation Tasks

- [ ] Decide whether `rediscovered` enters the Step 1.5 table as a distinct classification, and at what weight it clears +3 in a single cycle from a plausible decayed base.
- [ ] Decide whether decay is exempted for never-loaded entries, or redefined to measure staleness directly (e.g. against last-verified date rather than cycle count).
- [ ] Determine whether the second half needs an ADR amendment against ADR-040's tier model, per the JTBD-alignment scope note.
- [ ] Reconcile with P535 — the two tickets are mirror images on the two tiers and may share a fix.
- [ ] Decide whether hand-promotion should reset or carry forward the recorded score, so placement and score stop contradicting each other.

## Dependencies

**Composes with**: P535

### Second witness, in this repository (2026-09-19, P463 iter retro)

The mechanism the inbound report describes fired here, on the entry that saved the iteration.

`docs/briefing/governance-workflow.md` carries an entry stating that a ratified decision's body is immutable and changes only by supersession (ADR-116). The 2026-09-19 iteration working P463 turned entirely on that rule: the work was to record a decision superseding ADR-079 in part, and the entry is what says the old body must not be edited and the old filename must not change. It was cited and acted on throughout.

Its score going in was `-4` (last classified 2026-08-30). Step 1.5's arithmetic for the session: signal `+2`, decay `-1`, net `+1` — landing at `-3`, which is the delete-queue band. The single most load-bearing entry in the file, on the session that proved it load-bearing, scored into deletion. The in-band action taken was `trim` rather than `remove`, which preserved the substance, but that was a judgement call available only because the band permits "removes / trims"; a stricter reading deletes it.

This sharpens the report's claim in one respect: the entry is not merely undeliverable, it is **uncatchable**. Maximum single-cycle gain is `+1`, so an entry at `-4` needs four consecutive cited sessions to climb out of the band, while a single uncited cycle costs `-2`. From any deeply negative base the score cannot recover faster than it falls, regardless of how valuable the entry proves.

The sibling entry in the same file (a confirmed ADR's own "lands as an amendment here" instruction is unfollowable) scored `-6` on the same pass and was removed. That one was genuinely not exercised, so the removal is defensible — but it was filed at `-4` for the same structural reason, not because anyone had judged it stale.

## Related

- **P535** (`docs/problems/open/535-critical-points-outgrew-its-budget-so-the-session-start-hook-truncates-it.md`) — the mirror-image sibling on the Tier 1 surface. P535: entries only ever *enter* the roll-up, because the roll-up carries no per-entry scores and nothing ever falls out. This ticket: entries only ever *fall out* of the topic tree, because nothing ever loads them so nothing can score them up. Both are surfaces of a common premise neither ticket owns — the signal-score model assumes the scored entries are in context, which holds for neither tier as currently wired. Flagged as a cluster candidate for the next `/wr-itil:review-problems` pass.
- **P105** (`docs/problems/closed/105-*.md`) — the originating design ticket that introduced the signal-vs-noise pass, and recorded the monotonicity question as open at ship time.
- **ADR-040** — session-start briefing surface and the tier model the decay exemption would interact with.
- **JTBD**: the JTBD-alignment classifier returned `aligned-with-new-JTBD-for-existing-persona` for the ratified `developer` persona. Proposed job substance: *when my own session captured a lesson about a trap, I want that lesson delivered to the session that hits the trap again, so I never pay the full cost of a failure my system already documented.* Routing onto JTBD-011 was considered and rejected — JTBD-011 is bounded to how the agent conducts a turn, and is itself `human-oversight: unconfirmed`, so amending it would drag an unratified dependency into this fix's path. Elicitation queued for the next interactive `/wr-jtbd:confirm-jobs-and-personas` drain.
- **Upstream**: windyroad/agent-plugins#473 (inbound-reported, 2026-09-04).
