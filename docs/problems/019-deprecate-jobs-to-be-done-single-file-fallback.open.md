# Problem 019: Deprecate single-file `docs/JOBS_TO_BE_DONE.md` fallback

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 6 (Medium) — Impact: Moderate (3) x Likelihood: Possible (2)

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
- [ ] Amend ADR-008 (architect guidance): remove the backward-compatibility clause from Decision Drivers, from Option 1, from the Plugin Changes section (eval/enforce/mark-reviewed/agent fallbacks), and from the Confirmation bullets. Add to Consequences (Bad): "Projects on the legacy single-file layout must run `/wr-jtbd:update-guide` before upgrading."
- [ ] Decide amendment vs. supersession. Since ADR-008 is `.proposed`, a direct amendment is appropriate (no historical record to preserve).
- [ ] Update `wr-jtbd:update-guide` documentation to make explicit that it IS the migration path, and position it as a prerequisite for upgrading to any post-deprecation plugin version.
- [ ] Update P018 to drop the "(or `docs/JOBS_TO_BE_DONE.md` for legacy projects)" carve-out from the quadruplet invariant and CI validation task.
- [ ] Strip dual-path logic from `wr-jtbd` agent and any eval/enforce/mark-reviewed/agent fallbacks in packaged plugins.
- [ ] Add a release note / changelog entry calling out the breaking change for any external adopter still on the single-file layout.

## Related

- ADR-008 (proposed): `docs/decisions/008-jtbd-directory-structure.proposed.md` — target for the amendment
- Related problem: `docs/problems/018-tdd-enforce-bdd-example-mapping-principles.open.md` — simplified significantly once this lands
- `wr-jtbd:update-guide` skill — canonical migration path
- Memory note: `project_jtbd_migration.md` — records that bbstats is the reference implementation of the directory-based layout
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
- Tech-lead persona: `docs/jtbd/tech-lead/persona.md`
