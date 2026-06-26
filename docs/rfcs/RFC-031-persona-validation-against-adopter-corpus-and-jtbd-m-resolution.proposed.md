---
status: proposed
rfc-id: persona-validation-against-adopter-corpus-and-jtbd-m-resolution
reported: 2026-06-27
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P383]
adrs: []
jtbd: []
stories: []
---

# RFC-031: Persona validation against adopter corpus + JTBD-M-NNN resolution

**Status**: proposed
**Reported**: 2026-06-27
**Problems**: P383
**ADRs**: (none)
**JTBD**: (none)

## Summary

Stop the plugin home-repo persona set leaking into adopter installs (P151/P317 family). Two coordinated loci: (1) `/wr-itil:capture-problem` Step 1.5b validates `--persona=` against the adopter's real persona corpus (`docs/jtbd/*/` directory names) instead of a hardcoded enum; (2) the `wr-jtbd-is-job-or-persona-unconfirmed` predicate resolves maintainer `JTBD-M-NNN` IDs by preserving the alpha infix when globbing.

## Driving problem trace

- **P383** — `--persona=maintainer` (a valid adopter persona on disk) fails the hardcoded enum check and halts capture, inverting the contract (the cited-JTBD derivation path never enum-checks, so the explicit flag was the less reliable path); and `JTBD-M-NNN` IDs return not-found from the unconfirmed predicate, so adopters on that scheme cannot ratification-check those jobs.

## Scope

Two shippable surfaces:

- `@windyroad/itil` — `packages/itil/skills/capture-problem/SKILL.md` Step 1.5b `--persona` validation prose (LLM-executed; validate against `docs/jtbd/*/` dir names, home-repo enum fallback only when no jtbd dirs exist) + the free-text JTBD-correction path widened to tolerate `JTBD-M-NNN`.
- `@windyroad/jtbd` — `packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh` job-ref resolution preserving alpha infixes.

Out of scope: a committed-shell `validate-persona` helper (architect P383 review: prose-only is ADR-consistent — extracting a helper for an LLM-executed one-shot capture-time check is the inverse-P078 / P132 over-engineering trap; no hook fires it, no cross-install silent-break path).

## Tasks

- [x] Validate `--persona` against `docs/jtbd/*/` directory names, home-repo enum fallback only when no jtbd dirs exist (SKILL.md prose)
- [x] Resolve `JTBD-M-NNN` (and `M-NNN`) IDs in `is-job-or-persona-unconfirmed.sh` by stripping the optional `JTBD-` prefix to an infix-preserving stem
- [x] Behavioural bats: `JTBD-M-NNN` resolves; confirmed-marker exit 1; bare `M-NNN` variant; hyphenated-persona-name boundary lock; existing `JTBD-NNN` / bare-numeric regression-green
- [x] Widen the SKILL.md free-text JTBD-correction validation path to tolerate `JTBD-M-NNN` (JTBD P383 review consistency note)
- [ ] Sibling sweep: other skills that hardcode the home-repo persona enum (deferred — none found at the two named loci; re-check at manage-rfc accepted)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
