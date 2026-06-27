---
name: wr-itil:work-problems
description: Batch-work ITIL problem tickets while the user is AFK. Loops through the problem backlog by WSJF priority, delegating each problem to wr-itil:manage-problem, and stops when nothing is left to progress. Use this skill whenever the user says things like "work through my problems", "grind problems", "work the backlog", "work problems while I'm away", "process problems AFK", or any request to autonomously work through multiple problem tickets without interactive input. Also trigger when the user asks to "loop" or "batch" problem work, or says they'll be away and wants problems handled.
allowed-tools: Agent, Skill, Bash, Glob, Grep, Read
---

# Work Problems — AFK Batch Orchestrator

Autonomously loop through ITIL problem tickets by WSJF priority, working each one via `wr-itil:manage-problem`, until nothing actionable remains.

The user is AFK during this process, so every decision point that would normally require interactive input should be resolved automatically using safe defaults. The skill reports progress between iterations so the user can review what happened when they return.

## How It Works

Each iteration is one cycle of: scan backlog, pick highest-WSJF problem, work it, report result. The loop continues until a stop condition is met.

## First-run intake-scaffold pointer (P065 / ADR-036)

This skill is one of the two host skills wired to surface the [`/wr-itil:scaffold-intake`](../scaffold-intake/SKILL.md) skill on first invocation in a project that has not yet adopted the OSS intake surface. The contract is documented in [ADR-036](../../../../docs/decisions/036-scaffold-downstream-oss-intake.proposed.md) (Scaffold downstream OSS intake — skill + layered triggers).

**Preamble check** (run once at session start, before Step 0 of the loop):

1. Look for the four intake paths: `.github/ISSUE_TEMPLATE/config.yml`, `.github/ISSUE_TEMPLATE/problem-report.yml`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`.
2. Look for `.claude/.intake-scaffold-declined` (explicit decline marker — never re-prompt).
3. Look for `.claude/.intake-scaffold-done` (done marker — already scaffolded).

If any intake file is missing AND both markers are absent: this skill is **always invoked from an AFK orchestrator context** (per the skill's allowed-tools and persona). The Rule 6 fail-safe applies unconditionally:

- Do **not** fire `AskUserQuestion`.
- Do **not** auto-scaffold.
- Append a one-line `"pending intake scaffold"` note to the iteration's `ITERATION_SUMMARY` notes field. The note is a per-iteration audit trail signal — accumulating one line per AFK iter is acceptable per ADR-036 § Bad consequences and JTBD-006 "audit trail — every action taken during AFK mode should be traceable".

The user reviews the pending note on their next interactive session and runs `/wr-itil:scaffold-intake` (or `/wr-itil:manage-problem` with the foreground prompt branch) at that point. JTBD-006 forbids the agent from making this judgement call autonomously.

### Step 0: Preflight (per ADR-019)

Before opening the work loop, **get the repo into a clean state** so the orchestrator does not iterate against a stale backlog, silently strand prior-session in-flight work, or proceed past an ambiguously-dirty tree (P040, P109, P293). ADR-019 names three branches under the umbrella goal:

- **Branch 1 — Pull**: origin moved; trivial fast-forward divergence. Action: `git pull --ff-only` non-interactively (the existing fetch/divergence path below).
- **Branch 2 — Commit**: pre-existing uncommitted work that belongs in a commit (prior AFK iter hit quota / cancel / crash mid-ticket). Auto-commit when **both** discriminator conditions hold: (a) provenance is unambiguous (attributable to the prior iter's own in-flight flow) AND (b) risk is within appetite per ADR-018. **Deferred — current implementation routes Branch 2 → Branch 3**: the auto-commit mechanism + gate-composition wiring + bats are not yet shipped. Pre-existing uncommitted source edits demote to Branch 3 (halt-with-report) until the follow-up lands.
- **Branch 3 — AskUserQuestion / AFK-halt**: genuinely messy tree (ambiguous uncommitted state, non-fast-forward divergence, partial-prior-session work whose provenance is unclear). Interactive: `AskUserQuestion` per ADR-013 Rule 1 (four-option report: Resume / Discard / Leave-and-lower-priority / Halt). AFK: halt with structured Prior-Session State report — a **deliberate carve-out from the 2026-06-06 ADR-013 Rule 6 queue-and-continue default** (ambiguous session-continuity state requires user input; non-interactive recovery would mask the bug this preflight is meant to surface).

The Branch 1 fetch/divergence table below is the live implementation of Branch 1. The session-continuity detection pass after it is **Branch 3's detection mechanism** — it enumerates the signals that populate the Prior-Session State report when Branch 3 fires.

**Branch 1 mechanism:**

1. Run `git fetch origin`.
2. Compare local `HEAD` with `origin/<base>` (default `main`; otherwise the branch the user is on).
3. Branch on the divergence shape:

| Local vs origin | Action |
|---|---|
| HEAD at or ahead of origin/<base> | Proceed to Step 1 |
| origin/<base> ahead, local has no unpushed commits (pure fast-forward) | Run `git pull --ff-only` non-interactively. Log the count of pulled commits in the AFK iteration log. Proceed to Step 1. |
| origin/<base> ahead, local has unpushed commits (non-fast-forward) | STOP the loop (Branch 3 routing — non-fast-forward divergence is a "genuinely messy" signal). Report the divergence with `git log --oneline HEAD..origin/<base>` and `git log --oneline origin/<base>..HEAD`. Do NOT attempt to rebase or merge non-interactively — that is a judgment call the persona forbids in AFK mode. |

**Network failure**: if `git fetch origin` returns a network error, stop and report. Default behaviour is fail-closed — the user can retry when network is restored.

**Non-interactive authorisation**: per ADR-013 Rule 6, `git fetch origin` and `git pull --ff-only` are policy-authorised actions (no semantic merge, no destructive overwrite). `git pull --rebase`, `git merge`, and any operation that resolves conflicts are NOT policy-authorised — they require user input.

**Cross-cutting**: this rule applies to every AFK orchestrator skill. The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in the ticket-creator skills (`manage-problem` and `wr-architect:create-adr`), not here — see the related problem ticket for that work.

#### Branch 3 detection mechanism — session-continuity signal enumeration (per P109)

After the Branch 1 fetch/divergence check, Step 0 MUST run the session-continuity detection pass that populates Branch 3's signal set (and, when the Branch 2 follow-up lands, feeds the Branch 2 / Branch 3 discriminator). The Branch 1 check handles "did origin move under us"; this pass handles the distinct failure mode "did the prior session leave partial work that changes what iter 1 should do". A prior AFK subprocess can exit mid-ticket (quota 429, user-cancel, subprocess crash) and leave observable state in the working tree that the orchestrator must classify before opening the work loop.

**Signals to enumerate** (each maps to one `git status --porcelain` / filesystem / `git worktree` probe):

| Signal | Detection |
|---|---|
| Untracked `docs/decisions/*.proposed.md` | `git status --porcelain docs/decisions/` filtered for `??` entries ending `.proposed.md` — drafted but unlanded ADRs from a prior iter. |
| Untracked `docs/problems/*.md` | `git status --porcelain docs/problems/` filtered for `??` entries ending `.md` — drafted but unlanded problem tickets. |
| `.afk-run-state/iter-*.json` error markers | Files under `.afk-run-state/` containing `"is_error": true` OR `"api_error_status" >= 400` AND **fresh per the staleness filter** — file mtime is newer than HEAD's commit time (`git log -1 --format=%at HEAD`) OR within the last 24h, whichever is more permissive. Stale residuals (mtime older than HEAD's commit time AND older than 24h) are skipped silently — they represent prior-session partial work whose load-bearing trace has since been verified/landed via a subsequent commit, and the directional asymmetry of the contract is fresh = halt, stale = silent skip (P333; closes the indefinite false-positive halt where e.g. an iter-4-p246.json from 2026-05-18 was still firing the gate on 2026-05-30 despite P246 having been verified-closed on a subsequent session). Success files (`"is_error": false`) are ignored regardless of freshness. When ≥1 stale iter-error-marker is silently skipped, emit a one-line iter-summary annotation per JTBD-006 audit-trail outcome: `Step 0: N stale iter-error-markers skipped (oldest: iter-X-pNNN.json, age: D days). Run \`ls .afk-run-state/iter-*.json\` to inspect.` — preserves traceability of the skip action at near-zero cost and gives a recovery path if a stale-skipped marker was actually load-bearing. Contract source: ADR-032 subprocess artefact + P333 staleness refinement. |
| Stale `.claude/worktrees/*` dirs + matching `claude/*` branches | `git worktree list` filtered on `claude/*` branches adjacent to `.claude/worktrees/*` directories — prior subagent worktrees that were not cleaned up. Detection only — mutation (cleanup) is out of scope and requires a separate ADR. |
| Uncommitted modifications to SKILL.md / source / ADR files | `git status --porcelain` filtered for `M ` / ` M` entries on `packages/*/skills/*/SKILL.md`, `packages/*/hooks/*`, `docs/decisions/*.proposed.md`, or other source paths the prior session was mid-authoring. |

**Classification**: when any signal is present, build a structured Prior-Session State report listing each hit (signal category, path, one-line summary). An empty signal set means clean pass-through to Step 1.

**Routing on interactive-vs-AFK (per ADR-013 Rule 1 / Rule 6):**

- **Interactive** (`AskUserQuestion` is available AND the loop was not started in AFK mode): prompt the user with the Prior-Session State report and four options — **Resume the prior work** (land the drafted files as iter 1), **Discard the draft** and restart from scratch, **Leave-and-lower-priority** (skip the dirty paths and work the next backlog item that doesn't touch them), **Halt the loop** (too much dirty state to proceed non-interactively). Route the chosen branch before opening Step 1.
- **Non-interactive / AFK** (default for this skill per JTBD-006): do NOT call `AskUserQuestion`. Halt the loop with the structured Prior-Session State report in the AFK summary. Per ADR-013 Rule 6 fail-safe: ambiguous session-continuity state requires user input; non-interactive recovery would mask the bug this check is meant to surface. This matches Step 6.75's "dirty for unknown reason → halt" stance at the Step 0 layer — the orchestrator does not silently proceed past partial work.

**Step 2.5b cross-reference (P126)**: before emitting the final AFK summary for a Step 0 session-continuity halt, run Step 2.5b's surfacing routine. The routine is gated on ≥1 accumulated user-answerable skip; at Step 0 no iters have run yet so the gate is normally empty and Step 2.5b returns immediately, but the cross-reference is named here for contract uniformity — every halt path that emits a final summary routes through Step 2.5b regardless of whether the gating clause is empty in the typical case (`halt-paths-must-route-design-questions-through-Step-2.5b`).

**Network failure halt (Step 0 fetch failure)**: if `git fetch origin` returns a network error, the loop halts and reports per the rule above. Before emitting the final AFK summary for a network-failure halt, run Step 2.5b's surfacing routine — same Step 2.5b cross-reference as the session-continuity halt. The gating clause is normally empty at Step 0 (no iters have run), but the cross-reference is named here for contract uniformity (`halt-paths-must-route-design-questions-through-Step-2.5b`).

Step 6.75 treats a Step-0-resolved-with-user-confirmation state as `dirty-for-known-reason`: if the interactive branch's Resume option landed the drafted ADR as iter 1, the iter's commit clears the dirty state and the rest of the loop proceeds normally.

#### README reconciliation preflight (per P118)

After the session-continuity detection pass, Step 0 MUST run the diagnose-only README reconciliation check. The orchestrator reads `docs/problems/README.md`'s WSJF Rankings table to pick the highest-WSJF actionable ticket (Step 3); if that table lies about which tickets are open vs verifying vs closed, the orchestrator burns iterations on no-op tickets — exactly the failure class P118 captures (a prior session committed a ticket transition without staging the README refresh, and no subsequent session systematically reconciled).

```bash
wr-itil-reconcile-readme docs/problems
```

The `wr-itil-reconcile-readme` command is a `$PATH`-resolved shim shipped in `packages/itil/bin/` that dispatches the canonical `packages/itil/scripts/reconcile-readme.sh` body. ADR-049 — never invoke the canonical script via repo-relative path; the path does not resolve in adopter trees.

Exit-code routing:
- **Exit 0 (clean)**: continue to Step 1.
- **Exit 1 (drift detected)**: structured diff lines printed to stdout, one per drift entry (≤150 bytes per ADR-038 progressive-disclosure budget). Capture stdout to a temp file and classify the drift via the **uncommitted-rename carve-out** (P149) before halt-routing — see "Drift classification carve-out" immediately below.
- **Exit 2 (parse error)**: README missing or malformed. Halt the loop with the parse-error message and the structured Prior-Session State report — this is a deeper repair that needs investigation, not mechanical reconciliation.

##### Drift classification carve-out (P149)

The Exit 1 auto-route to `/wr-itil:reconcile-readme` is correct for **committed cross-session drift** but **wrong for uncommitted-rename-rooted drift** — when a prior AFK iter (or any in-flight session) carries a staged ticket rename that the next iteration's in-flow P094 / P062 refresh will reconcile in the upcoming commit per ADR-014's single-commit grain. Auto-routing in the latter case fires an extra `chore(problems): reconcile README ...` commit and splits one logical change across two commits, violating the grain. Worse for the AFK orchestrator: that extra commit lands BEFORE the iter's actual work commit, so the audit trail reads "reconcile, then ticket work" when the truth is "ticket work in progress, README refresh deferred to its in-flow contract".

Run the classifier on Exit 1 to distinguish the two cases:

```bash
wr-itil-reconcile-readme docs/problems > /tmp/wr-itil-drift-$$.txt
reconcile_exit=$?
if [ "$reconcile_exit" -eq 1 ]; then
  wr-itil-classify-readme-drift /tmp/wr-itil-drift-$$.txt docs/problems
  classify_exit=$?
  rm -f /tmp/wr-itil-drift-$$.txt
fi
```

The `wr-itil-classify-readme-drift` command is a `$PATH`-resolved shim (ADR-049 naming grammar) dispatching `packages/itil/scripts/classify-readme-drift.sh`. It cross-references drifting IDs from the script's stdout against `git status --porcelain docs/problems/` filtered for staged rename (`R`) entries.

Classifier exit-code routing:

- **`classify_exit == 0` (INLINE_REFRESH)**: every drifting ID is the destination of a staged rename in the working tree. Log a one-line note in the iter summary ("Step 0 reconcile drift covered by N staged rename(s); deferring README refresh to in-flow Step 5 / Step 7 per P094 / P062 + ADR-014 single-commit grain") and continue to Step 1. Do NOT invoke `/wr-itil:reconcile-readme` — the in-flow refresh will land the README correction in the same commit as the iter's ticket work.
- **`classify_exit == 1` (HALT_ROUTE_RECONCILE)**: at least one drifting ID is NOT covered by a staged rename — committed cross-session drift OR mixed. Per ADR-013 Rule 6 (non-interactive AFK fail-safe), invoke `/wr-itil:reconcile-readme` to apply the corrections + commit a `chore(problems): reconcile README ...` commit, then proceed to Step 1. The reconciled README is the orchestrator's source of truth for Step 3 ranking — a stale read at Step 1 would propagate the lie into the iteration's selection. Mixed routes to halt because `/wr-itil:reconcile-readme` resolves both classes safely; the in-flow refresh only handles the rename'd subset.
- **`classify_exit == 2` (parse error)**: classifier received empty / missing drift input — contract violation upstream. Fall back to the conservative auto-route.

This is a robustness layer ON TOP of P094 + P062, not a supersession — both per-operation contracts remain in force inside each iteration's manage-problem / transition-problem invocation.

### Step 0a: Auto-migrate adopter layout (P170 / RFC-002 / ADR-031)

After Step 0's fetch/divergence preflight and the README reconciliation block but **before** Step 1's backlog scan, source the shared shell migration routine and call the idempotent entrypoint:

```bash
wr-itil-migrate-problems-layout "$PWD"
```

`wr-itil-migrate-problems-layout` is the ADR-049 `$PATH` shim (adopter-safe — resolves `lib/migrate-problems-layout.sh` relative to the script, NOT cwd; P317/RFC-009) that internalises the former inline `source packages/itil/lib/migrate-problems-layout.sh; migrate_problems_to_per_state_layout "$PWD"`. NEVER `source packages/...` repo-relative from a SKILL — those paths only resolve in the source monorepo, not adopter installs.

The routine is **idempotent and partial-migration-safe**. It no-ops when no flat-layout files (`docs/problems/*.<state>.md` at the top level of `docs/problems/`) are detected — the common case post-Slice-5 T5a in this monorepo and in freshly-migrated adopter repos.

**Closes the Step 1 false-zero defect** (per ADR-031 § Backward Compatibility line 126 "Why both skills"): Step 1 enumerates BEFORE delegating to manage-problem. On a flat-layout adopter repo, the post-ADR-031 Step 1 glob would return zero matches at the per-state shape and stop-condition #1 would fire incorrectly — the orchestrator would exit with a false "nothing to do" signal, never reaching manage-problem's Step 0a auto-migrate. Wiring auto-migrate here at Step 0a is structurally required, not an optimisation.

On a flat-layout adopter repo (first invocation post-update — JTBD-101 plugin-developer auto-migration path), the routine:

1. Creates the five state subdirectories under `docs/problems/`.
2. Runs `git mv` to relocate every existing ticket from flat to per-state subdir.
3. Emits a standalone commit with subject `docs(problems): auto-migrate to per-state subdirectory layout (ADR-031)` and footer trailer `RISK_BYPASS: adr-031-migration` (recognised by the commit-gate hook per T11).

**AFK authorisation per ADR-013 Rule 6**: this fires unconditionally even in AFK / non-interactive / orchestrated mode. Pure-rename + pure-mkdir + standalone-commit actions are policy-authorised under ADR-019 precedent — fully reversible (`git revert`), no external-comms surface, no destructive overwrite. No `AskUserQuestion` gate.

**First-fire signal**: the routine emits a single stderr line on the migrating invocation; silent on no-op re-invocations.

After Step 0a completes (whether no-op or migration), proceed to Step 0b's inbound-discovery pre-flight check. The dual-tolerant glob at Step 1 (RFC-002 transitional window) continues to match both layouts; post-T6 (single-pattern collapse), Step 1 will tighten to per-state only and the migration commit ensures the adopter tree matches.

### Step 0b: Upstream inbound-discovery pre-flight (per ADR-062 § JTBD-006 driver)

After Step 0a's auto-migrate and before Step 1's backlog scan, check whether the upstream inbound-discovery cache is fresh. ADR-062 § Decision Drivers names `/wr-itil:work-problems` as the surface that should keep inbound reports visible during AFK loops; the TTL self-healing branch inside `/wr-itil:review-problems` Step 4.5b only fires if review-problems is entered. This step closes that gap by pre-flighting `/wr-itil:review-problems` when the cache is stale or missing.

**Mechanism:**

```bash
preflight_reason="$(wr-itil-check-upstream-cache-staleness "$PWD")"
```

`wr-itil-check-upstream-cache-staleness` is the ADR-049 `$PATH` shim (adopter-safe — resolves `lib/check-upstream-cache-staleness.sh` relative to the script, NOT cwd; P317/RFC-009) that internalises the former inline `source ...; should_promote_inbound_discovery_preflight "$PWD"` and echoes the result. NEVER `source packages/...` repo-relative from a SKILL — those paths only resolve in the source monorepo, not adopter installs.

The helper returns one of five outcomes (contract documented at `packages/itil/lib/check-upstream-cache-staleness.sh` + asserted by `packages/itil/skills/work-problems/test/work-problems-step-0b-cache-staleness-behavioural.bats`):

| `preflight_reason`                | Action                                                                                                |
|-----------------------------------|--------------------------------------------------------------------------------------------------------|
| `no-channels-config`              | Silent-pass. Downstream-adopter non-obligation per ADR-062 § Downstream-adopter contract. Proceed to Step 1. |
| `first-run-cache-absent`          | Dispatch `/wr-itil:review-problems` as a pre-flight iter via the standard `claude -p` subprocess wrapper (same shape as Step 5; see Step 5 for the subprocess invocation contract). |
| `first-run-last-checked-null`     | Same as `first-run-cache-absent` — cache schema present but never populated.                          |
| `ttl-expiry age=<N>s ttl=<M>s`    | Dispatch `/wr-itil:review-problems` as a pre-flight iter. Cache is stale; review-problems' Step 4.5b's TTL-expiry auto-recheck branch fires inside the dispatched subprocess and refreshes the cache + audit-log + README. |
| `fresh-within-ttl`                | Silent-pass per ADR-013 Rule 5 + P132 mechanical-stage carve-out. Proceed to Step 1.                  |

**Pre-flight dispatch shape**: when promoted, dispatch a single `claude -p --permission-mode bypassPermissions --output-format json` subprocess that invokes `/wr-itil:review-problems` (per P084 + ADR-032 subprocess isolation). The subprocess runs the full Step 4.5 inbound-discovery + assessment pipeline; the cache + `docs/audits/inbound-discovery-log.md` + `docs/problems/README.md` are refreshed in its own commit per ADR-014 (review-problems' Slice E commit grain). After the subprocess completes, the orchestrator reads the freshly-refreshed README at Step 1. **If the pre-flight subprocess exits non-zero OR returns `is_error: true`**, apply the non-blocking revert-and-proceed contract in "Step 0 pre-flight subprocess failure handling (P358)" below — do NOT halt the loop (a failed pre-flight is a non-load-bearing cache-refresh dependency, NOT an iter).

**Iter-summary annotation**:

- Channels-config absent: `Step 0b skipped — no upstream-channels.json (downstream-adopter non-obligation)`.
- Cache fresh: `Step 0b skipped — upstream inbound-discovery cache fresh within TTL`.
- Pre-flight ran: `Step 0b pre-flighted /wr-itil:review-problems — reason=<preflight_reason>, <N> reports discovered, <M> local tickets created`.

The annotation pre-empts the "surprise heavy iter" perception JTBD-006 expects auditability for — a maintainer running multiple short AFK loops within a 24h window will hit `fresh-within-ttl` on subsequent invocations and see the cache-fresh annotation, confirming the system's silent-pass discipline rather than wondering whether the check ran at all.

**AFK authorisation per ADR-013 Rule 6**: review-problems' Step 4.5 pipeline is itself AFK-safe — branch decisions are mechanical per P132 / ADR-044 category 4 silent framework action; external-comms gates on verdict/acknowledgement/pushback comments silent-pass on low-risk verdicts per ADR-028 + the `wr-risk-scorer:external-comms` subagent's *"policy-authorised drafts proceed silently"* contract (`packages/risk-scorer/agents/external-comms.md` § PASS Output); gate-denial sub-branches fail-soft and retry on the next discovery pass. No new user-attention surface introduced at the Step 0b promotion point.

**Compose-with**: ADR-014 (review-problems' Slice E commit grain holds — the pre-flight subprocess emits its own commit; orchestrator-main-turn does not commit Step 0b), ADR-013 Rule 5/6 (silent-pass + AFK fail-safe — both honored), P084 + P077 (subprocess isolation reuse — same `claude -p` wrapper as Step 5), ADR-019 (preflight surface — Step 0b is the natural extension of "reconcile state before opening the loop"), P132 (mechanical-stage carve-out — no `AskUserQuestion` at the promotion point). Mid-loop ticket creation by Step 4.5e's safe-and-valid branch enters the WSJF queue Step 1 reads on the same invocation — natural absorption, no deadlock; the pre-flight commit lands before Step 1's README read.

**Staleness contract drift**: the staleness comparison MUST stay symmetric with `/wr-itil:review-problems` Step 4.5b's branches (first-run / TTL-expiry / cache-fresh). Drift here re-opens the inbound-discovery staleness contract — any change to TTL semantics MUST update both this Step 0b helper and review-problems Step 4.5b in the same commit. <!-- INBOUND-CACHE-STALENESS-CONTRACT-SOURCE: packages/itil/skills/review-problems/SKILL.md Step 4.5b -->

After Step 0b completes (whether dispatched or silent-passed), proceed to Step 0c.

### Step 0c: Deferred-placeholder + README-cadence pre-flight (per P271)

After Step 0b's inbound-discovery pre-flight and before Step 1's backlog scan, check whether the deferred-placeholder backlog has accumulated past threshold AND the `docs/problems/README.md` "Last reviewed" cadence has slipped. This step closes the load-bearing gap P271 names: `/wr-itil:capture-problem` leaves deferred-placeholder Priority + Effort lines that `/wr-itil:review-problems` is the only authoritative re-rate path for; without an auto-fire trigger, placeholders accumulate silently across sessions (76 → 83 evidenced on the 2026-05-24 work-problems session) and the orchestrator dispatches iters against stale WSJF rankings.

**Mechanism:**

```bash
preflight_reason="$(wr-itil-check-deferred-placeholder-staleness "$PWD")"
```

`wr-itil-check-deferred-placeholder-staleness` is the ADR-049 + ADR-080 `$PATH` shim (adopter-safe — resolves `lib/check-deferred-placeholder-staleness.sh` relative to the script, NOT cwd; P317/RFC-009) that internalises `should_promote_review_problems_dispatch "$PWD"` and echoes the result. NEVER `source packages/...` repo-relative from a SKILL — those paths only resolve in the source monorepo, not adopter installs.

The helper returns one of five outcomes (contract documented at `packages/itil/lib/check-deferred-placeholder-staleness.sh` + asserted by `packages/itil/skills/work-problems/test/work-problems-step-0c-deferred-placeholder-staleness-behavioural.bats`):

| `preflight_reason`                                       | Action                                                                                                |
|----------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `no-deferred-placeholders`                               | Silent-pass per ADR-013 Rule 5 + P132 mechanical-stage carve-out. Proceed to Step 1.                  |
| `below-threshold count=<N> threshold=3`                  | Silent-pass — there is work to re-rate but not enough to be worth a heavyweight pass. Proceed to Step 1. |
| `no-readme count=<N>`                                    | Dispatch `/wr-itil:review-problems` as a pre-flight iter via the standard `claude -p` subprocess wrapper (same shape as Step 0b / Step 5). README absent OR malformed line 3 → first-run dispatch. |
| `fresh-readme count=<N> age=<X>s threshold=<Y>s`         | Silent-pass per ADR-013 Rule 5 — the cadence is in spec; today's captures are tomorrow's review.       |
| `stale-readme count=<N> age=<X>s threshold=<Y>s`         | Dispatch `/wr-itil:review-problems` as a pre-flight iter. Both axes met — there is work AND the cadence has slipped. |

**Two-axis AND rule (load-bearing per architect verdict on the P271 fix shape).** Both axes — count ≥ 3 AND README age > 7 days — must hold. Either axis alone over-fires:
- Count ≥ 3 alone fires on a backlog where review-problems was run yesterday and 3 captures came in today (that's the in-spec deferred-placeholder behaviour, not a staleness signal).
- Age > 7 days alone fires on quiet weeks where no captures occurred and there is nothing to re-rate.

The intersection is the actual signal: "there is work to do AND the cadence has slipped".

**Pre-flight dispatch shape**: when promoted (`no-readme` or `stale-readme`), dispatch a single `claude -p --permission-mode bypassPermissions --output-format json` subprocess that invokes `/wr-itil:review-problems` (per P084 + ADR-032 subprocess isolation). Reuse the Step 5 subprocess wrapper verbatim — same flag set, same idle-timeout SIGTERM poll loop, same retro-on-exit contract. The subprocess runs the full Step 2 + Step 2.5 + Step 4 + Step 5 re-rate + README refresh + commit; the orchestrator reads the freshly-refreshed README at Step 1. **If the pre-flight subprocess exits non-zero OR returns `is_error: true`**, apply the non-blocking revert-and-proceed contract in "Step 0 pre-flight subprocess failure handling (P358)" below — do NOT halt the loop (a failed pre-flight is a non-load-bearing cache-refresh dependency, NOT an iter).

**ADR-079 composition note**: Step 0c dispatches `/wr-itil:review-problems` which includes Step 4.6 relevance-close per ADR-079 — relevance-close fires as a side-effect of the auto-dispatch. This is desirable: relevance closes accumulate the same way deferred placeholders do, and the AND-trigger reasonably gates both pieces of work.

**Iter-summary annotation**:

- No placeholders / below threshold: `Step 0c skipped — <N> deferred placeholders below threshold (3)`.
- Fresh README cadence: `Step 0c skipped — README cadence fresh (age=<X>s within 7-day window)`.
- Pre-flight ran: `Step 0c pre-flighted /wr-itil:review-problems — reason=<preflight_reason>, <N> placeholders re-rated, <M> tickets auto-transitioned, <K> tickets relevance-closed`.

The annotation pre-empts the "surprise heavy iter" perception JTBD-006 expects auditability for — a maintainer running multiple short AFK loops with fresh-cache will see the silent-pass annotation, confirming the system's silent-pass discipline rather than wondering whether the check ran at all.

**AFK authorisation per ADR-013 Rule 6**: review-problems is itself AFK-safe — branch decisions are mechanical per P132 / ADR-044 category 4 silent framework action; Step 4 verification prompts skip silently when `AskUserQuestion` is unavailable per the review-problems Step 4 AFK branch. No new user-attention surface introduced at the Step 0c promotion point.

**Compose-with**: ADR-013 Rule 5/6 (silent-pass + AFK fail-safe), ADR-044 category 4 (silent-framework — the trigger is policy + observable evidence), ADR-014 (review-problems' commit grain holds — the pre-flight subprocess emits its own commit), ADR-049 / ADR-080 (PATH shim grammar + highest-version-wins wrapper), ADR-062 § Step 0b (precedent staleness-pre-flight shape), ADR-079 § Step 4.6 (relevance-close composition), P084 + P077 (subprocess isolation reuse — same `claude -p` wrapper as Step 5), P132 (mechanical-stage carve-out — no `AskUserQuestion` at the promotion point), P170 / RFC-002 (dual-tolerant glob — the helper handles both layouts), P317 / RFC-009 (adopter-safe PATH shim).

**Staleness contract drift**: the two-axis trigger (count ≥ 3 AND age > 7 days) MUST stay symmetric across the four SKILL surfaces that read it — this Step 0c, `/wr-itil:manage-problem` Step 0.5 (advisory), `/wr-itil:capture-problem` Step 7 (conditional trailing pointer), AND the helper's threshold constants. Drift here re-opens P271. <!-- DEFERRED-PLACEHOLDER-STALENESS-CONTRACT-SOURCE: packages/itil/lib/check-deferred-placeholder-staleness.sh -->

<!-- @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK orchestrator pre-flights review-problems so iters dispatch against fresh WSJF rankings) -->

After Step 0c completes (whether dispatched or silent-passed), proceed to Step 0d.

### Step 0d: Outbound upstream-responses pre-flight (per JTBD-006 AFK driver + JTBD-004 cross-repo coordination)

After Step 0c's deferred-placeholder pre-flight and before Step 1's backlog scan, check whether the outbound-responses cache is fresh. P249 Phase 1 shipped `/wr-itil:check-upstream-responses` as a manual skill (the outbound symmetric counterpart to Step 0b's inbound pipeline); P220 names the cadence gap that without an auto-fire trigger, upstream responses to issues we filed via `/wr-itil:report-upstream` go unread until the maintainer remembers to invoke the skill. This step closes that gap with the same pre-flight shape Step 0b uses for the inbound axis.

**Mechanism:**

```bash
preflight_reason="$(wr-itil-check-outbound-responses-staleness "$PWD")"
```

`wr-itil-check-outbound-responses-staleness` is the ADR-049 + ADR-080 `$PATH` shim (adopter-safe — resolves `lib/check-outbound-responses-staleness.sh` relative to the script, NOT cwd; P317/RFC-009) that internalises `should_promote_outbound_responses_preflight "$PWD"` and echoes the result. NEVER `source packages/...` repo-relative from a SKILL — those paths only resolve in the source monorepo, not adopter installs.

The helper returns one of five outcomes (contract documented at `packages/itil/lib/check-outbound-responses-staleness.sh` + asserted by `packages/itil/skills/work-problems/test/work-problems-step-0d-outbound-responses-staleness-behavioural.bats`):

| `preflight_reason`                | Action                                                                                                |
|-----------------------------------|--------------------------------------------------------------------------------------------------------|
| `no-back-link-tickets`            | Silent-pass. No local tickets carry a `## Reported Upstream` section; nothing to poll. Downstream-adopter non-obligation analogue to Step 0b's `no-channels-config`. Proceed to Step 1. |
| `first-run-cache-absent`          | Dispatch `/wr-itil:check-upstream-responses` as a pre-flight iter via the standard `claude -p` subprocess wrapper (same shape as Step 0b / Step 0c / Step 5). |
| `first-run-last-checked-null`     | Same as `first-run-cache-absent` — cache schema present but never populated.                          |
| `ttl-expiry age=<N>s ttl=<M>s`    | Dispatch `/wr-itil:check-upstream-responses` as a pre-flight iter. Cache stale; the skill polls each back-linked upstream URL, diffs against the cache, and emits STATE / NEW / LABEL / NONE / FAIL per back-link ticket. |
| `fresh-within-ttl`                | Silent-pass per ADR-013 Rule 5 + P132 mechanical-stage carve-out. Proceed to Step 1.                  |

**Pre-flight dispatch shape**: when promoted, dispatch a single `claude -p --permission-mode bypassPermissions --output-format json` subprocess that invokes `/wr-itil:check-upstream-responses` (per P084 + ADR-032 subprocess isolation). Reuse the Step 5 subprocess wrapper verbatim — same flag set, same idle-timeout SIGTERM poll loop. The subprocess runs the full check-upstream-responses Step 1 + Step 2 + Step 3 pipeline; the cache file `docs/problems/.outbound-responses-cache.json` + audit-log `docs/audits/outbound-responses-log.md` are refreshed in its own commit per ADR-014 (check-upstream-responses' SKILL.md Step 3 commit grain). After the subprocess completes, the orchestrator proceeds to Step 1. **If the pre-flight subprocess exits non-zero OR returns `is_error: true`**, apply the non-blocking revert-and-proceed contract in "Step 0 pre-flight subprocess failure handling (P358)" below — do NOT halt the loop (a failed pre-flight is a non-load-bearing cache-refresh dependency, NOT an iter).

**Iter-summary annotation**:

- No back-link tickets: `Step 0d skipped — no tickets carry ## Reported Upstream (downstream-adopter non-obligation)`.
- Cache fresh: `Step 0d skipped — outbound-responses cache fresh within TTL`.
- Pre-flight ran: `Step 0d pre-flighted /wr-itil:check-upstream-responses — reason=<preflight_reason>, <N> back-link tickets polled, <M> STATE/NEW deltas surfaced`.

The annotation pre-empts the "surprise heavy iter" perception JTBD-006 expects auditability for — a maintainer running multiple short AFK loops within a 24h window will hit `fresh-within-ttl` on subsequent invocations and see the cache-fresh annotation, confirming the system's silent-pass discipline rather than wondering whether the check ran at all.

**AFK authorisation per ADR-013 Rule 6**: check-upstream-responses is itself AFK-safe by construction — read-only externally (`gh issue view` only; no `gh issue comment` / `gh issue create`), so does NOT trip ADR-028's external-comms gate; zero `AskUserQuestion` calls (flag-based knobs per CLAUDE.md P085); partial-failure exit code 2 distinguishes "some upstream URLs unreachable" from "everything broke" so AFK orchestrators can branch correctly. No new user-attention surface introduced at the Step 0d promotion point.

**Compose-with**: ADR-013 Rule 5/6 (silent-pass + AFK fail-safe), ADR-044 category 4 (silent-framework — the trigger is policy + observable evidence), ADR-014 (check-upstream-responses' commit grain holds — the pre-flight subprocess emits its own commit), ADR-024 (back-link `## Reported Upstream` section is the source-of-truth scanned by the helper and read by the dispatched skill), ADR-049 / ADR-080 (PATH shim grammar + highest-version-wins wrapper), ADR-062 § Step 0b (precedent staleness-pre-flight shape — Step 0d is the outbound symmetric counterpart), P084 + P077 (subprocess isolation reuse — same `claude -p` wrapper as Step 5), P132 (mechanical-stage carve-out — no `AskUserQuestion` at the promotion point), P170 / RFC-002 (dual-tolerant glob — the helper handles both layouts), P317 / RFC-009 (adopter-safe PATH shim), P249 Phase 1 (the manual skill this step wires into a cadence).

**Staleness contract drift**: the staleness comparison MUST stay symmetric with the check-upstream-responses SKILL's Confirmation surface (TTL semantics + outcome shape). Drift here re-opens the outbound-responses staleness contract — any change to TTL semantics MUST update this Step 0d, the lib helper, AND the check-upstream-responses SKILL.md Confirmation section in the same commit. <!-- OUTBOUND-RESPONSES-STALENESS-CONTRACT-SOURCE: packages/itil/skills/check-upstream-responses/SKILL.md ## Confirmation -->

<!-- @jtbd JTBD-006 (Progress the Backlog While I'm Away — AFK orchestrator pre-flights check-upstream-responses so outbound STATE/NEW deltas surface without manual polling) -->
<!-- @jtbd JTBD-004 (Connect Agents Across Repos to Collaborate — closes the outbound symmetric feedback loop) -->

After Step 0d completes (whether dispatched or silent-passed), proceed to the shared pre-flight failure-handling contract below, then to Step 1.

### Step 0 pre-flight subprocess failure handling (P358 — non-blocking revert-and-proceed)

Step 0b / Step 0c / Step 0d (and **any future Step 0x pre-flight** that reuses the Step 5 `claude -p` subprocess wrapper) dispatch a `/wr-itil:review-problems` or `/wr-itil:check-upstream-responses` **pre-flight subprocess** "same shape as Step 5". That phrase imports the Step 5 *dispatch mechanism* (the `claude -p --output-format json` wrapper + the idle-timeout SIGTERM poll loop), but the **failure semantics are NOT shared** — and the prior prose left this implicit, which P358 surfaced. Step 5's exit-code semantics HALT the loop on non-zero exit / `is_error: true` because **the iter IS the loop body unit** — its failure is the loop's failure. A **pre-flight is a non-load-bearing cache-refresh dependency**, not an iteration of the loop body: Step 1's backlog scan reads whatever `docs/problems/README.md` already exists (freshly-refreshed or slightly-stale), so a failed pre-flight degrades to "cache not refreshed this pass" — never to "halt the loop".

**Contract — a pre-flight subprocess that exits non-zero OR returns `is_error: true` is NON-BLOCKING** (general rule; every Step 0x pre-flight inherits it):

1. **Revert any dirty working-tree state the failed pre-flight left.** The dispatched skill commits its own refresh per ADR-014 (review-problems' Slice E grain / check-upstream-responses' Step 3 grain) — it commits end-to-end or not at all. A subprocess that died mid-refresh may leave an **UNSTAGED** partial write across any path the dispatched skill is contractually allowed to touch: the staleness cache (`docs/problems/.upstream-cache.json` for 0b, `docs/problems/.outbound-responses-cache.json` for 0d), the audit log (`docs/audits/inbound-discovery-log.md` for 0b, `docs/audits/outbound-responses-log.md` for 0d), AND `docs/problems/README.md` + re-rated ticket bodies (0c). Revert the whole contractually-touchable set — not just the cache JSON — so a half-written README or audit-log is also restored. Revert each path **independently** (`git checkout -- docs/problems/ 2>/dev/null; git checkout -- docs/audits/ 2>/dev/null`) rather than as a combined `git checkout -- docs/problems/ docs/audits/` pathspec: the combined form errors and reverts NOTHING when `docs/audits/` is absent (a fresh adopter repo that has never run inbound/outbound discovery), whereas the per-path form tolerates the missing directory and still reverts the dirty `docs/problems/` write. Do NOT commit a partial write: a half-refreshed cache/README is worse than a stale-but-coherent one. If the dead pre-flight somehow left **STAGED** residue (it should not — the pre-flight owns its commit end-to-end), `git reset` (unstage) it first, then revert, so the orchestrator's own subsequent Step 1+ gate flow is not contaminated by a dead subprocess's index (mirrors the ADR-009 no-trust-window-extension reasoning — a dead `is_error: true` subprocess MUST NOT seed the parent's commit).
2. **Log a one-line iter-summary annotation** naming the failed pre-flight + the failure class: `Step 0<b|c|d> pre-flight FAILED (<exit-code | is_error class>) — reverted partial cache write, proceeding to Step 1 with existing README`. Preserves the JTBD-006 audit-trail outcome (the silent degradation becomes observable rather than invisible).
3. **Proceed to Step 1.** The pre-flight failure does NOT halt the loop and does NOT count against the Step 0 prior-session-state Branch 3 detection (step 1 above restored a clean tree, so the iter dispatches that follow start from a clean state).

**`is_error: true` sub-class note (reconciles P358 with the Step 5 taxonomy).** A pre-flight subprocess failure is the SAME `is_error: true` family the Step 5 exit-code semantics taxonomise (P261 SALVAGE / P214 HALT) — **including** the `socket connection was closed unexpectedly` variant (an `is_error: true` shape that routes to the Step 5 catch-all advisory). The load-bearing distinction P358 surfaces is **orthogonal to the SALVAGE-vs-HALT axis**: that axis is scoped to **iters** (the loop body); pre-flights have their own non-blocking failure contract. The Step 5 SALVAGE branch does **NOT** apply to a pre-flight even when the pre-flight left staged work — a pre-flight is not an iteration whose work the orchestrator salvages-and-commits; its job is a cache refresh the dispatched skill owns end-to-end. Pre-flight failure is therefore ALWAYS the revert-and-proceed branch above, never SALVAGE.

**AFK authorisation per ADR-013 Rule 6**: revert-and-proceed is a deterministic, non-interactive recovery — no `AskUserQuestion`. Reverting an unstaged partial write is fully reversible (the next loop pass re-attempts the refresh) and policy-authorised (ADR-019 preflight-reconciliation "leave the tree clean" precedent). Mirrors the P121 SIGTERM Rule-6 posture.

**Compose-with**: ADR-032 § "Pre-flight subprocess failure handling — non-blocking revert-and-proceed (P358 amendment)" (the architectural record + the iter-vs-pre-flight failure-semantics distinction), Step 5 exit-code semantics (the iter-failure HALT contract this is distinguished from), ADR-019 (preflight-reconciliation clean-tree surface), ADR-009 (no-trust-window-extension — the `git reset` of any staged residue), ADR-013 Rule 6 (non-interactive recovery), P358 (driver ticket). This is a fourth symmetric pre-flight surface alongside the three "Staleness contract drift" clauses (lines for Step 0b/0c/0d) — a future Step 0x pre-flight inherits this failure rule by construction; do NOT re-derive a step-specific copy.

### Step 1: Scan the backlog

Read `docs/problems/README.md` if it exists and is fresh (check via git history — see manage-problem step 9 for the cache freshness check). If stale or missing, scan all open + known-error tickets via the dual-tolerant pattern `ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null` (RFC-002 migration window — covers BOTH the flat `<NNN>-<title>.<state>.md` filename-suffix layout AND the per-state subdir `<state>/<NNN>-<title>.md` layout), extract their WSJF scores, and rank them.

**README row order matches Step 3 tier + tie-break selection (P138 + ADR-076)**: the README's WSJF Rankings table is rendered tier-first — rows partition into Tier 0 Critical-bypass (Severity ≥17 OR security-classified OR incident-linked) → Tier 1 Inbound-reported (`**Origin**: inbound-reported`) → Tier 2 Internal, and within each tier by the multi-key sort `(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)`. The cache-fresh path can therefore read the rendered table top-to-bottom and the first row is the orchestrator's pick — no in-memory tier/tie-break re-application needed. The slow path scan must apply the same tier partition then multi-key sort. <!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) --> <!-- TIE-BREAK-LADDER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 -->

Exclude:
- `.closed.md` files (done)
- `.parked.md` files (blocked on upstream)
- `.verifying.md` files (Verification Pending — fix released, awaiting user verification per ADR-022; surfaced in the Verification Queue section, never in dev-work ranking)
- Problems with no WSJF score (need a review first — run `/wr-itil:review-problems` as the first iteration if scores are missing)

### Step 2: Check stop conditions

Stop the loop and report a summary if any of these are true:

1. **No actionable problems** — zero open or known-error problems remain
2. **All remaining problems require interactive input** — e.g., they all need user verification (known-errors with `## Fix Released`), or their scope expanded beyond what's safe to auto-resolve
3. **All remaining problems are blocked** — investigation hit a dead end, or the fix requires changes outside the project

**Step 2.5 fires unconditionally at loop end** (P135 Phase 3 / ADR-044) — promoted from "fallback when stop-condition #2" to **default loop-end emit shape**. Anti-BUFD framing per ADR-044: the AFK loop is the empirical-discovery engine; direction-class observations + deviation-candidates accumulate from real friction across iters; loop-end batched presentation is the user-facing deliverable. Per-iter surfacing was the old (now-superseded) pattern; Phase 3 makes batch-at-loop-end the default for ALL stop conditions, not just #2.

For stop-conditions #1 and #3 (no actionable problems / all blocked), Step 2.5 still runs — it reads the accumulated `outstanding_questions` queue from `.afk-run-state/outstanding-questions.jsonl` and presents the batch. Empty queue → no `AskUserQuestion` fires; non-empty queue → batched per ADR-013 Rule 1 cap (≤4 per call, sequential if >4).

### Step 2.4: Pre-`ALL_DONE` gate sequence (UNCONDITIONAL — fires before every `ALL_DONE` emit, P341)

Before the orchestrator emits the final `ALL_DONE` sentinel for the AFK loop, it MUST run the following gate sequence. The sequence fires **unconditionally** — at every stop-condition (`#1`, `#2`, `#3` per Step 2) AND at every halt-path that emits a final AFK summary AND on quota-exhaustion / natural loop end. The sequence has four parts that MUST complete in order (gate (0) prepended per P390); the structural rule is `ALL_DONE` emits ONLY after (0) AND (a) AND (b) complete cleanly. Per-state subdir layout reminder: this step's order in the SKILL is logical (Step 2.4 fires *between* the Step 2 stop-check and the Step 2.5 surfacing routine *only as a wrapper*); the numerical ordering reflects the conceptual sequence (Step 2.4 wraps Step 2.5 + the new retro gate, then Step 2.5/2.5b execute as gate (a)'s worker).

**Gate (0) — Objective backlog-empty assertion (P390, fires FIRST, before gate (a)).** Before the rest of the sequence runs, the orchestrator MUST re-scan the live backlog and prove that the Step 2 stop-condition it is about to act on OBJECTIVELY holds. `ALL_DONE` is forbidden while ≥1 dispatchable ticket remains — a non-empty actionable backlog is itself the disproof of stop-condition #1/#2/#3.

1. *Re-scan.* Re-run the Step 1 dual-tolerant glob `ls docs/problems/*.open.md docs/problems/*.known-error.md docs/problems/open/*.md docs/problems/known-error/*.md 2>/dev/null` (RFC-002 window — both layouts). This is a fresh filesystem read, NOT a re-use of the Step 1 cache or the agent's recollection — tickets may have transitioned, closed, or been created by prior iters / the session-level retro since Step 1.

2. *Classify each ticket as dispatchable or not — objectively, per recorded marker, never by salience.* A ticket is **non-dispatchable** ONLY when an objective, recorded condition excludes it:
   - it is `verifying` / carries `## Fix Released` awaiting user verification (stop-condition #2, interactive);
   - it carries an upstream-blocked marker (`## Reported Upstream` / `- **Upstream report pending** --` / em-dash legacy) or a recorded blocked classification with a dead-end investigation (stop-condition #3);
   - it was filtered out THIS session by Step 3.5 (interactive-ratification predicate) or Step 3.6 (already-shipped relevance gate) — keyed off the durable per-session skip record those steps write (the `outstanding_questions` entry in `.afk-run-state/outstanding-questions.jsonl` carrying the ticket id), NOT agent recollection, so the classification is reproducible across the re-scan and cannot loop forever;
   - its fix changeset sits in `docs/changesets-holding/` with an unmet reinstate criterion (held, not dispatchable).
   Every other open / known-error ticket is **dispatchable** — ordinary autonomous fix-and-commit work. The agent MUST NOT reclassify a dispatchable ticket as non-dispatchable because the *salient* remainder of the backlog is interactive-gated, because the ticket "feels" out of scope, or because a user-directed pivot consumed the loop's attention. The subjective "this is a natural stopping point" judgement is exactly the P390 failure; the classification is per-ticket and marker-bound.

3. *Decide.* If the re-scan yields **≥1 dispatchable ticket**, `ALL_DONE` is FORBIDDEN: the stop-condition the orchestrator was about to emit does NOT objectively hold. The orchestrator loops back to Step 3 tier-first selection (Critical-bypass → Inbound-reported → Internal, within-tier WSJF per ADR-076) over the dispatchable set and dispatches the next iter — it does NOT proceed to gate (a)/(b)/(c). Only when the re-scan yields **zero dispatchable tickets** does gate (0) pass and the sequence proceed to gate (a). Gate (0) finding work is a **loopback, not a halt** — it is productive (the loop resumes draining), so it is NOT a Hard-fail halt trigger.

**Why gate (0) fires first**: gates (a)/(b)/(c) (surface questions → retro → emit) presume the loop is genuinely done; running the retro and emitting `ALL_DONE` while dispatchable work remains prematurely ends the AFK drain (P390), forcing the user to re-prompt "keep working the backlog" and defeating JTBD-006. Gate (0) makes "the backlog is objectively empty of dispatchable tickets" a hard, re-verified precondition of the whole sequence rather than a subjective agent judgement. A user-directed mid-loop pivot (e.g. an eval-cohort detour) does NOT discharge the Tier-exhaustion obligation: after the pivot, gate (0)'s re-scan resumes tier selection rather than terminating — which also catches the P390 coverage miss where a Tier-1 ticket (P382) was skipped entirely. Sibling class: P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference) — all agent-invented loop-control stops the framework did not authorise (ADR-044 "Continue / stop loops" is framework-resolved: the natural stop is concrete — `ALL_DONE` conditions objectively met — not "this feels done").

**Gate (a) — Outstanding-questions surface + oversight-unconfirmed drain (P348 amendment 2026-06-02).** Two sub-surfaces, both fire in this gate:

1. *Outstanding-questions surface.* Read `.afk-run-state/outstanding-questions.jsonl`. If non-empty, invoke Step 2.5b's surfacing routine to present the accumulated queue (via `AskUserQuestion`-when-available-else-table per ADR-013 Rule 1 / Rule 6). On completion, truncate the queue file. If the queue is empty, this sub-surface returns immediately. The surfacing routine is the existing Step 2.5b — Step 2.4 does NOT re-implement; it sequences.

2. *Oversight-unconfirmed drain.* Run `wr-architect-detect-unoversighted` and `wr-jtbd-detect-unoversighted` (both ADR-049 PATH shims, both always exit 0; output is the list of unoversighted artefact paths). If either lists ≥ 1 artefact whose frontmatter carries `human-oversight: unconfirmed` (the AFK-explicit-deferred state, distinct from the implicit-absent state pre-existing ADR/JTBD files carry), surface a one-line nudge: *"N iter-deferred decision(s)/job(s) carry `human-oversight: unconfirmed`. Run `/wr-architect:review-decisions` and `/wr-jtbd:confirm-jobs-and-personas` to drain."* If `AskUserQuestion` is available (`/wr-itil:work-problems` was invoked interactively before the AFK loop started), surface a 2-option choice — `Drain now` (invokes the appropriate drain skill before `ALL_DONE`) / `Defer to next session` (proceeds to gate (b) with the nudge in the final summary). If `AskUserQuestion` is unavailable, the nudge prints in the final summary table and gate (b) proceeds. The drain is NOT a halt — `unconfirmed` markers are explicit-by-design AFK signals (the iter wrote them KNOWING the user would need to confirm), and the drain is the documented path. Detector difference matters: ADRs/JTBDs that pre-date the ADR-066/ADR-068 marker contract carry NO `human-oversight:` line at all; they fall through to the existing review-decisions/confirm-jobs-and-personas backlog drain (no new surfacing here). The new surfacing fires ONLY on the explicit `unconfirmed` value — the AFK-iter-deferred class P348 introduces.

**Gate (b) — Session-level retro.** Invoke `/wr-retrospective:run-retro` via the Skill tool. This is the **orchestrator-main-turn session-level retro**, distinct from the per-iter retro fired inside each iter subprocess (per P086 / Step 5 retro-on-exit clause). The session-level retro covers cross-iter patterns, friction observations, framework-improvement candidates, and the AFK loop's overall trajectory — surface visible only after multiple iters have completed. Retro commits its own work per ADR-014; any tickets retro creates ride retro's own commit, and the orchestrator picks them up on the *next* invocation of `/wr-itil:work-problems` rather than re-entering the loop here.

**Gate (c) — Emit `ALL_DONE`.** The sentinel emits ONLY after gate (0), gate (a), and gate (b) complete. The final summary (per Output Format below) includes the Session Cost section and the Outstanding Design Questions table (when gate (a)'s fallback branch fired). `ALL_DONE` is the single canonical emit position — Step 2.5 no longer emits `ALL_DONE` directly; its closing prose hands control to Step 2.4 (b) per the cross-reference.

```
ALL_DONE
```

**Hard-fail mode (halt with directive instead of emit `ALL_DONE`).** If either gate cannot complete to a clean state, the orchestrator MUST halt with a clear directive rather than emit `ALL_DONE`. The halt is recoverable — the user returns, satisfies the gate, and re-invokes `/wr-itil:work-problems` (which observes the now-clean state and emits `ALL_DONE` on the natural Step 2 → Step 2.4 path).

Halt triggers:

- **Gate (a) cannot complete**: queue has user-input-required entries AND `AskUserQuestion` is unavailable AND the fallback Outstanding Design Questions table cannot render (e.g. write error to `.afk-run-state/`). The halt directive cites the queue file path + entry count + the rendering failure.
- **Gate (b) cannot complete**: `/wr-retrospective:run-retro` returns a non-zero exit code or the Skill tool itself is unavailable. The halt directive cites the run-retro failure mode (skill-unavailable / non-zero exit / commit-gate rejection per ADR-014). Retro is non-blocking *within* the iter subprocess (per Step 5's retro-on-exit clause) but **load-bearing** at the orchestrator-main-turn session-level gate — these are distinct surfaces.

**Why unconditional**: prior to this gate, Step 2.5's outstanding-questions surface fired conditionally on stop-condition #2; stop-conditions #1 and #3 did NOT route through it unless the queue happened to be non-empty AND the agent remembered the cross-reference. Session-level retro was implicit — only per-iter retros existed. The structural gap was that `ALL_DONE` could emit while direction-class observations remained queued AND without a session-level retro running — both gates were nominally documented but neither was a hard prerequisite. Step 2.4 closes this by making the gate sequence a hard, unconditional prerequisite. The 2026-05-31 user direction codified the invariant: *"the work-problems skill MUST surface the outstanding questions at the end before emitting ALL_DONE. It MUST then run a retro. Only then should it emit ALL_DONE"* (P341 Description verbatim).

**Composition**: gate (a) inherits the Step 2.5 / Step 2.5b surfacing routine without modification — the new structure is a wrapper, not a re-implementation. Gate (b) is the orchestrator-level extension of P086 (which fires retro at iter-subprocess level only). Gate (c) is the same `ALL_DONE` sentinel; only its emit position is amended. The pre-existing P126 cross-reference principle (`halt-paths-must-route-design-questions-through-Step-2.5b`) is preserved — halt-paths still route through Step 2.5b; the only addition is that even *successful* loop ends now route through Step 2.4 (a)+(b) before `ALL_DONE`. Per ADR-044 framework-resolution boundary: the agent-internal trust-boundary for *when* to surface is now framework-resolved (unconditional pre-`ALL_DONE`); the user-input surface *within* gate (a) is unchanged (still ADR-013 Rule 1 batched-AskUserQuestion when available, Rule 6 table fallback otherwise).

### Step 2.5: Surface accumulated outstanding questions at loop end (P135 Phase 3 — default emit shape)

Per ADR-044 framework-resolution boundary: human input is for direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction (six categories). Across N iters, those observations accumulate at iter level (`ITERATION_SUMMARY.outstanding_questions`) and persist to a session-level queue file. Loop-end Step 2.5 reads, ranks, and presents the batch.

**1. Read the accumulated queue.** Read `.afk-run-state/outstanding-questions.jsonl` — each line is one entry per the ITERATION_SUMMARY `outstanding_questions` schema (see Step 5 Output contract). De-duplicate identical entries (same `category` + same `question` text + same `existing_decision` for deviation-approval).

**2. Rank the entries.** Apply the ranking precedence: deviation-approval (highest) > direction > one-time-override > silent-framework > taste > correction-followup. Within each category, preserve iter-order (oldest first) so the user reads the queue in temporal sequence.

**3. Branch on interactivity.**

- **Default branch — call `AskUserQuestion` when available** (the orchestrator's main turn is interactive by construction; the user is presumed at the keyboard at loop end). Batch the entries into one or more `AskUserQuestion` calls per ADR-013 Rule 1 cap. Header per category: `"Outstanding direction"`, `"Approve deviation from existing decision"`, `"One-time override"`, etc. For deviation-approval entries, options are `Approve + amend ADR` / `Approve + supersede ADR` / `Approve + one-time exception` / `Reject (existing decision stands)` / `Defer (need more evidence)` — the 5-option shape matching the `proposed_shape` field. For other entries, options are extracted from the entry's `question` text or candidate fixes. Write answers back to the corresponding ticket files so the next AFK loop does not re-ask.

- **Fallback branch — emit `### Outstanding Design Questions` table** when `AskUserQuestion` is unavailable (restricted permission mode, hook-disabled tool surface). The table lists each entry with its `category`, `question`, `existing_decision` / `contradicting_evidence` for deviation-approval entries, and `ticket_id`. The user answers on return.

**4. Cleanup.** After all entries are resolved (whether via `AskUserQuestion` or table), truncate `.afk-run-state/outstanding-questions.jsonl` to empty. The next AFK loop starts with a clean queue.

**5. Cleanup + hand control to Step 2.4 (b) for session-level retro (P341).** Step 2.5 is the worker of Step 2.4 gate (a); after gate (a)'s surfacing routine completes and the queue file is truncated, control passes to Step 2.4 gate (b) for the session-level retro. The final summary (including the Outstanding Design Questions table when Step 2.5b's fallback branch fired) is prepared here but the `ALL_DONE` sentinel emits at Step 2.4 (c) AFTER retro completes — not at Step 2.5 directly. This makes Step 2.4 the single canonical `ALL_DONE` emit position; external scripts watching for completion read the sentinel from the post-retro position per Step 2.4.

### Step 2.5b: Surface accumulated user-answerable skips (reusable surfacing routine, P122 + P126)

Step 2.5b is the single source of truth for routing accumulated user-answerable skip-reasons through `AskUserQuestion`-when-available-else-table. It is the sub-step that Step 2.5 (stop-condition #2) AND every halt path that fires after iters have accumulated skipped tickets cross-references — keeping the surfacing logic in one place rather than duplicated across each halt path.

**Gating clause — fire only when at least one accumulated user-answerable skip exists.** Iterate the skip list collected by Step 4's classifier and count entries whose `skip_reason_category == user-answerable`. If the count is zero, return immediately and let the caller emit its summary directly. This guards empty-skip halts (e.g. Step 0 fetch-failure halt before any iters have run) from triggering an unnecessary round-trip.

**1. Extract the question set.** For every skipped ticket whose classifier skip-reason is `user-answerable` (see Step 4's taxonomy), extract its outstanding question(s) from the ticket body — typically from a "Pacing decision", "Naming decision", or outstanding "Investigation Tasks" section. Cap at 4 questions per `AskUserQuestion` call per Anthropic's tool documentation; the same cap applies regardless of whether Step 2.5b was invoked from stop-condition #2 or a halt path.

**2. Branch on interactivity per ADR-013 Rule 1 / Rule 6.**

- **Default branch — call `AskUserQuestion` when available** (the orchestrator's main turn is interactive by construction; the user is presumed at the keyboard). Batch the questions into one `AskUserQuestion` call (or more, if >4 questions, issued sequentially). Header: `"Outstanding design questions"`. For each question, set the prompt from the extracted text and the options from the ticket's candidate fixes or option list. Write each answer back to the corresponding ticket file so the next AFK loop does not re-ask. This is ADR-013 Rule 1 applied to the orchestrator's main-turn surface.
- **Fallback branch — emit `### Outstanding Design Questions` table** when `AskUserQuestion` is unavailable (restricted permission mode, hook-disabled tool surface, or any other context where the structured-question primitive cannot fire). The table lists each question with its Ticket ID, the question text, and one-line context. The user answers on return. This is ADR-013 Rule 6 fail-safe — fall back to a structured summary when the structured-interaction primitive is unavailable.

**Return.** Hand control back to the caller. The caller is responsible for emitting its own final summary (and the `ALL_DONE` sentinel for stop-condition #2; halt paths each have their own outcome label per Step 6 / ADR-042 Rule 5 / Step 6.75 / etc.).

**Cross-skill principle (architect FLAG, P122 + P126)**: orchestrator main turns default to `AskUserQuestion` when available; the AFK persona (JTBD-006) is served by the **subprocess-boundary contract under ADR-032** (iteration subprocess workers are AFK by construction via `claude -p` — they exit at `ITERATION_SUMMARY` and never reach the orchestrator's stop or halt surfaces), NOT by suppressing `AskUserQuestion` at the orchestrator layer. Step 5's iteration-prompt template carries the per-subprocess AFK contract (constraint: "Do not call `AskUserQuestion`"); the orchestrator's stop and halt surfaces fire only in the main turn where the user is presumed present. P122 established this principle at Step 2.5; P126 extends it to every halt path that emits a final AFK summary (the principle: **halt-paths-must-route-design-questions-through-Step-2.5b** — every halt path that fires after iters have accumulated user-answerable skips MUST run Step 2.5b before emitting its summary).

### Step 3: Pick the highest-WSJF problem in the highest non-empty tier

Selection partitions the backlog into three **tiers** and works the highest non-empty tier first; the WSJF tie-break ladder applies **within** a tier, not across tiers. Tiers, highest first (ADR-076):

1. **Tier 0 — Critical bypass**: Severity Very High (≥17) OR security-classified OR incident-linked. The most critical issues always come first, regardless of origin.
2. **Tier 1 — Inbound-reported**: ticket carries `**Origin**: inbound-reported` (reported to us by an external user; ADR-062). Worked ahead of internal tickets — customer-service / feedback-signal preservation: ignored reporters stop reporting and churn.
3. **Tier 2 — Internal**: everything else (`**Origin**: internal` or no Origin field).

Within the highest non-empty tier, select the problem with the highest WSJF score. If there's a tie, prefer:
1. Known Errors over Open problems (they have a confirmed fix path — less risk of wasted effort)
2. Smaller effort over larger (faster throughput)
3. Older reported date (longer wait = higher urgency)
4. Lower ID (deterministic final tiebreaker)

The full selection order is therefore: **tier** (Critical-bypass → Inbound-reported → Internal), then the within-tier ladder `(WSJF desc, Known-Error-first, Effort-divisor asc, Reported-date asc, ID asc)`. <!-- REPORTED-FIRST-TIER-SOURCE: /wr-itil:work-problems SKILL.md Step 3 (ADR-076) -->

### Step 3.5: JTBD ratification predicate-check (per RFC-016 / P344)

After Step 3 selects a candidate ticket and before Step 4 classifies it for dispatch, predicate-check the cited JTBDs of the selected ticket. The per-iter JTBD review subagent (ADR-068 surface 3 — the `[Unratified Dependency]` verdict) catches the same class INSIDE the iter subprocess, but only after spending iter-dispatch cost (~$3-5 + 5-10 min per skip). This step shifts the predicate left to the orchestrator layer for the cost of one grep + per-JTBD shim call — analogous to how Step 0b pre-flights inbound-discovery staleness rather than letting iters discover it. Driving exemplar: 2026-05-31 session 9 iter 5 dispatched P082 against unratified JTBD-001 + JTBD-006; the iter correctly skipped per ADR-074 substance-confirm-before-build, but the per-dispatch cost was wasted.

**Mechanism:**

```bash
wr-itil-check-ticket-jtbd-ratification "<selected-ticket-path>"
predicate_exit=$?
```

`wr-itil-check-ticket-jtbd-ratification` is the ADR-049 / ADR-080 `$PATH` shim that dispatches `packages/itil/scripts/check-ticket-jtbd-ratification.sh`. The script extracts cited `JTBD-NNN` IDs from the ticket body (Decision Drivers / `**JTBD**:` / `**Persona**:` references) and delegates per-JTBD ratification to `wr-jtbd-is-job-or-persona-unconfirmed` (the ADR-068 surface 3 single-artifact predicate). Polarity is INVERTED vs the inner predicate — the outer script answers "are all cited JTBDs ratified?" rather than "is THIS one unconfirmed?". Behavioural contract asserted by `test/work-problems-step-3-5-jtbd-ratification-predicate.bats`.

Exit-code routing:

| `predicate_exit` | Meaning | Action |
|---|---|---|
| `0` | All cited JTBDs ratified, OR ticket cites no JTBDs, OR per-JTBD shim missing (ADR-031 silent-pass) | Proceed to Step 4 normally — the ticket is dispatchable. |
| `1` | ≥1 cited JTBD unratified (or unresolved) — IDs on stdout, one per line; `JTBD-NNN (unresolved)` for inner exit-2 cases | Route the ticket to Step 4's user-answerable skip path (`skip_reason_category: user-answerable`). Queue an `outstanding_questions` entry (`category: "direction"`) naming the unratified JTBDs + ticket ID + remedy: *"Run `/wr-jtbd:confirm-jobs-and-personas` to ratify the cited jobs/personas, then re-invoke `/wr-itil:work-problems`."* Loop back to Step 3 to re-run the tier-first selection over the remaining backlog minus the skipped ticket. |
| `2` | Ticket file missing / unreadable | Halt the loop with the structured Prior-Session State report — this is the same shape as the README-reconciliation Exit 2 halt at Step 0 (deeper repair needed, not mechanical reconciliation). |

**Loopback tier preservation**: re-run the Step 3 tier-first selection over the remaining backlog minus the skipped ticket. Tier order (Critical-bypass → Inbound-reported → Internal) and within-tier WSJF ladder are preserved per ADR-076. If every actionable ticket is filtered out by Step 3.5, Step 2 stop-condition #1 (no actionable problems) fires naturally and the accumulated `outstanding_questions` entries surface at Step 2.4 gate (a) per the existing batched-`AskUserQuestion` contract.

**Why orchestrator-layer, not iter-layer**: the inner per-iter JTBD subagent stays in place (defence-in-depth — the iter-layer is the authoritative second-source, not a replacement surface). The orchestrator predicate is the optimisation: cheap pre-check eliminates wasted dispatch when the answer is knowable from a `grep` + frontmatter read. The two surfaces are not redundant — they cover different failure modes (orchestrator: shift-left cost optimisation; iter: substance-confirm-before-build governance gate per ADR-074). When the orchestrator silent-passes (predicate-exit 0 via missing-shim degenerate case per ADR-031), the iter-layer still catches any unratified-dep correctly.

**AFK authorisation per ADR-013 Rule 6**: this is a pure read-only predicate-check (no writes, no commits, no external comms). No `AskUserQuestion` at this step — the routing is deterministic per the table above. The user-answerable question accumulates in the queue file and surfaces at Step 2.4 gate (a) per the existing batched contract. Per ADR-044 framework-resolution boundary: routing is framework-resolved (mechanical); user input is preserved at the loop-end surface where it belongs.

**Compose-with**: ADR-068 (surface 3 single-artifact predicate — mirrored to orchestrator), ADR-074 (substance-confirm-before-build — JTBD-as-driver symmetric sibling to ADR-as-driver), ADR-076 (tier-first selection preserved by the loopback), ADR-031 (degenerate adopter silent-pass when per-JTBD shim absent), ADR-049 / ADR-080 (PATH shim grammar + highest-version-wins wrapper), ADR-014 (no commit at this step — predicate is read-only). The sibling-class gap for ADRs cited as Decision Drivers (ADR-074 master class) is RFC-016 § Deferred item 1 — captured for follow-on after this Step 3.5 dogfoods.

### Step 3.6: Pre-dispatch relevance gate (per P385)

After Step 3.5's JTBD predicate-check and before Step 4 classifies the selected ticket, run the cheap deterministic relevance evaluator on the **selected ticket only**. On a mature backlog a meaningful fraction of "open" / known-error tickets have already been fixed by later work but never transitioned (observed: 3 of 6 worked tickets in one session). A full Step 5 `manage-problem` dispatch (~$3-5 + 5-10 min) against such a ticket only rediscovers the shipped fix and transitions it — the conclusion is correct but the rediscovery is expensive. This step shifts that conclusion left to a millisecond shell check, exactly as Step 3.5 shifts the JTBD-ratification predicate left and Step 0c pre-flights the backlog-wide relevance-close.

**Mechanism:**

```bash
wr-itil-evaluate-relevance "<selected-ticket-path>"
relevance_exit=$?
```

`wr-itil-evaluate-relevance` is the ADR-049 `$PATH` shim dispatching `packages/itil/scripts/evaluate-relevance.sh` — the **same evaluator** `/wr-itil:review-problems` Step 4.6 uses for its relevance-close pass (ADR-079). It emits one verdict line and carries a built-in ≥7-day age gate (a freshly-reported ticket SKIPs and falls through to normal work — no self-close paradox). Behavioural coverage of the verdict shapes is the existing `packages/itil/scripts/test/evaluate-relevance.bats`; Step 3.6 adds no new computational surface, only routing, so it carries no separate behavioural script of its own (a SKILL.md-prose grep would be a structural test, rejected per P081 / ADR-052).

Exit-code routing:

| `relevance_exit` / verdict | Meaning | Action |
|---|---|---|
| `0` `CLOSE-CANDIDATE` (no caveat) | cited fix shipped — clean evidence per ADR-079 shapes | Do **not** dispatch a full iter. Dispatch ONE `/wr-itil:review-problems` relevance-close sweep reusing the Step 0c `claude -p` pre-flight shape (see Step 0c / Step 5). Its Step 4.6 batch-closes the selected ticket **and any sibling CLOSE-CANDIDATEs** in one ADR-014 commit. Set the once-per-session sweep sentinel. Loop back to **Step 1** (the sweep changed the backlog + refreshed the README — re-scan re-applies the ADR-076 tier partition from the refreshed rankings). |
| `0` `CLOSE-CANDIDATE-WITH-CAVEAT` | partial / mixed-phase evidence | Do **not** auto-close — a caveat is the maintainer's decision input, not a mechanical close (review-problems 4.6b/4.6d route AFK caveats to the next interactive confirm). Route to Step 4's user-answerable skip (`skip_reason_category: user-answerable`); queue an `outstanding_questions` entry (`category: "direction"`) carrying the **caveat short-tag + one-line verbatim** from the verdict (P350 brief-before-ID — surface the close-confirmation question, not a bare ID) + the remedy *"Run `/wr-itil:review-problems` to confirm/close this ticket."* Loop back to **Step 3** (minus the skipped ticket). |
| `1` `KEEP` / `KEEP-WITH-NOTE` | still relevant (paths present, or Phase-1 false-positive class) | Proceed to Step 4 — dispatch the full iter normally. |
| `2` `SKIP` | age gate (<7 d) OR no extractable evidence | Proceed to Step 4 — the evaluator gives no close signal; default to work. |
| `3` error | evaluator failed | Proceed to Step 4 — fail-soft, non-blocking (mirrors review-problems Step 4.6 exit-3 "do not abort the pass" + the Step 0 P358 pre-flight failure contract). |

**Why the sweep, not an inline close**: ADR-079 constraint #1 forbids a standalone relevance-close — the close MUST run inside `/wr-itil:review-problems`. The orchestrator main turn holds no Edit/Write surface (allowed-tools), so it dispatches the sweep rather than closing inline; Step 3.6 must never grow an inline `git mv` to Closed. The dispatched sweep runs as a `claude -p` subprocess that is **AFK-by-construction** — the Step 5 dispatch constraint forbids `AskUserQuestion` in the worker, so review-problems Step 4.6's surface-batch-confirm flow takes the silent-close branch automatically, identical to the existing Step 0c side-effect path ("Step 0c dispatches `/wr-itil:review-problems` which includes Step 4.6 relevance-close"). The sweep is structurally a pre-flight subprocess (backlog refresh it owns end-to-end), so it inherits the **Step 0 pre-flight subprocess failure handling (P358)** non-blocking revert-and-proceed contract — a failed sweep does NOT halt the loop; fall through to Step 4 normal dispatch and let the full iter rediscover-and-transition (status-quo correctness).

**Sweep sentinel (bounded re-dispatch)**: a single review-problems sweep closes every clean CLOSE-CANDIDATE ≥7 d in one pass, so after it commits no clean CLOSE-CANDIDATE should survive the Step 1 re-scan. If a clean CLOSE-CANDIDATE is selected again **after the sentinel is set** (the sweep failed to close it — e.g. review-problems errored), do NOT re-dispatch the sweep (avoids an unbounded sweep loop) and do NOT dispatch a full iter against the already-fixed ticket (the P385 anti-goal). Route it to Step 4's user-answerable skip + queue an `outstanding_questions` entry (`category: "direction"`) naming the ticket + *"clean CLOSE-CANDIDATE survived a relevance-close sweep — confirm/close manually"*, then loop back to Step 3. This keeps the higher-tier ticket visible (ADR-076) rather than silently re-worked or silently dropped.

**Loopback tier preservation**: the Step 1 re-scan (clean-close branch) and the Step 3 loopback (caveat / sentinel-survivor branches) both re-apply the ADR-076 tier-first selection (Critical-bypass → Inbound-reported → Internal) and within-tier WSJF ladder over the remaining backlog. If every actionable ticket is filtered out, Step 2 stop-condition #1 fires naturally and the accumulated `outstanding_questions` surface at the Step 2.4 gate.

**AFK authorisation per ADR-013 Rule 6**: the evaluator is read-only (no writes, no commits, no external comms); routing is deterministic per the table above — no `AskUserQuestion` at this step (ADR-044 framework-resolution boundary + P132 mechanical-stage carve-out, identical posture to Step 3.5). User input is preserved at the loop-end Step 2.4 surface where the caveat / survivor questions accumulate. The dispatched sweep's own commit grain is ADR-014 (the orchestrator main turn does not commit at Step 3.6).

**Compose-with**: ADR-079 (relevance-close evaluator + constraint #1 sweep-not-standalone), ADR-076 (tier-first selection preserved on every loopback), ADR-026 (evidence-grounded verdict + structured caveat field), ADR-013 Rule 5/6 (silent-pass + AFK fail-safe), ADR-044 cat 4 + P132 (mechanical-stage carve-out — no AskUserQuestion), ADR-014 (sweep owns its commit), ADR-032 + P084 (subprocess isolation — AFK-by-construction silent-close), ADR-049 (PATH shim), ADR-052 / P081 (behavioural coverage via the reused evaluator's bats; no structural SKILL-prose test), P358 (pre-flight subprocess failure → non-blocking revert-and-proceed), P271 / Step 0c (dispatch-shape reuse), P344 / RFC-016 / Step 3.5 (sibling shift-left orchestrator predicate), P346 / P347 (relevance-close drivers).

<!-- @jtbd JTBD-006 (Progress the Backlog While I'm Away — pre-dispatch relevance gate closes already-shipped tickets cheaply instead of rediscovering the fix at full iter cost) -->

### Step 4: Classify each problem

Read the problem file and apply these deterministic rules:

| Problem state | Action | Skip-reason category |
|---|---|---|
| `.verifying.md` (Verification Pending, per ADR-022) | **Skip** — fix released, awaiting user verification | user-answerable (verification) |
| Known Error with fix strategy documented | **Work it** — implement the fix (on release, transition to `.verifying.md` per ADR-022) | — |
| Known Error without fix strategy | **Work it** — produce a fix strategy, then implement | — |
| Open problem with preliminary hypothesis or investigation notes | **Work it** — continue the investigation | — |
| Open problem with no leads (empty Root Cause Analysis) | **Work it** — read the relevant code, form a hypothesis, document findings | — |
| Problem previously attempted twice without progress in this session | **Skip** — mark as stuck, needs interactive attention | user-answerable (direction) |
| Open problem with outstanding user-answerable design question (naming, direction, pacing, scope) | **Skip** — surface the question at stop (Step 2.5) | user-answerable (design) |
| Open problem needing architect design judgment (new-ADR-level question) | **Skip** — note the architect-design blocker; Step 2.5 may elevate via a pre-triggered architect call in `--deep-stop` mode | architect-design |
| Open problem blocked on upstream dependency or Claude Code capability gap | **Auto-invoke `/wr-itil:report-upstream` via the AFK fallback** (per ADR-024 2026-06-04 (P270) amendment — manage-problem Step 6 external-root-cause detection AFK fallback owns the actual invocation; this row routes through it). The report-upstream skill composes the draft then scores the prose via `wr-risk-scorer:external-comms` (ADR-028); below-appetite → sends; above-appetite → risk-reduces (open-ended LLM judgement per ADR-024 2026-06-04 second-amendment leaf (a)) then re-scores → sends-or-queues. Security routing per leaf (b): upstream-with-`SECURITY.md` + below-appetite → files via declared channel; upstream-without-`SECURITY.md` → external-comms-gated impact assessment to (i) our repo, (ii) our reputation, (iii) reported party. Queued reports save to `## Queued Upstream Report` (renamed from `## Drafted Upstream Report` per leaf (c)). Queue does NOT halt — outstanding_question surfaces at Step 2.4 / Step 2.5b end-of-loop per P352. Iter still classifies the ticket as `upstream-blocked` (the local ticket itself is still blocked on the upstream fix) and **skips work on it** after the report-upstream invocation completes — the report-upstream call is the action this row takes; classification stays `upstream-blocked` so Step 4 routes to skip-rather-than-work. Tickets already carrying `- **Upstream report pending** --` (or the legacy em-dash variant) from prior sessions are detected via the already-noted check and routed to the report-upstream invocation (the marker shape is retained as the detection substrate per the 2026-06-04 amendment; ASCII `--` is the canonical form per P210, em-dash is the legacy form, both matched). | upstream-blocked |

The default is to work the problem. Only skip when the rule explicitly says so. This is an AFK loop — forward progress matters more than avoiding dead ends, because dead ends are cheap (findings are saved) and interactive input is expensive (user is absent).

**Skip-reason taxonomy.** Every skipped ticket is tagged with one of three categories so Step 2.5 can select which ones to surface as questions:

- **user-answerable** — the user can answer directly (verification, naming, direction, pacing, scope). Step 2.5 surfaces these as questions (interactive) or in the Outstanding Design Questions table (non-interactive / AFK).
- **architect-design** — requires architect judgment first; may escalate to a new ADR. Step 2.5 can optionally pre-trigger the architect agent in `--deep-stop` mode to produce a concrete user-answerable question. Otherwise noted as "pending architect review".
- **upstream-blocked** — external dependency, Claude Code capability gap, or waiting on third-party fix. Truly terminal for this loop — no user question would change anything. Report the blocker (now via auto-invoke of `/wr-itil:report-upstream`, per ADR-024 2026-06-04 (P270) amendment) and move on. **Before skipping, run the manage-problem external-root-cause detection AFK fallback** (per P063 amended 2026-06-04): the fallback now invokes `/wr-itil:report-upstream` rather than only appending the marker. The report-upstream skill scores the drafted prose via `wr-risk-scorer:external-comms` (ADR-028); below-appetite branches send (public-issue Step 5 / comment Step 5c / security Step 6 per classification); above-appetite branches risk-reduce + re-score; if-still-above queue an `outstanding_questions` entry per P352 queue-and-continue (orchestrator does NOT halt). Existing tickets carrying `- **Upstream report pending** --` (canonical ASCII per P210), `- **Upstream report pending** —` (legacy em-dash), or `- **Reported Upstream:**` / a `## Reported Upstream` section are detected via the already-noted check; the marker shape is retained for backward compatibility and as the detection substrate. The outbound audit trail across AFK iterations now reflects ACTUAL filings (or queued-for-review drafts), not just deferred intents.

Record the category alongside the skip reason in the iteration report so Step 2.5 can read the categories deterministically.

**Time-box each problem** to avoid runaway investigation: the delegated `manage-problem` skill's internal logic decides scope. If investigation reveals the scope has grown (e.g., effort was estimated S but turns out to be L or XL), save findings to the problem file, update the WSJF score, and move to the next problem. Never sink unbounded effort into one problem during AFK mode.

If a problem is skipped by this step, add it to a "skipped" list with the reason and loop back to step 3 for the next one.

### Step 5: Work the problem (dispatch via `claude -p` subprocess, per P084)

**Dispatch each iteration to a fresh `claude -p` subprocess via Bash** — do NOT spawn via the Agent tool, do NOT invoke `/wr-itil:manage-problem` inline via the Skill tool.

- **Skill-tool inline invocation** expands manage-problem's SKILL.md (500+ lines) into the main orchestrator's context every iteration, accumulates across the AFK loop, and causes silent early-stop (`ALL_DONE` without a documented stop condition firing). This was the original pre-P077 failure mode.
- **Agent-tool dispatch to a `general-purpose` subagent** (the P077 amendment) works for context isolation but fails at the governance-gate layer: subagents spawned via the Agent tool do NOT have the Agent tool in their own surface (three-source evidence — ToolSearch probe, Claude Code docs at `code.claude.com/docs/en/subagents.md`, empirical runtime error `"No such tool available: Agent. Agent is not available inside subagents."`). Without Agent, the iteration worker cannot set architect + JTBD PreToolUse edit-gate markers (only settable via Agent-tool PostToolUse hook), cannot satisfy the risk-scorer commit gate, and silently halts on every gate-covered iteration. P084 diagnoses and closes this gap.
- **`claude -p` subprocess dispatch** (this step, per P084 / ADR-032 amendment): the subprocess is a full main Claude Code session with Agent available in its own surface. Governance review runs at full depth via the normal `wr-architect:agent` / `wr-jtbd:agent` / `wr-risk-scorer:pipeline` delegation path inside the subprocess; PostToolUse marker hooks fire correctly matching the subprocess's own `$CLAUDE_SESSION_ID`; the commit gate unlocks natively. Context isolation preserved by the process boundary (each subprocess is a distinct process with its own session state; orchestrator's main context only sees the stdout). This is the AFK iteration-isolation wrapper — subprocess-boundary variant under ADR-032.

**Dispatch command shape (Bash, backgrounded with idle-timeout poll loop per P121):**

```bash
ITERATION_PROMPT=$(cat <<'PROMPT_EOF'
<iteration prompt body — see below>
PROMPT_EOF
)

ITER_JSON=$(mktemp)
DISPATCH_START_EPOCH=$(date +%s)
IDLE_TIMEOUT_S="${WORK_PROBLEMS_IDLE_TIMEOUT_S:-3600}"

# AFK-iter cross-context-leak guard (ADR-032 P157 amendment, line 127):
# the orchestrator-session pending-questions queue at
# .afk-run-state/outstanding-questions.jsonl is for surfacing on the user's
# next interactive session — NOT inside iter subprocess contexts. The
# itil-pending-questions-surface.sh SessionStart hook self-suppresses when
# this env var is set so the orchestrator's accumulated queue does not leak
# into iter subprocesses' first turn.
export WR_SUPPRESS_PENDING_QUESTIONS=1

# AFK-iter oversight-nudge suppression (ADR-066): the architect plugin's
# SessionStart oversight nudge ("N decisions lack human oversight — run
# /wr-architect:review-decisions") is an interactive batch-confirm prompt. It
# must NOT fire into an absent-user iter subprocess. architect-oversight-nudge.sh
# self-suppresses when this env var is set — same discipline as the
# pending-questions guard above (JTBD-006 friction guard).
export WR_SUPPRESS_OVERSIGHT_NUDGE=1

# Project-scoped governance plugins are NOT loaded by headless `claude -p`
# (P382): it activates only USER-scoped enabledPlugins, and project activation
# is trust-gated (headless skips trust), so `--setting-sources user,project`
# alone does not attach them. Without this, the iter subprocess has no
# windyroad architect/jtbd/risk-scorer/voice-tone agents or gate hooks — it
# commits ungated and cannot run retro-on-exit. Pass each governance plugin
# explicitly via `--plugin-dir`, resolved portably from the installed
# marketplace cache (highest-version-wins, ADR-080; adopter-safe via the
# ADR-049 bin-on-PATH shim, NOT a repo-relative path). Unresolvable plugins are
# skipped silently. <!-- @jtbd JTBD-001 (iter commits ship gated) @jtbd JTBD-006 (full governance surface inside AFK iters) -->
mapfile -t PLUGIN_DIR_ARGS < <(wr-itil-resolve-governance-plugin-dirs)

claude -p \
  --permission-mode bypassPermissions \
  --output-format json \
  "${PLUGIN_DIR_ARGS[@]}" \
  "$ITERATION_PROMPT" \
  < /dev/null \
  > "$ITER_JSON" 2>&1 &
ITER_PID=$!

SIGTERM_SENT=0
LAST_POLL_EPOCH=$DISPATCH_START_EPOCH
SUSPEND_OFFSET_S=0
EXPECTED_POLL_DELTA_S=60   # matches `sleep 60` cadence below
SUSPEND_JITTER_S=120       # tolerance above expected before treating gap as suspend (P307)
while kill -0 "$ITER_PID" 2>/dev/null; do
  sleep "$EXPECTED_POLL_DELTA_S"
  NOW=$(date +%s)
  # P307 machine-sleep false-kill: when the host suspends between polls,
  # wall-clock advances while the iter subprocess is itself suspended (no
  # actual idle work). Detect the wall-clock jump and accumulate it into
  # SUSPEND_OFFSET_S so IDLE_SECONDS (computed against NOW - SUSPEND_OFFSET_S
  # below) reads active-elapsed rather than wall-clock-elapsed. Without
  # this, laptop suspend falsely kills a completing iter (2026-05-26 iter 1
  # evidence: idle jumped 481s -> 1016s -> 5544s across suspend gaps;
  # SIGTERM fired at 5544s > 3600s, lost the iter's commit + cost metadata).
  ACTUAL_POLL_DELTA=$(( NOW - LAST_POLL_EPOCH ))
  if (( ACTUAL_POLL_DELTA > EXPECTED_POLL_DELTA_S + SUSPEND_JITTER_S )); then
    SUSPEND_OFFSET_S=$(( SUSPEND_OFFSET_S + ACTUAL_POLL_DELTA - EXPECTED_POLL_DELTA_S ))
  fi
  LAST_POLL_EPOCH=$NOW
  LAST_COMMIT_EPOCH=$(git log -1 --format=%at HEAD 2>/dev/null || echo "$DISPATCH_START_EPOCH")
  # LAST_ACTIVITY_MARK = max(DISPATCH_START_EPOCH, last commit timestamp).
  # The dispatch-start floor handles skip-iterations that produce no commit:
  # they are bounded by IDLE_TIMEOUT_S since dispatch start, not by an
  # arbitrarily-stale repo commit. See trade-off paragraph below.
  if (( LAST_COMMIT_EPOCH > DISPATCH_START_EPOCH )); then
    LAST_ACTIVITY_MARK=$LAST_COMMIT_EPOCH
  else
    LAST_ACTIVITY_MARK=$DISPATCH_START_EPOCH
  fi
  IDLE_SECONDS=$(( NOW - SUSPEND_OFFSET_S - LAST_ACTIVITY_MARK ))
  if (( IDLE_SECONDS > IDLE_TIMEOUT_S )) && (( SIGTERM_SENT == 0 )); then
    kill -TERM "$ITER_PID" 2>/dev/null || true
    SIGTERM_SENT=1
    echo "[work-problems] iter idle ${IDLE_SECONDS}s > ${IDLE_TIMEOUT_S}s threshold — SIGTERM sent to PID $ITER_PID" >&2
  fi
done

wait "$ITER_PID" 2>/dev/null
ITER_EXIT=$?
SUBPROCESS_OUTPUT=$(<"$ITER_JSON")
rm -f "$ITER_JSON"
```

**Flag rationale:**

- `--permission-mode bypassPermissions` — handles non-interactive permission prompts. Without this, Bash/Edit/Write calls inside the subprocess halt on approval prompts (no TTY). Alternative modes (`acceptEdits`, `auto`, `dontAsk`) are acceptable if adopters need narrower permission scopes; `bypassPermissions` is the broadest and the empirically-verified path.
- `--output-format json` — deterministic structured output. The subprocess's final agent message lands in the JSON response's `.result` field; orchestrator extracts `ITERATION_SUMMARY` from that field. Plain-text output would require fragile scraping.
- `"${PLUGIN_DIR_ARGS[@]}"` — `--plugin-dir <root>` pairs for each governance plugin, emitted by `wr-itil-resolve-governance-plugin-dirs` (the `mapfile` line above). **Load-bearing (P382).** Headless `claude -p` activates only USER-scoped `enabledPlugins`; project-scoped plugins stay inactive because project-plugin activation is trust-gated and headless skips the trust prompt. Empirically (verified 2026-06-21) `--setting-sources user,project` does NOT fix this — only `--plugin-dir` makes a project-scoped plugin's agents/hooks/skills available. Without these args an iter in a project-scope adopter tree commits ungated (architect/jtbd/risk-scorer/voice-tone agents resolve to "not found") and cannot run retro-on-exit. The resolver derives each plugin's root from its `bin/` dir on `$PATH` (ADR-049 — present in adopter marketplace-cache trees and source-dev alike) and selects the highest-semver cached version (ADR-080 — `$PATH` order is frozen at session init and goes stale mid-session, so it is NOT trusted for version selection). Behavioural second-source: `packages/itil/scripts/test/resolve-governance-plugin-dirs.bats`. The expansion is empty (no-op) when no governance plugins resolve, so source-repo dev sessions and minimal adopters degrade gracefully.
- `< /dev/null` — explicit stdin-closed redirect (P089 Gap 1). Without this, `claude -p` waits up to 3s for stdin data in non-TTY contexts and then prints `Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.` to stderr. The warning is on stderr — if the caller separates stderr and stdout streams, the warning is harmless. But the orchestrator captures via `2>&1` (required because the CLI emits progress prose on stderr that must not interleave between JSON responses when multiple invocations chain). Under the `2>&1` merge the stderr warning prefixes the stdout JSON and breaks `jq` / `json.load` / `JSON.parse` extraction at "line 1, column 1: Expecting value". The redirect suppresses the warning at source. First observed AFK-iter-7 iter 1 (2026-04-21); workaround is the Anthropic CLI help's own suggestion.

**No per-iteration budget cap.** The dispatch deliberately omits `--max-budget-usd`. Per user direction 2026-04-21: the natural stop condition for an AFK loop is quota exhaustion, not an arbitrary per-iteration dollar cap. A cap would halt iterations before quota is actually exhausted, wasting remaining budget. Runaway-iteration risk is bounded by quota + the orchestrator's Step 6.75 halt on unexpected dirty state + exit-code handling below.

**Idle-timeout SIGTERM (P121).** The poll loop above is the orchestrator-side guard against stuck iteration subprocesses — iters that complete their semantic work (commits land, retro runs, `ITERATION_SUMMARY` is emitted into the agent output stream) but then sit waiting on a hook timeout, a backgrounded subagent that never resolved, or some other CLI-level idle behaviour before exiting. Without the guard the orchestrator polls indefinitely; the JSON file stays 0 bytes (the CLI only flushes on exit) and wall-clock burns for ~$8/hour of subprocess overhead with no API turns. The 2026-04-25 P118 iter 5 evidence: 121 min wall-clock; final commit at ~100 min; manual SIGTERM at 121 min produced a clean 5649-byte JSON response with `is_error: false`, full `## Session Retrospective` section, parseable `ITERATION_SUMMARY` block, and `duration_ms: 2992935` (49.9 min — the real-work portion). SIGTERM is therefore a safe recovery primitive for this stuck-state class — empirically a clean exit-flush, not a destructive interrupt. Behavioural confirmation lives in `test/work-problems-step-5-idle-timeout-sigterm.bats` (P121 ships with this fixture as the second-source the production observation needed). The default `IDLE_TIMEOUT_S=3600` (60 min) leaves headroom for genuinely long architectural iters; the `WORK_PROBLEMS_IDLE_TIMEOUT_S` env-var overrides per-environment for adopters who run very long iters or want a tighter guard. The orchestrator's Step 6 progress line SHOULD annotate `(SIGTERM_SENT)` when the branch fires so the user can distinguish a SIGTERM-recovered iter from a normal completion (per JTBD-006 audit-trail expectation).

**SIGTERM exit-flush is conditional, not universal (P147).** The "clean exit-flush" claim above is empirically true ONLY when the subprocess has already emitted `ITERATION_SUMMARY` through the agent stream before going idle (the P118 shape: semantic work complete + retro complete, then idle-wait on some final hook). The 2026-04-29 P146 incident falsified the universal generalisation: an iteration deadlocked in a `bash until`-loop polling a backgrounded-task output file (commits had landed; ITERATION_SUMMARY had NEVER been emitted) and SIGTERM at 68m34s produced exit 143 with a **0-byte JSON file**. `claude -p --output-format json` writes the entire response as a single blob ON normal exit; the SIGTERM-handler (whatever it does inside the CLI) cannot synthesise a JSON response that the agent loop never produced. **Stuck-before-emit subclass: SIGTERM still recovers wall-clock, but loses metadata.** When the orchestrator observes exit 143 + 0-byte JSON, it MUST treat the iteration as a metadata-loss event: (1) verify work integrity from independent evidence (`git log` for commits + `git status --porcelain` for tree state); (2) halt the AFK loop per exit-code semantics rather than silently continue; (3) reconstruct cost from the Anthropic billing dashboard rather than from the missing JSON envelope. The behavioural second-source for the stuck-before-emit case lives in the same `test/work-problems-step-5-idle-timeout-sigterm.bats` fixture (a fake-shim that traps SIGTERM and exits without writing stdout, asserting `JSON_BYTES=0` after the orchestrator-shape harness fires SIGTERM). Cost-of-metadata-loss < cost-of-stuck-subprocess; SIGTERM remains the right recovery primitive — the conditional caveat is about what flushes after, not whether to fire.

**LAST_ACTIVITY_MARK signal trade-off.** The mark is `max(DISPATCH_START_EPOCH, last commit timestamp)`. The dispatch-start floor is intentional: skip-iterations that produce no commit (Step 4 routes a ticket to `action: skipped`) are bounded by `IDLE_TIMEOUT_S` since dispatch start, not by an arbitrarily-stale prior-commit timestamp. This protects against false-positive SIGTERM at iter T=0 when the most recent commit happens to be hours old. The trade-off is the inverse: a skip-iter that runs for `IDLE_TIMEOUT_S` (60 min default) will SIGTERM even though it never had a chance to commit. The 60-min default is well past the typical skip-iter wall-clock (a normal skip completes in seconds), so the trade-off rarely fires in practice; adopters who run unusually long skip-evaluation iters (e.g. deep architect-design probes) should raise `WORK_PROBLEMS_IDLE_TIMEOUT_S` accordingly. Alternative signals considered and rejected: `stat -f%m "$ITER_JSON"` (binary — file mtime only changes on subprocess exit, useless during the idle gap); subprocess RSS-change tracking (noisy; spikes during Agent-tool expansions confound the signal). The git-log signal is the cheapest reliable progress indicator the orchestrator already has.

**Machine-sleep false-kill — suspend-detect heuristic (P307).** The IDLE_SECONDS computation above subtracts `SUSPEND_OFFSET_S` from wall-clock `NOW` so the orchestrator measures *active-elapsed* time rather than raw wall-clock between LAST_ACTIVITY_MARK and now. The offset accumulates whenever a poll observes `ACTUAL_POLL_DELTA > EXPECTED_POLL_DELTA_S + SUSPEND_JITTER_S` (default `60 + 120 = 180s`) — i.e., the gap between consecutive `sleep 60` polls vastly exceeds the cadence the loop scheduled. The driver is the 2026-05-26 iter 1 evidence: the iter's host suspended (lid-close mid-loop) and the next poll observed an idle of 5544s; the wall-clock-only computation tripped SIGTERM at 5544s > 3600s, exit 143 + 0-byte JSON (the P147 stuck-before-emit metadata-loss class), losing a commit + cost metadata for an iter whose semantic work had completed. The suspend-detect heuristic converts that wall-clock-elapsed measure to "active-elapsed approximate" without needing monotonic clocks (which bash does not natively expose anyway). Alternatives considered and rejected: (a) monotonic / active-time clocks (POSIX `CLOCK_MONOTONIC` is not surfaced by `date` or `$EPOCHSECONDS`; would require a C helper or a Python-shim subprocess per poll); (b) iter-side heartbeat file the poll loop reads instead of wall-clock (works but adds an iter-side write contract; suspend-detect is purely orchestrator-side, no iter-prompt changes). The jitter buffer (`SUSPEND_JITTER_S=120`) is the load-bearing safety margin: it tolerates slow-hook / GC / brief-load-spike jitter (up to 180s total inter-poll delay) without falsely shifting; only genuine suspend / system-clock jumps cross the threshold. Adopters with unusually noisy hosts can raise `SUSPEND_JITTER_S` per environment; lowering it risks counting brief stalls as suspend. The heuristic is asymmetric — it can absorb a 5 min host hang into the offset and treat it as suspend, but the cost is at worst that one iter runs an extra 5 min before SIGTERM (cheaper than losing the iter's commit + metadata to a false-kill).

**Iteration prompt body (self-contained — the subprocess has no prior conversation context):**

**Re-ground per iter (P211 — orchestrator-side construction invariant)**: each iter's prompt body MUST be re-grounded per iter against the CURRENT ticket's identity (ID + title) only. The orchestrator does NOT inline the target ticket's `## Fix Strategy` section verbatim into the dispatch prompt — the subprocess reads Fix Strategy from disk via `/wr-itil:manage-problem` inside its own context, where the design rationale travels with the ticket file and stays anchored to the correct ticket. Across iterations, no prior-iter content leaks into iter N's prompt body — specifically, prior ticket ID, prior Fix Strategy text, prior outcome reason, prior commit SHA, prior retro findings, and prior outstanding-question entries MUST NOT carry across the iter boundary into the new prompt. The construction is template-driven and reset per iter; no global accumulator carries from iter to iter. The "self-contained" opener above is a subprocess-side property (the subprocess has no prior conversation context); the re-grounding invariant is the symmetric orchestrator-side property (the orchestrator main turn does not carry prior-iter prompt content into the next iter's dispatch construction). P211 reported as inbound from downstream consumer bbstats as their P194 — without this invariant, an iter inherits a stale design-rationale frame and may land fixes anchored on the wrong ticket's intent, degrading the JTBD-006 audit trail. **`@jtbd JTBD-006`** (load-bearing).

1. **Context**: this is one iteration of the AFK work-problems loop. The user is AFK. The orchestrator selected `P<NNN> (<title>)` as the highest-WSJF actionable ticket.
2. **Task**: apply the `/wr-itil:manage-problem` workflow for `work highest WSJF problem that can be progressed non-interactively as the user is AFK`. Follow manage-problem SKILL.md verbatim, including architect / jtbd / style-guide / voice-tone gate reviews and the commit gate (manage-problem Step 11). Because this subprocess has the Agent tool in its own surface, the normal review-via-subagent paths work — no inline-verdict fallback needed.
3. **Constraints**: commit the completed work per ADR-014. Do NOT push, do NOT run `push:watch`, do NOT run `release:watch` — the orchestrator's Step 6.5 owns release cadence. Do NOT invoke `capture-*` background skills mid-iter (AFK carve-out — ADR-032), **EXCEPT** (a) **retro-surfaced observations of recurring class-of-behaviour** — those route to `/wr-itil:capture-problem` per the **P342 mechanical-stage carve-out** (see retro-on-exit constraint #4 below; same trust-boundary as `/wr-retrospective:run-retro` Step 4a verification close-on-evidence — P342); and (b) **the I13 fix-time RFC auto-create** — when the propose-fix gate inside the delegated `/wr-itil:manage-problem` traversal detects an RFC-less Known Error (`wr-itil-check-fix-rfc-trace` emits a `no-rfc-trace:` directive), the iter auto-creates a problem-traced skeleton RFC via `/wr-itil:capture-rfc` then proceeds (ADR-073 auto-create-everywhere). This is NOT an aside-capture distraction: the auto-created RFC is the **mandatory vehicle for THIS iter's own fix** (ADR-071), not a tangential observation — it is in-scope working of the current ticket, framework-mediated (NOT cat-1 direction-setting → NO `AskUserQuestion`, P132), and the loop is NEVER skipped or blocked for a missing RFC (ADR-073). Structured-log the auto-create event to the iter summary (`notes`) per JTBD-006 audit-trail + the ADR-073 reassessment criterion (auto-created-RFC-under-scoped signal feeds `/wr-retrospective:run-retro`). Do NOT use `ScheduleWakeup` under any circumstance (P083 — iteration workers must not self-reschedule). **NEVER call `AskUserQuestion` mid-loop in AFK** (P135 / ADR-044): direction / deviation-approval / one-time-override / silent-framework observations queue at `ITERATION_SUMMARY.outstanding_questions` for loop-end batched presentation. **This includes the manage-problem substance-confirm-before-build guard (ADR-074 (Confirm a decision's substance before building dependent work)):** when the propose-fix step detects that the fix builds on a born-`proposed` decision whose substance is unconfirmed (via `wr-architect-is-decision-unconfirmed`), the iter does NOT implement on it and does NOT ask mid-loop — it queues a `category: "direction"` entry naming the unconfirmed ADR + its Decision Outcome for loop-end confirmation, and routes the ticket to `action: skipped`, `skip_reason_category: user-answerable`. Building on the unconfirmed substance instead (or guessing the choice) is the P315 failure this guard exists to prevent. The queued substance-confirm is a legitimate cat-1 direction ask — it is NOT counted as lazy in the Step 2d Ask Hygiene Pass (ADR-074 lazy-count exclusion). Per-iter `AskUserQuestion` calls are sub-contracting framework-resolved decisions back to the user (lazy deferral per Step 2d Ask Hygiene Pass classification). Non-interactive defaults apply per ADR-013 Rule 6 + ADR-044's framework-resolution boundary. **Treat the user as transient** (P130): even when observably present at orchestrator dispatch time, the user may answer one question and disappear for hours; presence is not a reliable signal and is not the goal. The iter's job is to progress the ticket and accumulate questions for batched surfacing — not to ask "is it OK to proceed?" at a mechanical-stage boundary. **Do NOT poll `bats` output with a bats-console-summary regex against TAP-format output** (P146 — bash until-loop-deadlock antipattern). The bats-console-summary line `<N> tests, <M> failures` is emitted ONLY by bats's *default* (non-TAP) formatter; `bats --tap` does not emit a console summary, so a polling loop of shape `until [ -f $OUT ] && grep -qE '^[0-9]+ tests?,' $OUT; do sleep 5; done` spins forever after bats completes (silent deadlock — no error, no exit; recovery requires manual SIGTERM with metadata loss per the P146/P147 stuck-before-emit subclass). When you need to wait on a backgrounded bats run, prefer `wait $bg_pid` (Unix idiom — completion signaled by process exit, no regex required) or, for the Bash tool, `run_in_background=true` + `BashOutput` polling on the tool's exit-state field rather than regex-poll on stdout. If you genuinely must regex-poll TAP output, anchor on the TAP plan line `^[0-9]+\.\.[0-9]+` (e.g. `1..1455`) — TAP's plan line is emitted on completion and is format-stable across bats versions; the bats-console-summary line is not. The console-summary vs TAP-format divergence is the load-bearing detail: `bats` and `bats --tap` produce structurally different stdout, and the antipattern assumes the former when iter dispatch typically uses the latter. **Do NOT poll subprocess completion with `pgrep -f '<pattern>'` inside an `until` / `while` loop** (P232 — self-referential pgrep deadlock; sibling variant of P146). `pgrep -f` matches against the FULL command line of every running process, so the polling loop's own `zsh -c` argument (which contains the literal `pgrep -f '<pattern>'` text) matches itself; with multiple concurrent polling loops, each loop matches the others and spins forever. Worked example of the antipattern: `until ! pgrep -f 'bats --recursive' > /dev/null 2>&1; do sleep 5; done` — the 2026-05-16 P232 deadlock witness; 4 concurrent polling loops each matched the others' command lines while no actual bats process ran; 45 min wall-clock + $20-30 wasted before manual SIGTERM. The same self-reference shape applies to `while pgrep -f ...; do sleep; done` and to `until ! pkill -0 -f '<pattern>'` / `while pkill -0 -f '<pattern>'` (signal-0 polling). The structural fix is the same as P146: prefer `wait $bg_pid` (Unix idiom — shell-native completion signal, no regex / no pgrep) or Bash-tool `run_in_background=true` + `BashOutput` polling (harness-tracked completion state). The hook `packages/itil/hooks/itil-bash-polling-antipattern-detect.sh` denies these shapes at PreToolUse:Bash, but the prompt rule belongs here too — structural enforcement + prompt discipline together close the class. **If the fix changes shippable code or package behaviour** (any path under `packages/<plugin>/{src,bin,hooks,skills,scripts,lib,agents}` excluding test paths — `test/`, `hooks/test/`, `scripts/test/` — and excluding `README.md` + `docs/*.md`), **the iter MUST author a `.changeset/*.md` entry in the same single ADR-014-grain commit as the fix** (the changeset names the bumping plugin via the YAML frontmatter `"@windyroad/<plugin>": <patch|minor|major>` per the changesets-action contract). **Doc-only changes** (under `docs/`, `*.md`) **and test-only changes** (under any `test/` path) **that ship no behaviour MAY omit the changeset**. The orchestrator's Step 6.5 release-cadence drain runs `release:watch` only when `.changeset/` is non-empty after push — without an iter-authored changeset, code-shape fixes accumulate without ever shipping to npm (violating JTBD-006's audit-trail expectation + JTBD-007's "Keep Plugins Current" closure dependency). Hook `packages/itil/hooks/itil-changeset-discipline.sh` (P141) provides hook-level enforcement at `git commit` time as defence-in-depth — but plugin hook execution depends on the marketplace cache carrying the current hook version, so the prompt-time constraint here MUST land independently (composes-with the hook; does NOT rely on the hook being installed). Inbound-reported from downstream consumer bbstats as their P195 — see [Related](#related) for `**Origin**: inbound-reported (bbstats#195)` per ADR-076. **`@jtbd JTBD-006`** (load-bearing) **`@jtbd JTBD-007`** (closure-dependent).
4. **Retro-on-exit (P086) + retro-surfaced observation classification (P342) + iter-owned BRIEFING commit (P212)**: before emitting `ITERATION_SUMMARY`, invoke `/wr-retrospective:run-retro`. Retro runs INSIDE this subprocess so its Step 2b pipeline-instability scan has access to the iteration's rich tool-call history (hook misbehaviour, repeat-workaround patterns, subagent-delegation friction, release-path instability). Tickets retro creates ride a separate path: they delegate through `/wr-itil:manage-problem` which IS ADR-014 in-scope and self-commits each ticket per its own Step 11. Those commits land independently and the orchestrator picks them up on the next Step 1 scan.

   **BRIEFING.md commit responsibility — iter owns, run-retro does not (P212).** run-retro is explicitly out-of-scope for self-commit per ADR-014's Scope section (which lists `packages/retrospective/skills/run-retro/SKILL.md` under "Out of scope for now"). Retro therefore EDITS but DOES NOT COMMIT `docs/BRIEFING.md` / `docs/briefing/*.md`. The iter subprocess (NOT run-retro, NOT the orchestrator main turn) owns the BRIEFING commit. After retro completes, run `git status --porcelain docs/BRIEFING.md docs/briefing/`. If non-empty, the iter:

   1. Stages the dirty BRIEFING paths (`git add docs/BRIEFING.md docs/briefing/`).
   2. Delegates to `wr-risk-scorer:pipeline` per ADR-014's `work → score → commit` ordering. The BRIEFING refresh is mechanical chore-class (derived retro output, no source-of-truth change) — within-appetite by construction, same risk shape as the `chore(problems): reconcile README ...` and `chore(problems): check upstream responses` precedents in ADR-014's commit-message convention table.
   3. Commits as `chore(briefing): refresh from iter retro (P<NNN>)` where `P<NNN>` is the ticket the iter was working.

   Pre-P212, the orchestrator's Step 6.75 absorbed this as `dirty-for-a-known-reason` and added the commit at orchestrator-main-turn cost, invoking `wr-risk-scorer:pipeline` twice per iter (once for the ticket commit, once for the orchestrator-side hand-off). Shifting the commit into the iter subprocess preserves the audit trail (the same `chore(briefing)` commit lands), eliminates the orchestrator-main-turn hand-off, and moves the second scoring call from expensive main-turn context to cheaper iter-subprocess context. Step 6.75's table is amended below to classify dirty BRIEFING-at-iter-exit as a bug class rather than an expected hand-off.

   Proceed to `ITERATION_SUMMARY` emission regardless of retro findings — retro is non-blocking at the iter-subprocess layer (do not block on retro): if retro fails or surfaces findings, the iteration still returns a summary so the AFK loop does not silently halt on a flaky retro run. The iter MUST verify `git status` is clean (no remaining BRIEFING dirty state) before emitting `ITERATION_SUMMARY`. (Session-level retro at the orchestrator-main-turn layer per Step 2.4 gate (b) IS load-bearing — distinct surface; see Step 2.4 prose for the orchestrator-layer halt semantics.)

   **P342 classification taxonomy — retro-surfaced observations.** When the iter-retro's Step 4b Stage 1 surfaces a ticketable observation, the routing depends on classification:

   - **Recurring class-of-behaviour observation** (sibling iters hit same pattern; SKILL-contract drift; hook misbehaviour; framework-gap; pipeline instability with concrete fix path): **auto-ticket via `/wr-itil:capture-problem` with pre-resolved persona + JTBD flags** (or `/wr-itil:manage-problem` if capture-problem sibling not yet available). This is the **mechanical-stage carve-out per run-retro Step 4a precedent** — the retro IS the system designed to mechanically observe and surface recurring class-of-behaviour, so its output ticketing is policy-authorised silent proceed per ADR-013 Rule 5. The capture-problem dispatch commits its own ticket per ADR-014; the ticket enters the WSJF queue on the orchestrator's next Step 1 scan. This is the routing that closes the silent-queue-accumulation gap P342 names.

     **Dispatch shape under the I12 derive-then-ratify contract (ADR-060 Amendment 2026-06-02; R007 paired-capability gap)**: AFK callers MUST pre-resolve persona + JTBD via flags or capture-problem halts-with-stderr-directive (per capture-problem SKILL.md Step 1.5b AFK halt clause). The halt stderr is unobservable to the AFK user — silent loop-stall, violating JTBD-006's audit-trail guarantee. The iter subprocess derives both values from iter context BEFORE invoking capture-problem:

     1. **Persona derivation from iter context**: the iter is dispatched against a specific ticket carrying Origin + RFC trace + story trace; derive persona from those signals. Default to `developer` when context is ambiguous — it is the dominant persona across this monorepo's JTBD corpus. **Validate the derived value against the persona enum `{developer | tech-lead | plugin-developer | plugin-user}` BEFORE dispatch** (capture-problem halts-with-directive on invalid `--persona=` per its SKILL.md Step 1.5b validation rule). On invalid-derivation, route to `outstanding_questions` (genuinely-ambiguous branch below) instead of dispatching with a bad value.
     2. **JTBD derivation from iter context**: read the iter-prompt content. Cite `JTBD-006` for AFK-loop-continuity / iter-dispatch / orchestrator-mechanic contexts; `JTBD-001` for governance / ADR / decision-record contexts; `JTBD-101` for plugin-discoverability / plugin-developer / suite-extension contexts. Multi-JTBD entries are allowed (comma-separated, no spaces — per capture-problem's `--jtbd=` flag grammar).
     3. **Dispatch shape**: `/wr-itil:capture-problem --no-prompt --persona=<derived> --jtbd=<derived-list> "<description>"`. The `--no-prompt` flag is the AFK-mode marker that suppresses the I12 derive-then-ratify `AskUserQuestion` fallback inside capture-problem (per its SKILL.md Step 1.5b AFK halt clause); combined with the pre-resolved `--persona` + `--jtbd` flags, the derive-success silent-proceed path fires per ADR-044 category 4 silent-framework.
     4. **Genuinely-ambiguous derivation** (cannot pick persona/JTBD cleanly from iter context; signals contradict; derived persona fails enum validation): do NOT invoke capture-problem (would halt-with-stderr-directive into the iter subprocess's unobservable stderr; the observation is lost). Instead, queue the observation as an `outstanding_questions` entry with `category: "direction"`, naming the candidate-anchoring options for the orchestrator main-turn Step 2.5 surface. The orchestrator's `AskUserQuestion` on user return resolves the anchoring, then the user (or a future retro pass) creates the ticket.

   - **Direction-setting observation** (genuine user-judgment-bound question — design choice, deviation-approval, framework boundary): route to `outstanding_questions` entry per the ITERATION_SUMMARY schema. Orchestrator-level Step 2.5 surfaces these at loop end per the existing batched `AskUserQuestion` flow. These observations preserve the user's authority surface and MUST NOT auto-ticket.
   - **Ambiguous** (retro cannot cleanly distinguish recurring-class from direction-setting): **default to auto-ticket** per the P342 trust-boundary asymmetry, using the same persona + JTBD derivation contract above. The ticket lifecycle (`/wr-itil:manage-problem` Step 9d / `/wr-itil:review-problems` Step 4) will surface any embedded direction-setting question through the standard problem-review flow. Defaulting to queue would re-introduce the silent-queue-accumulation hazard P342 closes; defaulting to ticket has zero observation-drop risk. If persona/JTBD derivation itself fails (the recurring-class derivation branch's step 4), fall through to `outstanding_questions` rather than dispatch a halt-bound capture-problem.

   The classification is silent agent judgement (no `AskUserQuestion` per observation — that would re-route mechanical decisions back to the user, the lazy-deferral surface P135 / ADR-044 close). The mirror locus is run-retro `Step 4b` — same trust-boundary applies whether retro fires in iter context (this surface) OR standalone in main turn (run-retro Step 4b).
5. **Output**: end the final message with the `ITERATION_SUMMARY` block defined below — this is how the orchestrator consumes the iteration's result.

**Return-summary contract** (unchanged from the P077 amendment — the parse shape is dispatch-mechanism-agnostic). The subprocess's final message MUST end with this structured block, extracted by the orchestrator from the JSON `.result` field:

```
ITERATION_SUMMARY
ticket_id: P<NNN>
ticket_title: <title>
action: worked | skipped
outcome: closed | verifying | known-error | investigated | scope-expanded | partial-progress | skipped
committed: true | false | skipped
commit_sha: <sha>                                  # required when committed=true
reason: <one-line>                                 # required when committed=false or action=skipped
skip_reason_category: user-answerable | architect-design | upstream-blocked  # required when action=skipped
outstanding_questions: [<entry per ADR-044 6-class taxonomy — see schema below>]  # mandatory non-empty when iter touched a direction / deviation-approval / one-time-override / silent-framework decision; otherwise empty array
remaining_backlog_count: <N>
notes: <one-line>
```

**`outstanding_questions` schema (P135 Phase 3 / ADR-044)**: each entry is tagged with its category for loop-end Step 2.5 ranking. Two shapes:

```
# Standard direction / one-time-override / silent-framework / taste / correction-followup entry:
{
  category: "direction" | "one-time-override" | "silent-framework" | "taste" | "correction-followup"
  question: "<one-line — the genuine human-value question this iter surfaced>"
  context: "<one-line — the in-iter situation that surfaced it>"
  ticket_id: "P<NNN>"  # the iter's ticket; loop-end groups by ticket
}

# Deviation-candidate entry (the anti-BUFD-for-framework-evolution shape per ADR-044):
{
  category: "deviation-approval"
  existing_decision: "<ADR-NNN section / SKILL.md path:line / RISK-POLICY clause>"
  contradicting_evidence: "<tool invocation + observable outcome per ADR-026 grounding>"
  proposed_shape: "amend" | "supersede" | "one-time"
  rationale: "<one-line — why current evidence contradicts the existing decision>"
  ticket_id: "P<NNN>"
}
```

When the iter encounters an existing decision (ADR / SKILL contract / WSJF rule / RISK-POLICY entry) that current evidence contradicts, the agent does **NOT auto-deviate**. Instead it queues a `deviation-approval` entry per the schema. Loop-end Step 2.5 presents it as `AskUserQuestion` with options matching the proposed shape: `Approve + amend ADR` / `Approve + supersede ADR` / `Approve + one-time exception` / `Reject (existing decision stands)` / `Defer (need more evidence)`. The agent never auto-deviates; never blindly follows against evidence. **Not-queueing-when-strong-contradicting-evidence-exists is a regression** per the Phase 3 bats coverage (`work-problems-deviation-candidate-shape.bats`).

Architect review (R2) requires the commit state fields (`committed` / `commit_sha` / `reason`) so **Step 6.75's Dirty-for-known-reason branch stays evaluable** from the summary alone. JTBD review requires `ticket_id` / `action` / `skip_reason_category` / `outstanding_questions` so Step 2.5 and the Output Format's Completed / Skipped / Outstanding Design Questions tables can be populated deterministically without the orchestrator having to re-parse ticket files.

**Between-iter aggregation (P135 Phase 3)**: orchestrator's main turn appends each iter's `outstanding_questions` entries to a session-level queue file at `.afk-run-state/outstanding-questions.jsonl` between Step 6 (report) and Step 6.5 (release-cadence check). Each line is one JSON-encoded entry per the schema above. Loop-end emit (Step 2.5) reads the queue file, de-duplicates, ranks (deviation-approval > direction > one-time-override > silent-framework > taste > correction-followup), and presents as batched `AskUserQuestion` per ADR-013 Rule 1 cap (≤4 per call, sequential if >4). Per ADR-032 pending-questions artefact precedent.

**Mid-loop UserPromptSubmit handling (P135 Phase 3 / R4)**: when the orchestrator receives a user message DURING an iter (e.g. the user returns mid-loop and sends a new directive), the orchestrator MUST let the in-flight iter complete naturally to its `ITERATION_SUMMARY` emission BEFORE surfacing the new direction or the accumulated queue. Do NOT abort the iter mid-flight (no SIGTERM to the iter PID; no kill signal). The corrective for the 2026-04-27 iter-9-killed overcorrection: the user's correction was about future iter dispatch shape, not about the in-flight iter; killing wasted ~$5 + 25 min in-flight work. The handler waits for the natural exit, surfaces the queue + the new direction together, then routes per the user's response.

**Per-iteration cost metadata.** Alongside `.result`, the `claude -p --output-format json` response carries cost + usage fields in the same JSON blob. The orchestrator MUST extract these **named fields only** into per-iteration totals and session aggregates — nothing else from the JSON should be surfaced to the user or logged (PII guard: the response also carries `session_id`, `model`, `stop_reason`, and other envelope fields; the extraction is **scoped to the named fields** below so future contributors do not unconsciously broaden it).

Extracted fields (explicit field list):

- `.total_cost_usd` — dollar cost for the iteration.
- `.duration_ms` — wall-clock duration of the iteration subprocess.
- `.usage.input_tokens` — prompt tokens.
- `.usage.output_tokens` — generated tokens.
- `.usage.cache_creation_input_tokens` — tokens written to the prompt cache on this invocation.
- `.usage.cache_read_input_tokens` — tokens read from the prompt cache on this invocation (cache-read is the signal for warm-cache reuse across subsequent subprocess invocations in the same Bash session; high values here indicate the iteration benefited from prior-invocation caching).

Use `jq` (or an equivalent JSON parser) to extract them:

```bash
# $SUBPROCESS_OUTPUT holds the full JSON response body from claude -p.
read -r ITER_COST ITER_DURATION_MS ITER_INPUT ITER_OUTPUT ITER_CACHE_WRITE ITER_CACHE_READ < <(
  jq -r '[.total_cost_usd, .duration_ms, .usage.input_tokens, .usage.output_tokens, .usage.cache_creation_input_tokens, .usage.cache_read_input_tokens] | @tsv' <<<"$SUBPROCESS_OUTPUT"
)
# Accumulate into session totals for the ALL_DONE Session Cost section.
SESSION_COST=$(awk "BEGIN { printf \"%.4f\", ${SESSION_COST:-0} + $ITER_COST }")
SESSION_DURATION_MS=$(( ${SESSION_DURATION_MS:-0} + ITER_DURATION_MS ))
SESSION_INPUT_TOKENS=$(( ${SESSION_INPUT_TOKENS:-0} + ITER_INPUT ))
SESSION_OUTPUT_TOKENS=$(( ${SESSION_OUTPUT_TOKENS:-0} + ITER_OUTPUT ))
SESSION_CACHE_WRITE_TOKENS=$(( ${SESSION_CACHE_WRITE_TOKENS:-0} + ITER_CACHE_WRITE ))
SESSION_CACHE_READ_TOKENS=$(( ${SESSION_CACHE_READ_TOKENS:-0} + ITER_CACHE_READ ))
```

Do NOT extract `session_id`, `model`, `stop_reason`, `permission_denials`, `uuid`, or any other field from the JSON response. Those are subprocess-envelope fields that serve no user-visible purpose and risk leaking subprocess-internal identifiers into orchestrator output.

**Authority hierarchy (P089 Gap 2).** `total_cost_usd` and `usage.*` do NOT have the same reliability envelope — treat them accordingly when aggregating:

- `.total_cost_usd` is **authoritative for dollar cost** — cumulative across the subprocess's entire lifetime by contract. Use it as the sole source of truth for the Session Cost "Total cost (USD)" column and any cost-based stop condition.
- `.usage.*` token fields are **best-effort approximate** — the Anthropic CLI returns the final API response envelope, which is per-turn by construction. When the subprocess exits on a normal final turn the fields accumulate real usage; when the subprocess exits via a background-task completion-notification ack (a closing turn that only acknowledges a backgrounded task finished), the fields reflect ONLY that final ack turn and undercount dramatically. Detectable anomaly shape: the subprocess reports a final-turn-sized usage (handful of input tokens, hundreds of output tokens) alongside a wall-clock duration from the Bash wrapper's own timer that is orders of magnitude larger than the JSON's `duration_ms` field — the cumulative dollar cost still matches real spend, so the mismatch is self-evident on inspection.

Aggregation rule: sum `.total_cost_usd` into the session total and trust it; sum `.usage.*` into the session totals for cache-reuse ratio reasoning but label them best-effort in the Session Cost table. This asymmetry is correct-by-CLI-contract (cost is a session cumulative; usage is a per-response envelope); the orchestrator documents the asymmetry so adopters do not silently under-count tokens. First observed AFK-iter-7 iter 5 (2026-04-21): 1071s wall-clock / 60+ tool-use subprocess returned `duration_ms: 8546, num_turns: 1, usage.* ≈ 137K tokens, total_cost_usd: 6.08` — cost cumulative and correct, tokens reflecting only the final ack turn.

**Exit-code semantics — ordered check (P214 amendment to the P261 carve-out).** `claude -p` exits non-zero when the subprocess fails hard — subprocess crash, auth failure, unresolvable permission denial, API/quota exhaustion. Orthogonally, the `--output-format json` envelope carries an `is_error` field that fires `true` on transient API failures (529 Overloaded / 429 rate-limit / 401 auth-expired) where the subprocess exits 0 with `total_cost_usd: 0` — the API call never landed; no work was done; no `ITERATION_SUMMARY` was emitted. Before P214, the prose presented the exit-code rule first and the `is_error` carve-out as "orthogonal", which let an implementer silently route exit 0 + `is_error: true` to the `ITERATION_SUMMARY` parse path and miscount the failure as success. The orchestrator MUST instead read both fields in this explicit order, BEFORE parsing `.result`:

1. **Read the exit code.** Non-zero → halt the loop; report the exit code, stderr, and any partial `.result` in the final summary. Do NOT spawn the next iteration. The user returns to a stopped loop with a clear failure reason (e.g. "quota exhausted — resume when quota resets"). Exit-code check fires FIRST in the ordered sequence — non-zero exit takes precedence over the `is_error` branch below.
2. **Parse `is_error` from the JSON stdout BEFORE attempting to parse `ITERATION_SUMMARY`.** When `is_error: true`, route to the SALVAGE-vs-HALT decision contract below (the existing P261 carve-out, extended by P214 with the transient-API-error HALT advisory). The check MUST happen before the Exit-0 → `ITERATION_SUMMARY` parse path — the load-bearing P214 invariant is that `is_error: true` never silently falls through to the parse path.
3. **Exit 0 AND `is_error: false`** → parse `ITERATION_SUMMARY` from `.result` field; proceed to Step 6.

**`is_error: true` class taxonomy (P261 SALVAGE branch + P214 HALT branch).** Two sub-classes of `is_error: true` route differently inside the ordered check above. Deterministic SALVAGE-vs-HALT decision contract:

- **SALVAGE branch (P261 — stream-timeout class).** **IF** `is_error: true` AND staged files exist in the working tree (`git diff --cached --name-only` non-empty) AND any iter-authored bats fixtures pass → the orchestrator MAY apply the documented **4-step salvage path**: (1) run the iter's bats as a structural sanity check; (2) inspect the changeset + diffs for quality; (3) commit the staged work from the orchestrator main turn with explicit iter-attribution in the message (e.g. "iter hit API stream timeout before commit — committed staged work from orchestrator main turn"); (4) **the commit gate fires fresh** on the salvage commit, so architect / JTBD / risk-scorer validate the work cleanly on the orchestrator's own SESSION_ID (never reusing the dead subprocess's gate markers, per ADR-009 line 89). The salvage commit IS the iteration's one commit per ADR-014 (amend-folding is inapplicable — no iter commit exists to amend). Production shape: `API Error: Stream idle timeout - partial response received` in `.result` after staging coherent work but before `git commit` — staged files survive; JSON metadata preserved (unlike the P147 stuck-before-emit class).
- **HALT branch (P214 — transient-API-error class).** **ELSE IF** `is_error: true` AND nothing staged (`git diff --cached --name-only` empty) → halt the loop with a class-appropriate advisory line in the final summary. The transient-API-error class fires when the API call never landed; `total_cost_usd: 0`; no work was done. Map `.result` substrings to the advisory:
  - `529` / `Overloaded` → `"API overloaded; retry when service recovers"`
  - `429` / `rate limit` → `"API rate-limited; retry when limit window resets"`
  - `401` / `Authentication` / `auth expired` → `"API auth expired; refresh credentials before resuming"`
  - any other `is_error: true` shape → `"transient API error; inspect .result and resume manually"`

  Do NOT spawn the next iteration; the loop has no recoverable state to advance from. Retry policy for the transient classes (e.g. exponential backoff on 529 Overloaded, max-N attempts) is deferred to a Phase 2 amendment per P214's Investigation Tasks — Phase 1 is HALT-with-advisory only.
- **ELSE** (staged work incoherent / bats fail) → halt per the SALVAGE branch's fall-through contract.

The decision is deterministic and non-interactive — no `AskUserQuestion` (Rule 6, mirroring the P121 SIGTERM precedent at line 154 of ADR-032). **Distinct classes** within the `is_error: true` taxonomy: P261 SALVAGE (stream-timeout — staged work survives) vs P214 HALT (transient API error — nothing staged). **Distinct from** sibling subprocess-failure classes: P121 (SIGTERM idle-timeout — `is_error: false` clean exit-flush; subprocess HAD committed before going idle), P147 (SIGTERM stuck-before-emit — exit 143 + 0-byte JSON, metadata lost), and P146 (bash-polling antipattern — the deadlock mechanism behind P147). Here the iter exits on its own with `is_error: true`; no SIGTERM involved; metadata survives in the JSON envelope. Full contract: ADR-032 § "is_error:true stream-timeout salvage (P261 amendment)" + § P214 transient-API-error HALT extension. Behavioural fixtures: `test/work-problems-step-5-stream-timeout-salvage.bats` (SALVAGE branch — P261), `test/work-problems-step-5-is-error-transient-halt.bats` (HALT branch — P214).

**Quota as the natural stop.** The AFK loop runs until quota is exhausted or a stop-condition from Step 2 fires. There is no per-iteration dollar cap; running iterations until quota is actually exhausted maximises backlog progress per quota cycle. Quota-exhaust on a `claude -p` invocation surfaces as a non-zero exit and the orchestrator halts cleanly per the rule above.

**Hook session-id isolation.** Each `claude -p` subprocess has its own `$CLAUDE_SESSION_ID`. Gate markers at `/tmp/architect-reviewed-<ID>`, `/tmp/jtbd-reviewed-<ID>`, `/tmp/risk-scorer-*-<ID>` are scoped to the subprocess's own hook interactions and never shared with the orchestrator's main-turn SESSION_ID. This is the correct behaviour — the orchestrator's main turn runs its own gate flow if it edits gated paths; the subprocess's gate flow is independent. Implementations MUST NOT wire cross-process marker sharing.

**Inter-iteration continuity.** Step 6.5 (release-cadence check) and Step 6.75 (inter-iteration verification) stay in the **main orchestrator's turn**, NOT the iteration subprocess. Rationale: release-cadence and `git status --porcelain` are orchestration-level concerns; `push:watch`/`release:watch` are long-running waits that would waste iteration-subprocess context; the orchestrator needs to see the summary from one iteration before deciding whether to drain before the next. Orchestrator detects subprocess commits by reading the working tree (`git status --porcelain`) and the parsed `ITERATION_SUMMARY.commit_sha` — not session-state continuity with the subprocess.

The manage-problem skill (running inside the iteration subprocess) will:

- Run a review if the cache is stale.
- Select and work the highest-WSJF problem.
- Use its built-in non-interactive fallbacks (auto-split multi-concern problems, auto-commit when risk is within appetite).
- Delegate architect / JTBD / risk-scorer reviews via the Agent tool (available in the subprocess's surface) at the depth defined in each review skill's SKILL.md.
- Commit completed work per ADR-014 (the iteration subprocess's commit inside its own session — the orchestrator does NOT commit from its main turn, EXCEPT the one bounded `is_error: true` stream-timeout salvage carve-out per the Step 5 exit-code semantics above + ADR-032 P261 amendment, where the orchestrator main turn commits an iter's staged-but-uncommitted work after a fresh commit-gate validation).

### Step 6: Report progress

After each iteration, report:
- Which problem was worked (ID + title)
- What was done (investigated, transitioned to known-error, fix implemented, etc.)
- The outcome (success, partially progressed, skipped, scope expanded)
- How many problems remain in the backlog
- The iteration's cost metadata — format: `($<cost>, <duration_s>s, <total_tokens_K>K tokens)`. Cost comes from the `.total_cost_usd` field extracted in Step 5; duration from `.duration_ms`; total tokens is the sum of `.usage.input_tokens + .usage.output_tokens + .usage.cache_creation_input_tokens + .usage.cache_read_input_tokens`.
- Risk-register scaffold line when Step 6.4 drained ≥1 entry — format: `Risk register: <N> entries scaffolded (pending review)` per JTBD-006 outcome 4 (auditability of AI-assisted work). Omit the line when the drain was a no-op.

Format as a brief status line, not a wall of text. The user will read these when they return.

**Example:**
```
[Iteration 1] Worked P029 (Edit gate overhead for governance docs) — implemented fix, closed. 8 problems remain. ($0.32, 23s, 171K tokens)
[Iteration 2] Worked P021 (Governance skill structured prompts) — investigated root cause, transitioned to known-error. 7 problems remain. Risk register: 1 entry scaffolded (pending review). ($0.85, 47s, 432K tokens)
[Iteration 3] Skipped P016 (Multi-concern ticket splitting) — fix released, awaiting user verification. Worked P024 (Risk scorer WIP flag) — implemented fix, closed. 6 problems remain. ($1.12, 62s, 541K tokens)
```

### Step 6.4: Drain risk-register queue (per ADR-056 Phase 2b)

After the iteration's commit lands and before the release-cadence check, drain any `RISK_REGISTER_HINT` entries that the iteration's pipeline runs enqueued to `.afk-run-state/risk-register-queue.jsonl`. The hook (Phase 2a) writes the queue silently; this step (Phase 2b) materialises queued hints into `docs/risks/R<NNN>-<slug>.active.md` register entries. Per-iter cadence keeps the queue bounded and attaches the resulting `docs(risks): scaffold ...` commit to the iter that produced the hint (preserves ADR-014 single-ticket-unit-of-work grain).

**Mechanism — invoke the shared drain script:**

1. Run the shim: `wr-risk-scorer-drain-register-queue` (resolves to `packages/risk-scorer/scripts/drain-register-queue.sh` per ADR-049 naming grammar). The script:
   - Skips silently if `.afk-run-state/risk-register-queue.jsonl` is empty or absent (no-op exit 0).
   - Skips silently if `docs/risks/` has not been scaffolded (Phase 1 / install-updates Step 6.5 has not fired in this project yet — preserves the queue for the next drain).
   - Dedupes by `risk_slug`: N hints for the same slug → one register file with N Evidence Log entries (per the user direction "for each risk in `.risk-reports` there should be something in the register").
   - Mints new R<NNN> IDs via local-max + origin-max +1 (ADR-019 dual-source ID for ticket-creator surfaces).
   - Writes each new entry from a fixed shape with `Status: Active (auto-scaffolded — pending review)`, ADR-026 sentinel `not estimated — no prior data` for ungrounded scoring fields, and a `Curation: pending review` field for downstream review tooling.
   - Updates `docs/risks/README.md` Register table with one row per new risk (em-dash for stub scoring per ADR-056 §pending-review).
   - Stages all writes via `git add docs/risks` and truncates the queue file on success.

2. Parse stdout key=value output:
   - `entries_drained=N` — total queue lines processed.
   - `new_risks_created=N` — new register files written.
   - `evidence_appended=N` — slug-matched existing files updated.
   - `next_action=commit-staged|none` — when `commit-staged`, run a dedicated `docs(risks): scaffold` commit through the standard ADR-014 commit-gate flow.

3. **Commit (when `next_action=commit-staged`)**: stage is already done; commit message:
   ```
   docs(risks): scaffold R<NNN>... (<N> entries from queue)

   Drained .afk-run-state/risk-register-queue.jsonl per ADR-056 Phase 2b.
   <new_risks_created> new register entries; <evidence_appended> existing
   entries gained Evidence Log lines. All entries marked Active
   (auto-scaffolded — pending review) with ADR-026 sentinels for
   ungrounded scoring fields.
   ```
   The commit goes through architect / JTBD / risk-scorer review per ADR-014. Per ADR-013 Rule 5, the drain action itself is policy-authorised silent proceed — no `AskUserQuestion` round-trip needed; the shape is mechanical and ADR-056 supplies the authority.

4. Pass the `new_risks_created + evidence_appended` count into Step 6's progress report so the AFK summary surfaces register population per JTBD-006 outcome 4. When `entries_drained=0`, omit the register line entirely.

**Idempotency**: safe to invoke when queue is empty / missing. The script's no-op path is the steady state in projects without active above-appetite events.

**Failure handling**: if the drain script exits non-zero (template missing, write error, git failure), do NOT halt the loop — log the failure in the iter report and proceed to Step 6.5. The queue retains entries for next drain; Phase 3 backfill recovers any persistent loss.

### Step 6.5: Release-cadence check (per ADR-018, above-appetite branch per ADR-042)

After the iteration's commit lands but before starting the next iteration, check whether there is releasable material to drain. This prevents silent accumulation of unreleased changesets across AFK iterations (P041, P250) — accumulation costs audit fidelity and increases future drain risk with no governance benefit when residual stays within appetite. **The orchestrator MUST NOT release above appetite under any circumstance** — above-appetite states route to the ADR-042 auto-apply loop or halt.

**Mechanism — delegate, do not re-implement scoring:**

1. Invoke the risk scorer to score cumulative pipeline state. Two paths are valid (per ADR-015):
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool. The skill wraps the same pipeline subagent.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line and the `RISK_REMEDIATIONS:` block (if present).
3. **Classify the residual + queue state (P250)**:
   - **Above appetite (≥ 5/25)** — route to the **Above-appetite branch** below. Do NOT drain. Do NOT proceed to Step 6.75 until either (a) the auto-apply loop re-converges within appetite and drain succeeds, or (b) Rule 5 halt fires.
   - **Within appetite (≤ 4/25) AND there is releasable material** (any unpushed commits on `HEAD..origin/<base>` OR any entries in `.changeset/` OR any graduation-eligible entries in `docs/changesets-holding/` per ADR-061 Rule 1 that are not VP-blocked per Rule 2) — drain the queue per the Drain action below, then proceed to Step 6.75. The release-action threshold is "is there something to release?", NOT "has accumulated risk reached the safety band?" Per user direction 2026-05-17 (P250 Description): *"If it's low risk, you should release."* Low cost to release + low residual risk = release now; never accumulate.
   - **Within appetite (≤ 4/25) AND empty queue** (no unpushed commits AND no `.changeset/` entries AND no graduation-eligible held entries) — no drain (literally nothing to release). Proceed to Step 6.75. This is the genuine no-op fast-path; the gate is *absence of releasable material*, not residual band.

**Cohort-graduation pre-check (per ADR-061 Rule 5; P246):** when the within-appetite-with-releasable-material branch fires AND `docs/changesets-holding/` is non-empty, invoke the graduation evaluator BEFORE the Drain action. The evaluator is the deterministic Rule 1a join + Rule 2 VP carve-out + Rule 3b cohort-grouping pass shipped in `@windyroad/risk-scorer` Phase 2a/2b. **The graduation criterion is evidence-of-working-as-desired (Rule 4 per-class evidence floor), not elapsed wall-clock time** — per user direction 2026-05-17: *"Dogfooding makes sense, but it shouldn't be time based, it should be until we are happy that it's working as desired."* + *"Why are we waiting? That seems to go against the principles if you ask me."* Calendar predicates are NEVER a primary graduation trigger; the evaluator's `status=resolved` IS the graduation signal.

1. Run the shim: `wr-risk-scorer-evaluate-graduation` (resolves to `packages/risk-scorer/scripts/evaluate-graduation.sh` per ADR-049 naming grammar). The script enumerates `docs/changesets-holding/*.md` (excluding README), applies ADR-061 Rule 1a join + Rule 2 VP carve-out + Rule 3b cohort grouping, and emits one `GRADUATION_CANDIDATE:` line per held entry plus a final `GRADUATION_SUMMARY:` line.

   **Evaluator scope (load-bearing per P308)**: the evaluator script implements ONLY the deterministic Rule 1a + Rule 2 + Rule 3b passes. It does NOT compute release-risk and does NOT apply Rule 4 evidence-floor judgement — those are LLM-judgement surfaces owned by the orchestrator + the `wr-risk-scorer:pipeline` agent. Therefore evaluator `status=resolved` means *"the ticket-join succeeded and the entry is not VP-blocked"* only — it is **necessary but not sufficient** for graduation. The Rule 4 evidence-floor judgement (per-class evidence per ADR-061 Rule 4) MUST run as a separate orchestrator-side step before any `git mv` (P308 amendment).
2. Parse each `GRADUATION_CANDIDATE: changeset=<basename> | ticket=<P-id> | priority=<N> | class=<3a|3b> | [cohort=<id> |] status=<resolved|vp-blocked|halt-no-resolution>` line. Branch on `status`:
   - **`status=resolved`** — route to **Rule 4 evidence-floor judgement** (P308 amendment; see step 2a below). The evaluator's `status=resolved` is necessary-but-not-sufficient; Rule 4 judgement is the LLM-owned surface that ratifies the *evidence floor* per ADR-061 Rule 4 + ADR-044 framework-resolution boundary. Do NOT auto-graduate at this point. Per ADR-061 Rule 5: the graduation criterion authorises the *intent*; Rule 4 judgement is the precondition that admits *evaluation* of that criterion.
   - **`status=vp-blocked`** — skip. Per ADR-061 Rule 2 (Verification Pending carve-out; symmetric to ADR-042 Rule 2b). Do NOT graduate; held entry stays. The `.verifying.md` → `.closed.md` transition auto-clears the carve-out at a later Step 6.5 graduation pass.
   - **`status=halt-no-resolution`** — halt. Per ADR-061 Rule 1a terminal: when neither filename-convention join nor body-grep fallback resolves a ticket, OR the resolved ticket file is missing/unreadable, the orchestrator MUST NOT auto-graduate. Route to the **Step 6.5 cohort-graduation halt-no-resolution** halt point (framework-prescribed halt — see Mid-loop ask discipline subsection); halt-with-batched-questions per the Step 2.5b cross-reference.

2a. **Rule 4 evidence-floor judgement (P308 — LLM-owned, NOT framework-resolved)**. For each `status=resolved` candidate, the orchestrator MUST evaluate whether the class-specific evidence floor has been met before graduating. The evidence floor (ADR-061 Rule 4) is per-class: PreToolUse:Bash gates need ≥1 gate-fire trace; UserPromptSubmit detectors need ≥1 detector firing; commit-hook-with-auto-fix needs ≥1 correctness-verified auto-fix commit; SessionStart additionalContext needs ≥1 session-trail entry. The orchestrator reads the held entry's `Reinstate criterion (evidence-based, ...)` line from `docs/changesets-holding/README.md` Currently held entry + cross-references the on-disk evidence artefact named in the criterion. Per ADR-044, Rule 4 judgement is LLM-owned (not framework-resolved). Route per AskUserQuestion availability:

    - **Interactive (`AskUserQuestion` available)**: fire `AskUserQuestion` **per held entry** (NOT batched across cohort — each entry's evidence is independent, except for class=3b cohorts which graduate atomically per Rule 3b — when any cohort member's `AskUserQuestion` returns Graduate, ALL same-cohort members graduate together; when any returns Defer/Reject, the entire cohort stays held). Question text MUST inline (P350 brief-before-ID discipline): the held entry's basename + ticket + Priority, the per-entry evidence summary (from the README's Currently held entry — Rule 4 class-specific shape + cited artefact), and the candidate verdict. Options: **Graduate (evidence cited and met)** / **Defer (evidence not yet met — preserve hold)** / **Reject (manual intervention — surface back to user)**. Per ADR-013 Rule 1 cap (≤4 per call, sequential if >4). On `Graduate`, fall through to step 2b graduate-action. On `Defer`/`Reject`, the held entry stays in `docs/changesets-holding/`; emit one Auto-apply-trail line per ADR-061 Rule 6 citing the user's verdict + reason; proceed to next candidate. This per-entry AskUserQuestion is a framework-prescribed user-interaction surface — see Mid-loop ask discipline subsection.
    - **AFK (`AskUserQuestion` forbidden — iter subprocess / non-interactive context per P352 / ADR-013 Rule 6)**: queue one `outstanding_question` entry (category: `direction`) per held entry to `.afk-run-state/outstanding-questions.jsonl`. The entry's `question` field inlines the same evidence summary the interactive `AskUserQuestion` would surface (P350 brief-before-ID — do NOT use opaque IDs alone). Do NOT graduate. Continue Drain action: any pre-existing `.changeset/` entries still drain per the within-appetite contract (those entries were not graduations and are unaffected). Per P352 user-ratified universal AFK default: queue-and-continue (NOT halt, NOT silent skip, NOT auto-default). Loop-end Step 2.5 surfaces the queued questions as batched `AskUserQuestion` per the existing accumulated-question discipline.

2b. **Graduate-action (Rule 4-ratified path)**. When Rule 4 evidence-floor judgement returns `Graduate` (interactive `AskUserQuestion` Graduate verdict) for a held entry: perform `git mv docs/changesets-holding/<basename> .changeset/<basename>`. Append the entry to `docs/changesets-holding/README.md` "Recently reinstated" with the citation: `<basename> — graduation criterion met (status=resolved per Rule 1a join to <P-id>, Priority <N>; Rule 4 evidence-floor ratified per user verdict <verbatim>); class <3a|3b>; evidence cited`. For class=3b cohorts: when any cohort member's Rule 4 judgement returns `Graduate`, ALL same-cohort members with `status=resolved` graduate together atomically (Rule 3b cohort propagation — entire cohort ships or none does); when any returns Defer/Reject, the entire cohort stays held. Amend the iter's main commit per ADR-042 Rule 3 amend-based folding to preserve the ADR-032 one-commit-per-iteration invariant.

3. After processing all candidates: if anything graduated, the just-moved entries are now in `.changeset/` and ride the existing Drain action (no separate re-entry needed — the Drain action's `release:watch` step picks them up when `.changeset/` is non-empty). Proceed to the Drain action below.
4. **Governance gates apply (ADR-061 Rule 7)**: every graduation reinstate goes through the standard ADR-014 commit flow — architect / JTBD / risk-scorer gates ride the amend commit; gate rejection routes to ADR-042 Rule 5 halt with the rejection reason logged. The graduation criterion authorises the *intent*; the gates authorise the *action*.

**Idempotency**: safe to invoke when holding-area is empty (script exits 1 with `GRADUATION_SUMMARY: total=0` — orchestrator skips graduation, proceeds to Drain action). Safe when no candidates resolve (all `vp-blocked`) — no `git mv` operations, no README mutation, no commit amendment. Safe when AFK + all `status=resolved` route to queue (no graduation performed; outstanding_questions accumulate for loop-end surfacing per P352 / ADR-013 Rule 6).

**Audit trail (ADR-061 Rule 6)**: every `reinstate-from-holding` graduation appends one Auto-apply-trail line to the iter report AND one "Recently reinstated" line to `docs/changesets-holding/README.md` with the resolved problem-ticket ID, Priority value, graduation class (3a or 3b), and the evidence citation. The audit trail is the load-bearing artefact for ADR-026 cite + persist + uncertainty grounding.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` is non-empty after push, run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Resume the loop only after the release lands on npm.
4. **Post-release K→V auto-transition (P228)**: if step 2 actually ran AND succeeded (a release shipped to npm), fire the K→V auto-transition callback for `.known-error.md` tickets whose Release-vehicle citation matches a just-shipped changeset. See the **Post-release K→V auto-transition** subsection below for the full contract.
5. **Post-release cache refresh (P233)**: if step 2 actually ran AND succeeded (a release shipped to npm), chain `/install-updates` to refresh the plugin cache before the next iter dispatches. Skipped when step 2 was a no-op (empty `.changeset/` after push; no new plugin version exists). See the **Post-release cache refresh** subsection below for the full contract.

**Post-release K→V auto-transition (P228) — fires only after within-appetite Drain action step 2 (release:watch) succeeded:**

ADR-022 prescribes that Known Error tickets transition to Verification Pending on release, but until P228 there was no auto-fire surface to back-fill the transition once a fix ships. Iter subprocesses MUST NOT release (the orchestrator owns Step 6.5 per the iter dispatch constraints), so a fix that lands in iter N stays in `.known-error.md` until the orchestrator drains release in Step 6.5 — and prior to this callback, the K→V transition was silently deferred to "the next session" citing a misapplied P143 amendment. The 2026-06-08 P220 empirical witness — `## Fix Released` populated with no K→V transition — confirmed the gap.

**Mechanism:**

1. Invoke `wr-itil-enumerate-postrelease-kv-candidates` (ADR-049 PATH shim resolving to `packages/itil/scripts/run-enumerate-postrelease-kv-candidates.sh` / `packages/itil/lib/enumerate-postrelease-kv-candidates.sh`). The helper walks `docs/problems/known-error/*.md`, invokes `wr-itil-derive-release-vehicle <NNN>` per ticket, and emits one `KV_CANDIDATE: P<NNN> | <changeset>` line per ticket whose changeset has been shipped (derive exit 0). Tickets with no `**Release vehicle**: .changeset/<name>.md` reference (derive exit 2 — legacy pre-P330) and tickets whose changeset is still in the working tree (derive exit 3 — unreleased) are skipped silently. Final line: `KV_CANDIDATES_SUMMARY: total=<N>`.
2. Parse `KV_CANDIDATE:` lines from stdout.
3. For each candidate `P<NNN>`, dispatch `/wr-itil:transition-problem <NNN> verifying` via the Skill tool. The dispatched transition-problem skill is the authoritative executor for K→V per ADR-010 amended "Split-skill execution ownership" (P093) — orchestrator dispatch is the documented forwarder pattern, NOT a round-trip. The dispatched skill rides its OWN ADR-014 commit through architect / JTBD / risk-scorer gates per its existing Step 8 contract (rename + Status edit + `## Fix Released` write + README refresh + commit). The orchestrator does NOT re-implement the transition mechanics; it dispatches and reads the outcome.
4. After all candidates dispatched: emit one per-ticket transition outcome line to the iter summary in the form `K→V: P<NNN> | commit=<sha> | release=<vehicle>` (read from the dispatched transition-problem's `RELEASE_VEHICLE` block or Report-the-outcome stdout per Step 9 of transition-problem).
5. Push the resulting K→V commits via `git push` (the release itself has already shipped — these are post-release audit-trail commits and do NOT require a second release:watch round-trip).

**Conditional on actual release**: only fires when `release:watch` actually published (step 2 of the Drain action above ran AND returned success). Skipped when `push:watch` ran alone (empty `.changeset/`; no new plugin version). Without this guard, the enumerator would scan `.known-error/` on every iter with no shipped changeset to match — wasted reads.

**Non-blocking on individual transition failure**: if a dispatched `/wr-itil:transition-problem` fails (pre-flight reject, gate rejection, P057 staging trap, derive helper transient error), the orchestrator logs the failure for that ticket and continues to the next candidate. A single transition failure MUST NOT halt the loop or block siblings in the same cohort. Persistent failures across multiple iters surface as accumulated `outstanding_questions` entries per the standard Step 2.5b discipline.

**Policy authorisation (ADR-013 Rule 5)**: rides the same Rule 5 silent-proceed that already covers `push:watch` / `release:watch` / `/install-updates` in the drain — the K→V auto-transition is mechanically downstream of release and shares its authorisation. The derive-helper-citation match against the just-shipped changeset is deterministic (filename equality), not a judgment call — squarely in the safe-default tier per JTBD-006 "Decisions that would normally require my input are resolved using safe defaults".

**Mid-loop ask discipline (P130) preserved**: the dispatched transition-problem skill is wired to skip `AskUserQuestion` when invoked under AFK orchestrator context per its own ADR-013 Rule 6 fail-safe (transition-problem SKILL.md Step 8 risk-above-appetite branch). The orchestrator MUST NOT introduce any `AskUserQuestion` call at the callback site — the per-candidate routing is framework-resolved per ADR-044, and the callback fires in a mechanical-stage transition between drain step 2 and step 5 (cache refresh).

**V→C remains the maintainer's surface (persona constraint per JTBD-006)**: this callback fires ONLY for K→V (`known-error → verifying` — "fix released, awaiting verification"). It explicitly does NOT auto-fire V→C — the maintainer's judgment-reserved "fix actually works" closure remains untouched and continues to require their return per the existing transition-problem Step 4 `Verification Pending → Closed` precondition ("the user has explicitly confirmed the fix works in production").

**Composition with the Above-appetite branch (below)**: the K→V callback is anchored to the within-appetite Drain action step 4 — it does NOT fire after the above-appetite Rule 5 halt (no release shipped → nothing to match) and it does NOT fire mid-loop in the above-appetite auto-apply loop. When the auto-apply loop converges and re-enters the within-appetite Drain action, the K→V callback fires there per step 4.

**Composition with Cohort-graduation pre-check (P246)**: the cohort-graduation pre-check (step 2a above) fires BEFORE the Drain action; its `git mv` operations from `docs/changesets-holding/` to `.changeset/` happen BEFORE release:watch and ship as part of the same release. The K→V callback fires AFTER release:watch and consumes the just-shipped changeset set — so graduated cohorts that ship in the same release are correctly matched by the enumerator (the deleted-from-tree changeset has the graduated basename; the K-ticket's `**Release vehicle**: .changeset/<basename>.md` reference matches).

Per ADR-022 (Verifying lifecycle) + ADR-018 (release-cadence host) + ADR-010 amended P093 (transition-problem authoritative executor) + ADR-014 (per-transition commit grain) + ADR-013 Rule 5 (policy-authorised silent-proceed) + ADR-044 (framework-resolution boundary) + P228 (this ticket) + P233 (sibling callback) + P267 (derive-release-vehicle composed helper) + P330 (Release vehicle seed reference — input signal).

**Post-release cache refresh (P233) — fires only after within-appetite Drain action step 5 (above):**

After a successful release-cadence drain has shipped a new plugin version to npm, the orchestrator chains `/install-updates` to refresh the plugin cache before the next iter dispatches. Empirical evidence in `docs/briefing/afk-subprocess.md` ("Just-shipped gate-class hooks DON'T protect the immediate-next iter" entry) confirms iter subprocesses re-resolve plugin cache on spawn — so a just-shipped gate-class hook is inactive in the next iter unless the cache is refreshed first. The orchestrator IS the "restart" boundary for the next iter subprocess (each subprocess is a fresh `claude -p` per ADR-032 + `afk-subprocess-mechanics.md`); the cache refresh between release:watch and next-iter dispatch is the load-bearing step.

- **Conditional on actual release**: only fires when `release:watch` actually published (step 2 of the Drain action above ran AND returned success). Skipped when `push:watch` ran alone (empty `.changeset/`; no new plugin version). Without this guard, every iter burns wall-clock + npm-API noise on a no-op cache refresh.
- **Non-blocking on /install-updates failure**: if `/install-updates` fails (transient marketplace fetch error, P106-class quirk re-emergence, cache-miss + Non-interactive fallback dry-run), the orchestrator logs the failure and continues the loop. Degrades to current behaviour — cache stays stale; next iter may recur the just-shipped issue, equivalent to pre-amendment behaviour. The cache-refresh chain MUST NOT halt the loop on `/install-updates` failure under any circumstance.
- **Policy authorisation (ADR-013 Rule 5)**: rides the same Rule 5 silent-proceed that already covers `push:watch` / `release:watch` in the drain — the post-release cache refresh is mechanically downstream of release and shares its authorisation. Composes with P106's claude-plugin-install no-op-when-already-installed factor (the chained `/install-updates` handles the uninstall+install dance per P106).
- **Mid-loop ask discipline (P130) preserved**: if `/install-updates` Step 5b/5c consent gate fires (cache miss / scope delta / `INSTALL_UPDATES_RECONFIRM=1`), the orchestrator main turn treats this AS the **Non-interactive fallback** documented in `scripts/repo-local-skills/install-updates/SKILL.md` "Non-interactive fallback" subsection — log the dry-run output, do not interrupt the loop. The orchestrator's `.claude/.install-updates-consent` is normally present (install-updates Step 5a cache hit) so the gate fires silently. **ADR-044 framework-resolution boundary** authorises this AskUserQuestion-available-but-forbidden routing: invocation between iters is a mechanical-stage transition the framework has resolved; surfacing it to the user would dilute the Step 2.5b accumulated-question discipline.

**Composition with the Above-appetite branch (below)**: the cache refresh is anchored to the within-appetite Drain action step 5 — it does NOT fire after the above-appetite Rule 5 halt (no release shipped → nothing to refresh) and it does NOT fire mid-loop in the above-appetite auto-apply loop. When the auto-apply loop converges and re-enters the within-appetite Drain action, the cache refresh fires there per step 5. The chain's site is the Drain action only.

**Failure handling (P140)**: When `push:watch` or `release:watch` reports a CI failure or publish failure, the orchestrator follows a diagnose-then-classify routing — fix-and-continue for the documented mechanically-fixable allow-list, halt for everything else. The previous uniform halt rule converted mechanically-fixable failures (1-line stale-grep-string updates, transient flakes) into ~45min queue stalls, regressing JTBD-006 "Progress the Backlog While I'm Away" without any governance benefit.

**Diagnostic preamble (ADR-026 grounding)**: orchestrator MUST first fetch the failed CI log via `gh run view <run-id> --log-failed` (or `gh run view --log-failed` against the most recent failure). Read the failure output and classify into ONE of the buckets below. Cite the failed test output verbatim in the fix-and-continue commit message or halt summary so future readers can audit the classification.

**Fixable-in-iter allow-list (closed)**: the following classes are policy-authorised silent fix-and-continue per ADR-013 Rule 5. The list is **closed** — adding a new class is itself a deviation-candidate per ADR-044's framework-resolution boundary (surface to user via Step 2.5b's AskUserQuestion-default branch; do NOT auto-extend at agent discretion).

- **P081-class stale-grep-string** — structural test runs `grep -F '<literal>'` (or `grep -nE '<pattern>'`) against a SKILL.md / ADR / source file; non-zero return because source was edited and the test's grep string was not. Fix: update the grep string to current source phrasing. Composes with P081 (structural-tests-are-wasteful root cause); fix-and-continue is the stop-gap, P081's full retrofit is the structural elimination.
- **Hook stub mismatch** — test's mock-stdin field doesn't match current hook expectation (e.g. renamed JSON key, renamed event type). Fix: update the stub.
- **Test ID drift** — assertion message grep doesn't match a recently-renamed function or symbol. Fix: sed in the test.
- **Environmental flake** — CI runner intermittent issue (npm registry timeout, GitHub API rate limit, transient infra). Fix: re-trigger the workflow.

**Ambiguous classification defaults to halt.** If the failure does not unambiguously match one of the above, the orchestrator halts. No diagnose-then-guess.

**Fix-and-continue branch**: for a fixable class:

1. Apply the fix (typically a single `Edit` change).
2. Commit the fix through the **standard ADR-014 commit gate flow** — architect / JTBD / risk-scorer review per retry. A gate rejection routes to the halt branch (no retry budget restoration). Each fix-and-continue commit is its own discrete unit of work and rides its own commit through gates per ADR-014 + ADR-042 Rule 3 precedent (retries each ride their own commit).
3. `git push` and re-run `npm run push:watch` (or `release:watch` if the failure was on the release-PR side) to wait for CI re-trigger.
4. If CI passes, resume the loop (Step 6.75).
5. If CI fails again, increment the per-iteration retry counter and return to step 1.

**3-retry cap (per iteration, not per failure-class)**: after 3 fix-and-continue attempts in a single Step 6.5 invocation, the orchestrator routes to the halt branch regardless of failure class. Repeated failures of the "same" class are evidence the diagnosis was wrong; halt and surface for user judgment. The cap is per-iteration — a 4th distinct fixable failure in the same drain still halts.

**Halt branch (genuinely unrecoverable)**: halt the loop and report the failure in the AFK summary. Do not retry non-interactively. Genuinely-unrecoverable classes include: auth failure (npm token, GitHub credentials), npm publish rejection (version conflict, package access denied), semantic test failure requiring user judgment (not literal-string drift), repeated transient failures (3+ retries, per the cap above), and any failure outside the fixable-in-iter allow-list.

**Step 2.5b cross-reference (P126)**: before emitting the final AFK summary for a Failure handling / CI failure / release:watch halt, run Step 2.5b's surfacing routine. The routine is gated on ≥1 accumulated user-answerable skip; this halt path empirically frequently has accumulated skips from prior iters (the original P126 surface), so the gate is normally satisfied and Step 2.5b's AskUserQuestion-default branch fires (`halt-paths-must-route-design-questions-through-Step-2.5b`). The CI-failure cause itself remains a halt with bug-signal — Step 2.5b surfaces *prior-iter accumulated user-answerable skips only*; it does NOT ask the user how to remediate the CI failure (that requires the user to inspect the failing CI run on return).

`push:watch` and `release:watch` are policy-authorised actions when residual risk is within appetite per RISK-POLICY.md, so no `AskUserQuestion` is required for the drain itself (ADR-013 Rule 5). The fix-and-continue branch is itself policy-authorised by the closed allow-list above, satisfying ADR-013 Rule 5 without an `AskUserQuestion` round-trip.

**Composition notes**: fix-and-continue is the inverse of P132 (over-ask in interactive sessions) on the failure-handling surface — both arise from over-defensive uniform routing where a documented class-policy would empower silent action. Composes with P130 (orchestrator main-turn ask discipline — fix-and-continue does NOT introduce mid-iter asks; the closed allow-list resolves the decision per ADR-044). Cross-references: P081 (stop-gap composition — most fixables are P081-class), P135 (decision-delegation contract — the closed allow-list IS the framework-resolved policy).

#### Above-appetite branch (per ADR-042)

**Invariant**: the orchestrator MUST NOT release above appetite. There is no code path in Step 6.5 that releases at residual push/release ≥ 5/25. The orchestrator MUST NOT call `AskUserQuestion` as a shortcut out of the auto-apply loop — the scorer is the decision surface, not the user. The branch terminates in either a within-appetite drain or a Rule 5 halt.

**Auto-apply loop (ADR-042 Rule 2):**

1. Parse the scorer's `RISK_REMEDIATIONS:` block. Expected shape per ADR-015 / ADR-042 Rule 2a (5 columns):
   ```
   RISK_REMEDIATIONS:
   - R1 | <description> | <effort S/M/L> | <risk_delta -N> | <files affected>
   - R2 | ...
   ```
2. Read the descriptions. Decide what to do. The agent MAY follow a scorer suggestion, adapt it, or do something else entirely. There is no requirement to rank all suggestions upfront or iterate through them in order.
3. **Verification Pending carve-out (ADR-042 Rule 2b)**: if a remediation targets a commit attached to a `.verifying.md` ticket, do NOT auto-revert it. Skip that suggestion and decide on the next one.
4. Apply the chosen action using standard primitives (git, Edit, Bash). Example actions the agent might take:
   - `move-to-holding`: `git mv .changeset/<name>.md docs/changesets-holding/<name>.md`. Append the entry to `docs/changesets-holding/README.md` under "Currently held" per ADR-042 Rule 6. Amend the iteration's commit to fold the move (per ADR-042 Rule 3 amend-based folding — preserves ADR-032 one-commit-per-iteration invariant).
   - `revert-commit`: `git revert --no-edit <sha>`. The scorer SHOULD supply the target commit SHA in the `description` column (e.g., "Revert commit 9a1f96c that introduced the risky gate"). Before executing, verify the SHA is NOT attached to a `.verifying.md` ticket (Rule 2b carve-out). After revert, amend the iteration's commit to fold the revert. If `git revert` produces merge conflicts, route to Rule 5 halt with the conflict detail — do not attempt non-interactive conflict resolution.
5. Re-invoke the risk scorer (same delegation path as step 1 above — subagent preferred, skill fallback). Read the new `RISK_SCORES:` line.
6. **Loop classification**:
   - **Re-score within appetite (≤ 4/25)** — proceed to Drain action above. Done with the above-appetite branch.
   - **Re-score still above appetite (≥ 5/25)** — continue working to reduce risk. The agent reads the new remediations and decides what to do next. Loop.
   - **No remediations remain** or **the agent has exhausted its own ideas** — Rule 5 halt.

**Governance gates per auto-apply (ADR-042 Rule 3):** each auto-apply that requires a commit (the amend in step 4 above) goes through the standard ADR-014 commit flow — architect review, JTBD review, risk-scorer gate. A gate rejection falls through to Rule 5 halt. The scorer's suggestions do NOT bypass gates.

**Rule 5 halt (exhaustion):** when the auto-apply loop exhausts without convergence, or any gate/operation fails, halt the loop. Do NOT proceed to Step 6.75. Do NOT spawn the next iteration. Emit the iteration summary with:

- `outcome: halted-above-appetite`
- The final `RISK_SCORES:` line
- An "Auto-apply trail" subsection listing each remediation attempted with outcome
- Any Verification Pending ticket IDs implicated per Rule 2b
- A one-line scorer-gap note (e.g., "scorer produced only `move-to-holding` remediations; residual still ≥ 5/25 after exhaustion — extend scorer vocabulary per P108")

**Step 2.5b cross-reference (P126)**: before emitting the Rule 5 halt iteration summary, run Step 2.5b's surfacing routine. The routine is gated on ≥1 accumulated user-answerable skip; Rule 5 halts that fire late in a long AFK loop frequently have accumulated skips from prior iters, so Step 2.5b's AskUserQuestion-default branch typically fires (`halt-paths-must-route-design-questions-through-Step-2.5b`). **Critical guard (architect FLAG)**: Step 2.5b surfaces *prior-iter accumulated user-answerable skips only* — it does NOT ask the user how to remediate the above-appetite state itself; the halt-causing scorer-gap remains a halt-with-bug-signal per ADR-042 Rule 5 invariant ("never release above appetite", scorer is the decision surface, not the user). Surfacing prior-iter skips does not retry the above-appetite remediation, does not bypass the never-release-above-appetite invariant, and does not convert the halt into a non-halt — it just takes the existing prior-iter user-input round-trip with it.

Halt is a **bug signal** — the scorer should always have progressively more aggressive remediations available once P108 lands. Until then, exhaustion is expected when the only path to within-appetite requires a non-`move-to-holding` class.

**Audit trail (ADR-042 Rule 6):** append one line per auto-apply to the iteration summary's Auto-apply trail subsection, including remediation ID, action class, pre/post scores, action taken, and description citation. For `move-to-holding` actions, also append to `docs/changesets-holding/README.md` "Currently held".

### Step 6.75: Inter-iteration verification (P036)

Before spawning the next iteration's subagent, verify the working tree state against the expected outcome of the iteration that just completed. This is defence-in-depth: P035 closed the most-likely commit-gate failure path, but a subagent could still fail to commit for reasons the fallback does not cover (a failure inside `/wr-risk-scorer:assess-release`, a git conflict, a malformed commit message). Without this check, silent failures accumulate across iterations and the final summary reports commits that did not land.

**Mechanism:**

1. Run `git status --porcelain`.
2. Classify the output into one of three cases:

| Status | Expected when | Action |
|---|---|---|
| Clean (empty output) | The subagent committed successfully (the default happy path) | Proceed to Step 7 |
| Dirty for a known reason | A deliberate hand-off to the next iteration (e.g. the subagent chose to skip the commit and report "uncommitted state" because risk was above appetite — per the Non-Interactive Decision Making table above). Reason MUST be stated in the iteration report. | Include the dirty state in the next iteration's subagent context and proceed to Step 7 |
| Dirty for an unknown reason | Neither of the above — the subagent reported success but the tree is not clean, or the tree is dirty without a documented reason in the iteration report. **P212 case (no longer a hand-off)**: dirty `docs/BRIEFING.md` / `docs/briefing/*.md` at iter exit is a bug class — Step 5 retro-on-exit clause #4 now requires the iter to commit retro's BRIEFING edits as `chore(briefing): refresh from iter retro (P<NNN>)` before emitting `ITERATION_SUMMARY`. A dirty BRIEFING-at-iter-exit means the iter's retro-on-exit clause did not run to completion (retro hook failure, scoring failure, commit-gate rejection) and the orchestrator must NOT silently absorb it via a main-turn hand-off commit. | **Halt the loop.** Report the `git status --porcelain` output, the last subagent's reported outcome, and the divergence. Do NOT spawn the next iteration. |

**Rationale**: the orchestrator previously treated the subagent's reported outcome as truth. Any lie, partial write, or silent failure in the subagent propagated into the summary. The `git status --porcelain` check is the cheapest possible independent verification — policy-authorised, no network, no judgement required — and it catches exactly the class of failure the subagent cannot self-report.

**Step 2.5b cross-reference (P126)**: before emitting the final AFK summary for a Step 6.75 dirty-for-unknown-reason halt, run Step 2.5b's surfacing routine. The routine is gated on ≥1 accumulated user-answerable skip; Step 6.75 halts fire between iters and frequently have accumulated skips from prior iters, so Step 2.5b's AskUserQuestion-default branch typically fires (`halt-paths-must-route-design-questions-through-Step-2.5b`). The dirty-for-unknown-reason halt itself remains a halt with bug-signal — Step 2.5b surfaces *prior-iter accumulated user-answerable skips only*; it does NOT ask the user how to recover the dirty state (that remains a Rule 6 user-input requirement on return).

**Out of scope for this step**: attempting recovery from an unknown-reason dirty state. Per ADR-013 Rule 6, conflict resolution and ambiguous state require user input; non-interactive recovery would mask the bug this check is meant to surface.

**Verify-iter-claims sub-step (P335).** The clean/dirty-known/dirty-unknown classification catches the *commit-didn't-land* failure class but not the *commit-landed-with-false-claim* class — both the commit message and the `ITERATION_SUMMARY.notes` field are written by the same iter subprocess from the same model state, so they can agree with each other while disagreeing with the on-disk artefacts the claim names (the P335 session 8 iter 1 witness: commit message stated "all (a)–(j) Confirmation items green at source" + notes restated it + the cited ADR's 10 boxes were all `[ ]`). When the classification above returns Clean AND the iter reported `committed: true`, run the verify-iter-claims check:

1. Dump the iter's `ITERATION_SUMMARY.notes` field to a temp file (`/tmp/iter-notes-$$.txt`).
2. Invoke `wr-itil-verify-iter-summary <commit_sha> <notes_file>` (the PATH shim per ADR-049; never invoke the repo-relative `packages/itil/scripts/verify-iter-summary.sh` path from SKILL prose — adopter installs resolve the shim, not the source-monorepo path).
3. Read the exit code:
   - **Exit 0** → no over-claim detected (no ADR referenced, OR no completion-claim signal, OR signal-and-all-Confirmation-items-checked). Proceed to Step 7.
   - **Exit 1** → OVER-CLAIM detected (at least one cited ADR has unchecked `- [ ]` Confirmation items while the iter's commit message or notes contains completion-claim language like "all green at source", "all Confirmation items complete", "(a)-(j) green"). **Halt the loop** with `outcome: halted-iter-over-claim`. Include the verifier's stdout (the `OVER-CLAIM: ADR-NNN has N unchecked Confirmation item(s)...` lines) as the divergence detail in the halt summary. Route through Step 2.5b's surfacing routine before emitting the halt summary (`halt-paths-must-route-design-questions-through-Step-2.5b`); the over-claim halt itself remains a halt-with-bug-signal — the iter's self-contradicting output IS the bug, and the user must adjudicate on return (re-dispatch the work / accept partial state / amend the commit).
   - **Exit 2** → verifier invocation error (missing args, unreadable notes file, bad sha). Halt the loop with `outcome: halted-iter-verifier-error` and the verifier's stderr. This shape is itself an orchestrator-side bug; surfacing it loudly is preferable to silently proceeding.

**Detection class boundary.** Verify-iter-claims is the *emit-but-over-claim* class detector — distinct from the *stuck-before-emit* class (P147, exit 143 + 0-byte JSON) which is already covered by the Step 5 idle-timeout SIGTERM handling + this step's existing dirty/clean check (working tree dirty after a missing-summary iter halts the loop). The verifier is intentionally narrow (ADR `## Confirmation` checkboxes) — it catches the load-bearing recurring shape where an iter ships an invariant gate (CI drift, README pairing) in the same commit as the work the gate is meant to test. Other over-claim shapes (claimed commits with no diff hunks; claimed file edits not in `git show --stat`) can be added incrementally as further witnesses surface; option (d) iter-local drift-bats (running the verifier inside the iter subprocess before `ITERATION_SUMMARY` emission) is deferred pending evidence that orchestrator-side (a) is insufficient — evidence-based, not BUFD (same shape as P246/P247).

**Auto-correction is out of scope.** The orchestrator cannot retroactively make a false claim true; halt-with-bug-signal is the correct stance per ADR-013 Rule 6.

### Step 7: Loop

Go back to step 1. The backlog may have changed — new problems may have been created during fixes, priorities may have shifted, and the README.md cache will be stale.

Natural-language modifiers in the invocation args (`just`, `only`, `first`, `merely`, `simply` paired with a ticket reference — e.g. `/wr-itil:work-problems just work P170`) are **SCOPE FILTERS** that override Step 1's WSJF selection; they do NOT alter Step 7's loop-back semantics. See **Mid-loop ask discipline → Scope-pin-word semantics (P175)** below for the load-bearing prose.

## Non-Interactive Decision Making

When `AskUserQuestion` is unavailable or the user is AFK, the skill (and the delegated manage-problem skill) should resolve decisions automatically:

| Decision Point | Non-Interactive Default |
|---|---|
| How each iteration runs (iteration delegation) | Dispatch to a fresh `claude -p --permission-mode bypassPermissions --output-format json` subprocess via Bash per Step 5 — NOT Agent-tool dispatch (the Agent-tool-spawned subagent has no Agent in its own surface, so governance gates cannot be satisfied — P084), and NOT inline Skill-tool invocation (expands manage-problem into the orchestrator's context and burns turns — P077). The subprocess is a full main Claude Code session with Agent available, so architect / JTBD / risk-scorer reviews run at full depth; the orchestrator consumes the `ITERATION_SUMMARY` return-shape from the subprocess's JSON stdout. No per-iteration budget cap — natural stop is quota exhaustion. This is the AFK iteration-isolation wrapper — subprocess-boundary variant under ADR-032. Per P084 + P077 + ADR-032. |
| Retro at iteration end (per-iteration lessons captured) | Iteration subprocess invokes `/wr-retrospective:run-retro` before emitting `ITERATION_SUMMARY` so Step 2b pipeline-instability scan runs inside the subprocess's tool-call history. Retro commits its own work per ADR-014; orchestrator picks up retro-created tickets on next Step 1 scan. Non-blocking: if retro fails or surfaces findings, iteration still emits summary — do not halt the AFK loop on a flaky retro. Per P086 + ADR-032 subprocess-boundary retro-on-exit clause. |
| Which problem to work | Highest WSJF, no prompt needed |
| Multi-concern split | Auto-split (manage-problem step 4b fallback) |
| Scope expansion during work | Update problem file, re-score WSJF, move to next problem instead of continuing |
| Commit when risk within appetite | Auto-commit (manage-problem step 9e fallback) |
| Commit when risk above appetite | Skip commit, report uncommitted state |
| Pipeline risk within appetite (≤ 4/25) with releasable material (any unpushed commits OR any `.changeset/` entries OR any graduation-eligible held entries per ADR-061 Rule 1) | Drain release queue (`push:watch` then, if releasable changesets exist, `release:watch`) before next iteration — per ADR-018 (Step 6.5) as amended by P250. Trigger is *presence of releasable material*, not residual band reaching appetite. User direction 2026-05-17: "If it's low risk, you should release." |
| Pipeline risk within appetite (≤ 4/25) AND empty queue (no unpushed commits AND no `.changeset/` AND no graduation-eligible held entries) | No drain — literally nothing to release. Proceed directly to Step 6.75. The genuine no-op fast-path per P250. |
| Cohort-graduation pre-check fires before Drain action (within-appetite branch, `docs/changesets-holding/` non-empty) — evaluator returns `status=resolved` | Route to Rule 4 evidence-floor judgement (LLM-owned per ADR-061 Rule 4 + ADR-044 framework-resolution boundary). Evaluator's `status=resolved` is necessary-but-not-sufficient (P308 — evaluator script disclaims Rule 4 at lines 19-22). Interactive: per-held-entry `AskUserQuestion` with inline evidence summary (P350 brief-before-ID) + 3 options (Graduate / Defer / Reject). AFK: queue per-held-entry `outstanding_question` to `.afk-run-state/outstanding-questions.jsonl` (P352 / ADR-013 Rule 6 queue-and-continue universal default) — do NOT graduate, continue Drain for any pre-existing `.changeset/` entries. On Graduate verdict: `git mv docs/changesets-holding/<basename> .changeset/<basename>`, append README "Recently reinstated" entry citing the user's Rule 4 verdict, amend the iter's main commit per ADR-042 Rule 3. For class=3b cohorts, all cohort members graduate atomically on any-member Graduate verdict (Rule 3b cohort propagation); any Defer/Reject keeps entire cohort held. Per ADR-061 Rule 4 + Rule 5 + Rule 6 + Rule 7 + ADR-013 Rule 6 + P246 + P308 + P350 + P352 (Step 6.5 Cohort-graduation pre-check; step 2a Rule 4 evidence-floor judgement). Graduation criterion is evidence-of-working-as-desired (Rule 4 evidence floor), not elapsed wall-clock time — user direction 2026-05-17: "Dogfooding makes sense, but it shouldn't be time based, it should be until we are happy that it's working as desired." |
| Cohort-graduation pre-check — evaluator returns `status=vp-blocked` | Skip. Per ADR-061 Rule 2 Verification Pending carve-out (symmetric to ADR-042 Rule 2b). Do NOT graduate; held entry stays. `.verifying.md` → `.closed.md` transition auto-clears the carve-out at a later pass. Per ADR-061 Rule 2 + P246. |
| Cohort-graduation pre-check — evaluator returns `status=halt-no-resolution` | Halt at the framework-prescribed "Step 6.5 cohort-graduation halt-no-resolution" halt point. Per ADR-061 Rule 1a terminal: ambiguous join is a user-decision surface, not an agent-decision surface. Halt-with-batched-questions per the Step 2.5b cross-reference. Per ADR-061 Rule 1a + P246. |
| Post-release K→V auto-transition between iters (P228) | After a successful within-appetite Drain action shipped a release to npm, invoke `wr-itil-enumerate-postrelease-kv-candidates` to enumerate `.known-error.md` tickets whose `**Release vehicle**: .changeset/<name>.md` citation matches a just-shipped (deleted-from-tree) changeset, and dispatch `/wr-itil:transition-problem <NNN> verifying` per emitted `KV_CANDIDATE` line. Conditional on actual release (skipped when `push:watch` ran alone with no changeset); non-blocking on individual transition failure (logs per-ticket, continues to next candidate; persistent failures route to Step 2.5b accumulated questions). V→C remains a maintainer-only surface — this callback fires K→V only. Per ADR-022 + ADR-018 + ADR-010 amended P093 + ADR-014 + ADR-013 Rule 5 + ADR-044 + P228 + P233 + P267 + P330 (Step 6.5 Post-release K→V auto-transition subsection). |
| Post-release plugin cache refresh between iters (P233) | After a successful within-appetite Drain action shipped a release to npm, chain `/install-updates` to refresh the plugin cache before the next iter dispatches. Conditional on actual release (skipped when `push:watch` ran alone with no changeset); non-blocking on `/install-updates` failure (degrades to cache-stays-stale, equivalent to pre-amendment behaviour). Mid-loop ask discipline preserved by treating any `/install-updates` AskUserQuestion surface AS the Non-interactive fallback dry-run path. Per ADR-013 Rule 5 + ADR-044 + P130 + P106 + P233 (Step 6.5 Post-release cache refresh subsection). |
| CI failure during Step 6.5 drain (within-appetite branch) | Diagnose via `gh run view --log-failed`, classify against the closed fixable-in-iter allow-list (P081-class stale-grep-string, hook stub mismatch, test ID drift, environmental flake), fix-and-continue for fixable classes (each retry rides its own ADR-014 commit gate), 3-retry cap per iteration, halt for unrecoverable classes. Ambiguous classification defaults to halt. ADR-013 Rule 5 policy-authorised. Per ADR-026 grounding + ADR-044 framework-resolution boundary + P140 (Step 6.5 Failure handling). |
| Pipeline risk above appetite (push or release >= 5/25) | Auto-apply scorer remediations incrementally (ADR-042 Rule 2). The agent reads suggestions and decides what to do. Re-score after each apply; drain when within appetite. **Never release above appetite** (ADR-042 Rule 1) — no AskUserQuestion shortcut. Halt the loop with `outcome: halted-above-appetite` if the loop exhausts without convergence (ADR-042 Rule 5). Verification Pending commits excluded from auto-revert (Rule 2b). Per ADR-042 (Step 6.5 Above-appetite branch). |
| Origin diverged before start (Branch 1) | Pull `--ff-only` if trivial; route to Branch 3 (stop with `git log HEAD..origin/<base>` and reverse report) if non-fast-forward — per ADR-019 (Step 0 Branch 1 / Branch 3). |
| Pre-existing uncommitted work attributable to prior iter's in-flight flow (Branch 2 — DEFERRED) | Per ADR-019 Branch 2 (currently routes → Branch 3 until follow-up lands the auto-commit mechanism + JTBD-001 gate composition + bats). Auto-commit criteria when shipped: (a) provenance unambiguous AND (b) risk within appetite per ADR-018. Commit subject convention: `chore(preflight): recover prior-session in-flight work — <ticket-ref>` (JTBD-006 audit trail). |
| Prior-session partial work detected at start (Branch 3 detection — session-continuity dirty: untracked `docs/decisions/*.proposed.md` / `docs/problems/*.md`, `.afk-run-state/iter-*.json` with `is_error: true` or `api_error_status >= 400`, stale `.claude/worktrees/*`, uncommitted SKILL.md/source/ADR edits) | Halt the loop with a structured Prior-Session State report in the AFK summary — deliberate carve-out from the 2026-06-06 Rule 6 queue-and-continue default (ambiguous state would mask the bug this preflight surfaces). Do NOT attempt non-interactive resume. Interactive invocations prompt via `AskUserQuestion` with 4 options (resume / discard / leave-and-lower-priority / halt). Per P109 + ADR-013 Rule 6 + ADR-019 (Step 0 Branch 3 detection mechanism). |
| Fix verification needed | Skip problem, add to "needs verification" list |
| Stop-condition #2 with user-answerable skip-reasons | Default: call AskUserQuestion (batched, ≤4 per call, sequential when >4) — the orchestrator's main turn is interactive by construction per ADR-032 subprocess-boundary; user is presumed at the keyboard. Fallback: emit Outstanding Design Questions table when AskUserQuestion is unavailable (Rule 6 fail-safe). Per ADR-013 Rule 1 + P122 (Step 2.5). |
| Pre-`ALL_DONE` gate sequence at any loop end (every stop-condition + every halt-path that emits a final summary + quota-exhaustion natural end) | Run Step 2.4 sequence UNCONDITIONALLY before `ALL_DONE` emit: gate (a) outstanding-questions surface via Step 2.5b; gate (b) session-level retro via `/wr-retrospective:run-retro`; gate (c) emit `ALL_DONE` only after (a) AND (b) complete. Hard-fail mode: if either gate cannot complete cleanly, halt with directive instead of emit `ALL_DONE` — recovery is the user satisfying the gate and re-invoking the skill. Per ADR-044 framework-resolution boundary + ADR-013 + ADR-014 (retro commits its own work) + P086 (extends iter-level retro to orchestrator-level) + P341 (Step 2.4). |
| Halt-path final summary with accumulated user-answerable skips (CI failure / Rule 5 above-appetite / dirty-unknown / session-continuity / fetch failure) | Run Step 2.5b's surfacing routine before emitting the halt path's final AFK summary. Step 2.5b is gated on ≥1 accumulated user-answerable skip — empty-skip halts skip the routine. Step 2.5b surfaces *prior-iter accumulated user-answerable skips only*; it does NOT ask the user how to remediate the halt cause itself (CI failure / above-appetite state / dirty-unknown state remain halt-with-bug-signal). Per ADR-013 Rule 1 + ADR-032 + P126 (`halt-paths-must-route-design-questions-through-Step-2.5b`). |
| Unexpected dirty state between iterations | Halt the loop. Report the `git status --porcelain` output, the last iteration's reported outcome, and the divergence — per P036 (Step 6.75). Run Step 2.5b before emitting the halt summary if ≥1 accumulated user-answerable skip from prior iters (P126). Do NOT attempt non-interactive recovery of the dirty state itself. |
| Iter committed cleanly + claim contradicts on-disk ADR Confirmation state (P335) | Halt the loop with `outcome: halted-iter-over-claim`. Include the `wr-itil-verify-iter-summary` stdout (the `OVER-CLAIM: ADR-NNN has N unchecked Confirmation item(s)...` lines) as the divergence detail. Run Step 2.5b before emitting the halt summary if ≥1 accumulated user-answerable skip from prior iters. Do NOT auto-correct the iter's claim — the orchestrator cannot retroactively make a false claim true; the user adjudicates on return (re-dispatch / accept partial / amend). Per ADR-013 Rule 6 + ADR-032 subprocess-boundary trust contract + P335 (Step 6.75 verify-iter-claims sub-step). |
| External root cause detected at Open → Known Error, or at park with `upstream-blocked` reason | **Auto-invoke `/wr-itil:report-upstream`** via the manage-problem Step 6 external-root-cause detection AFK fallback (per ADR-024 2026-06-04 (P270) amendment). The report-upstream skill composes the draft then scores the prose via `wr-risk-scorer:external-comms` (ADR-028); below-appetite → sends (public-issue Step 5 / comment Step 5c / security Step 6 per classification); above-appetite → risk-reduces (open-ended LLM judgement per leaf (a)) then re-scores → sends-or-queues to `## Queued Upstream Report` (leaf (c)). Security routing per leaf (b): upstream-with-`SECURITY.md` + below-appetite → files via declared channel; upstream-without-`SECURITY.md` → external-comms-gated impact assessment. Queue does NOT halt (P352). Tickets already carrying the stable `- **Upstream report pending** -- external dependency identified; invoke /wr-itil:report-upstream when ready` marker from prior sessions are detected via the already-noted grep check and routed to the report-upstream invocation; the marker shape is retained as the detection substrate (ASCII `--` per P210 — em-dash variant is the legacy form, still matched by the already-noted check for backward compatibility). Per P063 (amended 2026-06-04) + P270 + ADR-013 Rule 6. |
| Mid-loop ask between iters in the orchestrator's main turn | Forbidden except at framework-prescribed user-interaction points (Step 0 session-continuity / fetch-failure halt; Step 2.5 / 2.5b loop-end emit; Step 6.5 above-appetite Rule 5 halt; Step 6.5 CI-failure / release:watch halt; Step 6.5 cohort-graduation halt-no-resolution halt; Step 6.5 cohort-graduation per-entry Rule 4 evidence-floor judgement (P308 — interactive only; AFK queues per P352); Step 6.75 dirty-for-unknown-reason halt). The loop's purpose is **progress + accumulation**; mechanical-stage transitions between iters are framework-resolved and MUST NOT prompt the user. Per ADR-044 framework-resolution boundary + ADR-013 Rule 1 (as amended by ADR-044) + P130. |

### Mid-loop ask discipline (orchestrator main turn) — P130

The orchestrator MUST NOT call `AskUserQuestion` between iterations except at the framework-prescribed user-interaction halt points listed below. The loop's purpose is **progress + accumulation** — progress every ticket the agent can advance autonomously, accumulate user-answerable questions as a side-effect, and surface the accumulated batch only at a halt point. This rule applies whether the user is observably present or not, because **presence-detection is unreliable** and is not the goal — the user may answer one question and disappear for hours; the orchestrator's job is to keep advancing the backlog and stage the user-interaction surface for whenever the user actually returns. Treat the user as transient.

**Framework-prescribed halt points (the only orchestrator-main-turn surfaces where `AskUserQuestion` is permitted):**

- **Step 0 session-continuity halt** — Prior-Session State report; user routes resume / discard / leave-and-lower / halt (interactive branch only; AFK branch halts with the structured report per ADR-013 Rule 6).
- **Step 0 fetch-failure halt** — `git fetch origin` network failure; halt-with-report so the user retries on return.
- **Step 2.5 / Step 2.5b loop-end emit** — accumulated `outstanding_questions` queue presented as batched `AskUserQuestion` (or fallback Outstanding Design Questions table per ADR-013 Rule 6). This is the framework's prescribed user-interaction point; do NOT dilute it by asking earlier.
- **Step 6.5 above-appetite Rule 5 halt** — auto-apply loop exhausted without convergence; halt-with-batched-questions per the Step 2.5b cross-reference (Step 2.5b surfaces *prior-iter accumulated user-answerable skips only* — the halt-causing scorer-gap remains a halt-with-bug-signal per ADR-042 Rule 5).
- **Step 6.5 CI-failure / `release:watch` failure halt** — push:watch or release:watch failed AND the failure is genuinely-unrecoverable (outside the fixable-in-iter allow-list, or 3-retry cap reached); halt-with-batched-questions per the Step 2.5b cross-reference. Failures inside the closed allow-list route to fix-and-continue per Step 6.5 Failure handling (P140), not this halt point.
- **Step 6.5 cohort-graduation halt-no-resolution halt (P246)** — graduation evaluator returned `status=halt-no-resolution` for one or more held candidates (Rule 1a terminal: neither filename-convention join nor body-grep fallback resolved a problem ticket, OR the resolved ticket file is missing/unreadable). The orchestrator MUST NOT auto-graduate under ambiguity per ADR-061 Rule 1a; halt-with-batched-questions per the Step 2.5b cross-reference. The halt-causing ambiguity itself remains a halt-with-bug-signal (the held entry stays in `docs/changesets-holding/`; manual reinstate or ticket-file correction required); Step 2.5b surfaces *prior-iter accumulated user-answerable skips only* and does NOT ask the user to resolve the ambiguity itself.
- **Step 6.5 cohort-graduation per-entry Rule 4 evidence-floor judgement (P308) — interactive only** — graduation evaluator returned `status=resolved` for ≥1 held candidate AND `AskUserQuestion` is available. Per ADR-061 Rule 4 + ADR-044 framework-resolution boundary, Rule 4 evidence-floor judgement is LLM-owned (not framework-resolved); the user ratifies per held entry with Graduate / Defer / Reject before any `git mv`. This is NOT a halt — the orchestrator continues the loop after the user verdict (graduate path performs git mv + README append + ADR-042 Rule 3 amend; defer/reject paths preserve the hold). When `AskUserQuestion` is unavailable (AFK path), the orchestrator queues `outstanding_question` entries per held candidate per P352 / ADR-013 Rule 6 queue-and-continue universal default — does NOT halt, does NOT silently proceed, does NOT auto-default. The held entries' user ratifications then surface at Step 2.5 loop-end via the existing accumulated-questions discipline.
- **Step 6.75 dirty-for-unknown-reason halt** — `git status --porcelain` divergence; halt-with-batched-questions per the Step 2.5b cross-reference.
- **Step 6.75 iter-over-claim halt (P335)** — `wr-itil-verify-iter-summary` detected the iter's commit message or `ITERATION_SUMMARY.notes` contains completion-claim language for an ADR whose `## Confirmation` section still has unchecked `- [ ]` items; halt-with-batched-questions per the Step 2.5b cross-reference. The over-claim itself remains a halt-with-bug-signal — Step 2.5b surfaces *prior-iter accumulated user-answerable skips only*; it does NOT ask the user how to remediate the false claim (re-dispatch / accept partial / amend the commit remains a user decision on return).

**No mid-iter ask points.** Every other point in the orchestrator's main turn (between Step 5 dispatch completing and Step 6.5 release-cadence check; between Step 6.75 verification and Step 7 loop-back; between Step 7 and Step 1 next-iteration; between consecutive iters generally) is a mechanical-stage transition that the framework has already resolved. Do NOT introduce ad-hoc `AskUserQuestion` calls at those points to confirm "is it OK to proceed?" or "want me to start the next iter?" — proceeding IS the framework-resolved default. Continue iterating until quota or stop-condition #1/#2/#3 fires.

<!-- @jtbd JTBD-006 (Progress the Backlog While I'm Away — scope-pin invocation does not trigger agent-inferred premature halt; loop advances pinned-ticket work until framework-prescribed stop fires) -->
<!-- @jtbd JTBD-001 (Enforce Governance Without Slowing Down — ADR-044 framework-resolution boundary for loop control codified in skill prose; no re-prompt round-trip after scope-pin invocation) -->
<!-- @problem P175 -->
**Scope-pin-word semantics (P175).** Natural-language modifiers in the invocation args — `just`, `only`, `first`, `merely`, `simply` paired with a ticket reference (e.g. `/wr-itil:work-problems just work P170`) — are **SCOPE FILTERS** over Step 1's WSJF selection: they pin the loop to the named ticket instead of letting Step 3's tier + tie-break ladder select. They are NOT count constraints. The Step 7 → Step 1 loop-back contract is unchanged; iterations continue on the pinned ticket until a framework-prescribed stop condition fires (Step 2 #1 no actionable / #2 all interactive / #3 all blocked; Step 2.4 gate (a)/(b) pre-`ALL_DONE` sequence; quota exhaustion; Step 6.5 / Step 6.75 / Step 0 halt paths). The orchestrator MUST NOT emit `ALL_DONE` from natural-language modifier interpretation alone — `ALL_DONE` is reserved for the framework-resolved stop surface per Step 2.4 gate (c). Concretely: if iter 1 on the pinned ticket returns `outcome: partial-progress` with `outstanding_questions` queued and remaining slices named in `notes`, the orchestrator dispatches iter 2 on the same pinned ticket; the loop only stops when the ticket's actionable work is exhausted (Step 2 #1 then fires for the pinned-scope view) OR a halt path fires. This is the **inverse-direction** failure mode of P130's inverse-presence pattern — both stem from agent over-inferring loop-control semantics the framework already resolved (per ADR-044 framework-resolution boundary's "Continue / stop loops" mediation; loop control is framework-resolved, agents do not invent halt criteria from natural-language modifiers). When the user invokes the orchestrator with a scope-pin word, treat that word as a **selection override** only, not a loop-control directive.

**Accumulated-question discipline at surface time** (per ADR-044's six-class authority taxonomy — questions that reach the user must be load-bearing):

- **Direction-setting only** — questions that ONLY the user can answer because they reflect goals, intent, or trade-offs the framework has not yet captured. Other accumulated observations (deviation-approval, one-time-override, silent-framework, taste, correction-followup) follow the same shape as the deviation-candidate schema in Step 5's `outstanding_questions` contract.
- **No BUFD** — don't pre-judge architectural decisions before evidence accumulates. Small, actionable questions; not galaxy-brain ones. The deviation-candidate surface (per ADR-044's anti-BUFD-for-framework-evolution clause) is the place where iter-discovered misfits accumulate; the user resolves with full context at loop end.
- **No questions answerable by research / exploration / experimentation** — the agent should prototype, read code, run experiments to answer those itself rather than sub-contracting routine investigative work back to the user. The user is the source for genuine direction-setting decisions, not for "what does this hook do" or "which file holds X" — those are research questions the agent owns.

**Cross-references:**

- **Step 5's iteration-prompt body** carries the per-subprocess "Do not call `AskUserQuestion`" constraint; this subsection carries the orchestrator-main-turn equivalent. Together they enforce the same discipline at both the subprocess layer and the main-turn layer end-to-end.
- **ADR-044** is the parent decision narrowing ADR-013 Rule 1 to framework-unresolved decisions; this subsection is one of its load-bearing implementation surfaces.
- **ADR-013 Rule 1** (as amended by ADR-044) restricts `AskUserQuestion` to framework-unresolved decisions; the framework-prescribed halt enumeration above is the orchestrator-layer interpretation of that narrowing.
- **ADR-013 Rule 6** is the non-interactive fail-safe — when `AskUserQuestion` is unavailable (restricted permission mode, hook-disabled tool surface), the framework-prescribed halts fall back to structured-summary table emission rather than skipping the user-interaction.
- **ADR-032** subprocess-boundary contract is unchanged — this subsection is orchestrator-main-turn discipline; the iteration-subprocess dispatch shape (P084 + P121 + P086 + P089) is untouched.

## Edge Cases

**Review needed first**: If no problems have WSJF scores, run `/wr-itil:review-problems` as the first iteration to score everything, then proceed to the work loop. (Independent of Step 0b's inbound-discovery pre-flight, which fires on cache staleness regardless of WSJF-score state.)

**Scope creep during investigation**: If investigating an open problem reveals the scope is larger than expected (effort re-sized from S to L, or L to XL), save findings to the problem file, update the WSJF score, and move to the next problem. Don't sink unlimited effort into one problem during AFK mode — the user can decide when they return.

**Circular work**: If the same problem keeps appearing as highest-WSJF across iterations without making progress, skip it after the second attempt and note it as "stuck — needs interactive attention".

**Git conflicts**: If a commit fails due to conflicts, stop the loop and report the conflict. Don't try to resolve conflicts non-interactively.

## Output Format

The skill should produce a final summary when the loop ends:

```
## Work Problems Summary

### Completed
| # | Problem | Action | Result |
|---|---------|--------|--------|
| 1 | P029 (Edit gate overhead) | Implemented fix | Closed |
| 2 | P021 (Structured prompts) | Investigated root cause | Transitioned to Known Error |

### Skipped
| Problem | Skip-reason category | Reason |
|---------|---------------------|--------|
| P016 (Multi-concern splitting) | user-answerable (verification) | Awaiting user verification |

### Outstanding Design Questions

(Emitted only when stop-condition #2 fires AND at least one skipped ticket has a `user-answerable (design/direction/pacing/scope)` skip-reason. Populated by Step 2.5 in non-interactive / AFK mode per ADR-013 Rule 6.)

| Ticket | Question | Context |
|--------|----------|---------|
| P049 (Known Error overloaded) | What should the new status be called, and what file suffix? | Decide so the rename/migration commit can land unambiguously. |
| P051 (run-retro improvement axis) | Ship in this AFK loop or next? | P050 is still fresh; rewriting Step 2/4b/5 twice in one session may churn. |

### Remaining Backlog
| WSJF | Problem | Status |
|------|---------|--------|
| 9.0 | P012 (Skill testing harness) | Open |

### Session Cost

Extracted from each iteration subprocess's `claude -p --output-format json` response (source: measured-actual, not estimated — per ADR-026 grounding). Renders identically in interactive and AFK modes; no decision branch, so output-side only. Cache-read column surfaces the warm-cache-reuse signal observed across subsequent subprocess invocations in the same Bash session.

**Authority note (per P089 Gap 2 — see Step 5 Authority hierarchy):** the "Total cost (USD)" column is authoritative (CLI reports `.total_cost_usd` as a session cumulative). The token columns are **best-effort** — they accumulate each iteration's `.usage.*` response fields, which reflect only the final-turn API envelope and can undercount when a subprocess exits via a background-task completion-notification ack. Cost-based reasoning trusts the cost column; token-based reasoning (cache-reuse ratios, cost-envelope calibration) reads the token columns with that caveat in mind.

| Metric | Value |
|--------|-------|
| Iterations run | 3 |
| Successful (committed) | 2 |
| Skipped | 1 |
| Total cost (USD) | $2.29 |
| Mean cost per iteration | $0.76 |
| Total input tokens | 42 |
| Total output tokens | 1,531 |
| Cache-creation tokens | 78,000 |
| Cache-read tokens (reuse) | 1,064,000 |
| Total duration | 2m 12s |

ALL_DONE
```

**`ALL_DONE` position (P341 Step 2.4).** The `ALL_DONE` sentinel is the FINAL line of the rendered summary, emitted at Step 2.4 gate (c) — AFTER Step 2.4 gate (a) (outstanding-questions surface via Step 2.5b) AND AFTER Step 2.4 gate (b) (session-level retro via `/wr-retrospective:run-retro`) BOTH complete cleanly. The session-level retro's own commit + any tickets it creates land BEFORE the `ALL_DONE` emit. External scripts watching for AFK-loop completion can rely on `ALL_DONE` as an honest sentinel: when it appears, both gates have completed. Hard-fail mode (halt with directive) replaces `ALL_DONE` when either gate cannot complete — adopters should treat the absence of `ALL_DONE` paired with a halt-directive line as the recoverable-pause shape (user satisfies the gate on return; re-invocation emits `ALL_DONE` cleanly).

When every skipped ticket is in the `upstream-blocked` category (stop-condition #3) or there are no skipped tickets (stop-condition #1), omit the Outstanding Design Questions section entirely rather than rendering an empty heading. The Session Cost section always renders when at least one iteration ran.

## Related

- **P341** (`docs/problems/open/341-work-problems-skill-must-surface-outstanding-questions-then-run-retro-before-emitting-all-done.md`) — driver for Step 2.4 Pre-`ALL_DONE` gate sequence (UNCONDITIONAL fire of outstanding-questions surface + session-level retro before `ALL_DONE` emit). 2026-05-31 user direction (verbatim in ticket Description): *"The work-problems skill MUST surface the outstanding questions at the end before emitting ALL_DONE. It MUST then run a retro. Only then should it emit ALL_DONE."* Closes the structural gap that allowed `ALL_DONE` to emit while direction-class observations remained queued AND without a session-level retro running. Behavioural second-source: `test/work-problems-p341-pre-all-done-gate.bats`. Composes with P086 (extends iter-level retro-on-exit to orchestrator-level), P126 (preserves `halt-paths-must-route-design-questions-through-Step-2.5b` principle), ADR-014 (retro commits its own work), ADR-044 (framework-resolution boundary for when to surface — now framework-resolved as unconditional pre-`ALL_DONE`).
- **P390** (`docs/problems/known-error/390-agent-declares-all-done-prematurely-while-actionable-backlog-remains.md`) — driver for Step 2.4 **Gate (0) — Objective backlog-empty assertion** (prepended ahead of gate (a)). Bug shape: the orchestrator emitted `ALL_DONE` while a dispatchable Tier-2 backlog remained, by generalising "the *salient* remainder is interactive-gated" to "Step 2 stop-condition #2 holds" — a subjective stop the framework did not authorise; it also skipped P382 (Tier-1 sev-16) entirely. Fix: before `ALL_DONE`, gate (0) re-scans the live open/known-error backlog (fresh dual-tolerant glob, not the Step 1 cache) and classifies each ticket dispatchable/non-dispatchable OBJECTIVELY by recorded marker (verifying / `## Fix Released`; upstream-blocked; blocked dead-end; Step 3.5/3.6 durable per-session skip record; held changeset). ≥1 dispatchable ticket FORBIDS `ALL_DONE` and loops back to Step 3 tier-first selection (loopback, not halt); a user-directed pivot does not discharge the Tier-exhaustion obligation. Sibling loop-control-stop class: P332 (run-retro skip rationalisation), P148 (Stage-1 ticketing skip), P175 (scope-pin loop-control inference); hardens P341's precondition. Behavioural second-source: `eval/promptfooconfig.yaml` Tier-A regex + Tier-B llm-rubric asserting the orchestrator does NOT emit `ALL_DONE` when ≥1 dispatchable ticket remains. Per ADR-044 "Continue / stop loops" framework-resolution (the natural stop is concrete — `ALL_DONE` conditions objectively met).
- **P342** (`docs/problems/open/342-iter-retros-queue-observations-as-outstanding-questions-instead-of-auto-ticketing-same-trust-boundary-as-step-4a.md`) — driver for Step 5 iter-prompt body's retro-surfaced observation classification taxonomy and capture-* carve-out. Iter retros' observations of recurring class-of-behaviour now route to `/wr-itil:capture-problem` (mechanical-stage carve-out per run-retro Step 4a precedent); only direction-setting observations queue at `outstanding_questions`; ambiguous defaults to auto-ticket per the trust-boundary asymmetry. The "no `capture-*` siblings mid-loop" rule is preserved for non-retro mid-iter capture (P078-class spam); the carve-out is bounded to the retro path. Sibling locus: `packages/retrospective/skills/run-retro/SKILL.md` Step 4b carries the symmetric mirror (same trust-boundary fires whether retro runs in iter context OR standalone in main turn). Behavioural second-source: `test/work-problems-p342-retro-auto-ticket-carveout.bats` + `packages/retrospective/skills/run-retro/test/run-retro-step-4b-retro-auto-ticket-carveout.bats`. Composes with run-retro Step 4a (precedent), ADR-013 Rule 5 (policy-authorised silent proceed), ADR-032 (foreground-spawns-N-background fanout already documented for Stage 1 in run-retro Step 4b), ADR-044 (mechanical-stage carve-out), P130 (mid-loop AskUserQuestion ban unchanged), P078 (capture-on-correction — distinct trigger surface; both end in capture but for different signals).
- **P121** (`docs/problems/121-afk-orchestrator-should-sigterm-stuck-subprocesses-after-idle-timeout.verifying.md`) — driver for Step 5's backgrounded-poll-loop dispatch shape (replacing the prior foreground-synchronous form) and the idle-timeout SIGTERM branch. The 2026-04-25 P118 iter 5 evidence: an iteration subprocess sat idle ~70 min after its final commit, then SIGTERM produced a clean JSON exit-flush. Fix: orchestrator backgrounds the subprocess, polls every 60s, computes `LAST_ACTIVITY_MARK = max(DISPATCH_START_EPOCH, git log -1 --format=%at HEAD)`, and sends SIGTERM when `now - LAST_ACTIVITY_MARK > WORK_PROBLEMS_IDLE_TIMEOUT_S` (default 3600s = 60 min). Behavioural second-source: `test/work-problems-step-5-idle-timeout-sigterm.bats` exercises a fake `claude -p` shim that sleeps past the threshold and asserts SIGTERM, JSON exit-flush, env-var override, and within-threshold no-fire. Step 6's per-iter progress line SHOULD annotate `(SIGTERM_SENT)` when the branch fires so users can distinguish recovered iters from natural completions. ADR-032's subprocess-boundary variant amended 2026-04-26 with the backgrounded-poll-loop refinement.
- **P146** (`docs/problems/146-afk-iteration-subprocess-bash-until-loop-polls-bats-output-with-bats-console-regex-against-tap-format.verifying.md`) — driver for Step 5 iteration prompt body's bats-output-polling-discipline clause. The 2026-04-29 incident (iter 1, PID 23580 child PID 16408) saw a `bash until`-loop poll a backgrounded bats output file with regex `^[0-9]+ tests?,` (bats's *default* console-summary format) against `bats --tap` output that never emits that line — silent infinite spin after bats completed; manual SIGTERM at 68m34s wall-clock; metadata loss per the P147 stuck-before-emit subclass. The polling idiom is NOT taught by any SKILL.md (audit confirmed via repo grep) — it is agent-learned from training data. Fix: prompt-discipline rule in the iteration prompt body's Constraints list explicitly forbidding the antipattern, naming `wait $bg_pid` (or Bash-tool `run_in_background=true` + `BashOutput`) as the safe substitute, and citing the TAP-vs-console-summary divergence so future contributors don't "fix" the rule incorrectly. Behavioural second-source: `test/work-problems-step-5-bats-polling-discipline.bats` asserts the prohibition phrase, the safe-substitute pointer, the P146 cite, the divergence explanation, and the Related-section cite.
- **P232** (`docs/problems/verifying/232-bash-until-loop-pgrep-self-referential-deadlock-new-variant-of-p146.md`) — sibling variant of P146; driver for the second clause in Step 5 iter prompt's polling-discipline rule plus the structural PreToolUse:Bash hook at `packages/itil/hooks/itil-bash-polling-antipattern-detect.sh`. The 2026-05-16 incident (iter 4, P132 Phase 2a-iii-B) saw 4 concurrent `until ! pgrep -f 'bats --recursive'` polling loops each match the OTHER loops' command lines and spin forever after the main commit landed; 45 min wall-clock + $20-30 wasted before manual SIGTERM. Two-layer fix: prompt-discipline clause naming the self-reference failure mode with worked-example syntax (`until ! pgrep -f ...`), PLUS PreToolUse:Bash hook denying `(until|while)[[:space:]]+!?[[:space:]]*(pgrep|pkill[[:space:]]+-0)` shapes with a deny message citing P232 and naming both recovery alternatives (`wait $bg_pid` shell-native, Bash-tool `BashOutput` harness-native). Behavioural second-source: `packages/itil/hooks/test/itil-bash-polling-antipattern-detect.bats` (positive cases — until/while pgrep, until/while pkill -0, heredoc; negative cases — one-shot pgrep, non-`-0` pkill, unrelated until/while, `wait $!`; advisory-message content cite). P146 prompt-only enforcement failed empirically in iter 4 of the very loop that ships it; P232 closes the class with structural enforcement.
- **P147** (`docs/problems/147-p121-sigterm-clean-flush-guarantee-conditional-needs-skill-md-caveat-for-stuck-before-emit-subclass.verifying.md`) — refinement to P121's "clean exit-flush" claim. P118's evidence held only for subprocesses that had already emitted `ITERATION_SUMMARY` before going idle; the 2026-04-29 P146 incident produced exit 143 + 0-byte JSON when SIGTERM fired before `ITERATION_SUMMARY` emission. Fix: SKILL.md prose now carries the conditional caveat (Step 5 "SIGTERM exit-flush is conditional, not universal" subsection) and adopters reading the prose are directed to treat exit 143 + 0-byte JSON as a metadata-loss event — verify work integrity from `git log` + `git status --porcelain`, halt the AFK loop, and reconstruct cost from the Anthropic billing dashboard. Behavioural second-source extends `test/work-problems-step-5-idle-timeout-sigterm.bats` with a stuck-before-emit fake-shim asserting `JSON_BYTES=0` after SIGTERM. Mechanism unchanged (SIGTERM remains the right recovery primitive); the refinement is documentation accuracy + the metadata-loss-event handling shape.
- **P089** (`docs/problems/089-work-problems-step-5-dispatch-robustness-stdin-warning-and-cost-metadata-edge-case.verifying.md`) — driver for Step 5's `< /dev/null` dispatch redirect and the Per-iteration cost metadata "Authority hierarchy" paragraph. Gap 1: stdin warning contaminated stderr-merged JSON captures; closed by adding `< /dev/null` to the canonical dispatch command. Gap 2: `.usage.*` undercounts when subprocess exits via a background-task completion ack while `.total_cost_usd` stays cumulative-authoritative; closed by documenting the authority hierarchy in Step 5 and the Session Cost output section so adopters trust cost and label token totals best-effort.
- **P086** (`docs/problems/086-afk-iteration-subprocess-does-not-run-retro-before-returning.verifying.md`) — driver for Step 5's retro-on-exit clause. Iteration subprocesses exit without running retro, so per-iteration friction (hook misbehaviour, repeat-workaround patterns, pipeline instability) evaporates on exit. Fix: iteration prompt body names `/wr-retrospective:run-retro` as a closing step before `ITERATION_SUMMARY` emission; retro runs inside the subprocess so Step 2b pipeline-instability scan has the full tool-call history; run-retro commits its own work per ADR-014; orchestrator picks up retro-created tickets on the next Step 1 scan.
- **P084** (`docs/problems/084-work-problems-iteration-worker-has-no-agent-tool-so-architect-jtbd-gates-block.open.md`) — driver for Step 5's subprocess-boundary dispatch. Supersedes P077's Agent-tool dispatch on the same Step 5 surface because Agent-tool-spawned subagents cannot themselves invoke Agent (platform restriction), which prevents governance gate markers from being set inside the iteration worker.
- **P077** (`docs/problems/077-work-problems-step-5-does-not-delegate-to-subagent.verifying.md`) — parent amendment. Established the AFK iteration-isolation wrapper sub-pattern and the `ITERATION_SUMMARY` return contract. P084 is the refinement that swaps the spawn mechanism; the isolation intent and return contract are preserved verbatim.
- **P083** (`docs/problems/083-work-problems-iteration-worker-prompt-does-not-forbid-schedulewakeup.open.md`) — iteration prompt body forbids `ScheduleWakeup`. Applies equally to subprocess-dispatched iterations.
- **P036** — inter-iteration verification (Step 6.75); remains in the orchestrator's main turn.
- **P040** — origin-fetch preflight (Step 0); unchanged.
- **P109** — session-continuity detection pass added to Step 0 after the fetch/divergence check. Enumerates five signals (untracked `docs/decisions/*.proposed.md`, untracked `docs/problems/*.md`, `.afk-run-state/iter-*.json` error markers, stale `.claude/worktrees/*` dirs, uncommitted SKILL.md/source/ADR edits). Routes interactive via `AskUserQuestion` with 4 options, AFK via halt-with-report per ADR-013 Rule 6.
- **P041** — release-cadence drain (Step 6.5); remains in the orchestrator's main turn.
- **P053** — Outstanding Design Questions surfacing at stop-condition #2 (Step 2.5); fed by the iteration subagent's `outstanding_questions` field.
- **P122** (`docs/problems/122-work-problems-stop-condition-2-defaults-to-afk-table-instead-of-asking-interactively.verifying.md`) — established the AskUserQuestion-default-when-available routing at Step 2.5. The routing prose (default branch, Rule 6 fallback, cross-skill principle, user-answerable scoping) was originally landed under Step 2.5; P126 moved it into the reusable Step 2.5b sub-step.
- **P126** (`docs/problems/126-work-problems-failure-handling-halt-bypasses-step-2-5-routing.known-error.md`) — extended the principle to every halt path that emits a final AFK summary. Step 2.5b is the single source of truth that Step 2.5, Step 0 (session-continuity + fetch-failure), Step 6.5 (Failure handling + Rule 5 above-appetite), and Step 6.75 (dirty-for-unknown-reason) all cross-reference. The principle: `halt-paths-must-route-design-questions-through-Step-2.5b`. Behavioural second-source: `test/work-problems-step-2-5b-cross-halt-routing.bats`.
- **P175** (`docs/problems/open/175-agent-over-narrows-scope-pin-words-into-count-constraints-halts-loop-on-agent-inferred-scope.md`) — driver for the **Scope-pin-word semantics** paragraph in the "Mid-loop ask discipline" subsection plus a brief forward-pointer at Step 7. Bug shape: when the user invokes `/wr-itil:work-problems just work P170` (or `only`/`first`/`merely`/`simply` paired with a ticket reference), the orchestrator over-narrows the natural-language modifier as a count constraint and emits `ALL_DONE` after iter 1 even when iter 1 returned `outcome: partial-progress` with named remaining slices AND no Step 2 stop-condition fired. Fix: SKILL.md prose classifies the scope-pin vocabulary as **selection override** (Step 1 WSJF override only); explicitly disclaims any loop-control effect; reminds that the Step 7 → Step 1 loop-back contract is unchanged and `ALL_DONE` is reserved for the framework-resolved stop surface per Step 2.4 gate (c). Inverse-direction sibling of P130 (P130 is inverse-presence inference; P175 is inverse-scope inference; both stem from agent over-inferring loop-control semantics the framework already resolved per ADR-044 "Continue / stop loops"). Behavioural second-source: `eval/promptfooconfig.yaml` Tier-A regex + Tier-B llm-rubric asserting the orchestrator does NOT emit `ALL_DONE` after iter 1 on a scope-pin-word invocation with named remaining slices.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 6 non-interactive fail-safe applies to every iteration-subagent decision surface.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — preserved under the iteration subagent; the subagent commits its own work.
- **ADR-015** (`docs/decisions/015-on-demand-assessment-skills.proposed.md`) — Agent-tool-vs-Skill-tool delegation precedent (Step 6.5's wording mirror).
- **ADR-018** (`docs/decisions/018-release-cadence.proposed.md`) — release cadence stays in the orchestrator's main turn, not the iteration subagent.
- **ADR-019** (`docs/decisions/019-afk-orchestrator-preflight.proposed.md`) — preflight stays in the orchestrator's main turn.
- **ADR-022** (`docs/decisions/022-problem-verification-pending.proposed.md`) — iteration outcomes map into the return-summary's `outcome` field (`verifying` for a released fix, `known-error` for a root-cause-confirmed ticket awaiting release, etc.).
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — pattern taxonomy parent; Step 5 implements the AFK iteration-isolation wrapper — subprocess-boundary variant per the P084 amendment (2026-04-21), refining the P077 Agent-tool amendment. The P077 amendment remains in the ADR as the historical Agent-tool variant; the subprocess variant is the lead for new adopters.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — doc-lint bats contract-assertion pattern used by `test/work-problems-step-5-delegation.bats`.
- **P211** (`docs/problems/known-error/211-work-problems-orchestrator-carries-prior-ticket-fix-strategy-text-into-iter-dispatch-without-re-grounding.md`) — driver for Step 5 iteration-prompt-body's "Re-ground per iter" orchestrator-side construction invariant. The bug shape (reported as inbound from downstream consumer bbstats as their P194): the orchestrator builds each iter's dispatch prompt by reading the target ticket's `## Fix Strategy` section and citing it verbatim into the subprocess prompt; across iterations, prior-ticket Fix Strategy text leaks into subsequent dispatches without re-grounding in the new ticket's design intent, and iters land fixes anchored on the wrong design rationale. Fix: SKILL.md Step 5's "Iteration prompt body" section now carries an explicit re-grounding paragraph (immediately after the "self-contained" opener) that (a) names the per-iter re-ground invariant against current-ticket-ID + title only, (b) forbids inlining `## Fix Strategy` verbatim into the dispatch prompt (the subprocess reads it from disk via `/wr-itil:manage-problem`), (c) names the cross-iter leakage class (prior ticket ID, prior Fix Strategy text, prior outcome reason, prior commit SHA, prior retro findings, prior outstanding-questions), (d) names the construction shape (template-driven, reset per iter, no global accumulator). Behavioural second-source: `test/work-problems-step-5-prompt-body-re-grounding.bats` (structural-permitted per ADR-052 Surface 2; tdd-review comment in fixture cites P012 as harness-gap). Composes with P084 (subprocess-boundary isolation — re-grounding is the symmetric orchestrator-side property of the subprocess's "no prior conversation context"), ADR-032 (AFK iteration-isolation wrapper — re-grounding clarifies the wrapper's isolation intent on the orchestrator side), JTBD-006 (load-bearing — audit trail degrades if iters work the wrong ticket's design rationale).
- **P206** (`docs/problems/known-error/206-work-problems-iter-workers-dont-add-changesets-fix-commits-accumulate-without-release.md`) — driver for Step 5 iter-prompt-body's explicit "if the fix changes shippable code, author a `.changeset/*.md` in the same commit" constraint (composes defence-in-depth with hook P141's `git commit`-time enforcement). Inbound-reported by downstream consumer **bbstats** as their P195 (`**Origin**: inbound-reported (bbstats#195)` per ADR-076 sort tier). Behavioural second-source: `test/work-problems-step-5-iter-changeset-required.bats` (structural-permitted per ADR-052; tdd-review comment in fixture).
- **P141** (`docs/problems/verifying/141-iter-prompt-time-reminder-misses-40-percent-of-publishable-iters-hook-level-enforcement.md`) — sibling hook (`packages/itil/hooks/itil-changeset-discipline.sh`) that enforces the changeset-discipline rule at `git commit` time. The Step 5 iter-prompt-body constraint composes-with this hook; the prompt-time rule is load-bearing because plugin-hook execution depends on the marketplace cache carrying the current hook version (a fresh-cache adopter without P141 still gets the constraint via the prompt).
- **JTBD-001**, **JTBD-006**, **JTBD-007**, **JTBD-101**, **JTBD-201** — personas whose reliability expectations the iteration-isolation wrapper restores. JTBD-006 (Progress the Backlog While I'm Away) + JTBD-007 (Keep Plugins Current Across Projects) are the load-bearing pair for the P206 changeset-discipline constraint — JTBD-006 requires the audit trail to stay accurate at release boundary; JTBD-007's closure depends on fixes actually shipping to npm.
