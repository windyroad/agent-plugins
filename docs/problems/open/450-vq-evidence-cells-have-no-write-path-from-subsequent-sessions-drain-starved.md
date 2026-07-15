# Problem 450: Verification Queue evidence cells are never populated from subsequent-session exercises, so the run-retro Step 4a auto-drain never fires

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 12 (High) — Impact: 3 (Moderate — the verification pipeline's automated drain is structurally starved; downstream queue grew to 47 tickets requiring a manual 4-agent triage to close 30; this repo's queue sits at ~190 with the same dynamic) × Likelihood: 4 (Likely — continuous: every verifying fix exercised in a later session fails to get its cell updated) — derived at capture per Step 4a
**Origin**: inbound-reported (#323)
**Effort**: M — a write-path mechanism (run-retro sub-step and/or per-session VQ-exercise detector) that records `yes — observed: <evidence>` when a later session exercises a verifying fix; design must stay honest per ADR-026 (observed proof, not inference)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The Verification Queue evidence-first cells (the `Likely verified?` column in `docs/problems/README.md`, canonical P186 values) are never populated with a `yes — observed:` value from subsequent-session live exercises. The run-retro Step 4a prior-session evidence drain (sub-step 9, P282) fires ONLY on rows whose cell already reads `yes — observed:`, but nothing writes that value when a later session or published edition exercises a verifying fix. Result: verifying tickets sit indefinitely — the downstream queue accumulated to 47 before a manual evidence-triage drain (four parallel read-only agents) closed 30 on 2026-06-28; the automated drain never triggered because every cell read `no (not observed)`.

The producer gap is the missing half of the P186 evidence-first design: P186 shipped the cell shape and the drain consumes it, but no mechanism writes the observed-evidence value between reviews. (Witnessed in this repo too: the 2026-07-15 review pass had to derive 7 close-on-evidence verdicts from scratch because no cell carried evidence despite months of live exercise.)

## Symptoms

- Every VQ row reads `no — not observed` regardless of how often the fix has been exercised since release.
- run-retro Step 4a sub-step 9 scans find zero `yes — observed:` rows across multiple retros and close nothing.
- Queue drains happen only via manual evidence-triage passes.

## Workaround

Run a manual evidence-triage drain when the queue grows: read each verifying ticket's `## Fix Released` section, gather observable evidence (fix on disk + exercised by a later session / test suite / installed version), batch-close the evidenced ones (the downstream 2026-06-28 drain and this repo's 2026-07-15 review-pass closes are worked examples). Conservative bar: close only on observed proof.

## Impact Assessment

- **Who is affected**: developer persona — every suite adopter running the verification lifecycle.
- **Frequency**: continuous.
- **Severity**: Moderate — automated drain defeated; manual triage cost recurs.
- **Analytics**: downstream repo tracked as P106; this repo's VQ ≈190 rows, all `no — not observed` before 2026-07-15.

## Root Cause Analysis

### Investigation Tasks

- [ ] Design the evidence write-path: where does a later session detect "this action exercised verifying ticket P<NNN>'s fix" and write the cell? (run-retro sub-step; possibly a lightweight per-skill exercise hook.)
- [ ] Keep the honesty bar: cell writes must cite ADR-026-grounded observations, never age or inference.
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P375 (named-re-entry vs self-firing cadence — class-adjacent instance: the drain exists but its input producer never fires), P186 lineage (closed — shipped the cell shape this ticket's producer feeds)

## Related

- Upstream issue #323 (inbound; reporter's downstream ticket P106).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P375's ratified fix (authoring-time deferral-cadence gate) creates no evidence producer and its own sibling-survey warns against rollup absorption; P414 is the wrap deferring a mechanical rotation (different step/defect); P433 is a close-time completeness scan, upstream of which rows never become closeable here.
