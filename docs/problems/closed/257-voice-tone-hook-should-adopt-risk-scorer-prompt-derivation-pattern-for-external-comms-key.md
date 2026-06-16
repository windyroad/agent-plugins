# Problem 257: voice-tone hook should adopt risk-scorer's prompt-derivation pattern for EXTERNAL_COMMS_VOICE_TONE_KEY

**Status**: Closed (resolved-by-P166 — fix landed in source before this ticket was captured; verified released + behaviourally tested)
**Reported**: 2026-05-18
**Closed**: 2026-06-17 (AFK work-problems iter-41)
**Priority**: 1 (Low) — Impact: 3 x Likelihood: 1 (re-rated at closure; symptom is now structurally impossible — see Resolution)
**Effort**: (none — fix already shipped; this iter is a paperwork/verification reconciliation only)

## Resolution (2026-06-17, AFK work-problems iter-41)

**Resolved-by-P166. No code change required — the fix this ticket recommends had already landed in source two days before the ticket was captured.**

The voice-tone evaluator hook
(`packages/voice-tone/hooks/external-comms-mark-reviewed.sh`) was amended to
use `derive_external_comms_key_from_prompt` on **2026-05-16** by commit
`9111efc3` *"fix(external-comms): hook-side sha256 derivation eliminates
double-invocation (closes P166, closes P163)"*. P257 was captured
**2026-05-18** — the user approved a deviation to do work the P166/P163
cluster fix had already delivered at the voice-tone surface.

The shipped implementation does **exactly** the architect-recommended
transition-support shape from the Investigation Tasks ("replace literal-key
read with helper-derived key, **keeping literal-as-fallback**"):
- PRIMARY: derive key from `tool_input.prompt` via
  `derive_external_comms_key_from_prompt` (hook lines 106–113).
- FALLBACK: agent-emitted `EXTERNAL_COMMS_VOICE_TONE_KEY` honoured during
  the deprecation window.

**Convergence evidence (verified from own observation, iter-41):**
- Per-package helper `packages/voice-tone/hooks/lib/external-comms-key.sh`
  is **byte-identical** to canonical `packages/shared/hooks/lib/external-comms-key.sh`
  (`diff` clean) — ADR-017 sync satisfied.
- Behavioural coverage exists and is **GREEN 6/6**:
  `packages/voice-tone/hooks/test/external-comms-mark-prompt-parse.bats`.
  Test 3 (*"PASS with structured prompt AND agent-emitted KEY: hook-derived
  key wins"*) directly encodes P257's friction case — a fabricated
  placeholder key emitted by the agent is **ignored**; the hook uses the
  prompt-derived key. The original symptom (placeholder-key fabrication →
  format-valid-but-wrong → gate denies → manual `touch`) is now
  **structurally impossible**.
- **Released**: shipped continuously through `@windyroad/voice-tone@0.5.14`
  (the stale-cache 0.5.0 noted at capture-time has long since refreshed; the
  surface has been re-touched and re-released by P276/0.5.11, 0.5.12, 0.5.13,
  P360/0.5.14).
- **In-the-wild observation, THIS session**: iters 35 (P364) and 39 (P360)
  shipped changesets through the voice-tone external-comms gate without the
  placeholder-key friction or manual-`touch` workaround P257 describes — the
  voice-tone marker auto-wrote from prompt derivation.

Closed as a duplicate-of / resolved-by P166 (parallel to the P264→P252
duplicate-closure precedent). P166 itself remains in `verifying/` as the
broader double-invocation fix spanning both evaluator surfaces; P257 is the
narrow voice-tone slice, verified at closure.

## Description

User-approved deviation-candidate from iter 8 + iter 10 of `/wr-itil:work-problems` session 6 (2026-05-18). The voice-tone evaluator hook (`packages/voice-tone/hooks/external-comms-mark-reviewed.sh`) reads the agent-emitted `EXTERNAL_COMMS_VOICE_TONE_KEY` literally — meaning the agent must emit a pre-computed 64-hex-char key in its verdict that matches what the gate computed. The risk-scorer hook (0.10.0) has already evolved to derive the key from the prompt structure via the shared `derive_external_comms_key_from_prompt` helper at `packages/shared/hooks/lib/external-comms-key.sh`.

This asymmetry between the two evaluator hooks is the recurring friction surface — agents calling the voice-tone evaluator end up fabricating placeholder hex keys (e.g. `5f7a2c1d...`, `6c8f3e7a...`), the hook validates them as 64-hex-format but they don't match the gate-computed key, the gate denies the Write, and the agent has to manually `touch` the correct-key marker to unblock.

**Evidence** (iter 8 + iter 10 of this session, 2026-05-18):
- Iter 8: voice-tone marker not auto-written despite agent PASS verdict; agent fabricated placeholder hex keys; manual `touch` of correct-key marker required to unblock both changeset writes.
- Iter 10: same friction at the multi-package changeset Write surface.
- Marketplace source (not yet released to voice-tone 0.5.0) has the `derive_external_comms_key_from_prompt` fallback per ADR-017 sync mechanism; cached version is stale.

**User direction** (verbatim, AskUserQuestion answer 2026-05-18 at session 6 loop-end Step 2.5): *"Approve + amend voice-tone hook (recommended) — Update packages/voice-tone/hooks/external-comms-mark-reviewed.sh to use the derive_external_comms_key_from_prompt helper (already in shared/hooks/lib/external-comms-key.sh per risk-scorer 0.10.0). This closes the asymmetry across both evaluator hooks."*

## Symptoms

- Voice-tone evaluator hook does not auto-write marker despite agent PASS verdict.
- Agents fabricate placeholder hex keys (64-char hex shape but wrong value) — hook validates format but rejects on key-derivation mismatch.
- Manual `touch /tmp/voice-tone-external-comms-reviewed-<correct-key>` required to unblock Writes.
- Same problem class as P166/P163 (hook-side sha256 derivation) at the voice-tone surface.

(symptoms section deferred to investigation)

## Workaround

Agent computes the gate-derived full-content sha256 manually and uses the correct value in marker `touch`. Documented in iter 9 + iter 10 prompts as "P198 changeset-author known-asymmetry" caveat.

## Impact Assessment

- **Who is affected**: every AFK iter that triggers a voice-tone evaluator check on a Write surface.
- **Frequency**: Likely (3) — fires on every changeset Write that voice-tone gates.
- **Severity**: (deferred to investigation) — initial: moderate (workaround works but slow).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort — re-rated to 1 (Low) at closure; symptom structurally impossible.
- [x] Read `external-comms-mark-reviewed.sh` — confirmed: PRIMARY prompt-derivation (lines 106–113) + literal fallback already present.
- [x] Read `packages/shared/hooks/lib/external-comms-key.sh` — confirmed `derive_external_comms_key_from_prompt` is the helper; already wired.
- [x] Architect verdict on the amendment — the shipped implementation IS the "keep both paths with literal-as-fallback (transition support)" option; verdict was delivered as part of the P166 architect review.
- [x] Update `external-comms-mark-reviewed.sh` — DONE via P166 commit `9111efc3` (2026-05-16), before this ticket was captured.
- [x] Behavioural bats coverage for the derived-key path — `external-comms-mark-prompt-parse.bats` GREEN 6/6 (includes the hook-derived-key-wins-over-fabricated-key case).
- [x] Per-package sync of `packages/voice-tone/hooks/lib/external-comms-key.sh` per ADR-017 — byte-identical to canonical (`diff` clean).
- [x] Changeset for `@windyroad/voice-tone` patch — already released via the P166/P163 cluster + subsequent (current `@windyroad/voice-tone@0.5.14`).
- [x] Compose with P166 / P163 cluster — RESOLVED: this is the voice-tone slice of the P166/P163 cohort; folded into their atomic fix.

## Dependencies

- **Blocks**: (none — workaround keeps the channel functional)
- **Blocked by**: (none — fix is hook source change + helper invocation)
- **Composes with**: P166 / P163 (external-comms hook-side sha256 derivation cluster — same problem class, this is the voice-tone-side parallel), P198 (recurring marker-key-derivation friction surface), P256 (sibling fix at the SKILL prompt-template surface, this same session)

## Related

- `packages/voice-tone/hooks/external-comms-mark-reviewed.sh` — the surface to amend.
- `packages/shared/hooks/lib/external-comms-key.sh` — canonical helper containing `derive_external_comms_key_from_prompt`.
- `packages/risk-scorer/hooks/external-comms-mark-reviewed.sh` 0.10.0 — the reference implementation already using the helper.
- ADR-028 — external-comms risk-scorer gate.
- ADR-017 — shared code sync via per-package lib/ copies.
- P166 / P163 — sibling cluster currently vp-blocked due to negative evidence per P198.
- P198 — broader marker-key-derivation friction surface tracker.
- P256 — sibling fix at the SKILL prompt-template surface (this same session, surfaced together).

(captured via /wr-itil:capture-problem; expand at next investigation)
