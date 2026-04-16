# Problem 019: Deprecate single-file `docs/JOBS_TO_BE_DONE.md` fallback

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 6 (Medium) — Impact: Moderate (3) x Likelihood: Possible (2)
**Effort**: L — 3 ADR edits, 1 hook, 4 BATS files, 1 SKILL.md, 1 file delete (re-sized after architect review 2026-04-16; was S)
**WSJF**: 1.5 — (6 × 1.0) / 4

## Description

ADR-008 specifies `docs/jtbd/` (directory with per-persona subfolders + per-job files) as the canonical JTBD structure, with a backward-compatibility clause accepting the legacy single-file `docs/JOBS_TO_BE_DONE.md`. The fallback was included because the ADR migrated an existing convention. Since ADR-008 is still `.proposed.md` (not ratified), and downstream work (P018 quadruplet traceability, `wr-jtbd:update-guide` skill) is complicated by the dual-format requirement, this problem proposes amending ADR-008 to remove the fallback.

Removing the fallback simplifies: the TDD plugin's traceability layer (P018), validation tooling (CI lookups against a single known layout), plugin-developer guidance (one pattern to teach), and the `wr-jtbd` agent's file-resolution logic.

## Symptoms

- P018's invariant has to say "either `docs/jtbd/` or `docs/JOBS_TO_BE_DONE.md`" in every reference — this leaks into every downstream consumer (test-content review, CI validation, agent lookup paths).
- `wr-jtbd` agent and `update-guide` skill carry two code paths for every read operation.
- Plugin developers authoring new jtbd-aware features face a choice: support both formats (more code, more tests) or support one and break the other (decision they shouldn't be making individually).
- ADR-008's Confirmation and Consequences sections carry mitigation clauses ("Confusion about where JTBDs live") that only exist because two locations are supported.

## Workaround

Keep supporting both formats. Accept the complexity tax on every downstream feature.

## Impact Assessment

- **Who is affected**:
  - Plugin-developer persona (JTBD-101 Extend the Suite) — inconsistent patterns make "clear patterns, not reverse-engineering" harder.
  - Tech-lead persona — single authoritative structure aids governance/auditability.
  - Solo-developer persona (JTBD-001) — downstream tooling (P018 traceability, validation) is simpler and faster when there's only one layout.
- **Frequency**: Every new feature that reads or validates JTBDs pays the dual-format tax.
- **Severity**: Medium. No user-facing breakage today, but compound cost grows as more features (P018, P016, P017 splitting helpers) reach for JTBD data.
- **Analytics**: N/A. Memory note `project_jtbd_migration.md` records that the project already migrated this way in its reference implementation.

## Root Cause Analysis

ADR-008 was drafted when a legacy single-file `JOBS_TO_BE_DONE.md` existed in bbstats and needed migration. The backward-compat clause was a transition aid. The transition has now been executed (bbstats is the reference implementation per memory note). The clause no longer serves an active migration — it only serves hypothetical projects that haven't run `update-guide` yet.

### Investigation Tasks

- [ ] Inventory: which projects currently in use have `docs/JOBS_TO_BE_DONE.md` without also having `docs/jtbd/`? If the answer is "none", removal is free.
- [ ] Amend ADR-008 in place (it is `.proposed`, no supersession required). Rather than silently mutating Option 1, **add a new "Option 3: Directory-only, no fallback"** as the chosen option and retain Option 1 (with backward compatibility) in Considered Options as the alternative now being rejected — preserves the rationale chain. Update the `date` field. Remove the backward-compat clause from Decision Drivers, from Plugin Changes (eval/enforce/mark-reviewed/agent fallbacks), and from Confirmation.
- [ ] In ADR-008 add an explicit carve-out: "The `wr-jtbd:update-guide` skill is the sole component permitted to read `docs/JOBS_TO_BE_DONE.md`, and only for one-shot migration into `docs/jtbd/`." Future cleanup passes must not strip this read path from the skill.
- [ ] In ADR-008 Consequences (Bad) add disposition policy: "Once migrated, the legacy file should be deleted (git history is the archive)."
- [ ] Update ADR-008 Confirmation to: "BATS tests assert single canonical path `docs/jtbd/`; legacy single-file is not consulted by runtime hooks."
- [ ] Update the supersession note in ADR-007 (`docs/decisions/007-jtbd-project-wide-enforcement.superseded.md`) to explicitly state that the single-file artifact name is no longer canonical (format change, not just structure change).
- [ ] Update ADR-005 (`docs/decisions/005-plugin-testing-strategy.proposed.md` line 138) — rephrase the `docs/jtbd` vs `docs/JOBS_TO_BE_DONE.md` example or note that legacy support has been removed.
- [ ] Remove the `docs/JOBS_TO_BE_DONE.md` exemption from `packages/architect/hooks/architect-enforce-edit.sh` (lines 67-69) and delete its case in `packages/architect/hooks/test/architect-enforce-scope.bats`.
- [ ] Remove or invert dual-path assertions in `packages/jtbd/hooks/test/jtbd-eval.bats`, `jtbd-mark-reviewed.bats`, `jtbd-enforce-scope.bats` — assert single canonical path only; negative tests where appropriate.
- [ ] Update `packages/jtbd/skills/update-guide/SKILL.md` to make explicit that it IS the migration path, and is the ONLY component allowed to read `docs/JOBS_TO_BE_DONE.md` (for migration only). Position as prerequisite for upgrading to any post-deprecation plugin version.
- [ ] Update P018 to drop the "(or `docs/JOBS_TO_BE_DONE.md` for legacy projects)" carve-out from the quadruplet invariant and CI validation task.
- [ ] Strip dual-path logic from `wr-jtbd` agent and any eval/enforce/mark-reviewed/agent fallbacks in packaged plugins.
- [ ] Delete this repo's own stub `docs/JOBS_TO_BE_DONE.md` (confirmed by jtbd-lead to be a 5-line stub redirect with no unique content).
- [ ] Add a release note / changelog entry calling out the breaking change for any external adopter still on the single-file layout.
- [ ] Re-run architect review after the above scope changes are in the ticket; proceed to implementation only after APPROVED.

## Related

- ADR-008 (proposed): `docs/decisions/008-jtbd-directory-structure.proposed.md` — target for the amendment
- Related problem: `docs/problems/018-tdd-enforce-bdd-example-mapping-principles.open.md` — simplified significantly once this lands
- `wr-jtbd:update-guide` skill — canonical migration path
- Memory note: `project_jtbd_migration.md` — records that bbstats is the reference implementation of the directory-based layout
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
- Tech-lead persona: `docs/jtbd/tech-lead/persona.md`
