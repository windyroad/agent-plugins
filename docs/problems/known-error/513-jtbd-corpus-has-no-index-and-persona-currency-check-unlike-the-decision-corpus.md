# Problem 513: The JTBD corpus has no index or persona currency check, unlike the decision corpus

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture. Impact 2: repo-local governance corpus; an unregistered job is invisible to anyone reading the index but the file still exists and still gates edits, so nothing breaks — it drifts. Likelihood 4: three instances in one adopter repo already, no control, and the sibling corpus that does have a control is the reason the gap is visible at all.
**Origin**: inbound-reported (adopter-repo P111)
**Effort**: M
**WSJF**: 8 — (8 × 2.0) / 2 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

A JTBD job file can be authored and land without ever being registered in `docs/jtbd/README.md` or in its persona's Jobs list. Nothing regenerates either surface and nothing checks them, so the index quietly stops describing the corpus.

The decision corpus has exactly this control — ADR-077's compendium, regenerated on every ADR edit and verified against HEAD — which is what makes the JTBD gap conspicuous rather than merely absent.

**Reported by an adopter**, with three instances:

1. `JTBD-M-004` landed 2026-06-10 unregistered in **both** `docs/jtbd/README.md` and `docs/jtbd/maintainer/persona.md`.
2. `JTBD-M-005` nearly landed the same way the next day — caught only because `wr-jtbd:agent` happened to return ISSUES FOUND mandating registration plus the M-004 backfill.
3. `persona.md` carried a stale `./JTBD-M-003-….proposed.md` link after that file was renamed to `.accepted.md` at acceptance.

Instance 2 is the one that matters: the catch was incidental. The reviewer was invoked for a different reason and noticed. Nothing in the path is designed to catch it, so the same authoring on a quieter day lands unregistered.

Instance 3 is a second failure mode in the same surface — the persona's link rots on a lifecycle rename, the same positional-reference class as ADR line-number citations.

## Symptoms

- A job file exists under `docs/jtbd/<persona>/` and appears in neither the README index nor the persona's Jobs list.
- A persona's Jobs list links a filename that no longer exists after a `.proposed.md` → `.accepted.md` rename.
- Neither condition surfaces anywhere; discovery is incidental.

## Workaround

Rely on `wr-jtbd:agent` noticing while reviewing something else. That is how instance 2 was caught, and it is not a control.

## Impact Assessment

- **Who is affected**: anyone reading `docs/jtbd/` to learn what jobs exist — including the JTBD gate itself, which anchors edits to jobs a reader cannot find from the index.
- **Frequency**: three instances in one adopter repo across roughly a day of authoring.
- **Severity**: silent corpus drift. An unregistered job still gates edits, so the corpus and its index disagree while both keep working.
- **Analytics**: none — this ticket is the first count, and it comes from an adopter rather than from here.

## Root Cause Analysis

Registration is a manual authoring step in two places (`README.md`, `persona.md`) with no generator and no checker. The decision corpus solved the same problem with a generator plus a refresh-discipline hook; the JTBD corpus has neither, so the same class of drift is unguarded.

The persona-link rot is a distinct mechanism: the link embeds the lifecycle state in the filename, so any acceptance transition invalidates every link to it. That is the same positional-reference fragility P482 records for ADR line-number citations, one artefact tier over.

### Investigation Tasks

- [ ] Decide the shape: regenerate both surfaces from the corpus (the ADR-077 compendium pattern), or check them and report drift (the advisory-script pattern)
- [ ] Decide whether the check is load-bearing at commit time or advisory at retro time — ADR-069 made the README skill-inventory check load-bearing for the same reason
- [ ] Handle the persona-link rot: either link without the lifecycle suffix, or regenerate persona Jobs lists so a rename cannot strand them
- [ ] Check whether `docs/rfcs/`, `docs/stories/` and `docs/story-maps/` carry the same index-vs-corpus gap — each has a README with no verified generator
- [ ] Behavioural test: a job file landing unregistered is detected

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P482

## Related

- **Adopter ticket P111** — the adopter ticket this traces to; carries all three instances.
- **ADR-077** — the decisions compendium: the generator-plus-refresh-discipline pattern this corpus lacks.
- **ADR-069** — made the README skill-inventory currency check load-bearing at commit time rather than advisory, on the same drift-class reasoning.
- **P482** — positional citations going stale corpus-wide; the persona-link rot is the same class at the JTBD tier.
