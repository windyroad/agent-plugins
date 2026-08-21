# Problem 491: The retro context trigger's thresholds are prose in five places, and none of them is the decision

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3. Impact 3: the shipped skills describe a trigger the decision no longer specifies, so an adopter reading them is told the wrong thing and the eval keeps certifying it. Nothing is corrupted; the cost is a governance record and its implementation disagreeing. Likelihood 3: it bites on any read of those surfaces, and it is certain to bite whoever next changes the trigger — but the trigger is not read often.
**Origin**: internal
**Effort**: M — five surfaces to correct, of which two are tests, plus a config surface that does not exist yet.
**WSJF**: 4.5 — (9 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-002
**Persona**: developer

## Description

ADR-112 settles when the deep context analyser fires: the last report older than **10 days**, or a bucket grown by more than **10%** *and* more than **5 KB**, at most once a day, with all three values overridable per project.

Nothing in the shipped tree agrees.

### Five surfaces still carry the superseded values, and they fail three different ways

The old values are 14 days, 20% and 10 KB. They appear in:

- **`run-retro/SKILL.md`** — the Delta-breach and Calendar-elapse bullets, the inactive-cadence note that is the only place the numbers reach a reader's screen, and the deep-layer routing bullet.
- **`analyze-context/SKILL.md`** — the When-to-use clauses, and the frontmatter `description:`, which is loaded into the skill listing on every session whether or not a retrospective runs.
- **`run-retro/eval/promptfooconfig.yaml`** — the file header, a case, the Tier-A rubric, and a second case.
- **`run-retro/test/run-retro-context-usage-step-2c.bats`** — greps the literals `older than 14 days` and `more than 20%`.
- **`analyze-context/test/analyze-context-skill-contract.bats`** — greps `14 days` and `20%`.

The two test files **redden on contact**: correct the prose and they fail, which is at least honest.

The eval is the dangerous one. Its threshold assertions match on alternations broad enough to survive the change — one passes on `calendar[\s\-]?elapse`, another on `delta[\s\-]?breach` — and its fixture premise (*"5 days < 14 days"*) still holds at 10 days. So it goes on **certifying the superseded contract silently**. A red test announces itself; this one will not, which makes it the surface most likely to be left behind.

### A sixth surface, until this ticket was written

ADR-043's own Decision Drivers bullet restated the trigger as `>14 days OR delta >20%` — the pre-floor shape, without the absolute gate at all. That was corrected when ADR-112 landed. It is recorded here because it is the shape of the problem: the numbers propagate into prose that nobody thinks of as carrying them.

### The tunability surface does not exist

ADR-112 makes the three values per-project overridable, resolved project file, then machine file, then defaults, with an environment variable able to trump all three as the CI and emergency escape hatch. That precedence is ADR-098's pattern, deliberately not its file — those keys belong to Cruise and its schema is closed.

**Nothing reads these three values today.** They are prose. So tunability is not a wiring job; it is a surface that has to be built, on the retrospective plugin's own config. Which file, and in what format, is this ticket's to settle.

### The sibling threshold is on the mechanism this rejects

The cheap layer's own byte ceiling is tunable, but only through an environment variable. That is the mechanism ADR-098 rejected — per-machine, undiscoverable, does not travel with the repository. After ADR-112 lands, one feature has two tunability mechanisms and they disagree about which is right. Migrating the cheap threshold rides here.

## Symptoms

- A skill describing a trigger the decision does not specify.
- An eval passing against a contract that has been superseded.
- An adopter reading the skill listing and being told the wrong cadence before they have run anything.
- Two thresholds on one feature configured two different ways.

## Workaround

Read ADR-112 rather than the skills. That is the inverse of the intended relationship.

## Impact Assessment

- **Who is affected**: anyone reading the retrospective skills to find out when the deep layer fires, and whoever next changes the trigger and finds five copies of the old answer.
- **Frequency**: on any read of those surfaces; certain for the next person to touch the trigger.
- **Severity**: the record and the implementation disagree, and one of the checks that should catch that is asleep.
- **Analytics**: none.

## Root Cause Analysis

Suspected: threshold values were written as prose into every surface that needed to mention them, rather than into one place that the others read. With no single source, changing the decision cannot change the behaviour, and the assertions written to protect the prose pin literals rather than meaning — so they either break on contact or pass regardless, and neither is a check.

### Investigation Tasks

- [ ] Decide the config surface: which file on the retrospective plugin, in what format, following ADR-098's project → machine → defaults precedence with an environment variable trumping all three. ADR-098's own file is not it — its schema is closed and its keys are Cruise's.
- [ ] Build something that reads the three values. Until this exists ADR-112 is half met: the numbers changed and nobody can override them.
- [ ] Correct the five surfaces to 10 days / 10% / 5 KB, or better, to read from the config rather than restate it. Restating is what produced five copies.
- [ ] Fix the eval so it can fail. Its assertions currently survive the change through broad alternations, and its fixture premise holds at both old and new values. An eval that cannot detect a contract change is not testing the contract.
- [ ] Settle whether the two grep-literal tests are updated or replaced. ADR-043 designates them a permitted doc-lint exception, but that permission is scoped to an enumerated list — section header, ADR citations, AFK fallback prose — which does not reach numeric thresholds. So this leans toward ADR-052's behavioural default rather than being evenly balanced.
- [ ] Migrate the cheap layer's byte ceiling off its environment variable onto the same surface, so one feature stops having two answers.
- [ ] Check `packages/retrospective/README.md`, which describes the deep layer as on-demand. The ADR citation there is left alone; the "on-demand" wording is the same false claim as the skill's own lede and belongs in this scope.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **ADR-112** — the decision this implements. It names the gap in its own Consequences rather than leaving it implicit, and its three-month reassessment asks whether this ticket was ever worked.
- **ADR-043** — the decision ADR-112 supersedes in part. Its surviving substance is overdue its own reassessment.
- **ADR-098** — the layered precedence pattern to follow, and the decision that rejected environment variables as the primary surface.
- **ADR-052** — behavioural tests as the default, which bears on whether the two grep-literal tests are updated or replaced.
- **P489** — the same shape one decision earlier: ADR-111 stated a rule, and what it cost the shipped surfaces went to its own ticket. This is that pattern applied again.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. ADR-112 is the fifth document of that sweep and this is its overflow.

(captured during the ADR-112 review, on the architecture reviewer's finding that the decision asserted a follow-up which did not exist.)
