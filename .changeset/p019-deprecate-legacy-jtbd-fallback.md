---
"@windyroad/jtbd": minor
"@windyroad/architect": patch
---

**Breaking change for external adopters**: remove the `docs/JOBS_TO_BE_DONE.md` runtime fallback. Canonical JTBD layout is now `docs/jtbd/` only (ADR-008 Option 3 chosen 2026-04-20 per P019).

**Who is affected**: any project still using the legacy single-file `docs/JOBS_TO_BE_DONE.md` layout. The JTBD gate, agent, and CI validation no longer consult the legacy file.

**Migration**: run `/wr-jtbd:update-guide` — it is the **sole** component in the suite permitted to read `docs/JOBS_TO_BE_DONE.md`, and only for one-shot migration into the `docs/jtbd/` directory layout. After migration, the legacy file can be deleted (git history is the archive).

**Runtime changes**:
- `@windyroad/jtbd` eval hook no longer injects the "docs/JOBS_TO_BE_DONE.md" enforcement variant; missing `docs/jtbd/` triggers an update-guide recommendation.
- `@windyroad/jtbd` enforce hook no longer exempts the legacy file and no longer falls back to it. On projects without `docs/jtbd/`, the gate blocks with a `/wr-jtbd:update-guide` suggestion.
- `@windyroad/jtbd` mark-reviewed hook no longer stores a hash against the legacy file; it exits early when `docs/jtbd/` is absent.
- `@windyroad/jtbd` agent description and lookup logic now reference only `docs/jtbd/`.
- `@windyroad/architect` enforce hook no longer exempts `docs/JOBS_TO_BE_DONE.md` as a peer-plugin policy artefact (it is no longer a recognised governance artefact).
- `@windyroad/architect` detect hook's "does not apply to" list no longer mentions `docs/JOBS_TO_BE_DONE.md`.

**Documentation changes**:
- ADR-008 amended: Option 3 "Directory-only, no fallback" added as the chosen option; Option 1 retained with dated rejection (2026-04-19) so the rationale chain is readable.
- ADR-005 line 138 rephrased to reflect the single canonical path.
- ADR-007 supersession note extended to call out the artefact-name change (format, not just structure).
- `wr-jtbd:update-guide` SKILL.md documents the migration carve-out explicitly.
- This repository's own `docs/JOBS_TO_BE_DONE.md` stub is deleted (it was a 5-line redirect with no unique content).
- Bats tests in `jtbd-eval`, `jtbd-enforce-scope`, `jtbd-mark-reviewed`, and `architect-enforce-scope` inverted to assert the legacy-file path is not consulted.
