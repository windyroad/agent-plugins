# Problem 263: CI gate `claude plugin install --dry-run` per plugin pre-publish — ADR-063 Confirmation #11 implementation

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 12 (High) — Impact: 4 (Significant — closes the test-gap class that allowed the P0 manifest break to ship; structural prevention for future plugin.json schema changes) x Likelihood: 1 (Rare — only fires when a future plugin.json schema change creates incompatible top-level keys)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; new CI workflow step + bats coverage)
**Type**: technical

## Description

Surfaced 2026-05-18 by the P0 manifest validity incident (P258 driver). The Phase 3 retroactive rollout (commit d33bb7d, shipped as @windyroad/itil@0.35.1 + 10 sibling plugins) broke `claude plugin install` for all 11 plugins because the new top-level `hooks:` / `skills:` / `agents:` keys with maturity-only records were rejected by Claude Code's manifest validator. The break shipped to npm because CI's pre-publish validation had NO gate that exercised `claude plugin install` against the actual published manifest shape — bats fixtures asserted JSON structure but never ran the installer.

ADR-063 Amendment 2026-05-18 captures this as new Confirmation criterion #11:

> §Confirmation #11 (Manifest validator compatibility): a `claude plugin install <plugin>@windyroad --scope project` against a freshly-published plugin MUST succeed. The Phase 3a bats coverage was insufficient — bats fixtures asserted JSON shape but not installer acceptance. Follow-on iter SHOULD add CI gate that runs `claude plugin install --dry-run` against each plugin pre-publish (P246 sibling-class — gate-the-actual-load-bearing-surface, not a proxy).

This ticket is the implementation of that Confirmation criterion.

## Proposed CI gate shape

A new GitHub Actions step in the CI workflow (e.g. `.github/workflows/ci.yml`) that:

1. For each `packages/<plugin>/.claude-plugin/plugin.json`:
   - Run `claude plugin install <plugin>@<local-marketplace> --dry-run --scope project` (or equivalent — the install validator runs without writing).
   - Capture exit code + stderr.
2. Fail the CI job if ANY plugin's dry-run install fails with validator-rejection.
3. Run pre-publish so the broken manifest never reaches npm.

**Open questions**:

- Does `claude plugin install --dry-run` exist? If not, may need to run a JSON-schema validation against the same schema Claude Code's installer uses (need to extract / reproduce the validator).
- How to install from a local marketplace in CI (vs the published one)? May need a CI-time marketplace setup step.

**Cross-reference (from P258 investigation 2026-05-26)** — partial answer to question 1: the [Claude Code plugins reference](https://code.claude.com/docs/en/plugins-reference) documents **`claude plugin validate <path> --strict`** as the manifest/frontmatter/hooks validation surface; `--strict` promotes warnings (unrecognised top-level keys) to errors, which is exactly the CI posture this gate needs. This is likely a simpler, more stable gate than reproducing the installer's validator — it validates `plugin.json`, skill/agent/command frontmatter, and `hooks/hooks.json` directly. The P258 grounding also clarifies the failure class this gate must catch: a **recognised, type-checked** top-level key (`hooks`/`skills`/`agents`/`commands`) carrying a wrong-typed value is a hard error even *without* `--strict`, whereas an unrecognised key needs `--strict` to surface. Implementation should confirm `claude plugin validate --strict` behaviour in CI before falling back to schema reproduction.

## Symptoms

- Without this gate: future plugin.json schema changes can ship to npm with shapes that break `claude plugin install`. Same class as the P0 incident.
- Bats green is not sufficient evidence that the shipped plugin is installable.

## Workaround

(none — this IS the structural prevention; bats green + manual install testing is the current state).

## Impact Assessment

- **Who is affected**: All future @windyroad/* plugin releases. Every adopter installing them.
- **Frequency**: Rare — the gate prevents the rare class of incident that already happened once.
- **Severity**: Significant (4) — prevents P0-class manifest breakages.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Investigate whether `claude plugin install --dry-run` flag exists; if not, find the alternative validation path.
- [ ] Set up local-marketplace fixture in CI (or use file:// based local marketplace).
- [ ] Add the CI gate step to `.github/workflows/ci.yml` — run before `Validate marketplace manifest` step.
- [ ] Behavioural bats coverage for the gate: positive case (clean manifest passes); negative case (broken hooks/skills shape fails).
- [ ] Update ADR-063 Confirmation #11 from "follow-on iter SHOULD add" to "shipped (P263 implementation)".
- [ ] Cross-reference P246 sibling-class "gate-the-actual-load-bearing-surface".

## Dependencies

- **Blocks**: (none — current bats coverage is the stand-in; the gate is the structural reinforcement)
- **Blocked by**: (none — implementation can start immediately)
- **Composes with**: P258 (root-cause driver ticket — manifest validator schema constraints), P246 (sibling fictional-defer class — gate-the-load-bearing-surface), ADR-063 Amendment 2026-05-18 (the source authority)

## Related

- `.github/workflows/ci.yml` — surface to amend.
- `docs/decisions/063-plugin-maturity-presentation-layer.proposed.md` Amendment 2026-05-18 — source authority.
- P258 — root cause; the P0 incident.
- P246 — sibling-class "gate-the-actual-load-bearing-surface".
- Commit 3cfa6fc — the hotfix that ships the corrected shape.
- Commit d33bb7d — the broken Phase 3 retroactive rollout.

(captured via /wr-retrospective:run-retro Step 4b Stage 1; expand at next investigation)
