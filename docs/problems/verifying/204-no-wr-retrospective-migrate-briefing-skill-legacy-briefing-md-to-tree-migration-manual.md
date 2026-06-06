# Problem 204: No /wr-retrospective:migrate-briefing skill — legacy docs/BRIEFING.md → docs/briefing/ tree migration is manual

**Status**: Verification Pending
**Reported**: 2026-05-15
**Fix Released**: pending @windyroad/retrospective release (this commit)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

> **new-jtbd-flag** (per JTBD classifier): the proposed skill addresses **adopter-artefact-layout-currency** — a third currency dimension not covered by JTBD-007 today (which scopes code-currency + README-content-currency only). Maintainer decision: amend JTBD-007 to extend currency scope (recommended) OR add new JTBD-009 (Migrate Adopter Artefacts When a Plugin's Layout Evolves).

## Description

The `wr-retrospective` plugin (v0.18.1) ships the dual-tolerant SessionStart hook (`packages/retrospective/hooks/session-start-briefing.sh`) per `P100 slice 2 / ADR-040`. The hook silently no-ops when `docs/briefing/README.md` is absent and reads from it when present, supporting both the legacy single-file `docs/BRIEFING.md` and the new per-topic `docs/briefing/` tree.

What's missing: an automation path for adopters carrying legacy `docs/BRIEFING.md` to migrate to `docs/briefing/`. Dual-tolerant read paths buy time, but a migration command closes the loop.

## Workaround

Manually split `docs/BRIEFING.md` into topic files under `docs/briefing/` per the documented layout. Error-prone and tedious for adopters with substantial briefing content.

## Impact Assessment

- **Who is affected**: every adopter project that carries legacy `docs/BRIEFING.md` from a prior `@windyroad/retrospective` release.
- **Frequency**: one-time per adopter, deferred indefinitely without an automation path.
- **Severity**: Low (dual-tolerant read keeps adopters working; only blocks the per-topic-rotation contract per Tier 3 envelope).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Architect call: amend JTBD-007 (recommended — extend currency scope a third time: code + README + artefact-layout) OR new JTBD-009 (Migrate Adopter Artefacts). **Queued to outstanding_questions** by P204 work-iter 2026-06-06 (AFK orchestrator constraint: no AskUserQuestion in iteration; goal requires user-ratified JTBD amendment/creation first).
- [x] Ship `/wr-retrospective:migrate-briefing` skill: parse legacy `docs/BRIEFING.md`, split by section headings (`## ` H2 markers, code-fence-aware), write per-topic files under `docs/briefing/<topic>.md`, generate README index, retire legacy file as `docs/BRIEFING.md.migrated-<date>`. Foreground-synchronous (ADR-032); self-commits (ADR-014); ships behavioural fixture + contract bats (ADR-052); script invoked via `wr-retrospective-migrate-briefing` PATH shim (ADR-049/ADR-080). Landed 2026-06-06.
- [x] Behavioural fixture: 10 fixture bats + 17 contract bats covering both idempotency directions (tree-present, no-legacy), three-section migration, slug collision (`-2` suffix), code-fence-protected H2, `--dry-run`, `--force`. All 27 pass.

## Fix

The `/wr-retrospective:migrate-briefing` skill ships in `packages/retrospective/skills/migrate-briefing/`:

- `SKILL.md` — contract surface, idempotency clause, ADR cross-references (032/014/038/040/049/052/080), Rule 6 audit
- `REFERENCE.md` — heading-extraction algorithm, slug-collision worked example, code-fence-awareness rationale, README index shape, recovery, scope exclusions
- `scripts/migrate-briefing.sh` — implementation: walks `docs/BRIEFING.md` line-by-line, fence-aware, splits by H2, slugifies headings (kebab + truncate + collision-dedup), atomic-stages to a temp dir, copies into `docs/briefing/`, retires legacy under date-stamped suffix
- `bin/wr-retrospective-migrate-briefing` — ADR-080 shim wrapper on `$PATH`
- `test/migrate-briefing-contract.bats` (17 tests) + `test/migrate-briefing-fixture.bats` (10 tests)
- Registered under `maturity.skills.migrate-briefing` in `.claude-plugin/plugin.json` (Experimental, bootstrapping)
- Changeset `migrate-briefing-skill-p204.md` (minor bump on `@windyroad/retrospective`)

## Verification

Ticket moves to Closed once `@windyroad/retrospective` ships the next release carrying this changeset and an adopter dogfood (or a fresh repo with a synthetic legacy `docs/BRIEFING.md`) demonstrates the migration end-to-end. Until then, this remains Verification Pending.

## Dependencies

- **Composes with**: P100 slice 2 (dual-tolerant SessionStart hook), ADR-040 (per-topic rotation), ADR-051 (README-content-currency), JTBD-007 (Keep Plugins Current).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/117
- **Pipeline classification**: aligned-with-new-JTBD-for-existing-persona (cache_audit_note: new-jtbd-flag); safe-low-fix-risk; route=safe-and-valid + flag.
- **Affected plugin**: @windyroad/retrospective.
