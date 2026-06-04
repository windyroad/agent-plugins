# `/wr-itil:capture-problem` Reference

This file hosts the rationale, edge cases, contract trade-offs, and ADR cross-references for the `/wr-itil:capture-problem` skill. SKILL.md is the runtime contract (~150 lines, on-topic per ADR-038 progressive disclosure); this REFERENCE.md is the on-demand expansion for maintainers and curious users.

## Why a separate skill?

The `/wr-itil:manage-problem` flow is ~10 turns of agent work for a full new-problem intake: Step 0 README reconciliation preflight, Step 2 wide-net duplicate grep + AskUserQuestion branch, Step 3 next-ID, Step 4 information-gathering AskUserQuestion, Step 4b multi-concern split AskUserQuestion, Step 5 ticket file write + P094 README refresh, Step 11 commit gate.

That cost is correct for the canonical new-problem path — the user wants to walk the flow, see duplicate-match prompts, and place the ticket in the WSJF ranking immediately.

It is wrong for the **aside-invocation** use case. P155 surfaced three repeating patterns where the heavyweight cost is load-bearing friction:

1. **Mid-AFK-iter sibling-findings**: agent observes a tangential ticket-worthy issue. The 10-turn ceremony breaks iter cadence — observation gets buried in `notes` field of `ITERATION_SUMMARY` and ~50% never reach the backlog.
2. **User-initiated rapid captures**: user says "btw, this is broken too — capture it". The 10-turn ceremony breaks conversational flow.
3. **AFK orchestrator main turn captures**: user-driven mid-loop interjections (P151 / P152 / P154 in the session that surfaced P155). Each capture took 5-15 minutes wall-clock through the heavyweight flow.

`/wr-itil:capture-problem` is the source-side fix: a lightweight skill with a deferred-placeholder pattern that captures the observation in ~3-4 turns and routes the deferred re-rating + README refresh through `/wr-itil:review-problems` at a time of the user's choosing.

## Contract trade-offs

### Capture-time false-positives are cheaper than false-negatives

P155 line 24: "capture-time false-positives (creating a duplicate that gets merged later) are cheaper than capture-time false-negatives (losing the observation entirely)."

This is the structural rationale for:
- **3-keyword cap on the duplicate-grep** — wider grep would surface more matches but force the user to either (a) add an AskUserQuestion branch (which capture-problem doesn't have) or (b) ignore the matches and proceed silently. A 3-keyword cap keeps the match list short and audit-able in the report.
- **Title-only filename match** — body-content matches would be too noisy at the conservative threshold. Files whose filenames have zero overlap but whose bodies mention a keyword are almost always different tickets that happen to discuss similar topics. False-positive cost would dominate.
- **No halt-on-match** — even when matches are found, capture proceeds. The duplicate gets resolved at next `/wr-itil:review-problems` (where the full-rank scan can detect and merge actual duplicates with the user in the loop).

### README refresh: inline (P199 Option 2 amendment, 2026-06-05)

Capture-problem stages `docs/problems/README.md` inline at Step 6, mirroring `/wr-itil:manage-problem` Step 5 P094 (refresh-on-create) + P134 (last-reviewed rotation). The previously-load-bearing "Deferred-README-refresh contract" was reversed by user direction recorded in P199 on 2026-05-31, then implemented on 2026-06-05.

**Rationale for the reversal** (user direction):
- The P165 README-refresh-discipline hook (shipped after the initial capture-problem design) blocks every capture commit that does not stage README. The P262 workaround (a `RISK_BYPASS: capture-deferred-readme` trailer) cleared the gate but kept the README transiently stale by design — a contract that always felt half-superseded by P165 reality.
- Option 2 acknowledges reality: stage the README. The cost is one mechanical render-and-stage primitive (already proven in `/wr-itil:manage-problem`); the capture-time speed distinction from manage-problem comes from the wide-net duplicate grep + AskUserQuestion branches that capture-problem skips, not the README skip.
- The `RISK_BYPASS: capture-deferred-readme` trailer is dropped from emission. The allow-list entry in `packages/itil/hooks/lib/readme-refresh-detect.sh::_README_REFRESH_BYPASS_TRAILERS` is retained as inert dead code for adopter compatibility (minimal-change discipline).

**Trade-off table (post-amendment)**:

| Surface | manage-problem | capture-problem (post-P199) |
|---------|----------------|------------------------------|
| README authoritativeness | Always current at commit boundary | Always current at commit boundary |
| Capture-time turn cost | +1-2 turns (regenerate + stage) | +1-2 turns (same primitive) |
| WSJF ranking visibility | Immediate (deferred-placeholder row) | Immediate (deferred-placeholder row) |
| Audit trail (commit) | One commit covers ticket + README | One commit covers ticket + README |
| README staleness window | None | None |
| Distinguishing cost shape | Wide-net duplicate grep + multi-AskUserQuestion branches | Title-only 3-keyword grep + zero AskUserQuestion |

The on-disk ticket inventory remains the source of truth; `/wr-itil:list-problems` cache-stale fallback re-derives directly from ticket files when needed.

### No AskUserQuestion at all

Architect Q4 + JTBD review confirmed: capture-problem is a **mechanical-stage skill** per ADR-044's framework-resolution boundary. Every potentially-interactive decision is framework-mediated:

- **Duplicate-check**: false-positive bias > false-negative bias. Mechanical rule: list matches, proceed regardless.
- **Priority**: framework-policy default `3 (Medium) — Impact 3 × Likelihood 1`, flagged for re-rate. Re-rating is mandatory before the ticket is worked, so no ticket gets ranked on a wrong default.
- **Effort**: framework-policy default `M`, flagged for re-rate. Same re-rating contract as Priority.
- **Multi-concern split**: out of scope. The user invoking capture-problem with a multi-concern observation gets one ticket with the full description as the body; they re-route to `/wr-itil:manage-problem` for the structured split.

This mirrors the mechanical-stage carve-out pattern documented in CLAUDE.md (P132 / inverse-P078 trap): when a SKILL contract names a stage as mechanical, do not ask. Per-action consent gates re-ask decisions the user already made and silently undo the load-bearing UX investment.

## Edge cases

### Empty `$ARGUMENTS`

Halt-with-stderr-directive. capture-problem requires a description; without one there is nothing to capture. The directive points the user to `/wr-itil:manage-problem`, which has Step 4 AskUserQuestion gathering for missing fields.

AFK orchestrators MUST NOT invoke capture-problem with empty arguments — caller-side contract. The Rule 6 audit makes this explicit so AFK-iter writers don't accidentally introduce a halt mid-loop.

### Description is a kebab-stopword soup

If the description's first 8-10 tokens are entirely stopwords (e.g. "the and of to in"), the slug derivation falls back to the full description hash modulo a short integer. The resulting slug is non-meaningful but unique; the user re-titles at next investigation.

This is a degenerate case — real captures carry meaningful first-tokens — but the fallback prevents a malformed empty-slug filename.

### ID collision with origin

The next-ID formula uses `git ls-tree origin/main` to read the remote-tracking ref without requiring a fetch. If a parallel session minted the same ID for a different problem and pushed it before this session captures, the local read sees the higher origin ID and increments past it.

If the local session has not fetched recently and origin has captures the local doesn't see, the formula may still collide. The renumber audit log line in Step 7 captures the resolution. P040 incident applies.

### Cross-skill marker ordering

The `/tmp/manage-problem-grep-${SESSION_ID}` create-gate marker is shared between `manage-problem` and `capture-problem`. Whichever fires first writes the marker; subsequent calls are idempotent (`: > FILE`).

This means a session that does `manage-problem` once then `capture-problem` three times has the marker set after the first manage-problem grep, and all three captures land without re-running the grep + mark sequence. capture-problem still runs its own minimal-grep in Step 2 (because the conservative threshold + report-listing is part of the contract), but the marker write is a no-op.

### P057 staging-trap

Not applicable. capture-problem only Writes a new file; it does not `git mv` an existing one. The P057 rule (re-stage after Edit on a `git mv`-d file) is irrelevant to this skill.

### Multi-concern descriptions

If the user supplies a multi-concern description (e.g. "checkout flow leaks tokens AND the price calculator rounds wrong"), capture-problem creates ONE ticket with both observations in the description body. Re-routing to `/wr-itil:manage-problem` for the structured split (Step 4b) is a deliberate design choice — the heavyweight flow owns the multi-concern decision because the split prompt requires user input to confirm boundaries.

The user can manually `/wr-itil:manage-problem <NNN>` later to split a captured multi-concern ticket if needed.

## Composition with the rest of the suite

### `/wr-itil:review-problems`

Handles the deferred re-rating + README refresh. Step 9b's auto-transition pass keys off the deferred-placeholder string and surfaces captured tickets for re-rating. The README refresh in Step 9e regenerates the table covering all captured-but-not-rated tickets in one pass.

### `/wr-itil:manage-problem`

Heavyweight intake counterpart. Shares the create-gate marker with capture-problem. The two skills are designed to coexist — neither supersedes the other. A user who starts with capture-problem and decides they want the structured intake flow re-invokes manage-problem on the captured ticket ID to flesh out the placeholders.

### `/wr-itil:work-problems` (AFK orchestrator)

Iter subprocesses can invoke capture-problem to capture sibling-findings without breaking iter cadence. The AFK carve-out in ADR-032 (line 85) excludes the **background-capture** variant from AFK contexts; the **foreground-lightweight-capture** variant introduced by this skill is fine inside iter subprocesses because it has no `Agent(run_in_background: true)` invocation — it's a normal foreground-synchronous skill that happens to do less work than manage-problem.

### `/wr-itil:capture-problem` callers

The intended invocation surface is `/wr-itil:capture-problem <description>`. The description must be a non-empty free-text payload; the skill does not branch on description shape.

## Related ADRs

- **ADR-009** — gate-marker-lifecycle (per-session /tmp markers; capture-problem reuses the manage-problem marker).
- **ADR-013** — structured user interaction (Rule 6 fail-safe; capture-problem has no AskUserQuestion branches so Rule 6 is trivially satisfied).
- **ADR-014** — governance skills commit their own work (capture-problem owns its commit).
- **ADR-022** — verification-pending status (out of scope for capture-problem; status transitions live in transition-problem).
- **ADR-031** — problem-ticket directory layout (capture-problem matches current flat-layout production reality; auto-migration is a future ADR-031 follow-up).
- **ADR-032** — governance skill invocation patterns (this skill's parent ADR; foreground-lightweight-capture variant amendment 2026-05-03).
- **ADR-038** — progressive disclosure (SKILL.md + REFERENCE.md split shape).
- **ADR-044** — decision-delegation contract (framework-mediated mechanical-stage carve-outs).
- **ADR-049** — bin/ on PATH (capture-problem reuses existing `wr-itil-reconcile-readme` shim; no new shim).
- **ADR-052** — behavioural-tests-default for skill testing (capture-problem's bats fixtures exercise primitives, not SKILL.md prose).

## Related problems

- **P014** — parent / master tracker.
- **P078** — capture-on-correction OFFER; depends on capture-problem.
- **P088** — settled the user-direction-scoped decision: capture-problem + capture-adr are shippable; capture-retro is deferred.
- **P119** — manage-problem create-gate; capture-problem composes with the same marker.
- **P148** — Tickets Deferred retro section (legacy when capture-problem ships).
- **P155** — driver ticket.
- **P156** — sibling capture-adr.
- **P157** — sibling pending-questions-surface hook.
