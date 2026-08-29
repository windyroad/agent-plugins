# Problem 415: External-comms commit-msg gate reviews only the first `-m` of a multi-`-m` git commit, causing deny-after-PASS on multi-paragraph commits

**Status**: Verification Pending
**Reported**: 2026-07-03
**Priority**: 6 (Medium) — Impact: 2 (Minor — deny-after-PASS friction, recoverable re-review) × Likelihood: 3 (Possible — multi-`-m` commits recur; observed) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: inbound-reported (#395) — stamped 2026-08-21 review from the upstream poll; upstream filing `wr-risk-scorer: external-comms gate leak-scans only the first -m value of a git commit`
**Effort**: S — accumulate ALL `-m` occurrences in the gate's extraction loop + bats
**WSJF**: 12 — (6 × 2.0) / 1 (2026-07-26 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; multiplier 1.0 → 2.0)
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

The external-comms-gate PreToolUse command parser (`packages/risk-scorer/hooks/external-comms-gate.sh`, canonical `packages/shared`, synced to voice-tone) extracts the commit-message body via a first-match-wins regex loop over `-m '...'` / `-m "..."` patterns that `break`s on the first hit. For a `git commit -m SUBJECT -m BODY -m TRAILER` (the multi-paragraph AI-canonical form), the gate therefore hashes ONLY the subject line, while the `wr-risk-scorer:external-comms` reviewer agent hashes the FULL draft wrapped in `<draft>...</draft>`. The two marker keys diverge, so the commit re-blocks with "draft has not been reviewed" even after a genuine `EXTERNAL_COMMS_RISK_VERDICT: PASS` — a permanent deny-after-PASS for any multi-`-m` commit.

## Symptoms

`git commit -m "subject" -m "para2" -m "..." -m "Co-Authored-By: ..."` blocks at the external-comms gate. Delegating to `wr-risk-scorer:external-comms` with the full message wrapped in `<draft>...</draft>` returns PASS and writes a marker keyed on the FULL message hash — but the gate recomputes the key from only the first `-m` (subject line) and finds no marker, so the retry re-blocks. Verified 2026-07-03: the reviewer marker `external-comms-risk-reviewed-9cfde227…` existed in `${TMPDIR}/claude-risk-$SID/`, its key matched `compute_external_comms_key "$FULL_MESSAGE" git-commit-message`, but the gate's key (subject-only) differed.

## Workaround

Pass the ENTIRE commit message as a SINGLE inlined double-quoted `-m "subject⏎⏎body⏎⏎trailer"` (the gate parses the raw command string — NOT shell-expanded `$VARS` — and its `-m "([^"]*)"` capture spans newlines, so it captures the whole body). Wrap that same full text as the reviewer `<draft>`. The two keys then match and even a pre-existing full-message marker is reused. Verify: `source packages/risk-scorer/hooks/lib/external-comms-key.sh; compute_external_comms_key "$FULLMSG" git-commit-message` must equal the marker filename suffix.

## Impact Assessment

- **Who is affected**: plugin-developer / AFK orchestrator iters (and any adopter) that build multi-paragraph commits with multiple `-m` flags — the AI-canonical commit shape. Every such commit re-blocks after a genuine PASS until collapsed to a single `-m`.
- **Frequency**: every multi-`-m` commit that touches an external-comms-gated surface (commit-message gating fires on public repos per P365). 3 blocked attempts in one iter 2026-07-03.
- **Severity**: Medium — recoverable (collapse to single `-m`) but the recovery is non-obvious and burns multiple round-trips + a reviewer dispatch each time; trains agents toward fragile marker hand-landing.
- **Analytics**: detectable by a gate deny immediately following an `EXTERNAL_COMMS_RISK_VERDICT: PASS` for the same session where the commit command carried ≥2 `-m` flags.

## Root Cause Analysis

The `-m` extraction in `external-comms-gate.sh` returns the FIRST regex match and `break`s, rather than accumulating ALL `-m`/`--message` occurrences and joining them with a blank line (git's own multi-`-m` composition rule) before hashing. The reviewer hashes the full authored message; the gate hashes a subset; the keys cannot match. Fix: change the parser to collect every `-m`/`--message` value in order and join with `\n\n` before computing the marker key — mirroring how git itself composes the final message. Edit the canonical `packages/shared/hooks/external-comms-gate.sh` + run its sync script (per `feedback_edit_canonical_synced_hook_not_consumer_copy`); consumer copies in risk-scorer + voice-tone ship via the sync.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — confirmed the first-match-`break` in the `-m` pattern loop; repeated values now use Git's `\n\n` composition
- [x] Create reproduction test — behavioural bats: multi-`-m` commit + full-message reviewer marker → gate PASS

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P353 (hash-marker brittleness umbrella), P082 (commit-message gating origin)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check skipped — candidate-cap short-circuit (P346 sub-step 2b)**: the mechanical pre-filter matched >5 open/verifying candidates on shared external-comms-gate signals (>20 hits); subagent dispatch skipped per SKILL contract; re-evaluate absorption at next /wr-itil:review-problems. **Nearest candidates by scope**: P364 (external-comms-gate marker-key mismatch on backtick-bearing gh bodies — same deny-after-PASS marker-key-divergence class, different input trigger: shell unescape vs multi-`-m` parser coverage), P353 (hash-marker brittleness umbrella — external-comms highest-friction surface; this is a new sub-instance), P276 (marker over-fires on PASS-class content edits), P082 (commit-message gating — the origin gate whose parser carries this defect, verifying), P365 (gate must not fire on commit-message in private repos — same surface, visibility axis). This ticket may fold into P353 as a sub-instance OR P082 as an implementation defect at review time.
- **Secondary observation (not the root defect)**: a stale user-scope `@windyroad/risk-scorer@0.13.5` install co-fires alongside this project's `0.16.0` gate (version skew across scopes). Both compute the same key for this clean draft, so the skew did not change the outcome here, but co-firing gates of different vintages is a latent divergence risk worth noting.
- **Witnessed**: 2026-07-03 AFK work-problems P363 (inbound-verdict K→V) iter — 3 blocked commit attempts with a 4×`-m` message before collapsing to a single inlined `-m`.

## Fix Strategy

**Kind**: improve
**Shape**: hook (bash parser)
**Target file**: `packages/shared/hooks/external-comms-gate.sh` (canonical; sync to risk-scorer + voice-tone consumer copies via the sync script)
**Observed flaw**: the `-m`/`--message` extraction returns the first regex match and `break`s, hashing only the subject line of a multi-`-m` commit.
**Edit summary**: accumulate ALL `-m`/`--message` values in command order and join with `\n\n` (git's multi-`-m` composition rule) before computing the marker key, so the gate hashes the same full message the reviewer wraps in `<draft>`.
**Evidence**: 3 blocked commit attempts 2026-07-03 P363 iter; marker key `9cfde227…` (full message) present but gate computed subject-only key.
**Release vehicle**: `.changeset/calm-complete-messages.md` (published 2026-08-29 in `@windyroad/risk-scorer@0.18.19` and `@windyroad/voice-tone@0.8.1`)

## Fix Implemented

- 2026-08-29 — commit `ff974cc1` updates the canonical shared hook, synchronizes the risk-scorer and voice-tone copies, and adds the focused behavioural regression.
- Verification: the external-comms Bats suite passed 38/38; fresh package extracts for both affected packages passed multi-message, single-message, and heredoc marker scenarios; the sync check confirmed byte-identical consumer copies.
- Lifecycle: the affected packages are published, satisfying the release-evidence gate for Verification Pending; post-release invocation evidence is still required for closure.

## Fix Released

- Released 2026-08-29 in `@windyroad/risk-scorer@0.18.19` and `@windyroad/voice-tone@0.8.1`.
- Implementation: `ff974cc1aa8a71f7797b943774646a65fd30d21c`; CI run `33246430346` completed successfully with that implementation in its ancestry.
- Release: workflow run `33246825673` completed successfully at release merge `5b80b942330d1699dfe32fc8dc80c2861cb7aa33`; npm registry readback returned both published versions.
- Fix summary: repeated quoted `-m` and `--message` values are reconstructed in command order and joined with Git's blank-line paragraph separator before marker lookup.
- Awaiting post-release invocation evidence; publication alone does not verify the installed hook journey.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-071 | STORY-071: Review the complete commit message once | done |
