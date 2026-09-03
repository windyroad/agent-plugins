# Problem 535: Critical Points outgrew its budget, so the session-start hook truncates the surface it exists to provide

**Status**: Open
**Reported**: 2026-09-04
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The Critical Points roll-up in `docs/briefing/README.md` is the session-start surface: the handful of rules that save the most wasted turns, curated so an agent sees them without reading the full briefing tree. ADR-040 Tier 1 budgets it at roughly 2 KB and about 10 bullets.

Measured 2026-09-04: **11,224 bytes across 18 bullets** — 5.5× the byte budget.

The consequence is not that it is merely long. It is that the harness truncates it. This session's SessionStart briefing hook emitted `Output too large (10.3KB). Full output saved to: …/hook-…-stdout.txt` and showed a 2 KB preview. Everything past the first few bullets reached a file on disk that nothing then read. So the section that exists specifically to be seen at session start is, past its first 2 KB, not seen at all — and the curation effort spent deciding what earns a place there is silently discarded.

## Symptoms

- The SessionStart briefing hook reports `Output too large (N KB). Full output saved to: <path>` and renders a preview rather than the section.
- Entries promoted to Critical Points in a retrospective are absent from the next session's visible context.
- Bullets have grown into paragraphs — several run over 1,000 characters and carry multi-clause histories with ticket-by-ticket witness lists, which is topic-file material rather than roll-up material.

## Workaround

Read `docs/briefing/README.md` directly at session start rather than relying on the hook's output.

## Impact Assessment

- **Who is affected**: every session. This is the one surface designed to be read without being asked for.
- **Frequency**: every session start, for as long as the section stays over the truncation threshold.
- **Severity**: the failure is silent and it defeats a load-bearing mechanism. Promotions land in a file nobody reads, and each retrospective adds more.
- **Analytics**: 11,224 bytes / 18 bullets measured 2026-09-04; the hook's own truncation notice is the direct observation.

## Root Cause Analysis

The Tier 1 budget is stated in ADR-040 but nothing measures it. `check-briefing-budgets.sh` enforces the Tier 3 per-topic-file envelope and exits 0 here because it does not look at the roll-up. The run-retro Step 1.5 budget guard says to promote only until the budget is met — but with no measurement, "is the budget met" is never actually evaluated, so promotions accumulate.

Demotion has the same gap. Step 1.5 says demotion happens automatically when an entry's score decays below +3, but the decay is applied to topic-file entries; the roll-up carries no per-entry scores of its own, so nothing ever falls out. Entries only ever enter.

Bullet length compounds it: several entries have accreted amendment history inline rather than being rewritten to their current rule, so the section grows even without new entries.

### Investigation Tasks

- [ ] Measure the roll-up. Extend the existing budget detector to the Tier 1 section, or add a sibling, so the overflow is reported rather than inferred.
- [ ] Give the roll-up a real demotion path. Entries need scores of their own, or promotion needs to displace rather than append.
- [ ] Decide the honest budget. If ~10 bullets is genuinely too few for this project, amend ADR-040 rather than silently exceeding it — but check that against the harness truncation threshold, which is the real constraint.
- [ ] Rewrite the longest bullets to their current rule and push the accreted history down into the topic files that already carry it.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: the run-retro Step 1.5 promotion path, which is the mechanism that grows the section, and the Tier 3 budget pass, which is the working precedent for measuring one.

## Related

Captured via `/wr-itil:capture-problem` from a session retrospective, in the same pass that promoted a nineteenth entry — the promotion was warranted on its own merits and still made the measured problem worse, which is what surfaced the gap.

Sibling in kind to the cadence class: a stated budget with no self-firing measurement behaves the same as no budget. P375 records the general shape; this is a specific instance with a measured number and a directly observed harm.
