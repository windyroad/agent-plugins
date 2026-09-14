# Problem 539: Governance reviewer plugins lack one canonical Codex completion transport, so marker fixes do not propagate

**Status**: Open
**Reported**: 2026-09-14
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture from repeated fail-closed delivery blocks across multiple governance plugins and fresh tasks
**Origin**: internal (user-reported recurrence)
**Effort**: L — cross-package shared generator, generated surfaces, behavioural fixtures, releases, and installed-runtime verification
**JTBD**: JTBD-001
**Persona**: developer

## Description

Codex governance reviewers repeatedly return PASS without persisting the marker required by the next fail-closed gate, even after multiple apparently successful fixes. The fixes have repaired individual plugin paths rather than the shared transport contract:

- P402 added generated completion bridges for style-guide and voice-tone using the event shapes known at that time.
- P477 repaired risk-scorer's bridge for current native dotted collaboration event names and `input_text` payload arrays.
- The shared generator still does not cover every marker-owning reviewer family, including JTBD and architect, and still carries earlier flattened-name/direct-object assumptions on generated paths.
- Existing tasks can remain loaded with older installed plugin versions, which amplifies the recurrence but does not explain the source-level divergence.

The result is serial whack-a-mole: a bounded plugin fix verifies correctly, but sibling reviewers retain different completion decoding and marker-persistence behaviour. A new runtime payload shape or a newly exercised reviewer then reproduces the same user-visible failure.

## Symptoms

- A mandated reviewer returns PASS, but the guarded edit, commit, push, or release reports that no marker exists.
- Re-running the same reviewer does not reliably clear the gate.
- A fix verified for one reviewer plugin does not prevent the same failure in another reviewer plugin.
- Restarted tasks can still reproduce the problem when their installed plugin versions or generated surfaces lag current source.

## Workaround

Use the exact plugin-specific recovery path named by the fail-closed gate after confirming the genuine PASS. Restart or replace a task when it is still loaded with an older installed plugin version. These recover individual operations; they do not close the shared defect.

## Impact Assessment

- **Who is affected**: developers using Codex with Windy Road governance reviewers and any delivery workflow gated on their persisted markers
- **Frequency**: repeated across risk-scorer, voice-tone, and JTBD task evidence; expected whenever an uncovered reviewer or payload shape is exercised
- **Severity**: Very High — valid governance results are discarded, repeatedly blocking delivery and creating pressure to bypass fail-closed controls
- **Analytics**: current evidence is transcript and fresh-task recurrence; suite-wide incidence remains to be measured

## Root Cause Analysis

### Investigation Tasks

- [ ] Inventory every marker-owning governance reviewer and map its Codex completion decoder, generated surface, and marker writer.
- [ ] Confirm the single existing shared generator/sync boundary that should own native completion decoding while keeping published packages self-contained per ADR-017.
- [ ] Capture current native dotted collaboration events and `input_text` payload arrays as one behavioural contract fixture exercised by every marker-owning plugin.
- [ ] Separate source correctness from installed-version freshness and define fresh-task verification for each affected published plugin.
- [ ] Preserve fail-closed role, package, parent, checkout, policy, and TTL bindings while removing duplicated transport parsing.
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: reliable Codex governance-marker persistence across reviewer plugins
- **Blocked by**: (none)
- **Composes with**: P402, P477, P506, P536

## Related

- **P402** is a bounded external-comms/background-completion failure covering risk-scorer and voice-tone paths. It is already Verification Pending and should not absorb a suite-wide transport contract.
- **P477** is the verified risk-scorer instance that added native dotted-event and `input_text` decoding. Its bounded fix remains valid; this ticket records why that repair did not propagate to sibling plugins.
- **P506** tracks stale-install detection, which amplifies this defect when restarted tasks still load older plugin versions.
- **P536** tracks worktree-bound governance state. Its checkout-identity root cause is separate from completion decoding.
- Mandatory hang-off check returned `PROCEED_NEW`: P402 owns selected async/external-comms transport failures, while P536 owns checkout identity and path normalisation; neither owns the cross-plugin shared contract.
- Architecture review returned PASS with no new ADR required for capture. Any later fix must reuse the existing shared sync/self-contained package model unless it deliberately changes the completion protocol or packaging architecture.

(captured via /wr-itil:capture-problem; expand at next investigation)
