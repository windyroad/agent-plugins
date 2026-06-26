# Problem 383: capture-problem `--persona` enum hardcoded to home-repo personas; rejects valid adopter personas (+ JTBD-M-NNN predicate gap)

**Status**: Open
**Reported**: 2026-06-26
**Priority**: 12 (High) — Impact: 4 x Likelihood: 3
**Origin**: inbound-reported (#282)
**Effort**: M
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`/wr-itil:capture-problem` Step 1.5b validates the `--persona=` flag against a hardcoded enum `{developer, tech-lead, plugin-developer, plugin-user}` (the plugin home-repo persona set). Adopter repos have their own `docs/jtbd/<persona>/` corpora (e.g. `smb-owner`, `advisor`, `maintainer`). A caller passing a perfectly valid adopter persona (e.g. `--persona=maintainer`) fails enum validation even though the persona exists on disk and the cited JTBD's frontmatter names it.

This inverts the contract: the cited-JTBD persona-derivation path does NOT enum-check, so the explicit `--persona` flag becomes the LESS reliable path. AFK callers that pre-resolve `--persona` (as the work-problems orchestrator is instructed to) hit a halt on a valid value.

Related: the `wr-jtbd-is-job-or-persona-unconfirmed` predicate returns "not found" for the maintainer `JTBD-M-NNN` ID scheme under all ref variants, so adopters using that scheme cannot ratification-check those jobs via the predicate.

## Symptoms

- `--persona=maintainer` (valid adopter persona on disk) fails enum validation and halts capture.
- `JTBD-M-NNN` IDs return "not found" from the unconfirmed predicate under all ref variants.

## Workaround

Use the cited-JTBD persona-derivation path (no enum-check) instead of the explicit `--persona` flag.

## Impact Assessment

- **Who is affected**: adopters with custom persona corpora using `--persona`, especially AFK orchestrator callers.
- **Frequency**: every capture that passes a non-home-repo `--persona` value.
- **Severity**: AFK halt on a valid value; class P151/P317 family (home-repo assumptions leak into adopter installs).

## Root Cause Analysis

### Investigation Tasks

- [ ] Validate `--persona` against the adopter's `docs/jtbd/*/` directory names (the real corpus), with the hardcoded enum as a fallback only when no jtbd dirs exist
- [ ] Resolve `JTBD-M-NNN` IDs in the `wr-jtbd-is-job-or-persona-unconfirmed` predicate
- [ ] Behavioural test: `--persona=<dir-name-not-in-enum>` accepted when the dir exists; rejected when it does not
- [ ] Sibling sweep: other skills that hardcode the home-repo persona enum

## Dependencies

- **Blocks**: reliable AFK `--persona` pre-resolution in adopter repos
- **Blocked by**: (none)
- **Composes with**: P282-class adopter-portability family (P151/P153/P219/P317 — home-repo assumptions in shipped artefacts)

## Related

- **Upstream**: windyroad/agent-plugins#282 — surfaced repeatedly in an adopter repo whose personas are `{smb-owner, advisor, maintainer}` during AFK work-problems loops.
- `packages/itil/skills/capture-problem/SKILL.md` — Step 1.5b `--persona` validation is the locus.
- `wr-jtbd-is-job-or-persona-unconfirmed` predicate — JTBD-M-NNN resolution gap.
