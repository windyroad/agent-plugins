# Problem 244: Phase 3 (F9) `wr-itil-plugin-maturity-list` in-suite display shim — reads installed plugins' plugin.json maturity field, emits NDJSON-per-surface + rollup-per-plugin

**Status**: Open
**Reported**: 2026-05-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

Phase 3 (F9) `wr-itil-plugin-maturity-list` in-suite display shim — reads installed plugins' plugin.json maturity field via marketplace-cached path per ADR-003, emits NDJSON-per-surface + rollup-per-plugin. ADR-063 §F9 names this as a Phase 3 contract (NOT a deferred follow-on) per architect adjustment A2 to ADR-063 itself. P087 iter-9 architect review (2026-05-17) reaffirmed Phase 3a scope as strict per ADR-014 commit-grain and explicitly carved out F9 as a separate sibling ticket — this ticket — so the deliverable does not get lost. Sibling to P237 (Phase 3a — population script), P238 (Phase 3b — renderer + drift detector), P239 (Phase 3c — bats doc-lint), P240 (Phase 3d — JTBD amendments). Captured per architect adjustment E in P087 iter-9.

The shim composes with the eventual upstream `claude plugin list` extension when it ships — the upstream extension can adopt the same NDJSON shape. Until then, F9 is the adopter-facing machine-readable rollup view across installed plugins.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Reconciliation (iter-19, 2026-06-16) — BLOCKED on F1 re-simplification + ADR-063 §F9 section reconcile

AFK work-problems iter-19 selected this ticket as an implementation candidate. Reconcile-first found it is **not yet actionable** — queued + skipped, not built. Findings:

1. **The F9 shim contract describes the superseded F2 shape.** This ticket body (2026-05-17) and ADR-063 §`wr-itil-plugin-maturity-list` bin shim contract (lines 344–376) + §Confirmation #7/#9 all specify the **F2-era** NDJSON record — `schema_version: "1.0"` on every record plus a `computed_at` + `evidence: {invocations_30d, days_shipped, closed_tickets_window, breaking_change_age_days}` block per surface.

2. **ADR-063 was simplified F2 → F1 (P300, confirmed 2026-06-08).** §Confirmation #16 now mandates **bare band strings**: "No `schema_version` / `computed_at` / `evidence` / `rollup_invocations_30d` / `bootstrapping` fields appear under F1." This directly contradicts the §F9 section above — the F9 shim reads `plugin.json`, so under F1 there is no `evidence`/`computed_at` source to emit, and the NDJSON output `schema_version` stamping is left ambiguous (kept per §Confirmation #7 vs dropped per F1 consistency). **The §F9 shim section + §Confirmation #7/#9 were never reconciled to the F1 amendment.**

3. **The F1 re-simplification build has NOT landed.** P300 §Verification (lines 43–47) tracks it as OPEN: "Sibling Phase 3a iter: re-simplify `plugin-maturity-populate.sh` to write F1 … Phase 3b → F3 badge … Phase 3c → F1/F3 bats." On-disk `packages/*/​.claude-plugin/plugin.json` confirmed still **F2/v2.0** (`schema_version: '2.0'`, `evidence`, `computed_at`, `bootstrapping`). Building F9 against the current F2 disk shape, or against the unbuilt F1 target, would build the consumer-facing NDJSON contract mid-transition — the P314/P315 built-on-then-rejected trap.

**Resolution before this ticket is actionable** (both required):
- (a) The P300 F1 re-simplification build lands (Phase 3a writer rewritten to F1 + `plugin.json` re-populated to F1 across the 11 plugins), so the shim reads a stable F1 shape.
- (b) ADR-063's §`wr-itil-plugin-maturity-list` bin shim contract + §Confirmation #7/#9 are amended to the F1 output shape (architect-reviewed): decide F9's NDJSON record fields under F1 (bare `{axis, plugin, surface, kind, band}` + rollup) and whether the output `schema_version` is retained for consumer-contract stability or dropped for F1 consistency.

ADR-074 substance-confirm is **not clear** for the F9 output contract until (b) reconciles the confirmed-but-self-contradictory ADR. Queued + skipped per iter-14–18 discipline.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Author `packages/itil/scripts/plugin-maturity-list.sh` canonical body — discovers installed `@windyroad/*` plugins via marketplace-cached `~/.claude/plugins/cache/<owner>/<plugin>/<version>/.claude-plugin/plugin.json` per ADR-003; reads each `maturity:` field; emits NDJSON one record per surface (with `kind` ∈ `{skill, agent, hook, command, plugin-rollup}`) plus one rollup record per plugin. `schema_version: "1.0"` on every record.
- [ ] Author `packages/itil/bin/wr-itil-plugin-maturity-list` shim per ADR-049 grammar.
- [ ] Author bats fixture covering ADR-063 §Confirmation criteria 7 (NDJSON shape: one record per surface + one rollup per plugin; `schema_version: "1.0"` on every record; exit 0 always) and 8 (no network primitive — negative-grep). Behavioural per ADR-052.
- [ ] Stderr-comment fallback (ADR-013 Rule 6) — no `@windyroad/*` plugins installed / marketplace cache inaccessible / all installed plugins missing `maturity:` field all hit the zero-records path with stderr-comment, exit 0.
- [ ] Decide marketplace-cache discovery mechanism: glob `~/.claude/plugins/cache/*/*/`+latest-version-resolution vs `claude plugin list --json` parse. Architect review on the discovery contract.

## Dependencies

- **Blocks**: (none — F9 is independent of Phase 3b / 3c / 3d ordering)
- **Blocked by**:
  - **P300 (F1 re-simplification build — the binding blocker, found iter-19)**: the F9 shim reads `plugin.json`, whose shape is contracted to move F2/v2.0 → F1 (bare strings) but has NOT yet been re-simplified (P300 §Verification lines 43–47 open; on-disk still v2.0). The shim cannot be built to a stable F1 contract until the writer + populated `plugin.json` are F1, AND ADR-063's §F9 shim section + §Confirmation #7/#9 are reconciled to F1 (currently F2-era, contradicting confirmed §Confirmation #16). See Reconciliation (iter-19) above.
  - P237 (Phase 3a populates the `plugin.json` `maturity:` field this shim reads — now in verifying). Until populated fields are present, the shim reads empty / missing fields and hits the stderr-comment fallback.
- **Composes with**: P087 (parent), ADR-063 §F9 (Phase 3 contract), ADR-058 §Confirmation #8 (schema_version precedent), ADR-049 (shim grammar), ADR-003 (marketplace-cached read path), ADR-013 Rule 6 (fail-safe).

## Related

- P087 — parent: no maturity / battle-hardening signal on plugins, skills, agents, or hooks.
- ADR-063 — Phase 3 presentation-layer contract; §F9 names this shim as Phase 3 contract.
- ADR-053 — Phase 1 taxonomy.
- ADR-058 — Phase 2 measurement scripts; §Confirmation #8 schema_version precedent.
- ADR-003 — marketplace-only distribution; read path for installed plugin.json.
- ADR-049 — bin shim grammar.
- ADR-013 Rule 6 — non-interactive fail-safe.
- ADR-052 — behavioural bats coverage.
- P237 — Phase 3a (writer); blocks this ticket via populated `plugin.json`.
- P238 — Phase 3b (README renderer + drift detector); sibling.
- P239 — Phase 3c (bats doc-lint per plugin); sibling.
- P240 — Phase 3d (JTBD outcome amendments); sibling.
