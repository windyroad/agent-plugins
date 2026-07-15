# Problem 421: Reference-section awk helpers destructively truncate governance files containing invalid UTF-8

**Status**: Open
**Reported**: 2026-07-05
**Priority**: 6 (Medium) — Impact: 3 (Moderate — destructive truncation of a governance file; git-recoverable but silent) × Likelihood: 2 (Unlikely — requires invalid UTF-8 in the target file; rare) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: M — byte-mode (LC_ALL=C) awk invocations + truncation guard across the reference-section helpers
**WSJF**: 3.0 — (6 × 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

Reference-section awk helpers destructively truncate governance files containing invalid UTF-8 (P334 sibling class). Witnessed 2026-07-05 during the P345 AFK iter: `wr-itil-update-problem-references-section <P345 ticket> "Stories"` hit macOS awk `towc: multibyte conversion failure` on a pre-existing invalid byte pair (`O\xe2\x86\x92\x92\x92KE` — a mangled `→` from an earlier session) and rewrote the ticket with ~45 lines DELETED (everything from the corrupt line through EOF: Investigation Tasks, Dependencies, Related, Change Log, Ratified Direction, `## RFCs`). Data loss was only caught because the staged diff was inspected; recovery needed restore-from-HEAD + manual section append + byte repair (landed in commit 2b1a7529).

Class: any of `packages/itil/scripts/update-{problem,rfc,jtbd}-references-section.sh` (and siblings) running BSD/macOS awk in a UTF-8 locale on a file with invalid bytes silently drops content instead of failing closed.

Fix candidates:

- (a) `LC_ALL=C` byte-mode wrap on the awk invocations (the P334 fix shape, already proven for the compendium generator + bats-gather).
- (b) `iconv -f UTF-8` validation pre-flight that aborts the rewrite (fail-closed) instead of writing a truncated file.
- (c) Both — validate, and byte-mode as belt.

Also note: two stray continuation bytes existed in the committed corpus since an earlier session — a one-off corpus sweep (`iconv -f UTF-8 -t UTF-8 < each md file`) would surface any other latent invalid-byte files before they trigger the same truncation.

## Symptoms

A reference-section helper run against a ticket/RFC/JTBD file containing invalid UTF-8 emits `awk: towc: multibyte conversion failure` on stderr and writes the file back with every line from the invalid byte through EOF missing (the appended section table replaces the dropped tail). Exit code is 0 — the caller sees success.

## Workaround

Inspect the staged diff after every helper run (deletions in a supposedly-additive render = the failure fired); recover via `git restore` + manual section append + byte repair, as done for P345 in commit 2b1a7529. Validate suspect files with `iconv -f UTF-8 -t UTF-8 < file > /dev/null`.

## Impact Assessment

- **Who is affected**: maintainers/agents running capture-story / capture-rfc / manage-rfc flows (any surface invoking the reference-section helpers) on a corpus containing latent invalid bytes; adopters of `@windyroad/itil` on macOS/BSD awk.
- **Frequency**: (deferred to investigation — requires the corpus sweep to count latent invalid-byte files)
- **Severity**: data loss on governance artefacts, silent (exit 0); bounded by git recoverability when caught pre-commit.
- **Analytics**: one witnessed fire (2026-07-05, P345 ticket).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause (confirm the awk section-rewrite path drops post-error lines; enumerate all helper scripts in the class, including non-itil siblings)
- [ ] Create reproduction test (fixture file with an invalid byte + helper run asserting fail-closed, no content loss)
- [ ] One-off corpus sweep: `iconv` -validate every `docs/**/*.md` file; repair any latent invalid-byte files

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P419 (same invocation site, distinct failure mode — gate relock, no data loss)

## Related

- P334 (closed) — sibling class lineage: awk substr Unicode portability in the compendium generator; fix shape was ASCII-ification + `LC_ALL=C`.
- P419 (open) — same reverse-trace helper invocation site; its defect is JTBD-gate policy-hash relock, not byte-safety. Cross-reference, not absorption (hang-off-check verdict 2026-07-05).
- P164 (verifying) — shell-portability survey class; its Phase 2 survey pre-cleared `update-problem-references-section.sh` for the octal class ONLY ("feeds string/glob contexts only, never `$(( ... ))`") — the byte-safety class here is orthogonal to that clearance.
- Hang-off-check arbitration 2026-07-05: PROCEED_NEW over candidates P248/P290/P419/P164/P182 (every overlap incidental or different root cause; P334 outside the open/verifying pre-filter scope).
- Commit 2b1a7529 — the witnessed recovery (restore + manual append + byte repair).

(captured via /wr-itil:capture-problem; expand at next investigation)
