---
"@windyroad/itil": minor
---

P065: scaffold downstream OSS intake — new `/wr-itil:scaffold-intake` skill + pre-publish PreToolUse gate

The `@windyroad/itil` plugin now ships a foreground-synchronous skill that scaffolds the five OSS intake files every project in the ecosystem needs to receive structured problem reports and route security disclosure properly:

- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/problem-report.yml` (P066-corrected problem-first shape)
- `SECURITY.md`
- `SUPPORT.md`
- `CONTRIBUTING.md`

Templates live at `packages/itil/skills/scaffold-intake/templates/*.tmpl` and use mustache-style substitution (`{{project_name}}`, `{{project_url}}`, `{{plugin_list}}`, `{{security_contact}}`, `{{year}}`) with no runtime dependency. The skill is idempotent: present files are skipped unless `--force`; full re-application produces no diff. Re-invocation reports diffs for outdated-present files.

**Trigger surfaces (layered)** per ADR-036:

1. **First-run prompt** — wired into `manage-problem` and `work-problems` SKILL.md preambles. Foreground branch fires `AskUserQuestion` with three options (scaffold now / not now / decline). AFK branch (per ADR-013 Rule 6 + JTBD-006) appends a one-line "pending intake scaffold" note to the iteration's `ITERATION_SUMMARY` and never auto-scaffolds. Markers `.claude/.intake-scaffold-{done,declined}` follow ADR-009 persistent-marker semantics.
2. **Pre-publish PreToolUse gate** — new hook `pre-publish-intake-gate.sh` denies `npm publish` and `gh pr merge ... changeset-release/*` when intake files are missing AND no decline marker AND `INTAKE_BYPASS=1` is not set. Override path: `INTAKE_BYPASS=1 npm publish`.
3. **CI check** — deferred to v2 via `--ci` flag (emits `.github/workflows/intake-check.yml`).

`packages/itil/hooks/hooks.json` registers the new PreToolUse:Bash hook. Skill is auto-discovered from the directory; no manifest change required.

Cross-reference paragraph added to `packages/itil/skills/report-upstream/SKILL.md` documenting the reciprocal-pair shape (report-upstream files at upstream intake; scaffold-intake creates downstream intake).

39 new behavioural bats tests:
- `packages/itil/hooks/test/pre-publish-intake-gate.bats` (10 tests — allow + deny matrix across surfaces, markers, and bypass).
- `packages/itil/skills/scaffold-intake/test/scaffold-intake-contract.bats` (15 tests — SKILL.md structural invariants per ADR-037).
- `packages/itil/skills/scaffold-intake/test/scaffold-intake-fixture.bats` (7 tests — empty repo, idempotent re-run, partial repo with pre-existing CONTRIBUTING.md).
- `packages/itil/skills/scaffold-intake/test/scaffold-intake-secrets-absent.bats` (7 tests — no /Users, /home, Windows paths, credential shapes, hardcoded author-repo references).
- `packages/itil/skills/manage-problem/test/manage-problem-first-run-intake-prompt.bats` (4 tests — wiring point fixed).
- `packages/itil/skills/work-problems/test/work-problems-first-run-intake-prompt.bats` (4 tests — wiring point fixed).

Closes P065 → Verification Pending. ADR-036 stays `proposed` (no status change required at implementation time).
