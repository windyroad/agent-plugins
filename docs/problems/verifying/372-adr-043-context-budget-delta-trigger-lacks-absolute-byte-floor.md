# Problem 372: ADR-043 context-budget delta-trigger lacks an absolute-byte floor — fires deep-layer on negligible deltas

**Status**: Verification Pending
**Reported**: 2026-06-17

## Fix Released

Released 2026-06-27 in `@windyroad/retrospective` (changeset `p372-context-budget-delta-absolute-floor.md`). Step 2c's ADR-043 delta-breach trigger now requires `>20% delta AND >10240 bytes` (absolute-byte AND-gate), so a tiny bucket's 20% wobble no longer fires the deep layer; ADR-043 amended with the floor; paired run-retro promptfoo case GREEN (the suite went 7/7 after P393's calibration). Reinstated from holding by P393's iter once the run-retro eval suite was green, then released. Transitioned K→V in the post-release batch.

**Awaiting user verification** — confirm the deep-context analysis no longer auto-fires on a negligible-byte bucket delta.
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: S (was M; the fix is a prose AND-gate on the existing delta axis + a one-line ADR amendment + one eval case — no script change)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The ADR-043 `run-retro` Step 2c combined auto-fire trigger (calendar-elapse >14 days OR delta >20% any bucket) lacks an absolute-byte floor on the delta-breach axis, so it fires the deep-layer `/wr-retrospective:analyze-context` on negligible absolute changes to small buckets.

Observed P314 iter 3 (2026-06-17): the trigger fired because the `project-claude-md` bucket grew 4277→5897 bytes (+37.9%), a 1620-byte absolute change from a single CLAUDE.md MANDATORY-block addition. The percentage tripped the 20% rule though the absolute delta is negligible. Small buckets (`project-claude-md`, `jtbd`) will trip this routinely on tiny edits, firing the deep layer (a committed report + several subagent calls) more often than the trigger's intent (catch *meaningful* growth).

Concrete fix: add an absolute-byte floor to the delta-breach check in `run-retro` Step 2c (and/or `measure-context-budget` / the snapshot-comparison logic) so a bucket must change by both >20% AND >some-absolute-threshold (e.g. >10 KB) to fire. Keep the calendar-elapse axis unchanged.

Note: this run still produced value (the deep layer surfaced 4 P097 SKILL.md >50KB breaches), so this is a low-severity refinement of an otherwise-working trigger, not a defect.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause (confirmed 2026-06-27):** ADR-043's `run-retro` Step 2c delta-breach trigger axis tests only a *relative* threshold (`>20%` change in any bucket vs the prior snapshot). Relative-only is scale-blind: a small bucket's absolute size makes a 20% swing trivially reachable on a single edit (`project-claude-md` 4277→5897 = +37.9% on a +1620-byte CLAUDE.md addition), so the axis fires the deep layer (a committed report + subagent calls) on absolute deltas too small to be a dominant context cost. The trigger evaluation is SKILL-prose (the LLM reads the HTML-comment snapshot trailer and compares) — there is no script computing the delta — so the fix is a prose refinement, not a script change.

**Fix (implemented 2026-06-27):** AND-gate an absolute minimum-delta floor of 10 KB (`|current − prior| > 10240` bytes) onto the existing 20% relative gate. A delta-breach now fires only when it clears BOTH gates. This suppresses the tiny-bucket noise while preserving every fire on a bucket large enough that a 20% delta is a real bloat signal.

The capture-time framing also raised the inverse concern — "a large-but-stable bucket (multi-MB `docs/problems`) never re-fires." That concern needs **no** code: the **calendar-elapse axis** (`>14 days`) already re-fires every bucket regardless of delta, so dominant context cost is re-analysed at least fortnightly. Adding a third "absolute-size firing axis" would only *increase* fires and cannot fix an over-fire — explicitly rejected (YAGNI; architect-confirmed).

**Surfaces changed (one commit):**
- `packages/retrospective/skills/run-retro/SKILL.md` Step 2c step 4 — Delta-breach bullet gains the 10 KB AND-gate; "trigger does NOT hold" note updated.
- `packages/retrospective/skills/analyze-context/SKILL.md` — 3 trigger-description lines updated in lockstep (cross-doc consistency).
- `docs/decisions/043-*.md` — Amendment 2026-06-08 block gains a dated sub-note (Amendment 2026-06-17) recording the floor + the rejected-third-axis rationale; threshold-grounding line lists `>10 KB` as an initial value per ADR-026.
- `packages/retrospective/skills/run-retro/eval/promptfooconfig.yaml` — second test case on the Step 2c contract asserting the floor gate (small-bucket-does-not-fire / large-delta-does-fire), Tier-A regex + Tier-B rubric (ADR-061 Rule 4 evidence-floor; R009 prose-surface coverage maintained).

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (Effort re-rated M→S this iter; Priority left at 3 pending full review-problems re-rate)
- [x] Investigate root cause — relative-only delta axis is scale-blind (confirmed)
- [x] Create reproduction test — promptfoo eval case (small-bucket-no-fire / large-delta-fire) on the Step 2c contract

### Next step

Fix is committed but **not yet released**. On the next `@windyroad/retrospective` release, transition Known Error → Verifying and verify via the paired promptfoo eval (`npx promptfoo eval -c packages/retrospective/skills/run-retro/eval/promptfooconfig.yaml`, Step 2c floor case GREEN).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P295

## Related

(captured via /wr-itil:capture-problem during P314 iter 3 run-retro Step 2c; expand at next investigation)

- **P295** (`docs/problems/verifying/295-adr-043-deep-context-analysis-needs-automatic-cadence-not-on-demand-only.md`) — introduced the ADR-043 auto-cadence trigger this ticket refines. P295 is in `verifying/` (its fix shipped, awaiting verification), so it cannot absorb this new scope; this ticket is the distinct absolute-floor refinement. This iter's trigger-firing is also positive evidence P295's fix works (the trigger fired).
- **P182** — `measure-context-budget` flat-glob coverage (sibling context-budget-script ticket; surfaced as a duplicate-grep title match).
- **P091** — session-wide context budget from plugin hook stack (parent context-budget concern; distinct — aggregate budget vs. trigger-threshold refinement).
- **Hang-off-check dispatch skipped**: the mechanical pre-filter surfaced 10 candidates (>5 cap), so per the capture-problem latency short-circuit the fresh-context `wr-itil:hang-off-check` subagent was not dispatched; candidate context recorded here for `/wr-itil:review-problems` re-evaluation. Most-relevant candidates: P295 (parent decision), P182 (sibling script).
- **ADR-043** — Progressive context-usage measurement; the trigger amendment 2026-06-08 (P295 settlement) is the surface to refine.
