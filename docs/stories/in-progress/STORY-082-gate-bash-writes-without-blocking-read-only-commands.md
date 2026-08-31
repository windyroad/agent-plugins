---
status: in-progress
story-id: gate-bash-writes-without-blocking-read-only-commands
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P503]
jtbd: [JTBD-001, JTBD-006, JTBD-008]
rfcs: [RFC-088]
story-maps: [STORY-MAP-002]
estimated-effort: L
---

# STORY-082: Gate Bash writes without blocking read-only commands

**Reported**: 2026-08-31
**Problems**: P503
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I Am Away), JTBD-008 (Decompose a Fix Into Coordinated Changes)
**RFCs**: RFC-088
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to trust unattended and interactive edits equally, as a developer using AI agents, I want explicit Bash-routed file writes to pass through the same governance gates and post-write bookkeeping as Edit and Write calls, while read-only shell commands remain fast and silent.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] One canonical, synced classifier returns explicit file targets for supported Bash write forms and returns no target for read-only commands such as `cat` and `grep`.
- [x] Classified Bash writes pass through the existing architect, JTBD, style-guide, voice-tone, and TDD edit gates without duplicating their path exclusions or authorization rules.
- [ ] Classified Bash writes that introduce architecture or JTBD human-oversight markers pass through the existing marker-discipline gates.
- [ ] After an authorized classified Bash write, architect refreshes the decision hash and compendium entry, and TDD runs its state-transition and test-quality-review post-write paths.
- [ ] Behavioral tests cover write redirection, read-only silence, unauthorized and evidence-backed oversight-marker writes, architect post-write refresh, and both TDD post-write routes.
- [x] Each changed package contains a patch changeset, and packed candidates contain the classifier and hook registrations expected for that package while package tests remain excluded by the existing tarball policy.

## Driving problem trace (required — I6 invariant)

P503 records that edit gates use the `Edit|Write` tool matcher as a proxy for file mutation, so Bash-routed writes bypass review and architect post-write bookkeeping, leaving unreviewed changes and a stale decision hash.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: every supported file-write route receives the same automatic governance without false-positive denials on read-only work.
- **JTBD-006**: unattended iterations can use their ordinary Bash route without silently escaping controls or poisoning a later honest edit.
- **JTBD-008**: one vertical story keeps the shared classifier, all gate callers, and their post-write effects together as one releasable fix.

## Implementation notes (optional)

Follow ADR-017: author one canonical helper under `packages/shared/hooks/lib/`, sync byte-identical copies into the five self-contained published plugins, and keep existing gate scripts authoritative for path policy. This story covers explicit supported write shapes only; it does not claim complete shell-language mutation detection.

Implemented support is bounded to literal output-redirection targets, heredocs, and `tee` operands in simple commands. Quoted target names and literal `cd directory &&` prefixes are supported. The classifier distinguishes operators from quoted text, comments, and heredoc bodies, and associates known content with the effective input and output descriptors. It never executes the command to discover targets.

Dynamic targets, shell control structures, and arbitrary in-process writes remain unclassified. These are remaining P503 coverage gaps, not evidence that the original report is resolved. Unknown runtime-produced content is omitted, so passing an event through a content-sensitive marker gate does not prove that every marker introduction is protected.

### Direct recovery evidence, 2026-08-31

The isolated worker failed with a model-capacity error before its handoff. The user authorized direct recovery. Its interrupted full test runs are not passing evidence; its premature acceptance ticks above have been cleared where end-to-end proof remains outstanding.

The recovered implementation passes 22 focused checks: 16 shared dispatcher cases and six architect dispatcher cases. These include native Bash comparisons for effective stdin, read-only false-positive regressions, actual registered hook commands in paths containing spaces, sync divergence and repeatability, denial propagation, and the real architecture marker-discipline gate with isolated test evidence. Post-write routing is covered with child stubs; that alone is not proof of refreshed hashes, generated compendium content, installed-runtime operation, or published package contents.

The wider affected hook suite passed all 696 checks. It ran before the final repeated-echo-option correction; all 22 focused checks were rerun successfully afterward, including that regression. A separate isolated fixture exercised the real architect Bash post dispatcher, hash refresh, compendium rewrite and README staging; only the compendium model response was stubbed. Actual npm-packed candidates for architect, JTBD, style-guide, voice-tone and TDD each contained the canonical helper and hook manifest, excluded package tests, and passed write/read-only smoke checks. None of these checks installed or enabled hooks in the user's runtime.

### Partial publication, 2026-08-31

Implementation `5fde23056a50577d882f4d4431e2361573f87864` passed [source CI](https://github.com/windyroad/agent-plugins/actions/runs/33381930776): 4,291 tests, two skips and 31 actual-agent cases. [PR 470](https://github.com/windyroad/agent-plugins/pull/470) merged as `6977e75fb3935c58df7962bff873a934bc2a26d7`; its [release workflow](https://github.com/windyroad/agent-plugins/actions/runs/33383002410) and [CI](https://github.com/windyroad/agent-plugins/actions/runs/33383002403) succeeded.

Architect 0.22.1, JTBD 0.14.3, style-guide 0.6.3, voice-tone 0.8.4 and TDD 0.6.1 are published. Each npm latest tag and downloaded tarball was verified, including canonical helper content, executable permissions, expected packed hook projection, test exclusion, and direct write/read-only behavior. The remaining acceptance criteria and coverage gaps above are unchanged; this story remains in progress. No installed hooks were updated or enabled.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P503
- RFC-088
- ADR-005
- ADR-017
- ADR-045
- ADR-052
- ADR-103
