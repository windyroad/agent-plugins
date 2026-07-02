# Problem 405: External-comms gate false-positives on `gh api` security-advisories read path

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 15 (High) — Impact: 3 (Moderate — silently blocks 1 of 3 channels every `/wr-itil:review-problems` Step 4.5c poll; fail-soft branch fires; no security-advisories discovery until fixed) × Likelihood: 5 (Almost certain — deterministic pattern-match; fires every run).
**Origin**: internal
**Effort**: S — regex tighten in the gate: distinguish read-only `gh api` invocations from outbound-draft body writes. WSJF = 15 / 2 = 7.5.
**JTBD**: JTBD-007
**Persona**: developer

## Description

`/wr-itil:review-problems` Step 4.5c polls three channels via `gh` — issues, discussions, security-advisories. The security-advisories poll uses the read-only `gh api repos/<owner>/<repo>/security-advisories --jq ...` shape.

The external-comms gate hook pattern-matches on the substring, not the invocation semantics. Any bash command containing `gh api ... security-advisories` fires the gate as if it were an outbound-draft body write requiring risk/voice review. Witnessed 2026-07-02 during a review-problems partial run — the third channel poll was blocked; audit log recorded the fail-soft skip.

Same defect class as P402 (mark hook doesn't fire on background-launched agents) — external-comms gate hooks pattern-match on shape signals that don't fully discriminate the intended surface.

## Symptoms

- Bash invocation of `gh api ... security-advisories` returns a `BLOCKED (external-comms gate)` deny even when it's read-only.
- Step 4.5c security-advisories channel always fails-soft-skip.
- Audit log records the skip; no security-advisory discovery ever completes.

## Workaround

- Manual `gh api` calls with a different shape (unlikely — the security-advisories endpoint always contains the token).
- Skip the third channel entirely (drop from `.upstream-channels.json`).
- Set `BYPASS_RISK_GATE=1` per-command.

## Impact Assessment

- **Who**: any adopter running `/wr-itil:review-problems` with a `github-security-advisories` channel configured.
- **Frequency**: every review pass; every session.
- **Severity**: Moderate — 1 of 3 discovery channels goes dark. Security advisories are the highest-signal channel for real inbound problem reports; losing it silently is meaningful.

## Root Cause Analysis

### Investigation Tasks

- [ ] Locate the external-comms gate hook's pattern-match regex; identify which token fires on the read path.
- [ ] Distinguish read-only invocations: presence of `--jq` (query-only), absence of `--method POST/PATCH/PUT`, absence of `--input`/`-f` body flags.
- [ ] Add a positive-exclusion: `gh api ... --jq ...` without body-input flags → skip the gate.
- [ ] Behavioural bats: fixture that pipes each of the three Step 4.5c invocations through the gate; assert issues + discussions + advisories all PASS on read-only shape.

## Dependencies

- **Blocks**: `/wr-itil:review-problems` Step 4.5c full three-channel poll.
- **Composes with**: P402 (external-comms gate mark-hook doesn't fire on background agents — different failure mode, same hook family), P395 (external-comms agent silently dormant on credibility axis).

## Related

- **P402** — same hook family; mark-hook side.
- **P395** — external-comms agent credibility axis.
- **ADR-028** — external-comms gate contract.
- `.upstream-channels.json` — the config that triggers the poll.
- Captured via `/wr-itil:capture-problem`; rated at capture per the `.changeset/rate-captures-at-capture.md` direction.
