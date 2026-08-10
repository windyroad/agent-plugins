---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed in the ADR-111 three-part shape. Offered: (1) count uncurated entries and re-surface until drained, (2) go back to silent once the register exists, (3) nudge once when a stub appears then stop. Picked (1), matching the draft. A prior question had already settled that the behaviour should be kept as its own decision rather than folded into ADR-047 or dropped. A further question settled the retired-entry treatment: offered count-active-and-sweep-once, count-active-only, or count-everything — picked sweep-once, so the 22 retired-but-never-scored entries became Phase 2 of P411 rather than being filtered away silently. Disclosed before the ask: that the drain skill this nudge implies was never built, that both deferrals of it have now fired their own triggers, and that the arm therefore asks every session for work nobody has a tool to do. The exclusion-shaped predicate — everything except retired, rather than active-only — was taken on the architecture review\u2019s finding that active-only would silently drop consciously-tolerated risks, which is the same write-off the maintainer had just rejected."
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: [ADR-047 (in part — the 2026-07-03 pending-review count amendment only)]
jtbd: [JTBD-002]
persona: developer
secondary-persona: tech-lead
reassessment-date: 2026-11-09
---

# ADR-113: An uncurated risk register says so, every session

## Context and Problem Statement

A risk register is only worth having if its entries are real. When the scorer meets a risk it has not seen before it writes a stub and marks it as needing curation — the impact, the likelihood and the controls are placeholders until a person weighs them. A stub is a promise to think about something later.

Nothing collected on that promise. Once the register directory existed, the hook that had been nudging about its absence went quiet, and the stubs accumulated behind a check that considered its job done. The register looked present and was hollow.

A third arm was added on 2026-06-27: once the register exists, count the entries still marked as needing curation and say so, every session, until the count reaches zero. It shipped with no decision. A week later an amendment was written into ADR-047 acknowledging exactly that — the arm had shipped and nothing had reconciled it — and that amendment was itself never ratified, six weeks after the document it was written into.

So the behaviour has been running since June on no authority at all.

## Decision Drivers

- A maintenance action with no automatic cadence does not happen. This is the same principle that put the other two arms there, applied to the state they both exit on.
- An auto-scaffolded stub is worse than an absent entry, because absence is visible and a stub reads as coverage.
- The hook is already there and already fires. The cost of the arm is one grep over a small directory, once per session.
- Silence has to mean something. If the hook says nothing whether the register is curated or full of stubs, its silence carries no information.

## Considered Options

1. **Count the uncurated entries and re-surface until they are drained.** The hook stops going quiet on register-present; it goes quiet on register-curated.
2. **Leave the hook silent once the register exists.** What it did before. Simple, and it is the state that let stubs accumulate unseen.
3. **Nudge once and stop.** Say it the first session after a stub appears, then never again. Cheaper on attention, but a single message in one session is the shape that gets missed — and there is no record of whether it was acted on.

## Decision Outcome

**Option 1.** After the other arms have had their turn, the hook counts register entries still marked as needing curation and emits one line when the count is above zero. It repeats every session until the count reaches zero.

**Retired entries are outside the count.** A risk that has been closed no longer needs its impact and likelihood weighed, and counting them puts a floor under the number that curation cannot move — twenty-two of them today, against forty-seven that remain countable. That floor would make the count undrainable and the reassessment below meaningless.

The predicate is **exclusion-shaped: every register entry except a retired one**, rather than a match on active entries. The register's status vocabulary is three-valued — active, accepted for a risk consciously tolerated, and retired. An accepted risk is live, and the impact and likelihood the curation marker says are missing are exactly what a decision to tolerate it should have rested on, so it counts. Matching on active alone would write those off silently, and would also miss an entry carrying no suffix, which the register documents as the form an entry takes before it is retired.

Those twenty-two were retired without ever being scored, which is a real gap rather than a rounding error. Narrowing the count removes the only thing that was surfacing them, so they are resolved once as a migration rather than filtered away silently. That migration is a phase of P411, not a sentence here.

**This surfaces the backlog. It does not drain it — and nothing else does either.** The skill that was meant to, `/wr-risk-scorer:review-register`, was deferred by two decisions until adopter demand appeared and has never been built. The hook accordingly points at the register directory and describes the work rather than naming a tool. ADR-056 set a numeric trigger for building it — thirty days past adoption with a curation rate under twenty percent — and ADR-059 carried that forward qualitatively as *when adopter usage demonstrates demand*. At forty-seven countable entries months later, both conditions are met. P411 tracks the build. Until it exists this arm names a backlog nobody has a tool for, which is better than a backlog nobody can see, and worse than the thing it should be.

**It is a read, not a write.** That distinction is not new reasoning here: this hook was reshaped from a rejected silent-write into a read-only nudge by ADR-047's 2026-06-08 amendment, ratified on 2026-06-10. Counting what is already on disk sits inside that ratified shape, so the prior rejection of session start as a place to *generate* register content is untouched.

It obeys the same suppression variable as every other nudge of its class, so one switch silences it along with the rest.

## Consequences

### Good

- Silence now means the register is curated, rather than merely present.
- The backlog is visible on the surface where the work would start, once per session, at the cost of one grep.
- The count can reach zero, which it could not before. That is what makes the reassessment below answerable.
- The three arms of one hook now cover the three states that matter: no policy, no register, and a register nobody has finished.

### Neutral

- The suppression variable covers this arm with the others.

### Bad

- **It repeats until drained, and there is nothing to drain it with.** The skill that would do the work does not exist, so the only way to clear the count is by hand or by suppressing the nudge. A message that recurs every session while the tool it implies is unbuilt is a fair description of the current state and an unfair position to leave someone in. That is the argument for P411, not against this arm.
- **The hook's behaviour is now described across three decisions.** This one, ADR-108 and ADR-047 each own one arm. No single document says what the hook does, and someone reading any one of them sees a third of it. The precedence order is asserted here because this is the only one of the three that can see all three states.

## Confirmation

- The three arms fire in order and the first match wins: policy absent, then register absent, then entries needing curation. A project with no policy gets the policy line only, whatever else is true.
- With the register present and every countable entry curated, the hook is silent — retired entries do not hold it open.
- With countable entries needing curation, one line names the count and points at the register directory. It does not name a drain skill, because none exists.
- The count excludes retired entries and includes accepted ones.
- With the suppression variable set, nothing is emitted.

## Related

- **ADR-047** — superseded in part: the 2026-07-03 amendment only. Its register-absent arm is its own substance and stands, as does its 2026-06-08 read-only reshaping, which this decision relies on.
- **ADR-108** — the policy-absent arm of the same hook.
- **ADR-056** — defines the curation marker this arm counts, and set the numeric trigger for building the drain skill. It documents writing the marker, not counting it.
- **ADR-059** — rejected session start as a firing surface for generating register content, and carried ADR-056's deferral forward qualitatively. This arm reads rather than writes, so that rejection does not reach it.
- **P411** — build the register-review skill, and sweep the twenty-two retired-but-never-scored entries as its second phase. This arm surfaces a backlog that currently has no drain.
- **P375** — the audit that found this hook going quiet one step early, and the ticket the arm shipped under.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. Sixth document of that sweep.

## Reassessment Criteria

`reassessment-date: 2026-11-09`. Two things to check. Whether the count ever reached zero — it now can, which it could not before. And whether P411 shipped, because if it has not, this arm has spent three months asking for work nobody was given a tool to do.
