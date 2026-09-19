# Problem 419: capture-story's mechanical reverse-trace edit to a docs/jtbd file re-locks the JTBD edit gate mid-session

**Status**: Known Error
**Reported**: 2026-07-05
**Priority**: 8 (Medium) — Impact: 2 (Minor — one re-review round-trip of friction) × Likelihood: 4 (Likely — deterministic on every story capture that touches a docs/jtbd reverse-trace) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: M — exempt the mechanical reverse-trace edit from gate re-lock (or re-stamp the marker post-edit)
**WSJF**: 8 — (8 × 2.0) / 2 (2026-07-26 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; multiplier 1.0 → 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

capture-story's mechanical reverse-trace edit to a docs/jtbd file re-locks the JTBD edit gate mid-session via policy-hash drift, forcing a full wr-jtbd:agent re-review round-trip before any subsequent project-file edit. Witnessed 2026-07-05 P408 iter: after capture-story rendered the STORY-037 reverse-trace row onto docs/jtbd/developer/JTBD-001-enforce-governance.proposed.md (commit 90c7f3b7), the next Write (a new bats test file) was denied with "jtbd policy file changed since last review" and a re-delegation to wr-jtbd:agent was required. The edit was helper-rendered and content-mechanical (a table row naming the new story), not a semantic policy change, so the re-review adds a subagent round-trip per story capture with zero review value. Every capture-story invocation that back-links a JTBD in a session with later edits hits this. Candidate fix shapes: exclude helper-rendered reverse-trace sections from the gate hash, or have the reverse-trace helpers refresh the gate marker hash after a mechanical render.

## Symptoms

- After any `/wr-itil:capture-story` run that back-links a JTBD, the next Edit/Write in the session is denied with "jtbd policy file changed since last review".
- A full `wr-jtbd:agent` re-review round-trip is required even though the docs/jtbd change was a helper-rendered `## Stories` table row.
- **2026-09-19 (P437 iter) — recurrence, and the reason no ordering workaround exists.** capture-story Step 6 ran `wr-itil-update-jtbd-references-section` over `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`, adding one `## Stories` row for STORY-091. The JTBD review had returned PASS minutes earlier. The next write — the first line of fix code at `packages/wardley/scripts/owm-to-svg.sh` — was denied with the same *"jtbd policy file changed since last review"*. The sibling advice to sequence jtbd-policy writes last cannot apply on this path: the propose-fix trace gate refuses to let implementation begin until the story's card exists, so the capture must precede the fix, and the capture contract mandates the invalidating write. Any fix that needs a story captured for it pays this round-trip. Cross-ref P453 (the gate's wider policy-path-drift ticket) — this is the capture-story instance of it.

## Workaround

Re-delegate to `wr-jtbd:agent` (subagent_type: `wr-jtbd:agent`, run_in_background: false) citing the mechanical reverse-trace commit; the refreshed marker unblocks edits. Costs one subagent round-trip per story capture.

## Impact Assessment

- **Who is affected**: developers and AFK iters running capture-story in sessions with subsequent edits
- **Frequency**: every capture-story invocation that back-links a JTBD (I9 makes the JTBD trace mandatory, so effectively every capture)
- **Severity**: Low — one subagent round-trip of friction; no data loss
- **Analytics**: N/A

## Root Cause Analysis

The JTBD edit gate hashes docs/jtbd/ content for drift detection (ADR-008/ADR-009 family). The capture-story Step 6 reverse-trace helpers (`update-jtbd-references-section.sh`) legitimately edit docs/jtbd files as a mechanical render, which the gate cannot distinguish from a semantic policy change.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Decide the fix shape: exclude reverse-trace sections from the gate hash vs. helper-side marker-hash refresh after a mechanical render
- [ ] Create reproduction test

### Recurrence 2026-09-19 (P543 iteration)

Same class, a different reverse-trace caller. Working P543, the STORY-098 `draft → accepted` transition ran `wr-itil-update-jtbd-references-section` on `docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md` to refresh its `## Stories` section — the transition's own mandated step. Several turns later a Bash write to `packages/itil/skills/work-problems/SKILL.md` was denied with *"jtbd policy file changed since last review. Re-delegate to wr-jtbd:agent"*, even though the JTBD review for that exact change had already returned PASS earlier in the same session.

The caller here is the story transition, not `/wr-itil:capture-story` — so the relock is not specific to capture; any skill step that runs a reverse-trace helper over `docs/jtbd/` invalidates the marker for every subsequent gated edit in the session. The workaround the memory note prescribes (do all JTBD-touching work first, then one review, then all gated edits in one batch) does not survive a lifecycle transition sitting between two gated edits, which is the ordinary shape of working a ticket.

Cost this time: the denied write was the temporary SKILL.md revert for a RED proof, so the recovery was to build the fixture out-of-tree instead of paying another review round. That worked, but it is a workaround for a workaround.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- P301 (oversight-marker frontmatter writes trip full architect/JTBD gate each drain batch, verifying) — same class: mechanical writes tripping a full gate re-review; different surface (oversight drain vs capture-story reverse-trace).
- Dup-grep filename matches (title-only, listed per capture contract): P002 (closed), P084 (closed), P301 (verifying), P312 (verifying).
- Hang-off pre-filter surfaced >5 body-signal candidates (candidate-cap short-circuit) — hang-off arbitration deferred to the next `/wr-itil:review-problems` cluster pass per the capture-problem Step 2b contract.
- Witness commit: 90c7f3b7 (STORY-037 capture; the JTBD-001 reverse-trace row).

(captured via /wr-itil:capture-problem; expand at next investigation)
