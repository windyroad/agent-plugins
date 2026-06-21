---
status: proposed
rfc-id: p164-phase-2-octal-eval-fix-script-surface-next-id
reported: 2026-06-22
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P164]
adrs: []
jtbd: []
stories: []
---

# RFC-027: Apply `10#` base-10 prefix to script-surface next-ID formula (P164 Phase 2 octal-eval fix)

**Status**: proposed
**Reported**: 2026-06-22
**Problems**: P164
**ADRs**: (none)
**JTBD**: (none)

## Summary

Phase 2 of P164. Bash arithmetic `$(( ... ))` interprets a leading-zero operand as octal; an operand like `008`/`009` is an invalid octal literal and bash aborts with `bash: 008: value too great for base`. Phase 1 (shipped 2026-05-11) fixed the 6 SKILL.md ticket-creator next-ID formulas with the `10#` base-10 prefix. Phase 2 extends the survey to script-surface formulas the original `\$\(\(\s*\$\(echo` grep pattern missed.

The Phase 2 repo-wide survey (all `packages/**/scripts/*.sh`, `packages/**/lib/*.sh`, `packages/**/hooks/**/*.sh`, repo-root `scripts/*.sh`, `bin/`) identified exactly **one** remaining vulnerable surface: `packages/risk-scorer/scripts/extract-risks-from-reports.sh:217` — `NEXT_ID=$(( ${LOCAL_MAX:-0} + 1 ))`, where `LOCAL_MAX` is extracted from zero-padded `R<NNN>` filenames. This is the #273 inbound-reported witness. All other next-ID arithmetic surfaces (`drain-register-queue.sh:80`, `enumerate-postrelease-kv-candidates.sh:90`, `derive-release-vehicle.sh:103`) already carry `10#`; every other zero-padded-ID extraction feeds string/glob contexts only, never `$(( ... ))`.

## Driving problem trace

- **P164** (latent octal-eval bug in next-ID formulas) — Phase 2 closes the script-surface gap of the same root-cause class Phase 1 fixed at the SKILL.md surface. Symptom: `bash: 008: value too great for base` from `extract-risks-from-reports.sh:217` once `docs/risks/R008-*.active.md` exists.

## Scope

Single-surface fix:

1. `packages/risk-scorer/scripts/extract-risks-from-reports.sh:217` — add the `10#` base-10 prefix: `NEXT_ID=$(( 10#${LOCAL_MAX:-0} + 1 ))`. Line 334 (`NEXT_ID=$((NEXT_ID + 1))`) needs no change — by that point `NEXT_ID` is a clean decimal integer with no leading-zero re-entry.
2. Regression bats: synthetic `R008-*.active.md` fixture asserting the script allocates `R009` cleanly without bash error (behavioural per ADR-052), added to `packages/risk-scorer/scripts/test/extract-risks-from-reports.bats`.

Investigation Task 5 (shared `lib/next-id.sh` helper) re-evaluated and kept **deferred** — the next-ID surfaces are heterogeneous (different ID prefixes R/P/ADR; filesystem-only-bootstrap vs ADR-019 dual-source) and each already handles `10#` inline; DRY benefit remains small versus sourcing-order risk. Same conclusion as Phase 1, with stronger evidence (heterogeneity confirmed by the Phase 2 survey). Architect endorsed (no new ADR required — local/reversible choice).

## Tasks

- [x] Broaden the survey grep beyond `\$\(\(\s*\$\(echo` to all bash arithmetic over zero-padded ID strings; survey `packages/**/scripts`, `lib`, `hooks`, repo-root `scripts`, `bin`.
- [x] Apply `10#` fix to `extract-risks-from-reports.sh:217`.
- [x] Add `R008 → R009` regression bats.
- [x] Re-evaluate the deferred `lib/next-id.sh` shared helper (kept deferred).

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
</content>
</invoke>
