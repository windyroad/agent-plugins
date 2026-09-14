# Problem 539: Governance reviewer plugins lack one canonical Codex completion transport, so marker fixes do not propagate

**Status**: Known Error
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

- [x] Inventory every marker-owning governance reviewer and map its Codex completion decoder, generated surface, and marker writer.
- [x] Confirm the single existing shared generator/sync boundary that should own native completion decoding while keeping published packages self-contained per ADR-017.
- [x] Capture current native dotted collaboration events and `input_text` payload arrays as one behavioural contract fixture exercised by every marker-owning plugin.
- [x] Separate source correctness from installed-version freshness and define fresh-task verification for each affected published plugin.
- [x] Preserve fail-closed role, package, parent, checkout, policy, and TTL bindings while removing duplicated transport parsing.
- [x] Create reproduction test.

### Confirmed root cause

The native completion event boundary had forked across packages. The generated style-guide and voice-tone bridge accepted flattened collaboration tool names and treated any object-valued `tool_response` as the decoded response, so current dotted names such as `collaboration.spawn_agent` were not matched and current `input_text` arrays were never unwrapped. JTBD had no generated completion bridge at all. Architect carried a separate package-local decoder, while risk-scorer had independently learned the current dotted/array shapes in P477.

The reproduction in `packages/shared/test/codex-reviewer-completion-transport.bats` packs the affected plugins, sends the captured dotted collaboration events with JSON wrapped in an `input_text` array, and expects each existing marker writer to receive the genuine PASS. It failed before implementation because the style-guide matcher omitted the dotted event and because the packed JTBD package contained no completion bridge.

### Evidence

- `scripts/sync-codex-plugin-surfaces.mjs` generated completion bridges only for style-guide and voice-tone.
- `packages/jtbd/hooks/hooks.json` exposed only the Claude `Agent` completion hook.
- `packages/architect/hooks/codex-agent-completion.mjs` duplicated the earlier direct-object/flattened-event decoder.
- `packages/risk-scorer/hooks/codex-agent-completion.mjs` contained the newer P477 dotted-event and recursive array decoder, proving the repair had remained local to one package.
- The focused packed-package reproduction returned RED before the fix at the dotted style-guide matcher assertion.

## Fix Strategy

RFC-093, “Reviewer results work across governance plugins,” delivers STORY-089 through the existing approved problem-resolution story map. The implementation keeps each package's marker and receipt state machine intact while moving native event-name and response decoding to one ADR-017 canonical helper synced into every consumer. Packed-package tests exercise the public artefacts; post-release verification must use fresh installed tasks so source correctness is not confused with a stale loaded plugin version.

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


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-089 | STORY-089: I can continue after a reviewer passes, without plugin-specific recovery | in-progress |
