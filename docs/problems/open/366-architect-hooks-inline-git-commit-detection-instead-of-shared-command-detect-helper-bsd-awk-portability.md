# Problem 366: Architect hooks inline `git commit` leading-token detection in awk instead of the shared `command_invokes_git_commit` helper — BSD-awk `\b` portability bug propagated via template-copy

**Status**: Open
**Reported**: 2026-06-16
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Description

Architect hooks inline their own `git commit` leading-token detection in awk instead of delegating to the shared `command_invokes_git_commit` helper that the itil P165 family uses — a P268-family consistency + portability gap.

Evidence (P337 iter 10, 2026-06-16): the retired `architect-compendium-refresh-discipline.sh` inlined `awk '/^git[[:space:]]+commit\b/'`. The `\b` word-boundary is a GNU-awk extension that BSD awk (macOS) does not match, so the leading-token check silently returned false, fell through `|| exit 0`, and the hook's deny never fired. Permit-path bats stayed green either way (they expect exit 0); only a deny-path fixture caught it. The new `architect-readme-pairing-check.sh` (RFC-014 Story B) fixed the `\b` to the portable `commit([[:space:]]|$)` but STILL inlines its own awk rather than using a shared helper.

By contrast itil's `itil-readme-refresh-discipline.sh` delegates to `packages/itil/hooks/lib/command-detect.sh::command_invokes_git_commit` (P268; siblings 272/274/275) — a shared, tested helper that already solved the substring-match (P268) and leading-token problems once.

## Symptoms

- A latent BSD/GNU awk-portability bug rode along when an architect hook was authored by copying an existing hook template.
- The architect commit-detection logic is re-implemented per hook rather than sourced from a shared, tested helper, so each copy can re-introduce the bugs the P268 family already fixed in the itil lib.
- Same BSD/GNU awk-divergence class as P334/P328.

## Workaround

(deferred to investigation) — the immediate `\b` instance is already fixed in `architect-readme-pairing-check.sh` (portable `commit([[:space:]]|$)`); no live `\b` bug remains. The structural gap (inline-awk vs shared helper) is the residual.

## Impact Assessment

- **Who is affected**: plugin maintainers (architect hook authors); adopters whose commits the architect hooks gate.
- **Frequency**: every new architect commit-detecting hook that copies an existing template.
- **Severity**: (deferred to investigation) — modest; consistency/refactor class, no current live defect.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Decide whether to extract/promote a shared command-detect helper to `packages/shared/` (cross-plugin) or duplicate-and-sync the itil `lib/command-detect.sh` into architect's `hooks/lib/` (composes with P304 — `packages/shared/` bundler approach)
- [ ] Refactor `architect-readme-pairing-check.sh` (and any other architect commit-detecting hook) to use the shared `command_invokes_git_commit` helper
- [ ] Add a deny-path bats fixture as the regression guard (permit-path-only coverage is what let the `\b` bug hide)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P304 (`packages/shared/` bundler-based shared-code approach — the natural home for a shared command-detect helper); P268 family (272/274/275 — the itil-side siblings of this command-detection-consistency class)

## Related

(captured via /wr-itil:capture-problem during the P337 work-problems iter 10 retro, 2026-06-16; expand at next investigation)

- **P268** (verifying) + siblings **272/274/275** (verifying) — the itil-side command-detection family. This is the architect-surface instance not previously ticketed. Hang-off considered: P268 + siblings are all in `verifying/` (specific-hook fixes awaiting verification, not an open tracker) and the family convention is one-sibling-per-hook-surface, so PROCEED_NEW as a sibling rather than absorbing into a verifying ticket (which would reopen it).
- **P334** / **P328** — BSD/GNU awk-portability class (same divergence the `\b` bug belongs to).
- **P304** — `packages/shared/` bundler-based shared-code approach; the shared command-detect helper's natural home.
- `packages/itil/hooks/lib/command-detect.sh::command_invokes_git_commit` — the shared helper architect should reuse.
- `packages/architect/hooks/architect-readme-pairing-check.sh` — the architect hook that currently inlines its own (now-portable) awk.
