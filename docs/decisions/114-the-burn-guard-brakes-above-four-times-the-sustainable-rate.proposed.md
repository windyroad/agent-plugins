---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed in the ADR-111 three-part shape. Offered: above four times sustainable, above twice, above eight times, or turn the guard off by default. Picked four, matching the draft. This was a RE-ask: an earlier question in the same session had offered keep-4 / explain-first / disable and been answered keep-4, but on a description that was wrong — it said the multiplier decides how hard the throttle brakes when behind pace. The architecture review found the guard sits in a branch reached only when behind the line, where nothing brakes at all below its threshold, so the number is the entire boundary between unthrottled and stopped rather than a tuning knob on an existing brake. The corrected description was put in front of the maintainer before this pick. Also disclosed: that four is unmeasured and nothing counts how often the guard fires; that the guard\u2019s existence rests on ADR-093, which is itself unratified; and that the boundary is strictly greater-than, so exactly four times does not trip it — the title said \u201cat\u201d and was corrected to \u201cabove\u201d."
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: [ADR-098 (in part — the burn_guard_multiple default and its rationale, as recorded in the 2026-07-24 amendment and in the Decision Outcome key entry)]
jtbd: [JTBD-010]
persona: developer
reassessment-date: 2026-11-09
---

# ADR-114: The burn guard brakes above four times the sustainable rate

## Context and Problem Statement

The quota throttle paces work against a weekly budget. When you are over the pacing line it slows you in proportion to how far over you are.

**It does nothing at all when you are behind the line.** Being behind means there is banked headroom, and spending it is the point — so below the line the throttle does not brake, deliberately. That is fine until the rate changes: a weekly window climbed from 28% to 99% in about a day and a half, because a session that starts the week behind the line sprints unthrottled right up to it. Long high-effort turns and several concurrent sessions burn far faster than banked headroom anticipates.

A guard was added for exactly that. It is not a harder version of the proportional correction — there is no correction underneath it to harden. It is the only thing that brakes a behind-the-line sprint, and the number decides when it starts.

That number arrived in an amendment written into the config schema the day after that schema was ratified, under a heading that says *pending ratification*. It never was, and it has been deciding when the throttle stops work ever since.

## Decision Drivers

- Behind the line there is no braking at all, so this threshold is the entire boundary between running unthrottled and stopping. It is not a tuning knob on an existing brake.
- The proportional correction demonstrably could not answer the runaway case, because it does not run in that regime.
- Braking hard stops work, so the threshold has to sit well clear of ordinary variation. One that fires too readily gets switched off, and a disabled guard protects nothing.
- Nobody measured this number. Saying so is part of recording it.

## Considered Options

1. **Fire above four times the sustainable rate.** What ships today.
2. **Fire above twice.** Narrows the unbraked gap and catches a runaway sooner; interrupts more often during a legitimately busy stretch.
3. **Fire above eight times.** Almost never interrupts, and leaves a correspondingly wider stretch where nothing brakes at all.
4. **No guard.** Proportional correction over the line and nothing behind it — the state that let a window go from 28% to 99% in a day and a half. Rejected as the default, and reachable per-project by setting the multiplier to zero.

## Decision Outcome

**Option 1.** The guard fires when the measured burn is strictly more than four times the rate the remaining budget can sustain — fast enough to exhaust the window in under a quarter of the time left.

Two regimes, and they are not the same shape. Over the line, the proportional correction applies and slows work in proportion to how far over you are. Behind the line, nothing brakes: the banked headroom is there to be spent, and it is spent at full speed until burn passes four times sustainable, at which point the throttle brakes hard. There is no gentle middle in that second regime, which is why the number matters — it is the whole boundary between unthrottled and stopped.

The multiplier is a project-tunable default resolved through the layered config this decision's parent established, with `WR_QUOTA_BURN_GUARD_MULTIPLE` trumping every layer as the escape hatch. Setting it to zero turns the guard off, which is the intended way to opt out: option 4 above is rejected as the default, not as a choice a project can make.

This settles the threshold. It does not settle whether the guard should exist — that is ADR-093's, and ADR-093 has not itself been ratified.

**Four is not measured.** It was chosen as comfortably clear of ordinary variation while still catching the runaway case, and it has run since July without a reported complaint — which is weak evidence, not data. Nothing records how often the guard fires, so there is no way to tell whether four is right, whether it has ever fired, or whether it fires constantly and is being tolerated.

## Consequences

### Good

- The failure that produced this — a window burned through in a day and a half — has an answer, in the regime where nothing else was watching.
- The threshold is a project's to change, and turning it off is a stated option rather than a workaround.
- A malformed value falls back to the default rather than to zero, so a typo cannot silently remove the protection.

### Neutral

- The value resolves through the same layers as every other knob in that config, so there is nothing new to learn to change it.

### Bad

- **Below the threshold, behind the line, nothing brakes.** That is deliberate and it is also the exposure: at four times sustainable, a burst can run at nearly four times the rate the budget supports and meet no resistance at all until it crosses. A smaller multiplier narrows that gap and interrupts more often. Nobody has measured which trade is right.
- **Nobody knows if four is right.** Nothing counts how often the guard fires, so the reassessment below has no evidence to reason from and will face the same guess.
- **When it fires it stops work.** That is the point, and it will be experienced as the tool getting in the way during a genuinely busy stretch. The escape hatch exists because that judgement belongs to whoever is working.

## Confirmation

- Over the line and measurably over-rate, the proportional correction applies.
- Over the line but measurably sustainable, and with no other window braking, nothing brakes.
- Behind the line, at or below four times sustainable, and with no other window braking, nothing brakes.
- When one window is over-line unresolved or behind-line guard-tripped, the other window does not escape it — the grip and the ramp are process-wide, not per-window.
- Burn strictly above four times sustainable trips the guard. At exactly four times it does not — the comparison is `>`, on integer arithmetic.
- An environment variable beats a project file; a project file beats the machine file; with none of them, four.
- Setting the multiplier to zero disables the guard, and no burn rate trips it.
- A non-integer value falls back to four rather than to zero.

## Related

- **ADR-098** — superseded in part: the multiplier's default and its rationale, both where the 2026-07-24 amendment states them and where they appear in the ratified key schema. That decision's layered precedence and the rest of its schema stand, and its body is untouched — the supersession is recorded here rather than written into it.
- **ADR-093** — introduced the guard. This decision settles its threshold, not its existence. Note that ADR-093 is itself unratified — `human-oversight: unconfirmed` — so the guard's existence rests on substance nobody has confirmed, and settling its threshold here does not change that.
- **P444** — a default buried in artefact mechanics passes under an artefact-level ratification. This number is why that ticket exists, and surfacing it as its own choice is the remedy.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. Seventh document of that sweep.

## Reassessment Criteria

`reassessment-date: 2026-11-09`. The thing to check is whether anything yet records how often the guard fires. Without that the next review re-guesses, and a number nobody can evaluate is one nobody should keep defending.
