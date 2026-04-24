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

### Step 0: Preflight (per ADR-019)

Before opening the work loop, reconcile local state with origin so the orchestrator does not iterate against a stale backlog or create tickets with IDs that collide with parallel sessions (P040).

**Mechanism:**

1. Run `git fetch origin`.
2. Compare local `HEAD` with `origin/<base>` (default `main`; otherwise the branch the user is on).
3. Branch on the divergence shape:

| Local vs origin | Action |
|---|---|
| HEAD at or ahead of origin/<base> | Proceed to Step 1 |
| origin/<base> ahead, local has no unpushed commits (pure fast-forward) | Run `git pull --ff-only` non-interactively. Log the count of pulled commits in the AFK iteration log. Proceed to Step 1. |
| origin/<base> ahead, local has unpushed commits (non-fast-forward) | STOP the loop. Report the divergence with `git log --oneline HEAD..origin/<base>` and `git log --oneline origin/<base>..HEAD`. Do NOT attempt to rebase or merge non-interactively — that is a judgment call the persona forbids in AFK mode. |

**Network failure**: if `git fetch origin` returns a network error, stop and report. Default behaviour is fail-closed — the user can retry when network is restored.

**Non-interactive authorisation**: per ADR-013 Rule 6, `git fetch origin` and `git pull --ff-only` are policy-authorised actions (no semantic merge, no destructive overwrite). `git pull --rebase`, `git merge`, and any operation that resolves conflicts are NOT policy-authorised — they require user input.

**Cross-cutting**: this rule applies to every AFK orchestrator skill. The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in the ticket-creator skills (`manage-problem` and `wr-architect:create-adr`), not here — see the related problem ticket for that work.

#### Session-continuity detection pass (per P109)

After the fetch/divergence check, Step 0 MUST run a session-continuity detection pass. The divergence check handles "did origin move under us"; this pass handles the distinct failure mode "did the prior session leave partial work that changes what iter 1 should do". A prior AFK subprocess can exit mid-ticket (quota 429, user-cancel, subprocess crash) and leave observable state in the working tree that the orchestrator must classify before opening the work loop.

**Signals to enumerate** (each maps to one `git status --porcelain` / filesystem / `git worktree` probe):

| Signal | Detection |
|---|---|
| Untracked `docs/decisions/*.proposed.md` | `git status --porcelain docs/decisions/` filtered for `??` entries ending `.proposed.md` — drafted but unlanded ADRs from a prior iter. |
| Untracked `docs/problems/*.md` | `git status --porcelain docs/problems/` filtered for `??` entries ending `.md` — drafted but unlanded problem tickets. |
| `.afk-run-state/iter-*.json` error markers | Files under `.afk-run-state/` containing `"is_error": true` OR `"api_error_status" >= 400` — prior iteration hit quota or API error; its work is likely partial. Success files (`"is_error": false`) are ignored. Contract source: ADR-032 subprocess artefact. |
| Stale `.claude/worktrees/*` dirs + matching `claude/*` branches | `git worktree list` filtered on `claude/*` branches adjacent to `.claude/worktrees/*` directories — prior subagent worktrees that were not cleaned up. Detection only — mutation (cleanup) is out of scope and requires a separate ADR. |
| Uncommitted modifications to SKILL.md / source / ADR files | `git status --porcelain` filtered for `M ` / ` M` entries on `packages/*/skills/*/SKILL.md`, `packages/*/hooks/*`, `docs/decisions/*.proposed.md`, or other source paths the prior session was mid-authoring. |

**Classification**: when any signal is present, build a structured Prior-Session State report listing each hit (signal category, path, one-line summary). An empty signal set means clean pass-through to Step 1.

**Routing on interactive-vs-AFK (per ADR-013 Rule 1 / Rule 6):**

- **Interactive** (`AskUserQuestion` is available AND the loop was not started in AFK mode): prompt the user with the Prior-Session State report and four options — **Resume the prior work** (land the drafted files as iter 1), **Discard the draft** and restart from scratch, **Leave-and-lower-priority** (skip the dirty paths and work the next backlog item that doesn't touch them), **Halt the loop** (too much dirty state to proceed non-interactively). Route the chosen branch before opening Step 1.
- **Non-interactive / AFK** (default for this skill per JTBD-006): do NOT call `AskUserQuestion`. Halt the loop with the structured Prior-Session State report in the AFK summary. Per ADR-013 Rule 6 fail-safe: ambiguous session-continuity state requires user input; non-interactive recovery would mask the bug this check is meant to surface. This matches Step 6.75's "dirty for unknown reason → halt" stance at the Step 0 layer — the orchestrator does not silently proceed past partial work.

Step 6.75 treats a Step-0-resolved-with-user-confirmation state as `dirty-for-known-reason`: if the interactive branch's Resume option landed the drafted ADR as iter 1, the iter's commit clears the dirty state and the rest of the loop proceeds normally.

### Step 1: Scan the backlog

Read `docs/problems/README.md` if it exists and is fresh (check via git history — see manage-problem step 9 for the cache freshness check). If stale or missing, scan all `.open.md` and `.known-error.md` files in `docs/problems/`, extract their WSJF scores, and rank them.

Exclude:
- `.closed.md` files (done)
- `.parked.md` files (blocked on upstream)
- `.verifying.md` files (Verification Pending — fix released, awaiting user verification per ADR-022; surfaced in the Verification Queue section, never in dev-work ranking)
- Problems with no WSJF score (need a review first — run `/wr-itil:manage-problem review` as the first iteration if scores are missing)

### Step 2: Check stop conditions

Stop the loop and report a summary if any of these are true:

1. **No actionable problems** — zero open or known-error problems remain
2. **All remaining problems require interactive input** — e.g., they all need user verification (known-errors with `## Fix Released`), or their scope expanded beyond what's safe to auto-resolve
3. **All remaining problems are blocked** — investigation hit a dead end, or the fix requires changes outside the project

When stop-condition #2 fires, do not jump straight to `ALL_DONE` — run Step 2.5 first to surface the outstanding questions.

For stop-conditions #1 and #3 (no questions to ask), skip Step 2.5 and emit the summary + `ALL_DONE` directly.

### Step 2.5: Surface outstanding design questions (P053, fires only for stop-condition #2)

The skipped tickets that triggered stop-condition #2 frequently carry **user-answerable design questions** (naming, direction, pacing, scope) whose answers would unblock the next AFK loop. The information the user needs to answer is fully known at stop time, so there is no cost to surfacing the questions before the terminal `ALL_DONE` emit.

**1. Extract the question set.** For every skipped ticket whose classifier skip-reason is `user-answerable` (see Step 4's taxonomy), extract its outstanding question(s) from the ticket body — typically from a "Pacing decision", "Naming decision", or outstanding "Investigation Tasks" section. Cap at 4 questions per `AskUserQuestion` call per Anthropic's tool documentation.

**2. Branch on interactivity per ADR-013 Rule 1 / Rule 6.**

- **Interactive invocation** (AskUserQuestion is available AND the loop was not started in AFK mode): batch the questions into one `AskUserQuestion` call (or more, if >4 questions, issued sequentially). Header: `"Outstanding design questions"`. For each question, set the prompt from the extracted text and the options from the ticket's candidate fixes or option list. Write each answer back to the corresponding ticket file so the next AFK loop does not re-ask.
- **Non-interactive / AFK invocation** (default for this skill per JTBD-006 — the persona is AFK): do NOT call `AskUserQuestion`. Instead emit an `### Outstanding Design Questions` section in the post-stop summary listing each question with its Ticket ID, the question text, and one-line context. The user answers on return.

This branch is the Rule 6 fail-safe applied to stop-condition #2: Rule 1 says route governance decisions through `AskUserQuestion`; Rule 6 says fall back to a structured summary when the tool is unavailable or the user is away. JTBD-006's persona constraint ("autonomously work without needing interactive input") makes the non-interactive path the default for this skill — AskUserQuestion is the exception, not the rule.

**3. Emit the final summary + `ALL_DONE`.** The summary includes the Outstanding Design Questions table when any user-answerable questions were surfaced (see Output Format).

```
ALL_DONE
```

This sentinel line allows external scripts to detect completion.

### Step 3: Pick the highest-WSJF problem

Select the problem with the highest WSJF score. If there's a tie, prefer:
1. Known Errors over Open problems (they have a confirmed fix path — less risk of wasted effort)
2. Smaller effort over larger (faster throughput)
3. Older reported date (longer wait = higher urgency)

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
| Open problem blocked on upstream dependency or Claude Code capability gap | **Skip** — but first append the pending-upstream-report marker to the ticket's `## Related` section (see P063 — run the manage-problem SKILL.md external-root-cause detection AFK fallback before skipping). The marker wording is fixed: `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready`. Use the already-noted check to avoid duplicates. | upstream-blocked |

The default is to work the problem. Only skip when the rule explicitly says so. This is an AFK loop — forward progress matters more than avoiding dead ends, because dead ends are cheap (findings are saved) and interactive input is expensive (user is absent).

**Skip-reason taxonomy.** Every skipped ticket is tagged with one of three categories so Step 2.5 can select which ones to surface as questions:

- **user-answerable** — the user can answer directly (verification, naming, direction, pacing, scope). Step 2.5 surfaces these as questions (interactive) or in the Outstanding Design Questions table (non-interactive / AFK).
- **architect-design** — requires architect judgment first; may escalate to a new ADR. Step 2.5 can optionally pre-trigger the architect agent in `--deep-stop` mode to produce a concrete user-answerable question. Otherwise noted as "pending architect review".
- **upstream-blocked** — external dependency, Claude Code capability gap, or waiting on third-party fix. Truly terminal for this loop — no user question would change anything. Report the blocker and move on. **Before skipping, run the manage-problem external-root-cause detection AFK fallback** (per P063): grep the ticket for the stable marker `- **Upstream report pending** —` or `- **Reported Upstream:**` / a `## Reported Upstream` section; if none is present, append `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` to the ticket's `## Related` section. This preserves the outbound audit trail across AFK iterations so the user can see the deferred action on return.

Record the category alongside the skip reason in the iteration report so Step 2.5 can read the categories deterministically.

**Time-box each problem** to avoid runaway investigation: the delegated `manage-problem` skill's internal logic decides scope. If investigation reveals the scope has grown (e.g., effort was estimated S but turns out to be L or XL), save findings to the problem file, update the WSJF score, and move to the next problem. Never sink unbounded effort into one problem during AFK mode.

If a problem is skipped by this step, add it to a "skipped" list with the reason and loop back to step 3 for the next one.

### Step 5: Work the problem (dispatch via `claude -p` subprocess, per P084)

**Dispatch each iteration to a fresh `claude -p` subprocess via Bash** — do NOT spawn via the Agent tool, do NOT invoke `/wr-itil:manage-problem` inline via the Skill tool.

- **Skill-tool inline invocation** expands manage-problem's SKILL.md (500+ lines) into the main orchestrator's context every iteration, accumulates across the AFK loop, and causes silent early-stop (`ALL_DONE` without a documented stop condition firing). This was the original pre-P077 failure mode.
- **Agent-tool dispatch to a `general-purpose` subagent** (the P077 amendment) works for context isolation but fails at the governance-gate layer: subagents spawned via the Agent tool do NOT have the Agent tool in their own surface (three-source evidence — ToolSearch probe, Claude Code docs at `code.claude.com/docs/en/subagents.md`, empirical runtime error `"No such tool available: Agent. Agent is not available inside subagents."`). Without Agent, the iteration worker cannot set architect + JTBD PreToolUse edit-gate markers (only settable via Agent-tool PostToolUse hook), cannot satisfy the risk-scorer commit gate, and silently halts on every gate-covered iteration. P084 diagnoses and closes this gap.
- **`claude -p` subprocess dispatch** (this step, per P084 / ADR-032 amendment): the subprocess is a full main Claude Code session with Agent available in its own surface. Governance review runs at full depth via the normal `wr-architect:agent` / `wr-jtbd:agent` / `wr-risk-scorer:pipeline` delegation path inside the subprocess; PostToolUse marker hooks fire correctly matching the subprocess's own `$CLAUDE_SESSION_ID`; the commit gate unlocks natively. Context isolation preserved by the process boundary (each subprocess is a distinct process with its own session state; orchestrator's main context only sees the stdout). This is the AFK iteration-isolation wrapper — subprocess-boundary variant under ADR-032.

**Dispatch command shape (Bash):**

```bash
ITERATION_PROMPT=$(cat <<'PROMPT_EOF'
<iteration prompt body — see below>
PROMPT_EOF
)

claude -p \
  --permission-mode bypassPermissions \
  --output-format json \
  "$ITERATION_PROMPT"
```

**Flag rationale:**

- `--permission-mode bypassPermissions` — handles non-interactive permission prompts. Without this, Bash/Edit/Write calls inside the subprocess halt on approval prompts (no TTY). Alternative modes (`acceptEdits`, `auto`, `dontAsk`) are acceptable if adopters need narrower permission scopes; `bypassPermissions` is the broadest and the empirically-verified path.
- `--output-format json` — deterministic structured output. The subprocess's final agent message lands in the JSON response's `.result` field; orchestrator extracts `ITERATION_SUMMARY` from that field. Plain-text output would require fragile scraping.

**No per-iteration budget cap.** The dispatch deliberately omits `--max-budget-usd`. Per user direction 2026-04-21: the natural stop condition for an AFK loop is quota exhaustion, not an arbitrary per-iteration dollar cap. A cap would halt iterations before quota is actually exhausted, wasting remaining budget. Runaway-iteration risk is bounded by quota + the orchestrator's Step 6.75 halt on unexpected dirty state + exit-code handling below.

**Iteration prompt body (self-contained — the subprocess has no prior conversation context):**

1. **Context**: this is one iteration of the AFK work-problems loop. The user is AFK. The orchestrator selected `P<NNN> (<title>)` as the highest-WSJF actionable ticket.
2. **Task**: apply the `/wr-itil:manage-problem` workflow for `work highest WSJF problem that can be progressed non-interactively as the user is AFK`. Follow manage-problem SKILL.md verbatim, including architect / jtbd / style-guide / voice-tone gate reviews and the commit gate (manage-problem Step 11). Because this subprocess has the Agent tool in its own surface, the normal review-via-subagent paths work — no inline-verdict fallback needed.
3. **Constraints**: commit the completed work per ADR-014. Do NOT push, do NOT run `push:watch`, do NOT run `release:watch` — the orchestrator's Step 6.5 owns release cadence. Do NOT invoke `capture-*` background skills (AFK carve-out — ADR-032). Do NOT use `ScheduleWakeup` under any circumstance (P083 — iteration workers must not self-reschedule). Non-interactive defaults apply per ADR-013 Rule 6.
4. **Retro-on-exit (P086)**: before emitting `ITERATION_SUMMARY`, invoke `/wr-retrospective:run-retro`. Retro runs INSIDE this subprocess so its Step 2b pipeline-instability scan has access to the iteration's rich tool-call history (hook misbehaviour, repeat-workaround patterns, subagent-delegation friction, release-path instability). Retro may create tickets or update `docs/BRIEFING.md` — run-retro commits its own work per ADR-014; any tickets it creates ride into either the iteration's own commit (if retro runs before the main commit) or a retro-owned follow-up commit, and the orchestrator picks them up on the next Step 1 scan. Proceed to `ITERATION_SUMMARY` emission regardless of retro findings — retro is non-blocking (do not block on retro): if retro fails or surfaces findings, the iteration still returns a summary so the AFK loop does not silently halt on a flaky retro run.
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
outstanding_questions: [<one-line each>]           # optional; drives Step 2.5 when skip_reason_category=user-answerable
remaining_backlog_count: <N>
notes: <one-line>
```

Architect review (R2) requires the commit state fields (`committed` / `commit_sha` / `reason`) so **Step 6.75's Dirty-for-known-reason branch stays evaluable** from the summary alone. JTBD review requires `ticket_id` / `action` / `skip_reason_category` / `outstanding_questions` so Step 2.5 and the Output Format's Completed / Skipped / Outstanding Design Questions tables can be populated deterministically without the orchestrator having to re-parse ticket files.

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

**Exit-code semantics.** `claude -p` exits non-zero when the subprocess fails hard — subprocess crash, auth failure, unresolvable permission denial, API/quota exhaustion. The orchestrator reads the exit code BEFORE parsing `.result`:

- Exit 0 → parse `ITERATION_SUMMARY` from `.result` field; proceed to Step 6.
- Non-zero exit → halt the loop; report the exit code, stderr, and any partial `.result` in the final summary. Do NOT spawn the next iteration. The user returns to a stopped loop with a clear failure reason (e.g. "quota exhausted — resume when quota resets").

**Quota as the natural stop.** The AFK loop runs until quota is exhausted or a stop-condition from Step 2 fires. There is no per-iteration dollar cap; running iterations until quota is actually exhausted maximises backlog progress per quota cycle. Quota-exhaust on a `claude -p` invocation surfaces as a non-zero exit and the orchestrator halts cleanly per the rule above.

**Hook session-id isolation.** Each `claude -p` subprocess has its own `$CLAUDE_SESSION_ID`. Gate markers at `/tmp/architect-reviewed-<ID>`, `/tmp/jtbd-reviewed-<ID>`, `/tmp/risk-scorer-*-<ID>` are scoped to the subprocess's own hook interactions and never shared with the orchestrator's main-turn SESSION_ID. This is the correct behaviour — the orchestrator's main turn runs its own gate flow if it edits gated paths; the subprocess's gate flow is independent. Implementations MUST NOT wire cross-process marker sharing.

**Inter-iteration continuity.** Step 6.5 (release-cadence check) and Step 6.75 (inter-iteration verification) stay in the **main orchestrator's turn**, NOT the iteration subprocess. Rationale: release-cadence and `git status --porcelain` are orchestration-level concerns; `push:watch`/`release:watch` are long-running waits that would waste iteration-subprocess context; the orchestrator needs to see the summary from one iteration before deciding whether to drain before the next. Orchestrator detects subprocess commits by reading the working tree (`git status --porcelain`) and the parsed `ITERATION_SUMMARY.commit_sha` — not session-state continuity with the subprocess.

The manage-problem skill (running inside the iteration subprocess) will:

- Run a review if the cache is stale.
- Select and work the highest-WSJF problem.
- Use its built-in non-interactive fallbacks (auto-split multi-concern problems, auto-commit when risk is within appetite).
- Delegate architect / JTBD / risk-scorer reviews via the Agent tool (available in the subprocess's surface) at the depth defined in each review skill's SKILL.md.
- Commit completed work per ADR-014 (the iteration subprocess's commit inside its own session — the orchestrator does NOT commit from its main turn).

### Step 6: Report progress

After each iteration, report:
- Which problem was worked (ID + title)
- What was done (investigated, transitioned to known-error, fix implemented, etc.)
- The outcome (success, partially progressed, skipped, scope expanded)
- How many problems remain in the backlog
- The iteration's cost metadata — format: `($<cost>, <duration_s>s, <total_tokens_K>K tokens)`. Cost comes from the `.total_cost_usd` field extracted in Step 5; duration from `.duration_ms`; total tokens is the sum of `.usage.input_tokens + .usage.output_tokens + .usage.cache_creation_input_tokens + .usage.cache_read_input_tokens`.

Format as a brief status line, not a wall of text. The user will read these when they return.

**Example:**
```
[Iteration 1] Worked P029 (Edit gate overhead for governance docs) — implemented fix, closed. 8 problems remain. ($0.32, 23s, 171K tokens)
[Iteration 2] Worked P021 (Governance skill structured prompts) — investigated root cause, transitioned to known-error. 7 problems remain. ($0.85, 47s, 432K tokens)
[Iteration 3] Skipped P016 (Multi-concern ticket splitting) — fix released, awaiting user verification. Worked P024 (Risk scorer WIP flag) — implemented fix, closed. 6 problems remain. ($1.12, 62s, 541K tokens)
```

### Step 6.5: Release-cadence check (per ADR-018, above-appetite branch per ADR-042)

After the iteration's commit lands but before starting the next iteration, check whether the unreleased queue would push pipeline risk to or above appetite. This prevents silent accumulation of unreleased changesets across AFK iterations (P041). **The orchestrator MUST NOT release above appetite under any circumstance** — above-appetite states route to the ADR-042 auto-apply loop or halt.

**Mechanism — delegate, do not re-implement scoring:**

1. Invoke the risk scorer to score cumulative pipeline state. Two paths are valid (per ADR-015):
   - **Primary**: delegate to subagent type `wr-risk-scorer:pipeline` via the Agent tool.
   - **Fallback**: if that subagent type is not available, invoke skill `/wr-risk-scorer:assess-release` via the Skill tool. The skill wraps the same pipeline subagent.
2. Read the returned `RISK_SCORES: commit=X push=Y release=Z` line and the `RISK_REMEDIATIONS:` block (if present).
3. **Classify the residual**:
   - **Within appetite (≤ 3/25)** — no drain needed. Proceed to Step 6.75.
   - **At appetite (= 4/25)** — drain the queue per the Drain action below, then proceed to Step 6.75.
   - **Above appetite (≥ 5/25)** — route to the **Above-appetite branch** below. Do NOT drain. Do NOT proceed to Step 6.75 until either (a) the auto-apply loop re-converges within appetite and drain succeeds, or (b) Rule 5 halt fires.

**Drain action (non-interactive, policy-authorised per ADR-013 Rule 6):**

1. Run `npm run push:watch` (push + wait for CI to pass).
2. If `.changeset/` is non-empty after push, run `npm run release:watch` (merge the release PR + wait for npm publish).
3. Resume the loop only after the release lands on npm.

**Failure handling**: If `release:watch` fails (CI failure, publish failure), stop the loop and report the failure in the AFK summary. Do not retry non-interactively — the user must intervene.

`push:watch` and `release:watch` are policy-authorised actions when residual risk is within appetite per RISK-POLICY.md, so no `AskUserQuestion` is required for the drain itself (ADR-013 Rule 5).

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
| Dirty for an unknown reason | Neither of the above — the subagent reported success but the tree is not clean, or the tree is dirty without a documented reason in the iteration report | **Halt the loop.** Report the `git status --porcelain` output, the last subagent's reported outcome, and the divergence. Do NOT spawn the next iteration. |

**Rationale**: the orchestrator previously treated the subagent's reported outcome as truth. Any lie, partial write, or silent failure in the subagent propagated into the summary. The `git status --porcelain` check is the cheapest possible independent verification — policy-authorised, no network, no judgement required — and it catches exactly the class of failure the subagent cannot self-report.

**Out of scope for this step**: attempting recovery from an unknown-reason dirty state. Per ADR-013 Rule 6, conflict resolution and ambiguous state require user input; non-interactive recovery would mask the bug this check is meant to surface.

### Step 7: Loop

Go back to step 1. The backlog may have changed — new problems may have been created during fixes, priorities may have shifted, and the README.md cache will be stale.

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
| Pipeline risk at appetite (push or release = 4/25) | Drain release queue (`push:watch` then `release:watch`) before next iteration — per ADR-018 (Step 6.5) |
| Pipeline risk above appetite (push or release >= 5/25) | Auto-apply scorer remediations incrementally (ADR-042 Rule 2). The agent reads suggestions and decides what to do. Re-score after each apply; drain when within appetite. **Never release above appetite** (ADR-042 Rule 1) — no AskUserQuestion shortcut. Halt the loop with `outcome: halted-above-appetite` if the loop exhausts without convergence (ADR-042 Rule 5). Verification Pending commits excluded from auto-revert (Rule 2b). Per ADR-042 (Step 6.5 Above-appetite branch). |
| Origin diverged before start | Pull `--ff-only` if trivial; stop with report (`git log HEAD..origin/<base>` and reverse) if non-fast-forward — per ADR-019 (Step 0) |
| Prior-session partial work detected at start (session-continuity dirty: untracked `docs/decisions/*.proposed.md` / `docs/problems/*.md`, `.afk-run-state/iter-*.json` with `is_error: true` or `api_error_status >= 400`, stale `.claude/worktrees/*`, uncommitted SKILL.md/source/ADR edits) | Halt the loop with a structured Prior-Session State report in the AFK summary. Do NOT attempt non-interactive resume. Interactive invocations prompt via `AskUserQuestion` with 4 options (resume / discard / leave-and-lower-priority / halt). Per P109 + ADR-013 Rule 6 (Step 0 session-continuity detection pass). |
| Fix verification needed | Skip problem, add to "needs verification" list |
| Stop-condition #2 with user-answerable skip-reasons | Emit Outstanding Design Questions table in summary (do NOT call AskUserQuestion). The persona is AFK by definition — per JTBD-006 and ADR-013 Rule 6 — so the table is the default. Interactive invocations may batch up to 4 questions through AskUserQuestion instead — per ADR-013 Rule 1 (Step 2.5). |
| Unexpected dirty state between iterations | Halt the loop. Report the `git status --porcelain` output, the last iteration's reported outcome, and the divergence — per P036 (Step 6.75). Do NOT attempt non-interactive recovery. |
| External root cause detected at Open → Known Error, or at park with `upstream-blocked` reason | Append the stable `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` marker to the ticket's `## Related` section; do NOT auto-invoke `/wr-itil:report-upstream` (Step 6 security-path branch is interactive — per ADR-024 Consequences). Use the already-noted grep check to avoid duplicate lines. Per P063 + ADR-013 Rule 6. |

## Edge Cases

**Review needed first**: If no problems have WSJF scores, run `/wr-itil:manage-problem review` as the first iteration to score everything, then proceed to the work loop.

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

When every skipped ticket is in the `upstream-blocked` category (stop-condition #3) or there are no skipped tickets (stop-condition #1), omit the Outstanding Design Questions section entirely rather than rendering an empty heading. The Session Cost section always renders when at least one iteration ran.

## Related

- **P086** (`docs/problems/086-afk-iteration-subprocess-does-not-run-retro-before-returning.verifying.md`) — driver for Step 5's retro-on-exit clause. Iteration subprocesses exit without running retro, so per-iteration friction (hook misbehaviour, repeat-workaround patterns, pipeline instability) evaporates on exit. Fix: iteration prompt body names `/wr-retrospective:run-retro` as a closing step before `ITERATION_SUMMARY` emission; retro runs inside the subprocess so Step 2b pipeline-instability scan has the full tool-call history; run-retro commits its own work per ADR-014; orchestrator picks up retro-created tickets on the next Step 1 scan.
- **P084** (`docs/problems/084-work-problems-iteration-worker-has-no-agent-tool-so-architect-jtbd-gates-block.open.md`) — driver for Step 5's subprocess-boundary dispatch. Supersedes P077's Agent-tool dispatch on the same Step 5 surface because Agent-tool-spawned subagents cannot themselves invoke Agent (platform restriction), which prevents governance gate markers from being set inside the iteration worker.
- **P077** (`docs/problems/077-work-problems-step-5-does-not-delegate-to-subagent.verifying.md`) — parent amendment. Established the AFK iteration-isolation wrapper sub-pattern and the `ITERATION_SUMMARY` return contract. P084 is the refinement that swaps the spawn mechanism; the isolation intent and return contract are preserved verbatim.
- **P083** (`docs/problems/083-work-problems-iteration-worker-prompt-does-not-forbid-schedulewakeup.open.md`) — iteration prompt body forbids `ScheduleWakeup`. Applies equally to subprocess-dispatched iterations.
- **P036** — inter-iteration verification (Step 6.75); remains in the orchestrator's main turn.
- **P040** — origin-fetch preflight (Step 0); unchanged.
- **P109** — session-continuity detection pass added to Step 0 after the fetch/divergence check. Enumerates five signals (untracked `docs/decisions/*.proposed.md`, untracked `docs/problems/*.md`, `.afk-run-state/iter-*.json` error markers, stale `.claude/worktrees/*` dirs, uncommitted SKILL.md/source/ADR edits). Routes interactive via `AskUserQuestion` with 4 options, AFK via halt-with-report per ADR-013 Rule 6.
- **P041** — release-cadence drain (Step 6.5); remains in the orchestrator's main turn.
- **P053** — Outstanding Design Questions surfacing at stop-condition #2 (Step 2.5); fed by the iteration subagent's `outstanding_questions` field.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 6 non-interactive fail-safe applies to every iteration-subagent decision surface.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — preserved under the iteration subagent; the subagent commits its own work.
- **ADR-015** (`docs/decisions/015-on-demand-assessment-skills.proposed.md`) — Agent-tool-vs-Skill-tool delegation precedent (Step 6.5's wording mirror).
- **ADR-018** (`docs/decisions/018-release-cadence.proposed.md`) — release cadence stays in the orchestrator's main turn, not the iteration subagent.
- **ADR-019** (`docs/decisions/019-afk-orchestrator-preflight.proposed.md`) — preflight stays in the orchestrator's main turn.
- **ADR-022** (`docs/decisions/022-problem-verification-pending.proposed.md`) — iteration outcomes map into the return-summary's `outcome` field (`verifying` for a released fix, `known-error` for a root-cause-confirmed ticket awaiting release, etc.).
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — pattern taxonomy parent; Step 5 implements the AFK iteration-isolation wrapper — subprocess-boundary variant per the P084 amendment (2026-04-21), refining the P077 Agent-tool amendment. The P077 amendment remains in the ADR as the historical Agent-tool variant; the subprocess variant is the lead for new adopters.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — doc-lint bats contract-assertion pattern used by `test/work-problems-step-5-delegation.bats`.
- **JTBD-001**, **JTBD-006**, **JTBD-101**, **JTBD-201** — personas whose reliability expectations the iteration-isolation wrapper restores.
