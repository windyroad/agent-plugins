# Problem 365: external-comms risk-scorer gate must not fire on git-commit-message surface in private repos

**Status**: Verifying
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal (cross-project witness)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001, JTBD-101
**Persona**: plugin-developer

## Description

External-comms risk-scorer gate must NOT fire on `git-commit-message` surface in private repositories. Cross-project witness from `a separate private adopter repo` (private repo) where the gate blocked a commit message draft, surfacing the BLOCKED stderr directive identical to the public-repo path. Commit messages in private repos are not external-facing comms by any policy class and the gate fire is a pure false-positive class.

Sibling-class to P364 (marker-derivation friction on commit-message surface) but a distinct visibility-class bug — the marker mismatch is a hash drift, this one is a scope drift: the gate should check repo visibility (e.g. `gh repo view --json visibility -q .visibility` returning `PRIVATE` / `INTERNAL`) before firing on git-commit-message surface and silent-pass when repo is non-public.

User direction 2026-06-11: *"this MUST NOT fire for private repos"*.

Fix locus: wr-risk-scorer external-comms hook / agent `SURFACE: git-commit-message` branch — repo-visibility precondition gate before marker-derivation.

## Symptoms

(deferred to investigation)

- Witnessed in `a separate private adopter repo` (private repo) — gate fired on commit-message surface, BLOCKED with the same stderr directive seen in the public agent-plugins repo.

## Workaround

(deferred to investigation)

- `BYPASS_RISK_GATE=1` env override at commit time (documented existing escape hatch; coarse-grained — bypasses ALL surfaces not just commit-messages).

## Impact Assessment

- **Who is affected**: (deferred to investigation) — every adopter on a private/internal repo who hits the gate at commit time.
- **Frequency**: (deferred to investigation) — fires on every gated commit (PreToolUse).
- **Severity**: (deferred to investigation) — false-positive friction class; no security implication (private repo content stays private).
- **Analytics**: (deferred to investigation).

## Root Cause Analysis

**Confirmed root cause**: The `git-commit-message` surface (added by ADR-028's P082 amendment) gated commit-message bodies unconditionally, on the premise — stated in the hook's own surface comment — that the body "reaches every reader of git log, PR commits tab, release-page auto-notes, CHANGELOG." That premise holds **only when the repo is public**. The surface carried no precondition checking that the commit's eventual destination is actually external, so in a private/internal repo (no external reader) the marker-review delegation deny fired on every normal commit as a pure scope-class false-positive. Distinct from P364 (a marker-key hash-drift on the same surface) — P365 is a scope drift.

**Fix shipped (2026-06-16)**: A repo-visibility precondition was added to the canonical `packages/shared/hooks/external-comms-gate.sh` (synced byte-identically to risk-scorer + voice-tone via `scripts/sync-external-comms-gate.sh`), placed AFTER the leak-pattern pre-filter and BEFORE the marker gate. When `SURFACE = git-commit-message`, the gate resolves `gh repo view --json visibility -q .visibility` and silent-passes on any non-`PUBLIC` result.

**Policy decision** (resolving the Investigation Task below): **silent-pass entirely** on non-public, NOT pass-but-still-mark-reviewed. User direction ("this MUST NOT fire for private repos") forecloses the mark-reviewed option (it would still require the review ceremony). Two refinements within that direction:
- **Fail-non-public on indeterminate** — gh absent / unauthenticated / no remote / API error (empty result) is treated as non-public and silent-passes. A commit message is only *demonstrably* external when the repo is confirmably PUBLIC. The residual is a narrow, bounded fail-open: a single commit's tone/prose review is skipped in a genuinely-public repo where gh is transiently unavailable.
- **Leak pre-filter preserved** — the credential / prod-URL `leak_detect_scan` still runs for every surface in every repo (placement is after it), so committing a secret into git history is still hard-failed regardless of visibility. Only the prose-review deny is silenced for non-public repos.

Recorded as ADR-028 Amendment 2026-06-16 (P365). No RISK-POLICY.md change needed — the surface-by-surface visibility logic lives in the gate, and the policy doc governs leak classes (unchanged).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Locate the `SURFACE: git-commit-message` branch in the external-comms hook + agent prompt — gate hook line ~155-167 (surface detect) + ~321 (marker gate); fix is hook-side only, agent unchanged (agent only runs when delegated)
- [x] Add repo-visibility precondition check using `gh repo view --json visibility -q .visibility` — done; indeterminate result treated as non-public
- [x] Decide policy: silent-pass entirely on PRIVATE+INTERNAL — chosen (per user direction); NOT pass-but-still-mark-reviewed
- [x] Behavioural bats: PRIVATE → silent-pass; INTERNAL → silent-pass; PUBLIC → existing behaviour preserved — added to both consumers' `external-comms-gate.bats` (plus indeterminate-gh, surface-scoping, and credential-still-fails regression guards)
- [x] Document the policy — recorded as ADR-028 Amendment 2026-06-16 (P365); RISK-POLICY.md unchanged (gate-side logic, not a leak class)

## Fix Released

**Status**: Verification Pending (committed, not yet released).

- **Commit**: external-comms gate repo-visibility precondition for the git-commit-message surface (P365).
- **Files**: `packages/shared/hooks/external-comms-gate.sh` (canonical) + synced `packages/{risk-scorer,voice-tone}/hooks/external-comms-gate.sh`; behavioural bats in both consumers; ADR-028 amendment + compendium README entry; changeset (`@windyroad/risk-scorer` + `@windyroad/voice-tone` patch).
- **Tests**: `external-comms-gate.bats` green in both packages (risk-scorer 32, voice-tone 30); `scripts/sync-external-comms-gate.sh --check` green (byte-identity).
- **Verify after release**: in a private/internal adopter repo, `git commit -m "..."` no longer surfaces the BLOCKED external-comms directive; in a public repo the gate still fires; a credential-shaped body still hard-fails in any repo.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P364 (sibling-class marker-derivation friction on the SAME surface) — both should be fixed together if practical.

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)
- P364 — sibling class on the same surface (marker-derivation friction; hash-drift class). This ticket is the scope-drift class.
- P353 — original marker-derivation friction precedent.
