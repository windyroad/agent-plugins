---
"@windyroad/retrospective": minor
---

feat(retrospective): JTBD-anchored README drift advisory script (closes P152 Phase 1)

Adds `check-readme-jtbd-currency.sh` (and `wr-retrospective-check-readme-jtbd-currency` bin shim per ADR-049) — the Phase 1 advisory detector codified by ADR-051.

The detector walks `packages/*/README.md`, greps for `JTBD-\d{3}` citations, resolves each cited ID against `docs/jtbd/<persona>/JTBD-NNN-*.md` (any status suffix), and emits per-package signal:

```
README package=<name> has_jtbd_anchor=<yes|no> cited_jobs=<N> known_jobs=<M> drift_hints=<csv>
TOTAL packages=<N> with_jtbd=<M> drift_instances=<K>
```

`drift_hints` vocabulary:

- `missing-jtbd-section` — README has no `JTBD-\d{3}` cite.
- `stale-jtbd-citation` — cited ID has no resolving file under `docs/jtbd/`.
- `deprecated-jtbd-citation` — cited ID resolves only to `.deprecated.md` / `.superseded.md`.
- `skill-inventory-drift` — a directory under `packages/<plugin>/skills/` is not named in the README.

Phase 1 closes the asymmetric pressure-stack P152 surfaces: the project has dense gates for code drift (architect, JTBD, risk-scorer, style-guide, voice-tone, TDD, changeset-discipline) but zero gates for README content drift. Plugin READMEs are hand-maintained and silently drift between releases — empirical baseline on detector first-run is 12/12 plugins flagged with `drift_instances=12`.

Advisory only — exit code is always 0 per ADR-013 Rule 6 fail-safe / ADR-040 declarative-first / ADR-051 Phase 1. Phase 2 (R6-gated load-bearing hook) escalates if `drift_instances ≥ 2` across 3 consecutive `chore: version packages` releases without correction.

Phase 1 ships:

- ADR-051 — `@windyroad/*` plugin READMEs anchor on JTBD job IDs with declarative drift advisory.
- JTBD-302 — Trust That the README Describes the Plugin I Just Installed (new plugin-user job).
- JTBD-007 amendment — currency expansion from code-currency to doc-content-currency.
- 12 behavioural bats fixtures (drift / clean / stale / deprecated / inventory / multi-package / no-readme cases) per ADR-005 + P081.
- bin/ shim per ADR-049 naming grammar.

Out of scope for Phase 1 (filed as follow-on work):

- Retroactive refresh of the 12 plugin READMEs to JTBD-anchored shape.
- Wiring the detector into `/wr-retrospective:run-retro` Step 2b.
- Generalisation to adopter-project surfaces (marketing HTML, public docs, changelog narrative).
- Walking `.github/ISSUE_TEMPLATE/*.yml` per JTBD-lead's Phase 1.5 recommendation.

Architect APPROVED at low risk: net-new advisory script + ADR + JTBD job + JTBD amendment + bats; no executable code change; no commit-gate path touched. JTBD PASS — primary fit JTBD-302 (newly filed) + JTBD-007 (currency expansion); composition fit JTBD-001 / JTBD-101 / JTBD-202 / JTBD-301.
