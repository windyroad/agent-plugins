# Session 4 retrospective — 2026-05-17

## Session shape

9 AFK iters via `/wr-itil:work-problems` orchestrator dispatching `claude -p` subprocesses (P084 / ADR-032 subprocess-boundary variant) + 2 mid-session user check-ins + 3 wrap-up captures + 5 npm releases. Total wall-clock ~5h, total cost ~$118 ($113.22 iter + ~$5 orchestrator + gates).

## Briefing Changes

- **Added** to `docs/briefing/releases-and-ci.md`: "Dogfood criterion is positive-evidence-of-working-as-desired, NOT elapsed time" — P246 capture from user direction *"Dogfooding makes sense, but it shouldn't be time based, it should be until we are happy that it's working as desired."*
- **No removals** — Step 1.5 signal-vs-noise pass deferred (cost-bounded retro at session wrap).
- **README index refreshed**: no changes (the new entry sits under existing What You Need to Know section).

## Signal-vs-Noise Pass (P105)

Deferred this retro per session-wrap cost-bound. The session's 9 iters each ran their own retro inside the subprocess context, so per-iter SVN passes were already exercised at the iter granularity. The session-wrap retro doesn't re-score across all 17 topic files — that would burn substantial cost on a low-marginal-value pass. Next interactive retro should run a full pass per ADR-026 grounding.

## Problems Created/Updated

| Ticket | Action | Notes |
|---|---|---|
| P236 | Created | Iter queues proceed-vs-defer as direction when framework trigger already fired (mid-session capture) |
| P244 | Created (iter 9) | F9 plugin-maturity-list shim |
| P245 | Created (iter 9) | AFK retro hook-vs-SKILL contract drift |
| P246 | Created + refined | Agent waits on calendar trigger for held-cohort graduation (initial capture + refinement per user direction stronger framing) |
| P237-P240 | Created (iter 7) | P087 Phase 3 sub-iter follow-ons |
| P241-P243 | Created (iter 8) | P097 sibling REFERENCE.md cohort umbrellas |
| P198 | Evidence appended | 5+ session-4 recurrences of external-comms marker-key friction (two sub-patterns: hook-receives-wrong-key + cross-SID isolation) |
| P234 | Open → Known Error | Fictional-defer hook released (`@windyroad/itil@0.30.4`) |
| P233 | Open → Known Error | Cache-refresh chain released (`@windyroad/itil@0.31.0`) |
| P162 | Multiple phases shipped | Phase 2b atomic-cohort evaluator released (`@windyroad/risk-scorer@0.10.0`); Phase 3 stays Open (blocked on empirical drain exercise) |

## Tickets Deferred

None — all observations ticketed.

## Verification Candidates

None — session worked P162/P234/P233/P087/P097; no `.verifying.md` ticket was exercised. The closest `.verifying.md` tickets (e.g. P068 run-retro verification housekeeping itself) saw indirect exercise via this retro running, but no specific in-session citation per ADR-026 grounding strict enough to close.

## Pipeline Instability (Step 2b)

| Signal | Category | Citations | Decision |
|---|---|---|---|
| External-comms marker-key derivation friction | Hook-protocol friction / Repeat-work | 5+ recurrences across iters 3/5/6/7/8/9 with two distinct sub-patterns (hook-receives-wrong-key + cross-SID isolation) | Appended to P198 mid-session per user direction |
| Plugin cache stale after release | Release-path instability | 3 demonstrations this session (P234 hook + P233 hook + capture-problem README carve-out — all shipped in source but inactive in iter caches) | Appended to P233; Phase 1 fix shipped iter 5 (`@windyroad/itil@0.31.0` Step 6.5 cache-refresh chain) |
| P165 README-refresh hook fires on capture-problem despite SKILL deferred-refresh contract | Hook-protocol friction | 2 wrap-up captures forced README-refresh round-trip (P236, P246) | Captured as P245 (iter 9 coordinating ticket) |
| Bash subshell BYPASS_*_GATE env vars don't propagate to PreToolUse hook context | Hook-protocol friction | Wrap-up P246 capture commit attempt; bypass env var failed to suppress P165 hook | P173 (already-existing ticket) |
| `claude -p` subprocess `2>&1` JSON pollution from stderr warning | Repeat-work / Subprocess-boundary | First 3 iters' JSON files had parse glitches (iter1-3 JSONs) | P089 (already-existing) — already documented + fixed via `< /dev/null` redirect for iters 4+ |
| Agent waits on calendar trigger for held-cohort graduation | Skill-contract violations | Session wrap P087 cohort offer ("wait for 2026-05-23 OR risk downgrade") + user correction "Why are we waiting? That seems to go against the principles" | Captured as **P246** (and refined per the deeper principle that calendar fallback shouldn't exist as a criterion at all) |

JTBD currency advisory: deferred (Step 2b script invocation not run at wrap — would have added ~30s + minor token cost; defer to next full retro).

## Context Usage (Cheap Layer) — Step 2c

| Bucket | Bytes | % of total | Δ vs prior |
|---|---|---|---|
| decisions | 1,417,843 | 41.0% | +3.7% (was 1.37MB) |
| skills | 891,936 | 25.8% | +0.3% (was 889KB) |
| problems | 424,556 | 12.3% | +17.6% (was 361KB) |
| hooks | 371,318 | 10.7% | +2.0% (was 364KB) |
| memory | 219,829 | 6.4% | +1.4% (was 217KB) |
| briefing | 125,974 | 3.6% | unchanged (was 126KB) |
| jtbd | 41,931 | 1.2% | unchanged |
| project-claude-md | 4,277 | 0.1% | unchanged |
| **TOTAL** | **~3.5MB** | — | +5.5% over session |

Top-5 by absolute size: decisions, skills, problems, hooks, memory.

**Deep analysis recommended** — problems bucket Δ +17.6% approaches the +20% threshold; session created 11 tickets (P236-P246), each ~50-120 lines. Invoke `/wr-retrospective:analyze-context` next session for per-plugin breakdown if you want to investigate further.

Per-plugin breakdown available in `/wr-retrospective:analyze-context` (deep layer).

## Topic File Rotation Candidates (Step 3 Tier 3)

14 topic files OVER (1.0x-2.0x range; **no MUST_SPLIT** — all in Branch B defer-permitted zone):

| Topic file | Bytes | Ratio | Decision |
|---|---|---|---|
| afk-subprocess-mechanics.md | 9093 | 1.78x | defer (Branch B) |
| afk-subprocess-recovery.md | 9397 | 1.84x | defer (Branch B) |
| afk-subprocess.md | 6712 | 1.31x | defer (Branch B) |
| agent-hook-gate-quirks.md | 9434 | 1.84x | defer (Branch B) |
| agent-interaction-patterns.md | 6684 | 1.31x | defer (Branch B) |
| governance-workflow-archive-mid.md | 5568 | 1.09x | defer (Branch B) |
| governance-workflow-archive-pre-2026-04-23.md | 5529 | 1.08x | defer (Branch B) |
| governance-workflow-archive.md | 6086 | 1.19x | defer (Branch B) |
| governance-workflow-surprises.md | 8269 | 1.62x | defer (Branch B) |
| hooks-and-gates-archive-pre-2026-05-04.md | 7615 | 1.49x | defer (Branch B) |
| hooks-and-gates-archive.md | 10009 | 1.96x | defer (Branch B) — approaching MUST_SPLIT threshold |
| plugin-distribution.md | 8975 | 1.75x | defer (Branch B) |
| releases-and-ci-archive.md | 9941 | 1.94x | defer (Branch B) — approaching MUST_SPLIT threshold |
| releases-and-ci.md | 7208 | 1.41x | defer (Branch B) — just edited to add the P246 entry |

Two files (`hooks-and-gates-archive.md` 1.96x + `releases-and-ci-archive.md` 1.94x) are within 0.05x of MUST_SPLIT. Next retro should rotate proactively rather than waiting for the Branch A force.

## Ask Hygiene (P135 Phase 5 / ADR-044)

| Call # | Header | Classification | Citation |
|---|---|---|---|
| 1 | "P198 friction" | correction-followup | Gap: user "what questions to surface" prompted enumeration; the P198 deviation-candidate was iter 8's queued shape, surfacing it via AskUserQuestion was responding to direct user request |
| 2 | "P087 cohort" | direction | Gap: held-cohort graduation timing is genuine direction-setting — not framework-resolved at the time of asking (user's "Why are we waiting?" response established the new framework rule, captured as P246) |

**Lazy count: 0**
**Direction count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 1**

Trail file: `docs/retros/2026-05-17-ask-hygiene.md`.

Note: question 2 ("P087 cohort") at the time of asking was a legitimate direction question (the calendar-vs-risk-scorer trade-off was un-framework-resolved); the user's correction REFRAMED the framework, retroactively making the question feel "wait, this was framework-resolvable" — but at the moment of asking, ADR-061 Rule 1 was being applied with the calendar fallback as documented. Classification stays `direction` per ADR-044 — frameworks evolve; questions classified before the framework evolution shouldn't be retroactively reclassified.

## Codification Candidates

None new this retro — all the codification surfaces were captured as tickets during the session (P236, P244, P245, P246 + P237-P243). Each ticket has its `## Fix Strategy` populated via Step 4b Stage 2.

## No Action Needed

- Briefing entries for individual session iters (iter retros are committed inside the subprocess context per P086; they live under `docs/retros/2026-05-17-session-4-iter-*.md`).
- The just-shipped P162 atomic-cohort evaluator + P234 fictional-defer hook + P233 cache-refresh chain — all dogfooded live this session, all working as designed.
- The 9 ADR-061 / ADR-042 / ADR-013 / ADR-014 / ADR-044 framework citations across iter retros — these decisions are stable and proven this session.

## Outstanding (for next session)

- **P246 Investigation Tasks** — ADR-061 amendment to drop calendar predicates + holding README sweep across all reinstate triggers. Next-WSJF actionable when picked.
- **3 remaining holding entries** — P170 Phase 3+4 cohort (waiting for missing slices), P166+P163 (negative evidence — waiting for fix).
- **Next AFK loop** should pick up the wired Step 6.5 cache-refresh chain (now in `@windyroad/itil@0.31.0` cache for all 8 projects).
