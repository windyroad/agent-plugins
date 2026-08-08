# Problem 484: The reading-context persona constraint is load-bearing in two ratified decisions but documented nowhere

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3. Impact 3: an undocumented persona attribute that two ratified decisions turn on gets re-derived from scratch each time it matters, so it is applied inconsistently and can be argued away by anyone who has not seen the earlier cases. Not higher, because each individual instance has been caught — by the human hitting it. Likelihood 3: it surfaces whenever a governance artefact is designed for a human to read, which in this cluster is most changes.
**Origin**: internal
**Effort**: S — one constraint added to a persona file, plus its re-ratification under the lockstep rule
**JTBD**: JTBD-002
**Persona**: developer

## Description

The `developer` persona documents pain points and context constraints. It does not document how or where this person reads. It should, because two ratified decisions already turn on it and a third had to leave the argument uncited.

The attribute: **governance artefacts are read on devices with no repository access** — a phone preview, an email attachment, a sandboxed viewer, GitHub's HTML rendering. The consequence is not presentational. A claim made *on* an artefact cannot be checked against the corpus at read time, so the artefact has to be self-evidently true rather than verifiable-in-principle. And an artefact needing anything beyond its own bytes to be readable is not readable at all in that context.

### Where it is already load-bearing

- **ADR-105** (the grid ships in the file) exists because the maintainer opened a story map on a phone and got a fallback message instead of the map. Its entire Context is this constraint, argued from first principles because there was nothing to cite.
- **ADR-107** (a map's RFC list is derived from its release rows) leans on it — a derived list is right without anyone checking it, which matters precisely because the reader cannot check it — and had to leave that half of the argument out, citing only the documented "having to manually police AI output" pain point.
- The house **P350** rule states the same fact as a working instruction — *"the user does NOT have project filesystem access on every device"* — but P350 is a ticket about brief-before-ID, not a persona record.
- It drove a live defect the same day: a story map's value clauses were separated only by a CSS rule, so a map opened away from its directory ran three clauses together into one unreadable line. Nothing tested for it, because nothing had written down that maps get read that way.

### Why it belongs at persona tier

It is not a fact about any one job. It is a fact about the person, and it constrains every artefact they read — decisions, story maps, tickets, briefs. Asserting it inside an ADR would record persona substance in the wrong tier, which is the tiering argument ADR-106 was ratified on. The 2026-08-04 re-ratification of this persona took the same view for the repo-shape constraint.

## Symptoms

- A decision arguing a reading-context constraint from first principles because there is nothing to cite.
- A decision leaving half its rationale out for the same reason.
- An artefact that renders correctly only in its own directory, with no test covering the other case.
- Design discussion re-litigating whether the maintainer can "just open the repo".

## Workaround

Cite ADR-105's Context, which argues it in full, and the P350 rule. Both are real; neither is a persona record, so neither survives as a constraint the next author will find.

## Impact Assessment

- **Who is affected**: whoever designs an artefact for a human to read, and the human reading it.
- **Frequency**: every artefact intended for human review — decisions, story maps, briefs, tickets.
- **Severity**: legibility and rework. The defects it causes are found by the human hitting them rather than by anything detecting them.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the constraint was learned through incidents rather than through interviewing, so it landed in incident records — an ADR context, a ticket's working rule — rather than in the persona. Nothing routes an incident-derived persona fact back to the persona file.

### Investigation Tasks

- [ ] Draft the constraint for `docs/jtbd/developer/persona.md` § Context Constraints. Roughly: *reads governance artefacts on devices without repository access, so an artefact must be self-evidently true and readable from its own bytes rather than verifiable against the corpus.*
- [ ] Re-ratify the persona under the ADR-068 lockstep rule and P357, since a persona edit needs its own confirm event.
- [ ] Check whether `tech-lead` and `plugin-user` carry the same constraint. `plugin-user` almost certainly does, and has less claim on the repo than anyone.
- [ ] Once documented, revisit ADR-105 and ADR-107 to cite it rather than re-argue it — as new decisions, per P483, since both are ratified.
- [ ] Answer the general question: what routes a persona fact discovered during an incident back into the persona file? Today nothing does.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P483.

## Related

- **ADR-105** — argues the constraint in full because it could not cite it.
- **ADR-107** — leans on it and leaves it uncited; names this ticket in `## Related` for that reason.
- **P350** — states the same fact as a working rule about briefing, not as a persona record.
- **P483** — why the fix is a persona amendment plus re-ratification rather than an edit to the decisions that need it.
- **P289** — broadened and renamed this persona; the same file, a different gap.
- Found by `wr-jtbd:agent` during the ADR-107 review, 2026-08-08: *"Two ratified decisions have now turned on a persona attribute that was never written down."*

(captured via /wr-itil:capture-problem; the duplicate-check surfaced 10 title matches on persona/reading/constraint — P287, P288, P289, P323 and P401 among them — and none is this problem: they concern type-classification retirement, new-artefact ratification, a persona rename, unratified-dependency detection, and capture-time anchoring respectively. This is a missing constraint on an existing persona.)
