# Problem 386: review-problems Step 4.6 AFK-silent relevance-close contract cites a dangling work-problems Step 6.5 cross-reference

**Status**: Open
**Reported**: 2026-06-27
**Priority**: 5 (Low) — Impact: 1 × Likelihood: 5 = 5. Rated at review 2026-07-02: dangling cross-ref; small doc fix.
**Origin**: internal
**Effort**: S. WSJF = (5 × 1.0) / 1 = 2.5.
**JTBD**: JTBD-006
**Persona**: developer

## Description

`review-problems` SKILL.md Step 4.6 AFK-silent relevance-close contract cites a dangling cross-reference: lines ~338 and ~395 anchor the AFK silent-close branch on "`/wr-itil:work-problems` Step 6.5", but work-problems Step 6.5 is the Release-cadence check — it contains no relevance-close invocation. Today relevance-close is reached in work-problems only as a side-effect of the Step 0b/0c (and now Step 3.6, per P385) pre-flight dispatch of `/wr-itil:review-problems`.

The AFK-silent guarantee is correct in practice — the dispatched review-problems runs as a `claude -p` subprocess that is AFK-by-construction (the Step 5 dispatch constraint forbids `AskUserQuestion` in the worker), so its Step 4.6 surface-batch-confirm flow takes the silent-close branch automatically. But the cited authority chain is broken at the reference: it points at a step that does not implement what the citation claims.

Fix: re-anchor review-problems lines ~338/395 on subprocess-AFK-by-construction (Step 5 dispatch constraint + ADR-032 subprocess isolation) + the Step 0c / Step 3.6 side-effect dispatch path, not "work-problems Step 6.5".

## Symptoms

- A reader following review-problems' AFK-silent-close authority chain lands on work-problems Step 6.5 (Release-cadence check), which has no relevance-close logic — the contract appears unimplemented even though it is correct via the subprocess-AFK-by-construction path.

## Workaround

None needed — the runtime behaviour is correct; only the documented authority chain is wrong.

## Impact Assessment

- **Who is affected**: maintainers reading/auditing the relevance-close AFK contract; agents that cargo-cult the dangling reference into new prose (P385 Step 3.6 nearly inherited it — caught at architect review).
- **Frequency**: on every audit/extension of the relevance-close contract.
- **Severity**: documentation-correctness only; no runtime defect.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Re-anchor review-problems SKILL.md lines ~338/395 on subprocess-AFK-by-construction + Step 0c/Step 3.6 side-effect path — done; both relevance-close refs re-anchored on the `claude -p` AFK-by-construction subprocess mechanism (Step 5 dispatch constraint + ADR-032) reached via the Step 0b/0c/0d pre-flight + Step 3.6 pre-dispatch path, mirroring work-problems Step 3.6 line 477 canonical phrasing.
- [x] Audit review-problems for any other "work-problems Step 6.5" relevance-close references — done; line 475 is a *correct* Step 6.5 release-cadence ref (left intact). Found one adjacent non-relevance-close ref (line 287, Step 4.5 inbound-discovery) carrying the identical dangling-pointer defect — corrected in the same commit (re-anchored on the Step 0b pre-flight dispatch).
- [x] Behavioural/structural check that the cited anchor resolves to a step that implements relevance-close dispatch — verified against work-problems SKILL.md: Step 0b/0c (lines 174–227) and Step 3.6 (lines 454–477) are the real side-effect dispatch surfaces; Step 6.5 (line 850) is the Release-cadence check with no relevance-close. The review-problems promptfoo eval (`eval/promptfooconfig.yaml`) guards the Step 4.5 inbound-discovery surface (the line-287 edit landed there) — re-run GREEN as the regression check + R009 −1 modulator evidence. The Step 4.6 relevance-close re-anchors (lines 338/395) are non-behavioural prose; runtime silent-close behaviour is unchanged.

## Fix Strategy

- **Kind**: improve
- **Shape**: skill
- **Target file**: `packages/itil/skills/review-problems/SKILL.md` (lines ~338, ~395)
- **Observed flaw**: AFK silent-close branch cites "work-problems Step 6.5" which is the Release-cadence check, not a relevance-close surface.
- **Edit summary**: replace the "work-problems Step 6.5" anchor with the subprocess-AFK-by-construction mechanism (Step 5 dispatch constraint + ADR-032) and the Step 0c/Step 3.6 side-effect dispatch path.
- **Evidence**: surfaced 2026-06-27 during P385 architect review (first-pass ISSUES FOUND, issue 1); architect explicitly requested capture rather than silent in-P385 fix since it predates P385.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P385 (work-problems Step 3.6 pre-dispatch relevance gate — re-anchored its own prose on the correct mechanism; this ticket fixes the upstream source of the dangling ref)

## Related

- `packages/itil/skills/review-problems/SKILL.md` — Step 4.6b/4.6d AFK silent-close branch (lines ~338, ~395).
- `packages/itil/skills/work-problems/SKILL.md` — Step 5 dispatch constraint (AFK-by-construction) + Step 0c / Step 3.6 (the actual side-effect dispatch path).
- **ADR-079** — relevance-close pass design; **ADR-032** — subprocess isolation; **P385** — Step 3.6 driver where the dangling ref was caught.
- Captured via /wr-itil:capture-problem during the P385 iter retro (Step 4b Stage 1 mechanical-auto-ticket carve-out).
