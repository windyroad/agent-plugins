# Problem 383: capture-problem `--persona` enum hardcoded to home-repo personas; rejects valid adopter personas (+ JTBD-M-NNN predicate gap)

**Status**: Known Error
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

- [x] Validate `--persona` against the adopter's `docs/jtbd/*/` directory names (the real corpus), with the hardcoded enum as a fallback only when no jtbd dirs exist
- [x] Resolve `JTBD-M-NNN` IDs in the `wr-jtbd-is-job-or-persona-unconfirmed` predicate
- [x] Behavioural test: `--persona=<dir-name-not-in-enum>` accepted when the dir exists; rejected when it does not
- [x] Sibling sweep: other skills that hardcode the home-repo persona enum — none found beyond the two named loci (grepped `developer.*tech-lead.*plugin` enum literals across `packages/*/skills`, `packages/*/scripts`, `packages/*/hooks`; the Step 1.5b candidate-generation prose at SKILL.md still *proposes* home-repo personas, correct for the home repo — it is LLM analysis, not a validation gate)

### Confirmed root cause (2026-06-27)

Two independent loci, both instances of the P151/P317 class (home-repo assumptions leak into adopter installs):

1. **capture-problem Step 1.5b `--persona` validation** (`packages/itil/skills/capture-problem/SKILL.md`): the flag-table entry and the `persona_value` resolution prose both pinned the valid set to the literal home-repo enum `{developer, tech-lead, plugin-developer, plugin-user}`. The cited-JTBD derivation path (resolution step 2) reads `persona:` frontmatter and never enum-checks, so the explicit `--persona` flag was the *less* reliable path — exactly inverted.

2. **`is-job-or-persona-unconfirmed.sh` job-ref resolution** (`packages/jtbd/scripts/`): the resolver matched `grep -qiE 'JTBD-?[0-9]+|^[0-9]+$'` then extracted `grep -oE '[0-9]+' | head -1` — the first numeric run only. On `JTBD-M-101` this drops the `M` and globs `JTBD-101-*.md` (wrong file or none). The guard fails *open* (no flag fires), so the `[Unratified Dependency]` build-upon guard silently can't find adopter maintainer jobs.

## Fix Strategy

Traced by **RFC-031** (Persona validation against adopter corpus + JTBD-M-NNN resolution). Two coordinated surfaces:

- **`@windyroad/itil`** — Step 1.5b `--persona` validation now validates against the directory names under `docs/jtbd/*/` (the adopter's real corpus, project-root-relative — `ls -d docs/jtbd/*/`), falling back to the home-repo enum only when no `docs/jtbd/` directories exist. The free-text JTBD-correction path is widened to tolerate the `JTBD-M-NNN` alpha-infix shape. LLM-executed prose, consistent with all other Step 1.5b derivation logic — architect P383 review confirmed a committed-shell `validate-persona` helper would be the inverse-P078 / P132 over-engineering trap (no hook fires it; no cross-install silent-break path).
- **`@windyroad/jtbd`** — the job-ref resolver strips an optional `JTBD-` prefix to a stem that preserves alpha infixes (`JTBD-M-101` → `M-101`) and globs `docs/jtbd/*/JTBD-M-101-*.md`. `JTBD-NNN` and bare-numeric behaviour unchanged; bare `M-NNN` variants also resolve.

## Reproduction test

`packages/jtbd/scripts/test/is-job-or-persona-unconfirmed.bats` — added cases: maintainer `JTBD-M-NNN` resolves (exit 0, preserves infix); confirmed `JTBD-M-NNN` exits 1; bare `M-NNN` variant resolves; hyphenated-persona-name (`smb-owner`) boundary lock (routes to the persona branch). All 17 cases green post-fix; the three new `JTBD-M-NNN` cases were red against the pre-fix script (TDD). Both `detect-unoversighted` sync guards stay green. The capture-problem persona-validation side is LLM-executed SKILL prose with no unit harness (consistent with the rest of Step 1.5b).

Architect + JTBD gates: PASS. External-comms + voice-tone gates on the changeset: PASS.

## Dependencies

- **Blocks**: reliable AFK `--persona` pre-resolution in adopter repos
- **Blocked by**: (none)
- **Composes with**: P282-class adopter-portability family (P151/P153/P219/P317 — home-repo assumptions in shipped artefacts)

## Related

- **Upstream**: windyroad/agent-plugins#282 — surfaced repeatedly in an adopter repo whose personas are `{smb-owner, advisor, maintainer}` during AFK work-problems loops.
- `packages/itil/skills/capture-problem/SKILL.md` — Step 1.5b `--persona` validation is the locus.
- `wr-jtbd-is-job-or-persona-unconfirmed` predicate — JTBD-M-NNN resolution gap.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-031 | proposed | Persona validation against adopter corpus + JTBD-M-NNN resolution |
