---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed in the ADR-111 three-part shape, over three question sets. On when it fires: (1) elapsed time or real growth whichever first, (2) elapsed only, (3) growth only, (4) on-demand only — picked (1), matching the draft. On the values: (a) 14 days/20%/10 KB fixed, (b) the same tunable, (c) 30 days/30%/25 KB, (d) 7 days/10%/5 KB — picked (d), which the draft did not carry, so the outcome, grounding, consequences and confirmation criteria were rewritten before the marker was written. Because (d) left tunability unstated, a further question offered changeable-per-project / fixed / fixed-and-revisit — picked changeable. Then the architecture review found that 7 days collapses into every-retro for a weekly-or-slower cadence, which is the cost ADR-043 rejected in the maintainer\u2019s own words; that was put back to them with three options — step back to 10 days (recommended), keep 7 and accept every-retro, or return to 14 and take the eagerness on the growth axis alone — and they chose 10. So the settled trigger is 10 days / 10% / 5 KB, tunable. Disclosed before the asks: the numbers are guesses, nothing collects evidence to validate them, and they are prose in skills rather than values anything reads. Disclosed after the value pick: 5 KB costs the floor its derivation, since at half the cheap layer\u2019s report envelope the original argument no longer holds. The maintainer noted mid-sequence that each option set should carry a recommendation; the first two did not."
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: [ADR-043 (in part — the 2026-06-08 combined-trigger amendment and its 2026-06-17 absolute-floor sub-note)]
jtbd: [JTBD-002]
persona: developer
secondary-persona: tech-lead
reassessment-date: 2026-11-09
---

# ADR-112: The deep context analysis fires on elapsed time or on real growth

## Context and Problem Statement

A retrospective measures what is filling the context window. There are two layers. The cheap one runs every time and costs a couple of kilobytes: it totals each bucket and writes the numbers down. The expensive one reads into those buckets and says what is actually in them, and it writes a committed report.

The expensive layer was on-demand only. Someone had to remember to run it, which meant it was never run. The maintainer's direction, recorded twice: *"it shouldn't rely on someone remembering"*, and *"if there is no automatic cadence, it does not happen."*

So it was given a trigger. That trigger was recorded as an amendment inside a document ratified thirteen days earlier, and a second amendment was added nine days after that to fix a defect in it. Neither was ever ratified, and both changed how a shipped skill behaves.

## Decision Drivers

- Something that only runs when remembered does not run. That is what put the trigger there.
- The analyser must not become the thing it measures. The expensive layer writes a committed report and spawns work; firing it on every retrospective would make it a cost rather than a check.
- A trigger that fires on noise gets ignored, and then it is on-demand again with extra steps.
- The thresholds are guesses. Nobody has the data to set them properly, and pretending otherwise would be worse than saying so.

## Considered Options

### When it fires

1. **Elapsed time or real growth, whichever comes first** — fire when the last report is older than the elapsed-time threshold, or when any bucket has grown by more than both a relative and an absolute amount. At most once a day.
2. **Elapsed time only.** Simple and predictable, and it cannot fire on noise. It also cannot notice a bucket that triples the week after a run.
3. **Growth only.** Fires when something actually changed, and never otherwise — so a corpus that is large and stable is never looked at again, however dominant its cost.
4. **On-demand only.** The state before any of this. Rejected: it is the state the maintainer twice said does not work.

### What the numbers are, and whether a project can change them

a. **14 days / 20% / 10 KB, fixed.** What ships today, hard-coded in the skill.
b. **14 days / 20% / 10 KB, tunable per project.** Same starting values, but a project can change them without editing a shipped skill. Nothing reads these three today, so this means building something that does.
c. **Fire less often — 30 days / 30% / 25 KB.** Cheaper, at the cost of noticing growth later.
d. **Fire more often — 7 days / 10% / 5 KB.** Catches growth sooner, at the cost of more committed reports and more subagent work.

The tunability question applies to whichever value-set is chosen: any of these can ship fixed or tunable. Note that no script evaluates these three numbers today — they exist only as prose in the skills — so making them tunable means building an evaluation surface for them, not reusing the cheap layer's.

## Decision Outcome

**Option 1, with option (d)'s growth gates and the elapsed clock at 10 days rather than 7, tunable per project.**

The deep layer fires from the cheap layer when either condition holds:

- **Elapsed time.** The most recent report is older than **10 days**, or there is no prior report at all.
- **Real growth.** Any bucket has changed since the last snapshot by more than **10%** *and* by more than **5 KB**. Both, not either.

All three are defaults a project can override. They resolve project file first, then machine file, then these defaults — with an environment variable able to trump all three, as the CI and emergency escape hatch. That precedence is ADR-098's and this decision adopts the pattern, not its file: those keys are Cruise's and its schema is closed, so the retrospective plugin needs its own surface.

**An environment variable is not the surface to build.** It is per-machine, undiscoverable, and does not travel with the repository, which is why the layered file won that argument already. The cheap layer's own byte ceiling is still tunable only that way; this decision does not follow it. Nothing reads these three values today, so the obligation is to build the layered surface, not to add another variable.

That is a separate question from precedence. Once the layered surface exists an environment variable still outranks it — that is what an escape hatch is for, and CI and emergencies are why one is kept. What is rejected is shipping the variable *instead of* the files, not the variable sitting above them.

At most once per day. The report written that day is itself the record that it ran, so there is no separate state to keep.

Both gates on the growth axis are needed because either alone misfires. Percentage alone trips on nothing: a small bucket moved 4,277 to 5,897 bytes — a single paragraph added to a configuration file — and that is 38%, enough to spawn a committed report and a subagent for 1.6 KB. An absolute floor alone would never fire on a bucket small enough to matter proportionally.

The inverse worry — a large, stable corpus that never re-fires because it never moves — is covered by the elapsed-time axis, which re-examines every bucket on its own schedule regardless of change. That is why there is no third condition. Adding one could only increase how often this fires, and the problem being solved was that it fired on noise.

When it fires it runs silently and writes its report. It never asks anything, in an attended session or an unattended one.

**The three numbers are guesses, and these ones are deliberately eager.** The values that shipped were 14 days, 20% and 10 KB, each borrowed from something else: 14 days as roughly two retrospective cycles, 20% from the breach grain ADR-040 uses for Tier 3 briefing budgets, and 10 KB from the cheap layer's own report ceiling — `CONTEXT_BUDGET_MAX_BYTES`, default 10240 — on the reasoning that a delta smaller than the measuring instrument cannot be the dominant cost.

This decision moves all three. The growth gates halve, to 10% and 5 KB, to catch real change sooner. The elapsed clock goes to 10 days rather than the 7 that halving would give, and that number has a reason the other two do not: the deep layer only fires from a retrospective, so at 7 days a project retro-ing weekly or slower always has an elapsed clock and fires every single time — the every-retro cost ADR-043 rejected outright. Ten sits above a weekly cadence and below a fortnightly one. So the two growth gates are chosen, and the elapsed clock is derived from the cadence it has to clear.

It also costs the 10 KB floor its derivation. At 5 KB the floor is half the measuring instrument rather than equal to it, so the argument that gave the old number its authority no longer applies. Five kilobytes is chosen, not derived, and nothing distinguishes it from four or six except that it is half of what was there.

Recorded, in ADR-043's own words for these values: **not estimated — chosen as initial values**. What also changes is the interval for revisiting them, from six months to three. The numbers govern how often a committed report is written into someone's repository, they have now moved once without evidence, and a wrong value is cheaper to find at three months than at six.

## Consequences

### Good

- The expensive layer runs without anyone remembering, which was the whole point.
- It fires less often than the retrospectives themselves, provided those run at intervals shorter than 10 days. At 10 days or longer the clock has always elapsed by the time a retrospective runs, and it fires on every one — which is why the number sits where it does.
- A trivial edit to a small file still does not trigger a committed report and a subagent. The 1.6 KB case that produced the floor stays below it even at 5 KB.

### Neutral

- The daily guard needs no state of its own: the presence of today's report is the state.

### Bad

- **Five shipped surfaces still say 14 days, 20% and 10 KB**, and they fail in three different ways. Two are grep-literal tests that redden on contact, asserting `14 days` and `20%` against skill prose. One is the eval, which does not redden at all: its threshold assertions match on alternations broad enough to survive, and its fixture premise holds at 10 days as it did at 14, so it keeps certifying the superseded contract silently — the surface most likely to be left behind, precisely because it stays green. The other two are skill prose, including a frontmatter description loaded on every session whether or not a retrospective runs. Whether the two grep-literal tests are updated or replaced is not settled here: ADR-043 designates them a permitted doc-lint exception, but that permission is scoped to an enumerated list — section header, ADR citations, AFK fallback prose — which does not reach numeric thresholds, so the question leans toward ADR-052's behavioural default rather than being evenly balanced. Until all five move, this decision describes behaviour the code does not have.
- **The numbers are unvalidated and have now moved once without evidence.** The two growth gates were chosen by analogy and halved by judgement. The elapsed clock is the one number with a reason, and even that reasons from an assumed weekly cadence rather than from data — nobody has measured how often retrospectives actually run. Nothing is collecting what would say whether any of them is right, and the three-month reassessment will face the same absence unless something starts recording how often the trigger fires and whether those fires were worth it.
- **It costs more.** The two growth gates halve and the elapsed clock shortens from 14 days to 10, so more committed reports and more subagent runs on every project that installs this — bounded at no more than the lesser of the retrospectives themselves and 36 clock fires a year plus growth fires. The whole point of the 10 KB floor was to stop firing on noise, and 5 KB moves back toward the noise it was added to exclude.
- **Making them tunable is work that does not exist yet.** No script reads these three values; they are prose in two skills. Tunability means building an evaluation surface for them, and until it exists the decision is only half met — the numbers change but nobody can override them.
- **A very large bucket still waits up to 10 days.** If the multi-megabyte problem corpus becomes the dominant cost the day after a run, nothing notices until the clock elapses. That is the deliberate price of not adding a third condition.
- **A project's first retrospective fires the expensive layer.** With no prior report the elapsed-time axis holds, so a fresh adopter's very first retro spawns a subagent and commits a report before there is any history to compare against. It is correct — there is nothing to go on and the deep read is the only way to get a baseline — but it is an unexpected first-run cost in someone else's repository.

## Confirmation

- With no prior report, the deep layer fires.
- With a report older than 10 days, it fires regardless of what changed.
- A bucket that moves 38% but only 1.6 KB does not fire it — the case that produced the floor.
- A bucket that moves 8% but 50 KB does not fire it either — both gates, not one.
- A project that sets its own values gets those; with none, the machine file; with neither, these defaults.
- An environment variable wins over a project file that sets a different value — the escape hatch outranks the layers beneath it.
- When today's report already exists, it does not fire again, and the retrospective says why.
- When nothing triggers, the retrospective says that too, rather than staying silent about it.

## Related

- **ADR-043** — the decision this supersedes in part: the trigger, and the floor added to it nine days later. Everything else — the two-layer split, what each layer measures, the budget proof for the cheap layer, the snapshot trailer — is its own substance and stands. Its 2026-05-26 amendment also stands: it is the requirement this decision satisfies rather than replaces.
- **ADR-098** — the layered project, then machine, then defaults precedence this borrows. The pattern only: the keys and the file are Cruise's and its schema is closed, so these thresholds need the retrospective plugin's own surface.
- **ADR-026** — grounding: cite the anchor, persist it, state the uncertainty. The three numbers are recorded as chosen by analogy with their anchors named, not as measured.
- **ADR-040** — the Tier 3 briefing-budget breach grain, which is where the 20% this decision replaces came from.
- **P295** — the ticket that settled the trigger shape.
- **P372** — the ticket behind the absolute floor. Its instance is the 38%-on-1.6 KB fire.
- **P283** — where the automatic-cadence direction was recorded.
- **P444** — design decisions buried in artefact mechanics passing under an artefact-level ratification. Why the three numbers are their own answer here rather than prose inside the outcome.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. Fifth document of that sweep.

## Reassessment Criteria

`reassessment-date: 2026-11-09` — three months, the interval this decision sets. The thing to check is whether the numbers have been left alone because they are right, or because nobody is looking. If the deep layer has fired only on the calendar for three months, the growth axis is doing nothing and its thresholds are wrong.
