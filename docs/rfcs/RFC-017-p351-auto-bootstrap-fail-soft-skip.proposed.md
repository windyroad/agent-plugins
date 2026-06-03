---
status: proposed
rfc-id: p351-auto-bootstrap-fail-soft-skip
reported: 2026-06-03
decision-makers: [Tom Howard]
problems: [P351]
adrs: [ADR-013, ADR-044, ADR-049, ADR-052, ADR-062, ADR-071]
jtbd: [JTBD-101, JTBD-007]
stories: []
---

# RFC-017: P351 — auto-bootstrap on missing precondition config (witnessed instance + structural lint)

**Status**: proposed
**Reported**: 2026-06-03
**Problems**: P351
**ADRs**: ADR-013 (AskUserQuestion is the structured user-interaction surface — Rule 6 non-interactive fail-safe routes the AFK branch), ADR-044 (decision-delegation contract — category 1 direction-setting routes the bootstrap question; category 4 silent-framework boundary preserved at the malformed-JSON branch), ADR-049 (PATH shim for lint dispatch), ADR-052 (behavioural bats default for lint coverage), ADR-062 (inbound-discovery surface where the witnessed instance lives — Downstream-adopter non-obligation preserved via the decline-permanently empty-stub surface), ADR-071 (every fix goes through an RFC — why this RFC exists)
**JTBD**: JTBD-101 (Extend the Suite — silent skip violates the deliver-installed-features expectation), JTBD-007 (Keep Plugins Current — "process reports what changed, what stayed the same, and what failed")

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P351 fix under the RFC-first framework per ADR-071. It carries **no independent architectural decisions**: the auto-bootstrap routine's shape (one-prompt-per-session interactive / direction-queue AFK / decline-permanently empty-stub) was architect-resolved on the prior review (`a6747bd57c7953b14` — APPROVED-WITH-CONDITIONS). The condition was the RFC trace itself; this RFC IS that trace. Pattern modelled on RFC-015 (the P333 retro-fit) per architect direction. Status transitions `proposed → verifying` alongside the P351 ticket on `@windyroad/itil` release per ADR-022 fold-fix.

## Summary

P351: skills with config-file preconditions (`.upstream-channels.json`, etc.) silently fail-soft-skipped on missing config. The user direction (2026-06-03 with screenshot evidence) named the pattern as broken: *"this is a problem. the skill should auto-bootstrap (with user input as needed) rather than skipping."*

The fix has two parts:

1. **Witnessed-instance fix** at `packages/itil/skills/review-problems/SKILL.md` Step 4.5a. Replaces the prior "missing file → skip Step 4.5 entirely" prose with a state-branched auto-bootstrap routine. Interactive mode prompts for channel-type + per-channel coordinates (single batched `AskUserQuestion` ≤4 questions per ADR-013 Rule 1), previews the planned JSON before writing (JTBD persona-fit constraint), writes the config, resumes the original pass. AFK mode queues a `direction` outstanding_question per `/wr-itil:work-problems` Step 5 schema (ADR-044 category 1) so loop-end Step 2.5 surfaces it as batched `AskUserQuestion`; the iter continues other passes for THIS run. Decline-permanently surface writes `{"channels": [], "ttl_seconds": 86400, "declined_at": "<ISO>"}` so adopters who never want inbound-discovery keep zero ceremony tax per ADR-062 § Downstream-adopter non-obligation. Malformed-JSON branch preserved as genuine fail-soft (the adopter shipped a config; auto-rewriting would destroy their work).

2. **Structural lint** at `packages/itil/scripts/check-fail-soft-skip-discipline.sh` (canonical) + `packages/itil/bin/wr-itil-check-fail-soft-skip-discipline` (ADR-049 PATH shim) that walks `packages/*/skills/*/SKILL.md` and emits a WARN per matching prose pattern. Tightened pattern set per architect review: `fail-soft skip|silently skip|skipping.*config|skipping.*not configured|not configured.*skip` (the bare `skipping` pattern false-positives on legitimate per-channel skip prose). Phase 1 advisory (exit 0); CI wires it as `continue-on-error: true`. Phase 2 promotion via `WR_FAIL_SOFT_SKIP_WARN_ONLY=0` once every WARN'd file has been migrated.

## Driving problem trace

- **P351** (`docs/problems/verifying/351-skills-fail-soft-skip-when-precondition-config-missing-should-auto-bootstrap-with-user-input.md`) — Step 4.5a fail-soft-skip witnessed instance + class-of-pattern signal. Status: Verification Pending (fold-fix per ADR-022 P143 lands the verifying transition in the same commit as the fix).

## Scope

Single-commit landing (this RFC's capture commits alongside the fix per ADR-014):

- `packages/itil/skills/review-problems/SKILL.md` Step 4.5a — replace the silent-skip prose with the auto-bootstrap routine.
- `packages/itil/scripts/check-fail-soft-skip-discipline.sh` — new lint script.
- `packages/itil/bin/wr-itil-check-fail-soft-skip-discipline` — new ADR-049 PATH shim (synced from `packages/shared/lib/shim-wrapper-template.sh`).
- `packages/itil/scripts/test/check-fail-soft-skip-discipline.bats` — behavioural bats per ADR-052.
- `.github/workflows/ci.yml` — advisory step.
- `docs/problems/verifying/351-*.md` — fold-fix ticket transition.
- `.changeset/p351-auto-bootstrap-fail-soft-skip.md` — `@windyroad/itil` patch changeset.

## Decisions carried (none — routine shape resolved architect-PASS)

Architect review verdict `a6747bd57c7953b14`:

- ADR-013 (PASS) — interactive `AskUserQuestion` once per skill invocation; AFK routes to `outstanding_questions` per Rule 6.
- ADR-014 (PASS) — single commit per ADR-014.
- ADR-022 (PASS) — P057 staging re-apply on `git mv` + `## Fix Released` section is the correct fold-fix pattern.
- ADR-026 (PASS) — bootstrap prose grounds each `AskUserQuestion` field by referencing 4.5c's existing channel-type list.
- ADR-044 (PASS) — bootstrap is direction-setting (category 1), correctly routed.
- ADR-049 (PASS) — shim shape matches existing pattern.
- ADR-052 (PASS) — WARN-on-fixture / CLEAN-on-fixture are behavioural; existence checks acceptable per repo `.bats` convention.
- ADR-062 (PASS) — fail-soft contract preserved for the malformed-JSON branch + decline-permanently empty-stub surface.

Architect condition: ADR-071 unconditional RFC-first requires a thin RFC. This RFC IS that condition's satisfaction (modelled on RFC-015 per architect direction).

JTBD review verdict `ae67127915ad3c9c1`:

- JTBD-101 aligned (Extend the Suite — silent fail-soft skip inverts deliver-installed-features expectation; auto-bootstrap restores it).
- JTBD-007 secondary alignment (Keep Plugins Current — silent no-op against installed capability is the failure class).
- All three referenced JTBDs / personas exit=1 ratified (no Unratified Dependency flag).
- Persona-fit constraints: preserve fail-soft as last-resort if bootstrap declined (decline-permanently surface satisfies); AFK branch continues other passes (already in scope); preview file contents before writing (added to interactive-mode routine).

Alternatives considered + rejected as below-ADR-bar:

- **Default-skeleton scaffold with placeholders** — risks adopters never reviewing the placeholder; degrades to a different silent failure mode.
- **Block the pass until configured** — violates ADR-062 § Downstream-adopter non-obligation; adopters who don't want inbound-discovery cannot use the skill at all.
- **Per-pass prompt** — re-asks the same question at every invocation; the "one-prompt-per-session + decline-permanently surface" pair handles the recurrence correctly.

## Deferred (advisory, captured for follow-up)

1. **17 sibling WARN sites** the lint flagged in the source repo (the inline-rotation `silently skip` directive class across `manage-problem` / `manage-rfc` / `manage-story` / `transition-problem` / `review-problems` + the `silently skip` literal in `work-problems` / `check-upstream-responses` / `run-retro`). Phase 1 advisory expectation: SKILL.md authors disambiguate per site. Follow-on tickets may pick these up.
2. **Pattern codification** — the auto-bootstrap routine itself (config-path-check → propose-scaffold → AskUserQuestion-or-direction-queue → write → resume) is a candidate for a shared helper at `packages/itil/lib/auto-bootstrap-config.sh`. Deferred per user-pinned scope: "fix the WITNESSED instance only + ship the lint". A follow-on RFC may extract the pattern when the second affected skill needs it.
3. **`@jtbd` source-annotation** near the Step 4.5a auto-bootstrap routine — annotation added inline as HTML comments per existing SKILL.md convention. A follow-on may promote to file-level frontmatter when that convention lands.

## Tasks

- [x] SKILL.md Step 4.5a amendment (auto-bootstrap routine).
- [x] `packages/itil/scripts/check-fail-soft-skip-discipline.sh` (canonical lint script).
- [x] `packages/itil/bin/wr-itil-check-fail-soft-skip-discipline` (ADR-049 PATH shim — synced template).
- [x] `packages/itil/scripts/test/check-fail-soft-skip-discipline.bats` (behavioural bats per ADR-052).
- [x] `.github/workflows/ci.yml` advisory step (continue-on-error).
- [x] P351 fold-fix transition (Open → Verification Pending; `docs/problems/open/` → `docs/problems/verifying/`).
- [x] `.changeset/p351-auto-bootstrap-fail-soft-skip.md` `@windyroad/itil` patch.
- [ ] Release the held changeset → P351 `Verifying → Closed` (release-gated; this RFC `proposed → verifying`).

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Verification

The held `@windyroad/itil` changeset `p351-auto-bootstrap-fail-soft-skip` is the release marker. On release, P351 transitions `Verifying-by-fold-fix → Closed-by-release-evidence` per ADR-022 and this RFC transitions `proposed → verifying`. User-side verification: a `/wr-itil:review-problems` invocation in an adopter tree WITHOUT `.upstream-channels.json` should fire the auto-bootstrap routine (interactive prompt) rather than silently skipping; an `/wr-itil:work-problems` AFK invocation in the same tree should queue a `direction` outstanding_question that surfaces at loop-end Step 2.5. The behavioural bats covers the lint contract; the SKILL.md amendment is exercised at runtime via the Step 4.5a code path.

## Related

- **P351** — driving problem ticket (Verification Pending; fold-fix landed alongside this RFC).
- **ADR-013** — AskUserQuestion as structured user-input surface; Rule 6 non-interactive fail-safe routes the AFK branch.
- **ADR-044** — decision-delegation contract; bootstrap is category-1 direction-setting; malformed-JSON skip stays category-4 silent framework action.
- **ADR-049** — PATH shim for adopter-safe script resolution.
- **ADR-052** — behavioural bats default for lint coverage.
- **ADR-062** — inbound-discovery surface where the witnessed instance lives; Downstream-adopter non-obligation preserved via decline-permanently surface.
- **ADR-071** — every fix goes through an RFC; this RFC is the unconditional-trace compliance instance for the P351 fix.
- **RFC-015** — the P333 retro-fit RFC this RFC's structure is modelled on (thin problem-traced retro-fit, no independent decisions).
- **JTBD-101** — Extend the Suite; silent fail-soft skip violates deliver-installed-features expectation.
- **JTBD-007** — Keep Plugins Current; silent skip is a no-op against installed capability.
- **P065** (closed) — `/wr-itil:scaffold-intake` sibling-pattern precedent for bootstrapping config artefacts at adopter install time.
