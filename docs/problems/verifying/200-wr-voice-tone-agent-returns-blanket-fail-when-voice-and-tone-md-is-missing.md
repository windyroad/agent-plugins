# Problem 200: wr-voice-tone:agent returns blanket FAIL when docs/VOICE-AND-TONE.md is missing

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

> **safe-high-fix-risk flag** (per dual-axis-risk classifier): the proposed "fail-open with prompt" option would change a gate from blanket-FAIL to fail-open in the missing-policy-file branch, which weakens voice-tone enforcement for all adopters who haven't yet opted in. The alternate "self-bootstrap on first run" option additionally aligns with "Adopter-attack-surface expansion" (hook-driven write into adopter repos). Maintainer should weigh gate-strength-vs-adopter-friction before picking an implementation path.

## Description

`@windyroad/voice-tone`'s `wr-voice-tone:agent` subagent returns blanket FAIL on every invocation in projects that do not have `docs/VOICE-AND-TONE.md`. The agent's reported reason: "the guide is missing and must be created before this copy can be approved".

The gate is wired correctly (it runs on every commit-gate flow and on `gh issue create` per ADR-028), but its input artefact is absent and the agent has no graceful path. There are two reasonable upstream behaviours, neither implemented today:

1. **Self-bootstrap on first run** — when `docs/VOICE-AND-TONE.md` is missing, the agent could invoke `/wr-voice-tone:update-guide` (or equivalent bootstrap path) inline rather than fail. This matches the framing "the plugin should self bootstrap".
2. **Fail-open with prompt** — when the guide is missing, treat the gate as PASS-with-warning and emit a one-line `Run /wr-voice-tone:update-guide to enable voice-tone reviews` message. Adopter projects that haven't opted in to voice-tone shouldn't be blanket-blocked.

Either is an improvement over the current blanket FAIL.

## Symptoms

- Every commit-gate flow that delegates to `wr-voice-tone:agent` in a project without `docs/VOICE-AND-TONE.md` returns FAIL.
- The FAIL is meta-level — content reviews PASS independently — so the FAIL becomes background noise that has to be ignored manually.
- Observed 6+ times across a single 2026-05-13 work-problems session (3 iter subprocess commits + 3 follow-up commits), always overridden.

## Workaround

For the dry-aged-deps project (downstream witness), `docs/VOICE-AND-TONE.md` was bootstrapped via `/wr-voice-tone:update-guide` to close the gap locally. The upstream improvement still benefits every other adopter project that hasn't opted in yet.

## Impact Assessment

- **Who is affected**: every adopter project without `docs/VOICE-AND-TONE.md` — JTBD-003 (Compose Only the Guardrails I Need) violation (per JTBD classifier).
- **Frequency**: every commit-gate flow in such projects.
- **Severity**: Moderate — gate's signal-to-noise degraded; adopters learn to ignore the FAIL, which weakens its protective effect.

## Root Cause Analysis

The `wr-voice-tone:agent` and `wr-voice-tone:external-comms` agent.md files' "Your Role" step 1 reads `docs/VOICE-AND-TONE.md` unconditionally and offers no graceful path when the file is absent. The agent then routes through "Guide Gap Detection" (a FAIL verdict in `agent.md`) because the missing-file case is structurally indistinguishable from a "guide does not cover this context" case at the prose level. The two evaluator agents are out of conformance with ADR-028 (External-comms gate — voice-tone + risk/leak evaluators on shared PreToolUse surface), which Decision Outcome line 56 already specifies the graceful-fallback shape: *"if `docs/VOICE-AND-TONE.md` is absent, voice-tone review is advisory-only... its verdict file reads PASS unconditionally"*. The canonical `external-comms-gate.sh` hook implements this fallback at line 272 (`permit_with_advisory` when the policy file is absent). The agent prose drifted from ADR-028 and produced a blanket FAIL verdict instead of PASS-with-advisory.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Architect call: ADR-028 already specifies the graceful PASS-with-advisory fallback (line 56) — no NEW architectural choice required; the fix is a conformance edit. The safe-high-fix-risk flag is over-cautious in this case because the gate-level protective surface (`voice-tone-enforce-edit.sh`) is unchanged; only the reviewer agents' missing-guide path is corrected. (architect verdict 2026-06-05: PASS.)
- [x] Implement chosen option in `packages/voice-tone/agents/agent.md` + `packages/voice-tone/agents/external-comms.md` missing-guide branch. (Ticket originally referenced `voice-tone.md`; actual file is `agent.md`.)
- [ ] Behavioural test for the missing-guide path — deferred; no existing voice-tone agent-test surface (architect/jtbd agent tests are structural bats assertions under the ADR-005 Permitted Exception). Add when adopter-side promptfoo-eval scaffolding is introduced for voice-tone agents.

## Fix Strategy

ADR-028 § Decision Outcome already records the chosen option (PASS-with-advisory when `docs/VOICE-AND-TONE.md` is absent). The fix updates the agent prose at two sites:

1. `packages/voice-tone/agents/agent.md` — add a "Missing Guide Handling (P200)" section after "Your Role". Step 1 is amended to route to the new section when the file is absent (return PASS-with-advisory; do not proceed to step 2). Mirrors `packages/architect/agents/agent.md` step 1's "If `docs/decisions/` itself does not exist, that is fine" pattern.
2. `packages/voice-tone/agents/external-comms.md` — replace the weak statement ("You should only be invoked when the policy file exists") with an explicit "Missing Guide Handling (P200)" section that emits `EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS` when the policy file is absent. Brings the agent verdict into agreement with the canonical hook's existing advisory-only permit (`external-comms-gate.sh` line 272).

`voice-tone-enforce-edit.sh` is intentionally **unchanged** — the in-project edit gate remains BLOCKing on missing policy doc. The blanket-FAIL the ticket describes was the agents' defect, not a load-bearing safety feature; the protective surface for adopters who haven't opted in lives in the enforce-edit hook, not in the reviewer-agent verdict.

**Release vehicle**: .changeset/wr-voice-tone-p200-graceful-no-op-on-missing-guide.md

## Fix Released

Released in @windyroad/voice-tone next patch (changeset `wr-voice-tone-p200-graceful-no-op-on-missing-guide.md`; release queued for orchestrator's release cadence). Fix sites:

- `packages/voice-tone/agents/agent.md` — new "Missing Guide Handling (P200)" section after "Your Role"; step 1 routes to it when `docs/VOICE-AND-TONE.md` is absent (PASS-with-advisory, write `printf 'PASS' > /tmp/voice-tone-verdict`, stop).
- `packages/voice-tone/agents/external-comms.md` — new "Missing Guide Handling (P200)" section replacing the prior weak "you should only be invoked when the policy file exists" prose; emits `EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS` when the policy is absent so the verdict agrees with `external-comms-gate.sh`'s existing line-272 permit-with-advisory.

Brings agent prose into conformance with ADR-028 (External-comms gate — voice-tone + risk/leak evaluators on shared PreToolUse surface) § Decision Outcome line 56 ("its verdict file reads PASS unconditionally" when the policy file is absent). Hook surface (`voice-tone-enforce-edit.sh`) unchanged — adopter projects that have not run `/wr-voice-tone:update-guide` still see Edit/Write blocks on copy-bearing files; only the reviewer-agent verdict for missing-guide gets corrected.

Awaiting user verification: confirm that in a project without `docs/VOICE-AND-TONE.md`, delegating to `wr-voice-tone:agent` or `wr-voice-tone:external-comms` now returns PASS with the advisory line instead of FAIL.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P038 (voice-tone external-comms gate — same evaluator), P064 (closed — external-comms parent gate), P124 (wr-voice-tone:agent guide-missing handling — sibling concern from a different invocation context).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/124 (filed 2026-05-13 from downstream voder-ai/dry-aged-deps project ticket P005).
- **Pipeline classification** (review-problems Step 4.5e): JTBD-alignment=aligned-with-existing-JTBD (JTBD-003 + JTBD-001); dual-axis-risk=**safe-high-fix-risk** (cache_audit_note: high-fix-risk-flag — surfaces at next interactive review); route=safe-and-valid + flag.
- **Affected plugin**: @windyroad/voice-tone.
