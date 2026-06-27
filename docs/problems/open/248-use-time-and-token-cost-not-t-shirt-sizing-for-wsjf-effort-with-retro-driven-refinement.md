# Problem 248: Use time and token cost (not t-shirt sizing) for WSJF effort, with retro-driven estimation refinement

**Status**: Open
**Reported**: 2026-05-17
**Priority**: 6 (Medium) — Impact: 2 (Minor — improves WSJF estimation accuracy; current t-shirt sizing functions but allows no calibration loop) × Likelihood: 3 (Possible — exercised on every `/wr-itil:review-problems` re-rate pass and every `/wr-itil:work-problem` selection; estimation drift compounds with backlog age)
**Effort**: M (schema extension on `.afk-run-state/iter*.json` + per-ticket tally + retro-step calibration feedback hook)
**WSJF**: 6/2 = **3.0** (Open multiplier 1.0; re-rated 2026-05-17 from placeholder during `/wr-itil:review-problems`)

## Description

Currently, for problem WSJF we use t-shirt sizing (S/M/L/XL) for how much effort we think they will be. This is vague and subjective and does not allow for refinement.

Instead we should use **time or token cost**. Specifically:
- For an **open problem**, the effort should be our estimate for the **root cause analysis**.
- For **known errors**, it should be the effort to implement the **RFC** (in time or tokens).

The system should then keep a **tally of the time or token spent doing root cause analysis**. Similarly a tally should be kept of the **time or token spent implementing an RFC**.

The retrospective can then use this data to **refine the estimation process**, so that over time the **RMS of the estimation error is reduced**.

If possible, I'd love it to do **both time and tokens** as both are valuable for me to know.

The retro can the[n use these tallies to feed estimation accuracy improvement over sessions] *(user's description ended mid-sentence; preserving as captured per ADR-026 grounding — the intent is clear from the prior sentence about retro-driven RMS reduction; the truncation can be expanded at the next investigation pass)*.

## Symptoms

(deferred to investigation)

Initial signals already in evidence this session alone:
- Session 4 burned ~$118 across 9 iters; per-iter cost ranged $4.82 to $28.05. T-shirt sizing buckets (M=Medium) cannot represent that 6x spread.
- P162 was estimated M and shipped Phase 1+2a+2b+3 across 3 sessions (multi-iter L effective).
- P087 was estimated L and shipped across 4 phases this session alone (still Open with phases remaining).
- Multiple tickets were re-rated mid-session as scope clarified — t-shirt buckets don't make refinement observable as a delta.

## Workaround

Currently manual: user reads cost summaries, mentally calibrates t-shirt estimates per ticket. No persistent feedback loop. Iteration-cost data IS captured per iter (`.afk-run-state/iter*.json` carries `total_cost_usd` + `duration_ms` + token totals — see `/wr-itil:work-problems` Step 5 cost-metadata extraction contract), but is not attributed back to source tickets.

## Impact Assessment

- **Who is affected**: every WSJF prioritization decision (every /wr-itil:work-problems iter selection; every /wr-itil:review-problems re-rank). The estimation noise compounds across the whole backlog.
- **Frequency**: every retro that touches WSJF; every iter that picks based on WSJF.
- **Severity**: (deferred to investigation) — initial signal: high. Estimation accuracy directly affects what work gets done first.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — why was t-shirt sizing chosen originally? (Cross-reference P047 closed-ticket history for the prior accuracy attempt and what closed it.) → finding captured below (2026-06-16).
- [x] Design the schema change — how does Open vs Known Error effort split work? (per Description: Open = RCA effort estimate; Known Error = RFC implementation effort estimate; both in time AND tokens.) → captured in Phase 1 Design Outcome below.
- [x] Design the tally accumulation mechanism — `.afk-run-state/iter*.json` per-iter data is the source; what aggregates per-ticket? (Likely a `## Effort Tally` section on the ticket body, appended per relevant iter; sums of time+tokens for RCA phase and separately for RFC implementation phase.) → captured in Phase 1 Design Outcome below.
- [x] Design the retro-driven refinement — what does the retro do with the data? (Compare estimate vs actual per closed/transitioned ticket; compute RMS over recent N tickets; surface trend in retro summary; potentially auto-adjust default-effort heuristic per pattern type.) → captured in Phase 1 Design Outcome below.
- [ ] (Phase 2) Create reproduction test — bats fixture: ticket created with estimated_time + estimated_tokens; iter logs actual; retro computes RMS over closed tickets.
- [ ] (Phase 2) Schema migration plan — how do existing tickets (with t-shirt sizes) migrate? Both-axes coexistence vs hard cutover? (Phase 1 outstanding question Q3 below.)
- [ ] (Phase 2) WSJF formula change — current `WSJF = Priority / Effort-divisor` (divisor 1/2/3/5 per S/M/L/XL); new formula needs to consume time-or-token-cost as the effort denominator. Both axes (time AND tokens) suggests EITHER use one as primary + report the other, OR compose them. (Phase 1 outstanding question Q1 below.)

### Root Cause Finding — why t-shirt sizing, and what P047 left open (2026-06-16)

T-shirt sizing (S/M/L/XL) was chosen for **low cardinality + human legibility at ranking time** — a WSJF denominator a human can set without instrumentation, readable directly from `docs/problems/README.md`. The cost is exactly what this ticket targets: it is a *subjective, set-once-ish scalar with no calibration loop*.

**P047** (closed 2026-05-12, `docs/problems/closed/047-wsjf-effort-bucket-accuracy-gaps.md`) was the prior accuracy attempt. It did **not** abandon t-shirt sizing — it patched the two most acute symptoms while keeping the scheme:

1. **Granularity** — added the **XL** bucket (divisor 8) because the open-ended L bucket conflated "one sitting" with "multi-week" work; re-rated 5 tickets L→XL.
2. **Staleness** — added an explicit **effort re-rate pre-flight** to the Open→Known Error transition (Step 7) + reworded Step 9b to "Re-estimate Effort", so the estimate is no longer purely set-once.

Crucially, P047 **explicitly deferred actuals-grounding** to its sibling **P022** (the "agents must not fabricate time estimates" rule): *"P047 ships static-bucket granularity + re-rating; P022 will later add actuals-grounded bucket selection on top."* Neither P047 nor P022 closed the remaining gap — replacing the *subjective* scalar with a *measured* one and adding a feedback loop.

**Therefore P248 is the actuals-grounded successor that closes what P047/P022 punted.** It does not supersede P047 — it builds on P047's two surviving hooks: the lifecycle-transition re-rate point (where the RFC estimate is set) and P022's grounding principle (estimates must be backed by data). The novel mechanism P248 adds is the **per-ticket actuals tally** (already-captured `.afk-run-state/iter*.json` data attributed back to source tickets) feeding a **retro RMS-of-estimation-error calibration loop** — the calibration loop is precisely the thing P047 lacked when it observed "estimates were mostly right per-ticket but the bucket scheme is the aggregate limiting factor."

This confirms the design direction is sound; it does **not** resolve the Q1–Q5 parameter choices below, which remain genuine user-direction-setting decisions (substance-confirm-before-build per ADR-074). RCA is complete; the fix path is documented but parameter-blocked, so the ticket stays **Open** (no Known Error transition this iter — transitioning would imply a locked fix path the Q1–Q5 gate contradicts).

## Phase 1 Design Outcome (2026-06-08)

Phase 1 narrow scope: spec only; Phase 2 implements. The user direction is pinned (verbatim, 2026-06-08): *"effort should be time/tokens for open problems (RCA estimate) and for known errors (RFC implementation estimate); system tallies time/tokens spent; retro refines RMS estimation error over time."* Spec below; outstanding sub-questions surfaced for user ratification BEFORE Phase 2 build (substance-confirm-before-build per ADR-074 / `feedback_confirm_decision_substance_before_building`).

### Design (1) — Schema extension: where the estimates and tallies live

**(a) Per-iter source artefact** — `.afk-run-state/iter*.json` already carries the per-iter actuals via the work-problems Step 5 cost-metadata extraction contract:

- `.duration_ms` — wall-clock duration (authoritative)
- `.total_cost_usd` — dollar cost (authoritative per P089 Gap 2 authority hierarchy)
- `.usage.input_tokens` / `.usage.output_tokens` / `.usage.cache_creation_input_tokens` / `.usage.cache_read_input_tokens` — token totals (best-effort per P089 Gap 2 — final-turn API envelope; can undercount on background-ack exits)
- `.session_id` — Claude session UUID (already present)
- `.result` — embeds the `ITERATION_SUMMARY` block which carries `ticket_id` (and `outcome` / `transition` discriminators)

**No new fields are required on the iter*.json schema** — the existing fields suffice. The single addition Phase 2 needs is an authoritative `ticket_id` field at the JSON top-level, written by the work-problems Step 5 dispatch wrapper (already known to the dispatcher at fan-out time — it's the iter's selected ticket). Filename parsing (`iter-N-pNNN[-phase][-extra].json`) is heuristic-only and breaks on multi-ticket iters (`iter-afk1-session9-p340-p339.json`); the ITERATION_SUMMARY block in `.result` is authoritative but requires `.result` parse to extract. Lifting `ticket_id` to the JSON top-level closes both gaps cheaply.

**Optional Phase 2 additions** (cleaner attribution, not strictly required):
- `phase`: when the iter explicitly tags a phase (e.g. `phase3c`), write it alongside `ticket_id` so the tally can separate RCA-phase from RFC-phase actuals on the same ticket.
- `lifecycle_phase`: explicit discriminator `rca` | `rfc` derived from the ticket's status at iter-start (Open → `rca`; Known Error → `rfc`). Makes the tally bucketing deterministic without requiring filename phase tags.

**(b) Per-ticket schema — estimate fields on the ticket body**. Add to the ticket frontmatter-like header block (the existing `**Effort**: M (...)` line):

```
**Effort-Estimate-RCA-Time**: <minutes>             # set on capture; refined at investigation passes
**Effort-Estimate-RCA-Tokens**: <K tokens>          # set on capture; refined at investigation passes
**Effort-Estimate-RFC-Time**: <minutes>             # set on transition Open → Known Error
**Effort-Estimate-RFC-Tokens**: <K tokens>          # set on transition Open → Known Error
```

The existing `**Effort**: <S|M|L|XL>` line is retained during the migration window for backward compatibility with un-migrated tickets and for WSJF formula transition (Phase 2 design Q1 below). The new fields are additive — old tickets continue to function under the legacy t-shirt formula until re-rated.

**(c) Per-ticket schema — actuals as `## Effort Tally` section**. New section appended after `## Workaround` (before `## Impact Assessment` for visibility during re-rate):

```markdown
## Effort Tally

<!-- AUTO-GENERATED by wr-itil-tally-effort; do not hand-edit -->

### RCA Phase (Open-status iters)

| Iter | Date | Duration (s) | Cost (USD) | Total Tokens (K) | Outcome |
|---|---|---|---|---|---|
| iter-1-p248 | 2026-06-08 | 240 | 2.40 | 850 | investigated |
| ... | | | | | |
| **Total** | | **240** | **$2.40** | **850K** | |

### RFC Phase (Known-Error-status iters)

| Iter | Date | Duration (s) | Cost (USD) | Total Tokens (K) | Outcome |
|---|---|---|---|---|---|
| (none yet — ticket still Open) | | | | | |
| **Total** | | **0** | **$0.00** | **0K** | |

### Estimation Accuracy

| Phase | Estimate-Time | Actual-Time | Time Error % | Estimate-Tokens | Actual-Tokens | Tokens Error % |
|---|---|---|---|---|---|---|
| RCA | 60 min | 4 min | -93.3% | 1000K | 850K | -15.0% |
| RFC | — | — | — | — | — | — |
```

Append-only per relevant iter; `wr-itil-tally-effort <ticket-id>` refreshes the section. The Estimation Accuracy sub-table feeds the retro calibration step (Design 3 below).

### Design (2) — Per-ticket tally aggregation

**(a) Aggregation script** — `packages/itil/scripts/tally-effort.sh` (PATH-shimmed as `wr-itil-tally-effort` per ADR-049):

```
wr-itil-tally-effort <ticket-id>           # refresh tally for one ticket
wr-itil-tally-effort --all                 # refresh all open/known-error tickets
wr-itil-tally-effort --since <date>        # refresh tickets touched since date
```

Mechanism:
1. Scan `.afk-run-state/iter*.json`.
2. For each iter file, extract `ticket_id` (from top-level field once Phase 2 adds it; fall back to `.result` ITERATION_SUMMARY parse during migration window; final fallback to filename heuristic).
3. Determine lifecycle phase (`rca` | `rfc`) from the iter's `lifecycle_phase` field (Phase 2) OR from the ticket's status AT ITER-COMMIT-TIME (re-derive by git-log on the ticket file: the suffix at commit time of `commit_sha` discriminates). Closure-by-construction approach: every iter is one of RCA (Open) or RFC (Known Error) per the ticket's status at dispatch time.
4. Sum `duration_ms`, `total_cost_usd`, and `usage.*` token totals into per-phase buckets.
5. Rewrite the ticket's `## Effort Tally` section (replace-section idempotent edit).

**(b) Trigger surfaces** (no auto-write at iter end — read-only tally script keeps iter dispatch path lean):
- `/wr-itil:review-problems` Step 4.X — refresh tallies for every open/known-error ticket BEFORE WSJF re-rate (so re-rate consumes current actuals).
- On-demand CLI invocation by the user.
- `/wr-retrospective:run-retro` Step 2e calibration (Design 3 below) — refresh before computing RMS.

**(c) Why read-only vs write-on-iter-end**: keeps the iter Step 6 finalisation path lean; avoids tally-write contention under `/wr-itil:work-problems` orchestrator concurrent iter dispatch (P305 root cause class); makes the tally idempotent (re-runnable, deterministic from .afk-run-state corpus). Trade-off: between review passes the tally section is stale — acceptable because consumers (review + retro) refresh first.

### Design (3) — Retro calibration feedback step

**(a) New step in `/wr-retrospective:run-retro` SKILL.md**: `### 2e. Effort Estimation Calibration (P248)` — fires after Step 2d Ask Hygiene, before Step 3 briefing update.

**Mechanism:**

1. Run `wr-itil-tally-effort --since <last-retro-date>` to refresh tallies for tickets touched since the prior retro.
2. For each ticket transitioned (`open → known-error`, `known-error → verifying`, `verifying → closed`) since the prior retro:
   - Read `Effort-Estimate-{RCA|RFC}-{Time|Tokens}` (estimate) and the matching tally Total (actual) for the phase that just closed.
   - Compute relative error: `(actual - estimate) / estimate` per dimension.
3. Compute RMS error across the closed-since-prior-retro cohort:
   - `RMS-Time = sqrt(mean(error_time_i^2))`
   - `RMS-Tokens = sqrt(mean(error_tokens_i^2))`
   - Separately per phase (RCA closures vs RFC closures) — RCA effort patterns are not RFC effort patterns.
4. Append to retro output `### Effort Estimation Calibration` section:

```markdown
### Effort Estimation Calibration (P248)

| Phase | Closed in window | RMS Time Error | RMS Tokens Error | Trend vs prior retro |
|---|---|---|---|---|
| RCA | 3 | 42% | 35% | -8% / -12% (improving) |
| RFC | 1 | 120% | 95% | first sample |
```

5. Store the RMS values + cohort size in a calibration-history file (`docs/retros/.effort-calibration-history.jsonl`) — append-only JSONL, one record per retro per phase. Trend-vs-prior-retro reads the last record from this file.

**(b) Phase 2+ extensions (deferred, surfaced as outstanding questions Q4/Q5 below):**
- Auto-adjust default-effort heuristic per pattern (e.g. "ADR-only changes default to X min / Y K tokens").
- Per-pattern bucketing (docs-only vs code+test vs cross-package) so the heuristic refines per work-type.
- Confidence interval rendering — `±RMS` annotation on new ticket effort estimates.

### Outstanding Questions (substance-confirm-before-build per ADR-074)

Phase 2 build is BLOCKED on these. Queue for the user's next interactive turn per ADR-013 Rule 6 + ADR-044 category-1 direction-setting.

**Q1 — WSJF scalar choice (direction-setting):** WSJF needs a single Effort denominator. With both time AND tokens captured, which is primary?
- Option A: **Time-as-primary** (minutes). Tokens captured for observability only; WSJF denominator is time-only.
- Option B: **Cost-as-primary** (USD). Wraps time × hourly-rate-equivalent + token-cost; single dollar scalar.
- Option C: **Composite scalar** (e.g. `max(time_norm, tokens_norm)` where each is normalised against a project-baseline). Captures both dimensions in one WSJF rank.
- Option D: **Dual WSJF** (rank tickets two ways and present both — Time-WSJF and Tokens-WSJF). User picks which to action.

**Q2 — RCA-and-RFC estimate coexistence (deviation-approval):** Open tickets carry RCA estimate; transitioning to Known Error adds RFC estimate. Two sub-questions:
- (a) Does the RCA estimate stay on the ticket after transition (for retrospective calibration) or get archived?
- (b) Does WSJF on a Known-Error ticket use `RFC-estimate` only, or `RCA-estimate (remaining) + RFC-estimate`? (Most RCA work is done by Known-Error transition; remaining-RCA is typically 0; but cases where the Known-Error transition is partial (some RCA still pending) need a rule.)

**Q3 — Migration of existing t-shirt-sized tickets (direction-setting):**
- Option A: **Hard cutover** — re-estimate every open/known-error ticket in time+tokens at Phase 2 ship; legacy `**Effort**:` field removed.
- Option B: **Dual-axis coexistence** — new tickets carry time+tokens; legacy tickets continue under t-shirt buckets via fallback table (`S=30min, M=120min, L=480min, XL=1440min` derived from the existing divisor 1/2/4/8 anchor); migrate opportunistically at next manage-problem touch.
- Option C: **Auto-derive from history** — for closed tickets with tally data, back-compute estimates from actuals + tag confidence. Open/Known-Error tickets without history fall back to Option B coexistence.

**Q4 — RMS error metric scope (taste / deviation-approval):**
- Window: rolling-N-tickets vs since-last-retro vs all-time? Recommend rolling N=20 most-recent closures per phase to balance stability vs responsiveness.
- Bucketing: global vs per-effort-bucket (S/M/L/XL legacy) vs per-pattern (docs-only / code-impl / cross-pkg)? Recommend global initially; per-pattern is Phase 2+.
- Closed-ticket scope: only `closed.md` transitions, or include `verifying.md` and `known-error.md` transitions too (each transition is a calibration signal — Open→KE measures RCA-estimate accuracy; KE→VP measures RFC-estimate accuracy)? Recommend all three transitions feed calibration; closure isn't required.

**Q5 — Token-cost composability (taste):** Tokens come in 4 dimensions (input + output + cache_creation + cache_read). For the estimate-and-tally:
- Option A: **Simple sum** — total = input + output + cache_creation + cache_read.
- Option B: **Cost-weighted sum** — weight each by per-token USD price (gives a token-equivalent scalar that tracks dollar cost).
- Option C: **Report all four** in the tally; estimate against the simple sum (Option A) for WSJF.

Recommend Option C (full disclosure in tally, simple sum for estimate matching) — preserves observability, simple to estimate against.

**Q6 — `ticket_id` JSON top-level addition (silent-framework per ADR-074 category-4):** Phase 2 needs `ticket_id` written at JSON top-level by the work-problems Step 5 dispatch wrapper. This is a mechanical change with one decision-point: the existing `.result` ITERATION_SUMMARY `ticket_id` field is the canonical source; the top-level is a hoist for cheap jq access. No user direction required — framework-resolves to "hoist on next work-problems edit pass".

### Phase 2 work (deferred to follow-on iters)

Once Q1–Q5 are answered:
- Implement `wr-itil-tally-effort` script + PATH shim.
- Add `lifecycle_phase` + `ticket_id` top-level fields to work-problems Step 5 dispatch JSON write contract.
- Add Step 2e to `/wr-retrospective:run-retro`.
- Migrate `.afk-run-state/iter*.json` corpus (back-fill `ticket_id` from filename or .result parse for historic files; new iters write the field forward).
- Migrate existing tickets per Q3 chosen strategy.
- Update WSJF formula per Q1 chosen strategy; update SKILL.md WSJF section in `manage-problem` accordingly.
- Add bats fixture: ticket created with estimated_time + estimated_tokens; synthetic iter logs actual; retro computes RMS over closed tickets.

### Phase 1 outcome

**Spec captured; Phase 2 BLOCKED on Q1–Q5 direction.** Single AskUserQuestion (sequential 4+2 per ADR-013 Rule 1) once user is interactive. Spec is internally consistent and ships in this iter's commit; no implementation files were touched; risk envelope = docs-only Low.

### Phase 2 Direction Ratified 2026-06-17

User ratified during the 2026-06-17 outstanding-questions drain:

- **Q1 — WSJF scalar choice: Option B (Cost-as-primary, USD).** WSJF Effort denominator is the USD scalar wrapping time × hourly-rate-equivalent + token-cost. Aligns WSJF with budget framing; couples to the hourly-rate assumption (the assumption itself becomes a Phase 2 design choice — pick a sensible default and let it be tunable).
- **Q3 — Migration: Option B (Dual-axis coexistence).** New tickets carry time + tokens (and the derived USD scalar); legacy tickets continue under the t-shirt fallback table (S=30min, M=120min, L=480min, XL=1440min) with token-cost imputed from time × baseline-rate until next `/wr-itil:manage-problem` touch. Opportunistic migration; no mass re-estimate commit.

Q2 (RCA+RFC estimate coexistence), Q4 (RMS metric scope), Q5 (token-cost composability) remain unratified BUT framework-resolvable: the recommended defaults in the question text above stand as the silent-framework choices (Q2: keep RCA estimate; WSJF uses remaining-RCA + RFC. Q4: rolling N=20 closures, global bucketing, all three transitions feed calibration. Q5: Option C — full disclosure in tally, simple sum for WSJF). Q6 is mechanical (hoist on next work-problems edit pass).

Phase 2 build unblocked. Next step: implement `wr-itil-tally-effort` per Phase 2 work list above with Cost-as-primary WSJF formula + Dual-axis migration table.

### Phase 2 progress — `## Effort Tally` render + idempotent inject (2026-06-27)

Data-layer slice landed (ADR-067 Decision Outcome item 2 + the item 2a `source:` provenance flag). Builds directly on the already-shipped aggregation core (commit 8152f8ab).

**What landed** — `packages/itil/scripts/effort-tally.sh` gained two modes alongside the unchanged legacy list mode:
- `--render [--source <afk-backfill|live-iter>] <ticket-file> [AFK_DIR]` — prints the `## Effort Tally` markdown section for one ticket (cost authoritative, time reliable, tokens `~`-flagged best-effort per the P089 Gap 2 hierarchy).
- `--write …` — idempotently injects/replaces that section in the ticket body (lazy-empty: zero iters → section removed), mirroring the blessed `update-problem-references-section.sh` replace-section idiom.
- Phase bucketing (RCA vs RFC) derived from the ticket's `**Status**` line — `Open` → RCA, else → RFC. Deliberate single-phase ceiling (named in the AUTO-GENERATED marker); per-iter git-log phase discrimination is the upgrade path.
- 7 new behavioural bats (render, RCA/RFC bucketing, source-flag flip, idempotent write, lazy-empty, stale-section removal) — `effort-tally.bats` now 15/15 green; full itil scripts suite 491/491.

Architect APPROVED (reuse the single script; current-status bucketing is an acceptable transitional ceiling under ADR-067 item 2; body-section write is the blessed pattern). JTBD PASS (serves JTBD-006 AFK audit trail + JTBD-202 structured auditable output).

**What remains (next slices, unblocked):**
- ADR-067 item 1 — `**Estimated time**` + `**Estimated tokens**` body fields, derived silently in capture/manage-problem (SKILL prose → promptfoo-paired).
- ADR-067 item 4 — retro RMS-of-estimation-error step in `/wr-retrospective:run-retro` (needs item 1 estimates to compute error).
- SKILL wiring — call `wr-itil-effort-tally --write` from `/wr-itil:review-problems` Step 4.X + the retro (ADR-049 shim dispatch required at that point, not this slice).
- Real-ticket backfill — bulk `--source afk-backfill` pass over the 75-ticket / 120-iter historical corpus (larger, noisier commit; held as its own slice).

**Re-score:** Priority unchanged at 6. Remaining Phase-2 scope (estimate fields + retro RMS + wiring + backfill) is still ≈ M. **WSJF 6/2 = 3.0 unchanged; ticket stays Open (partial-progress).**

**Release vehicle**: `.changeset/p248-effort-tally-render-write.md` (`@windyroad/itil` patch) — to be resolved to PR + release-date at next `/wr-itil:transition-problem` touch via `wr-itil-derive-release-vehicle P248`.

## Dependencies

- **Blocks**: any future WSJF estimation accuracy improvement work (this is the foundation)
- **Blocked by**: none — fix is a schema + tally + retro-step extension
- **Composes with**: P162 (parent for dogfood-graduation effort estimation), P234 / P246 (effort estimation feeds the "do we have evidence" judgment), P076 (transitive dependencies — separate dimension but composes)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P047** (closed, `docs/problems/closed/047-wsjf-effort-bucket-accuracy-gaps.md`) — prior ticket about t-shirt effort bucket accuracy. **Cross-ref resolved 2026-06-16** (see Root Cause Finding above): P047 patched granularity (XL bucket) + staleness (re-rate pre-flight) but kept t-shirt sizing and explicitly deferred actuals-grounding to P022. P248 is the **actuals-grounded successor** that closes what P047/P022 punted — it builds on, not supersedes, P047's re-rate hook + P022's grounding principle.
- **P076** (verifying) — WSJF does not model transitive dependencies; different dimension but same WSJF-refinement axis.
- **P138** (verifying) — README WSJF row order; tangential.
- **P162** — codify dogfood-graduation criteria (sibling: effort estimation is one input to the symmetric balance principle).
- `.afk-run-state/iter*.json` — per-iter cost metadata source (existing surface, ready to feed the tally).
- `/wr-itil:work-problems` SKILL.md Step 5 — cost-metadata extraction contract (already extracts `total_cost_usd` + `duration_ms` + `usage.*` fields).
- `/wr-retrospective:run-retro` SKILL.md — the retro that would consume the per-ticket tallies and emit RMS-of-estimation-error trend.

**Note on description truncation**: the user's captured args ended mid-sentence with "The retro can the". The prior sentence already established the retro's role (use tallies to refine estimation, reduce RMS over time). The truncated fragment likely intended to repeat or extend that point. Captured verbatim per ADR-026 grounding; expand at next investigation pass.
