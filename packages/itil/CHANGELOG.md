# @windyroad/problem

## 0.19.4

### Patch Changes

- 9c50d03: `docs/problems/README.md` now self-heals from cross-session drift (P118).

  A new diagnose-only script `packages/itil/scripts/reconcile-readme.sh` checks
  the README's WSJF Rankings, Verification Queue, and Closed sections against
  the on-disk ticket files (`docs/problems/<NNN>-*.<status>.md`). Exit codes:
  0 = clean, 1 = drift detected (one structured row per drift entry to stdout,
  ≤150 bytes per ADR-038 progressive-disclosure budget), 2 = parse error.

  A new skill `/wr-itil:reconcile-readme` wraps the script with an agent-applied-
  edits pattern that preserves the README's narrative content (the "Last reviewed"
  prose paragraph at the top and the per-row closure-via free text in the Closed
  section). Full README regeneration is forbidden — narrative content is human-
  curated session memory.

  Two preflight invocation surfaces fire the script before doing anything else:

  - `/wr-itil:manage-problem` Step 0 — halt-with-directive on drift before parsing
    the request, so ticket creation / update / transition never proceeds against
    a stale README that would re-encode the lie into the post-operation refresh.
  - `/wr-itil:work-problems` Step 0 — auto-apply via `/wr-itil:reconcile-readme`
    in AFK mode (per ADR-013 Rule 6) so the orchestrator's Step 3 ranking reads
    ground truth.

  `/wr-itil:transition-problem` deliberately does NOT invoke the script — P062's
  existing transition-time refresh inside the same commit already covers that
  surface; redundant preflight there would pay the cost on every transition.

  This is a robustness layer ON TOP of P094 (refresh-on-create, Closed) and P062
  (refresh-on-transition, Closed) — both per-operation contracts remain in force.
  The reconciliation contract catches drift introduced by past sessions where the
  single-commit-transaction discipline was skipped (bug, partial-progress hand-
  off, conflict resolution, etc.) and that no per-operation contract can
  retroactively detect or correct.

  ADR-014 amended with a "Reconciliation as preflight robustness layer" sub-rule
  (P118, 2026-04-25). ADR-022 Confirmation criterion 3 extended with a
  reconciliation invariant cross-referencing the new script.

## 0.19.3

### Patch Changes

- 22b9a17: P078 — Hook now offers ticket capture on strong-signal correction.

  A new `UserPromptSubmit` hook (`itil-correction-detect.sh`) detects strong-affect correction signals in the user's prompt — `FFS`, all-caps imperatives (`DO NOT`, `DON'T`, `STOP`), direct contradiction (`that's wrong`, `you're not listening`), exasperation markers (`!!!`), meta-correction (`you always`, `you never`, `you keep`) — and injects a `MANDATORY` reminder telling the assistant to OFFER `/wr-itil:capture-problem` (with `/wr-itil:manage-problem` as today's fallback) BEFORE addressing the operational request. Once-per-session full block + terse-reminder pattern (ADR-038).

  Without this, strong-signal corrections decay with session context and the same class-of-behaviour pattern recurs next session, with the user having to manually request the ticket every time.

  Pattern vocabulary lives in `packages/itil/hooks/lib/detectors.sh::CORRECTION_SIGNAL_PATTERNS`. Detection is intentionally aggressive (case-insensitive); false positives degrade gracefully (one extra advisory line — the offer is non-blocking).

## 0.19.2

### Patch Changes

- 84124f6: `/wr-itil:report-upstream` gains Step 4b dedup + Step 5c comment path (P070): close the two duplication windows that were the skill's most externally-visible failure mode. Step 4b.1 own re-run check greps the local ticket for an existing `## Reported Upstream` URL and halts-and-surfaces if present. Step 4b.2 third-party search uses `gh issue list --repo <upstream> --search "<keywords>" --state all --json ... --limit 10` as a cheap pre-filter, then performs an inline LLM semantic match against each candidate's body via `gh issue view <n> --json body,title` (no subagent dispatch — per Direction decision 2026-04-21, the gh-search prefilter trims input to ~5-10 candidates which keeps the inline check affordable). Step 5c comment path lands cross-references via `gh issue comment <n>` when a dedup match is selected, and the local ticket records `Disclosure path: commented-on-existing-issue <URL>` in `## Reported Upstream` rather than `public issue`.

  **Modified files:**

  - `packages/itil/skills/report-upstream/SKILL.md` — adds Step 4b (own re-run + third-party search branches), Step 5c (comment path), and extends Step 7 disclosure-path enumeration with `commented-on-existing-issue`.
  - `docs/decisions/024-cross-project-problem-reporting-contract.proposed.md` — Decision Outcome adds Step 4b + Step 5c; Out-of-scope dedup bullet narrowed to residual `update-mode`; Confirmation criterion 2 gains the new bats coverage line; Related lists P070 as driver.
  - `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — 9 new behavioural assertions (Step 4b presence, own-re-run detection language, third-party `gh issue list --search` language, Step 5c comment-path, AFK halt-and-save behaviour, disclosure-path enumeration); file 24/24 green.

  **AFK behaviour (interim):** halt-and-save the drafted report to the local ticket's `## Drafted Upstream Report` section per ADR-013 Rule 6. The maintainer-annoyance risk evaluator that would gate auto-comment is **DEFERRED** to compose with `wr-risk-scorer:external-comms` per ADR-028 line 117 — keeps P070 effort at M and avoids cross-cutting work blocking on P064. When P064 lands, a follow-up bundling commit will wire the maintainer-annoyance evaluator + P064 leak gate together so the AFK auto-comment branch can fire at appetite.

  **Architect verdict**: PASS x3 (overall shape, bats, ADR-024 amendment) — confirmed inline LLM check (no subagent) is the right scope and that maintainer-annoyance evaluator deferral is the right architectural call. **JTBD verdict**: PASS — JTBD-004 primary fit (cross-repo coordination protected from spam); JTBD-001 / JTBD-006 / JTBD-101 protected by halt-and-surface fallback. **Risk**: 2/25 Very Low; reduces silent-duplicate risk on the report-upstream surface.

  P070 (Open → Verification Pending). Verification path: exercise the skill twice against the same upstream + local ticket (4b.1 should halt on second run); exercise against an upstream with overlapping existing issues (4b.2 should offer comment path or halt-and-save in AFK).

- ccc8ffc: `/wr-itil:manage-problem` Step 2 duplicate-check enforcement (P119): close the structural gap that lets agents bypass the duplicate-prevention grep by writing tickets directly to `docs/problems/` via the Write tool. Adds a `PreToolUse:Write` hook that gates new-file creation under `docs/problems/<NNN>-*.<status>.md` on a per-session marker set by Step 2. Without the marker the agent gets a `permissionDecision: deny` directing them back into the skill — where Step 2 grep + `AskUserQuestion` for matches fires before the new file lands.

  **New files:**

  - `packages/itil/hooks/manage-problem-enforce-create.sh` — PreToolUse:Write hook. Matches `docs/problems/<NNN>-*.<status>.md` new-file paths (numeric-prefix basename test, ADR-031 forward-compat). Allow-lists `docs/problems/README.md` (chicken-and-egg — regenerated by Steps 5/6/7) and existing files (Edit-flow / status transitions). Only Write is gated; Edit on existing tickets is the transition-problem surface.
  - `packages/itil/hooks/lib/create-gate.sh` — sibling of `lib/review-gate.sh`. Different semantics (no TTL drift detection — the marker is just "Step 2 ran for this session"), so kept separate per architect direction. Per-session scope (`/tmp/manage-problem-grep-${SESSION_ID}`) — single marker covers all new tickets in a skill invocation, enabling Step 4b multi-concern split without re-grep blocking.
  - `packages/itil/hooks/test/manage-problem-enforce-create.bats` — 16 behavioural assertions (deny path, allow path, multi-concern split compatibility, README exemption, Edit-flow exemption, status-suffix coverage, ADR-031 forward-compat, marker hygiene).

  **Modified files:**

  - `packages/itil/hooks/hooks.json` — registers the new `PreToolUse:Write` matcher.
  - `packages/itil/skills/manage-problem/SKILL.md` Step 2 — adds substep 7: write the create-gate marker after the grep completes. Adds a "Hook contract (P119)" callout explaining the deny shape and warning against manual marker-setting.

  **Architect verdict**: APPROVED — fits ADR-009 gate-marker lifecycle + ADR-038 progressive disclosure without amendment; per-session marker scope confirmed; ADR-031 forward-compat advisory addressed in matcher. **JTBD verdict**: PASS — closes JTBD-001 governance-skip pain point; preserves JTBD-006 AFK queue integrity; protects JTBD-201 audit trail. **Tests**: 38/38 itil hooks; 876/876 full suite; no regressions.

  P119 (Open → Verification Pending).

## 0.19.1

### Patch Changes

- cbf178e: work-problems Step 5 dispatch robustness (P089): two bounded refinements within the shipped 0.13.0 `claude -p` subprocess dispatch + 0.14.0 cost-metadata extraction contract — no ADR amendment, no CLI change.

  **Gap 1 — stdin-warning redirect.** The canonical Step 5 dispatch command now ends with `< /dev/null` to suppress the `claude -p` 3-second stdin-wait warning. The warning is emitted to stderr, which is fine when streams are consumed separately; under the orchestrator's `2>&1` merge (required to keep stderr prose from interleaving between chained invocations) the warning prefixed stdout and broke `jq` / `json.load` / `JSON.parse` extraction of `.result` and cost metadata. The redirect is the Anthropic CLI help's own suggested workaround. First observed AFK-iter-7 iter 1 (2026-04-21); iter 2-7 used the workaround.

  **Gap 2 — authority hierarchy for cost vs usage.** Added an Authority hierarchy paragraph to the Per-iteration cost metadata block and a matching Authority note to the Output Format Session Cost section. `.total_cost_usd` is cumulative-authoritative by CLI contract and is the trusted dollar signal; `.usage.*` is a per-turn response envelope and can reflect only the final-turn ack when the subprocess exits via a background-task completion notification — observed AFK-iter-7 iter 5 where a 1071s wall-clock / 60+ tool-use run reported `duration_ms: 8546, num_turns: 1, usage.* ≈ 137K tokens, total_cost_usd: 6.08` (cost correct, tokens final-turn-only). Session Cost output now renders the cost column as authoritative and labels token totals best-effort. Detection criterion (final-turn-sized usage alongside wall-clock-orders-of-magnitude-larger-than-`duration_ms`) stated descriptively; no change to the named-field extraction list.

  No SKILL.md contract break; no runtime behaviour change in the orchestrator. Tests: 6 new assertions in `work-problems-step-5-delegation.bats` (30/30 passing).

## 0.19.0

### Minor Changes

- 77f0542: P109: work-problems Step 0 preflight detects prior-session partial-work state

  `/wr-itil:work-problems` Step 0 (AFK orchestrator preflight) gains a **session-continuity detection pass** after the existing `git fetch origin` + divergence check. This closes the gap where an AFK loop restarted after a quota (429) / error / user-cancel would silently iterate past partial work left in the working tree.

  **Signals enumerated** (each maps to one `git status --porcelain` / filesystem / `git worktree` probe):

  - Untracked `docs/decisions/*.proposed.md` — drafted but unlanded ADRs from a prior iter.
  - Untracked `docs/problems/*.md` — drafted but unlanded problem tickets.
  - `.afk-run-state/iter-*.json` files with `"is_error": true` OR `"api_error_status" >= 400` — prior iteration hit quota or API error (ADR-032 subprocess artefact contract). Success files (`"is_error": false`) are ignored.
  - Stale `.claude/worktrees/*` directories + matching `git worktree list` entries on `claude/*` branches — prior subagent worktrees not cleaned up. Detection only — mutation/cleanup is out of scope and would require a separate ADR.
  - Uncommitted modifications to `packages/*/skills/*/SKILL.md`, `packages/*/hooks/*`, `docs/decisions/*.proposed.md`, or other source paths the prior session was mid-authoring.

  **Routing per ADR-013 Rule 1 / Rule 6**:

  - **Interactive**: `AskUserQuestion` with 4 options — **Resume the prior work** (land drafted files as iter 1), **Discard the draft**, **Leave-and-lower-priority** (skip the dirty paths), **Halt the loop**.
  - **Non-interactive / AFK** (default for this skill per JTBD-006): halt the loop with a structured Prior-Session State report in the AFK summary. Matches Step 6.75's "dirty for unknown reason → halt" stance at the Step 0 layer — the orchestrator does not silently proceed past partial work.

  **Surfaces**:

  - `packages/itil/skills/work-problems/SKILL.md` Step 0 — adds the session-continuity detection subsection plus a decision-matrix row in the Non-Interactive Decision Making table.
  - `docs/decisions/019-afk-orchestrator-preflight.proposed.md` — extended (within its 2026-07-18 reassessment window); no new ADR created. Confirmation criterion 5 added for the contract-assertion bats.
  - `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats` — 16 contract-assertion tests per ADR-037 covering signal enumeration, interactive/AFK routing, and the decision-matrix row.

  Closes P109 → Verification Pending.

## 0.18.1

### Patch Changes

- b2424c8: P113: declare `Skill, Agent` in `wr-itil:report-upstream` allowed-tools

  The `report-upstream` skill body (`packages/itil/skills/report-upstream/SKILL.md` Step 9 / line 330) invokes the `wr-risk-scorer:pipeline` subagent (requires the `Agent` tool) and falls back to `/wr-risk-scorer:assess-release` per ADR-015 (requires the `Skill` tool). Neither was declared in the SKILL.md frontmatter `allowed-tools` field. `report-upstream` was the only itil skill that declared `AskUserQuestion` without also declaring `Skill` — and the only itil skill missing from Claude Code's TUI slash-command autocomplete despite being present in the agent-side skill enumerator.

  Candidate mechanism (to confirm post-release per the verification path on P113): Claude Code's TUI autocomplete appears to validate declared-vs-used tools in skill frontmatter and silently drop skills whose bodies invoke tools not declared in `allowed-tools`, while the server-side enumerator (which populates the agent's available-skills list) is more lenient. If the hypothesis holds, adding `Skill, Agent` restores `/wr-itil:report-upstream` to the autocomplete surface without changing runtime behaviour. If the hypothesis is wrong, P113 reopens for upstream escalation to Anthropic.

  Closes P113 → Verification Pending.

## 0.18.0

### Minor Changes

- 8ad3d3b: ADR-041: auto-apply scorer remediations when above appetite; never release above appetite

  Land ADR-041 closing P103 (`/wr-itil:work-problems` escalated resolved above-appetite release decisions) and P104 (partial-progress painted the release queue into a corner).

  Behaviour:

  - `work-problems` Step 6.5 gains an above-appetite branch. When `push` or `release` residual risk lands ≥ 5/25, the orchestrator auto-applies scorer remediations in rank order (largest `|risk_delta|` first) until residual risk converges within appetite (≤ 4/25). Each auto-apply amends the iteration's main commit per ADR-041 Rule 3 (preserves ADR-032 one-commit-per-iteration invariant).
  - `manage-problem` Step 12 and `manage-incident` Step 15 terminal release sequences inherit the same above-appetite branch; each auto-apply is its own commit since there is no iteration wrapper in non-AFK mode.
  - **Never release above appetite**: there is no code path in either lineage that drains at ≥ 5/25. Exhaustion halts the loop/skill per ADR-041 Rule 5.
  - **Closed action-class enumeration (Rule 2a)**: ADR-041 v1 ships with `move-to-holding` implemented (`git mv .changeset/<name>.md docs/changesets-holding/<name>.md`). Classes `revert-commit`, `amend-commit`, `feature-flag`, `rollback-to-tag` are deferred to P108. Unsupported class descriptions route to Rule 5 halt.
  - **Verification Pending carve-out (Rule 2b)**: auto-revert never fires against commits attached to `.verifying.md` tickets; Rule 5 halt names the VP ticket(s).
  - **Governance gates apply per auto-apply (Rule 3)**: the scorer proposes; architect + JTBD + risk-scorer gates authorise. No scorer-bypass path.
  - **Audit trail (Rule 6)**: iteration/skill reports emit an Auto-apply trail subsection (one line per apply); `docs/changesets-holding/README.md` "Currently held" appends for `move-to-holding` actions.
  - **Holding-area blessed (Rule 7)**: `docs/changesets-holding/` promoted from provisional to authoritative. ADR-041 cited as the governing decision; provisional banner removed.

  Supersedes the implicit above-appetite branch of ADR-018 Step 6.5 and the explicit above-appetite branch of ADR-020 §6; both ADRs cross-reference ADR-041 from the same commit. At-or-below-appetite drain behaviour in both is unchanged.

  Authorised by ADR-013 Rule 5 (policy-authorised silent proceed): `RISK-POLICY.md` appetite + ADR-041 Rule 2a enumeration constitute the policy for the auto-apply loop.

  Follow-up work tracked in **P108** (`docs/problems/108-scorer-remediation-action-class-vocabulary.open.md`) — scorer contract extension (structured `action_class` column in `RISK_REMEDIATIONS:`) + orchestrator parsers for the four deferred classes. Until P108 lands, ADR-041 v1's scope is the `move-to-holding` subset.

  Closes P103, P104. Opens P108.

## 0.17.2

### Patch Changes

- 8d28266: P094 — `/wr-itil:manage-problem` now refreshes `docs/problems/README.md` on new-ticket creation (Step 5, unconditional) and on ranking-changing updates (Step 6, conditional on Priority / Effort / WSJF line changes). Step 11's staging language extends the single-commit rule from Step 7 transitions to cover Step 5 creation and Step 6 ranking-change updates so README.md rides every commit that alters on-disk ticket ranks. Closes P094.

## 0.17.1

### Patch Changes

- d2fa4c6: P093 — resolve `/wr-itil:transition-problem` ↔ `/wr-itil:manage-problem` circular delegation for `<NNN> <status>` args.

  `/wr-itil:transition-problem` now hosts the Step 7 transition block inline: pre-flight checks per destination (Open → Known Error / Known Error → Verifying / Verifying → Close), P063 external-root-cause detection with the AFK fallback, `git mv` + Status edit + P057 explicit re-stage, `## Fix Released` section write on the `.verifying.md` destination, P062 README refresh, and the ADR-014 commit through the risk-scorer pipeline gate. The skill no longer re-invokes `/wr-itil:manage-problem` — the round-trip clause that created the infinite-delegation cycle has been stripped from `manage-problem`'s Step 1 `<NNN> <status>` forwarder paragraph.

  Per architect guidance, the fix follows a "copy, not move" shape: the in-skill Step 7 block on `manage-problem` stays intact for in-skill callers (Step 9b auto-transition, the Parked path, Step 9d closure inside review). The split skill carries a scoped inline copy for the user-initiated transition path only.

  ADR-010 amended with a new **"Split-skill execution ownership"** sub-rule (2026-04-22) codifying the "copy, not move" principle so the same trap does not recur in future clean-split skills.

  Existing `transition-problem-contract.bats` test 7 inverted in place to assert no round-trip; test 8 added for inline Step 7 mechanics. Full itil sweep: 736/736 green.

## 0.17.0

### Minor Changes

- d938a04: P067 — `/wr-itil:report-upstream` classifier is now problem-first per ADR-033. The Step 3 classifier picks `problem` shape as primary (tokens: problem / issue / concern / defect / gap / scoped-npm reference / root cause / reproduction / workaround) and demotes bug / feature / question to backward-compat fallback shapes. The Step 5 structured default body is problem-shaped (Description / Symptoms / Workaround / Affected plugin / Frequency / Environment / Evidence / Cross-reference); bug-shaped / feature-shaped / question-shaped bodies are retained as fallback-only templates for the corresponding backward-compat branches. Template-discovery preference order now searches `problem-report.yml` / `problem.yml` / `problem-report.md` / `problem.md` before bug / feature / question template candidates. ADR-033 partially supersedes ADR-024 Decision Outcome Steps 3 and 5; ADR-024 Steps 1, 2, 4, 6, 7, 8 and all Consequences remain in force. Ships after P066's intake-template reform (2026-04-20) so the skill's preference order matches the reference intake shape this repo now ships.
- 73c48b7: P076 — WSJF scoring in `/wr-itil:manage-problem` now models transitive dependencies. Ticket effort is split into `marginal` (the ticket's own added work) and `transitive` (`max(marginal, max{ Blocked_by upstreams })`); WSJF uses the transitive effort so a dependent ticket can never out-rank a ticket whose work is strictly contained within it. Additions:

  - New `### Transitive dependencies (P076)` subsection in `packages/itil/skills/manage-problem/SKILL.md` WSJF Prioritisation section defining the rule, the `**Blocked by**` signal, the `**Composes with**` non-propagation carve-out, the `.closed.md` / `.verifying.md` / `.parked.md` upstream-contributes-0 carve-out, cycle-bundling semantics, a worked example (P073 marginal S + blocked by P038 XL → transitive XL → WSJF 1.5), a concrete re-rate message format (`P<NNN>: Effort <OLD> → <NEW> (transitive via <UPSTREAM>)`), and a reassessment-criteria note for future sibling-ADR extraction if a second skill adopts the `## Dependencies` convention.
  - New `## Dependencies` section in the Step 5 problem-ticket template with `**Blocks**` / `**Blocked by**` / `**Composes with**` rows (bare IDs, empty lists allowed) and a concrete example block.
  - New Step 9b.1 dependency-graph-traversal pass in `manage-problem` and a mirrored Step 2.5 in `/wr-itil:review-problems` (the executor split per P071) that builds the `**Blocked by**` adjacency map, topologically sorts, propagates effort, writes an `<!-- transitive: <bucket> via <UPSTREAM> -->` audit comment on the Effort line, and reports each re-rate in the step-3 review output.
  - New `manage-problem-transitive-dependencies.bats` contract + behavioural test file (21 assertions — 15 structural contract assertions per ADR-037 plus 6 behavioural fixture tests exercising the transitive-closure algorithm directly so prose-drift like `min` instead of `max`, or a missing carve-out for closed upstreams, is caught at test time).
  - Three new contract assertions on `review-problems-contract.bats` covering the new Step 2.5 pass, canonical-rule citation, and re-rate message shape.

  No new ADR authored (following ADR-022's inline-amendment precedent for WSJF additions); reassessment trigger documented inline. Backward-compatible — tickets without a `## Dependencies` section behave as before (empty closure → transitive == marginal).

## 0.16.0

### Minor Changes

- 6f3265a: P086: AFK iteration subprocess now runs `/wr-retrospective:run-retro` before emitting `ITERATION_SUMMARY`

  The AFK `/wr-itil:work-problems` iteration subprocess previously emitted `ITERATION_SUMMARY` and exited without running retro, discarding every per-iteration friction observation — hook TTL expiries, marker-vs-file deadlocks, repeat-workaround patterns, subagent-delegation friction, release-path instability. Across a 5-iteration AFK loop that's 20–50 tool-level observations the backlog never sees, degrading JTBD-006's "clear summary on return" outcome and JTBD-101's "new friction patterns become ticketable" promise.

  `packages/itil/skills/work-problems/SKILL.md` Step 5 iteration prompt body gains a closing step (step 4) naming `/wr-retrospective:run-retro` before the `ITERATION_SUMMARY` emission step. Retro runs INSIDE the subprocess so its Step 2b pipeline-instability scan has access to the iteration's full tool-call history; retro commits its own work per ADR-014 (run-retro delegates ticket creation to `/wr-itil:manage-problem`); orchestrator picks up retro-created tickets on the next Step 1 scan naturally — no cross-process marker sharing required. Retro is non-blocking: if retro fails or surfaces findings, the iteration still emits `ITERATION_SUMMARY` so the AFK loop does not halt on a flaky retro run.

  `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` subprocess-boundary variant gains a matching "Retro-on-exit (P086 amendment)" clause under the Pattern contract block, parallel to how P084 amended P077 — the retro contract is the subprocess-boundary variant's closing-step invariant alongside spawn command, stdout parse shape, exit-code semantics, hook session-id isolation, post-subprocess state re-read, and orchestration boundary.

  `packages/itil/skills/work-problems/test/work-problems-step-5-delegation.bats` gains four doc-lint contract assertions (P086): iteration prompt names `/wr-retrospective:run-retro`; retro ordered BEFORE `ITERATION_SUMMARY` emission; retro named as non-blocking closing step; ADR-014 cited for retro commit ownership.

  Architect review PASS (no ADR invariant violated; amendment shape parallels P084→P077). JTBD review PASS (JTBD-006 + JTBD-101 primary alignment; JTBD-001 no-regression — retro runs inside subprocess, orchestrator main turn unaffected).

## 0.15.0

### Minor Changes

- 4a25a60: P071 split slices 6b + 6c + 6d: new `/wr-itil:restore-incident`, `/wr-itil:close-incident`, and `/wr-itil:link-incident` skills

  `/wr-itil:manage-incident <I> restored`, `/wr-itil:manage-incident <I> close`, and `/wr-itil:manage-incident <I> link P<M>` are deprecated; the three remaining incident-lifecycle user intents now have their own skills so the `/` autocomplete surfaces each one directly (JTBD-001 + JTBD-101 + JTBD-201). These are slices 6b + 6c + 6d of the P071 phased-landing plan, bundled in one commit because each mirrors slice 6a (mitigate-incident, commit 248edad) verbatim except for the transition each owns. Bundling amortises cache-warmup + full bats re-run cost across three identical-pattern splits; per-slice separability is preserved via one contract-bats file per skill.

  - `packages/itil/skills/restore-incident/SKILL.md` — NEW split skill (slice 6b).
    `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill`
    — diverges from close-incident + link-incident because restore invokes
    `/wr-itil:manage-problem` via the Skill tool for the problem-handoff
    (ADR-011 Decision Outcome point 4) and uses AskUserQuestion for the
    "create problem / no problem required" branch. Owns the
    `.mitigating.md → .restored.md` rename, the Status field update, the
    "Service restored" Timeline entry, and the `## Linked Problem` or
    `## No Problem` section write. Pre-flight enforces at least one
    recorded mitigation attempt + a captured verification signal per
    ADR-011. Re-invocation on an already-`.restored.md` file is
    idempotent (Case B) — does not re-edit the Status field.
  - `packages/itil/skills/restore-incident/test/restore-incident-contract.bats`
    — NEW 12 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
    JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
  - `packages/itil/skills/close-incident/SKILL.md` — NEW split skill (slice 6c).
    `allowed-tools: Read, Write, Edit, Bash, Glob, Grep` — no
    AskUserQuestion (the linked-problem gate is a hard check with a message,
    not a decisional prompt), no Skill tool (no cross-skill invocation).
    Owns the `.restored.md → .closed.md` rename, the Status field update,
    and the "Incident closed" Timeline entry. Gate accepts linked problems
    in `.known-error.md`, `.verifying.md` (ADR-022 extension), or
    `.closed.md` state; `.open.md` blocks close with a pointer to
    `/wr-itil:transition-problem`. `## No Problem` section bypasses the
    gate. Already-closed invocations short-circuit idempotently.
  - `packages/itil/skills/close-incident/test/close-incident-contract.bats`
    — NEW 13 contract assertions (ADR-037 pattern; @problem P071 +
    @jtbd JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability;
    includes the ADR-022 `.verifying.md` gate-allowance regression guard).
  - `packages/itil/skills/link-incident/SKILL.md` — NEW split skill (slice 6d).
    `allowed-tools: Read, Write, Edit, Bash, Glob, Grep` — two data
    parameters (incident ID + problem ID) and no decisional prompts.
    Owns the `## Linked Problem` section write / update, including the
    retroactive-link-from-No-Problem conversion (Case C) which also
    appends a `Retroactive link to P<MMM>` Timeline entry so the audit
    trail records the revision.
  - `packages/itil/skills/link-incident/test/link-incident-contract.bats`
    — NEW 11 contract assertions (ADR-037 pattern; @problem P071 +
    @jtbd JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
  - `packages/itil/skills/manage-incident/SKILL.md` — Step 1 parser now
    recognises three additional shapes (`<I###> restored`, `<I###> close`,
    `<I###> link P<MMM>`) and delegates via the Skill tool; emits the
    canonical deprecation systemMessage verbatim for each. Steps 8
    (restore), 9 (close), and 11 (link) reduced to thin-router notes
    pointing at the new skills. `deprecated-arguments: true` already
    pinned from slice 5.
  - `packages/itil/skills/manage-incident/test/manage-incident-restore-forwarder.bats`
    — NEW 4 forwarder contract assertions.
  - `packages/itil/skills/manage-incident/test/manage-incident-close-forwarder.bats`
    — NEW 4 forwarder contract assertions.
  - `packages/itil/skills/manage-incident/test/manage-incident-link-forwarder.bats`
    — NEW 4 forwarder contract assertions.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  This completes the `/wr-itil:manage-incident` subcommand split. All five
  word-verb subcommands (`list`, `mitigate`, `restored`, `close`, `link`)
  are now first-class named skills. `manage-incident` retains two
  responsibilities: (1) declare a new incident (no arguments) and (2)
  update an existing incident body (`<I###> <details>` — data parameter
  only, not a verb subcommand). All five forwarders will be removed
  together in `@windyroad/itil`'s next major version.

  P071 phased-landing plan status: slices 1 (list-problems), 2
  (review-problems), 3 (work-problem singular), 5 (list-incidents), 6a
  (mitigate-incident), 6b (restore-incident), 6c (close-incident), and 6d
  (link-incident) shipped. Slice 4 (`transition-problem`) shipped in a
  prior release. All planned slices are now complete; P071 is eligible
  for transition to `.verifying.md` pending user sign-off per ADR-022.

- 38756a8: P071 split slice 5: new `/wr-itil:list-incidents` skill

  `/wr-itil:manage-incident list` is deprecated; the list-incidents user
  intent now has its own skill so the `/` autocomplete surfaces it directly
  (JTBD-001 + JTBD-101 + JTBD-201). This is slice 5 of the P071 phased-landing
  plan, mirroring slice 1 (list-problems) verbatim.

  - `packages/itil/skills/list-incidents/SKILL.md` — NEW read-only skill
    (`allowed-tools: Read, Bash, Grep, Glob` — no Write, no Edit, no
    AskUserQuestion). Reads `.investigating.md`, `.mitigating.md`, and
    `.restored.md` files from `docs/incidents/`; sorts by severity per
    ADR-011 ("Severity, not WSJF" — incidents are time-bound events where
    the WSJF effort divisor is meaningless).
  - `packages/itil/skills/list-incidents/test/list-incidents-contract.bats`
    — NEW 10 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
    JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
  - `packages/itil/skills/manage-incident/SKILL.md` — `deprecated-arguments:
true` frontmatter flag per ADR-010 amended; Step 1 `list` argument now
    routes to a thin-router forwarder that delegates via the Skill tool and
    emits the canonical deprecation notice verbatim.
  - `packages/itil/skills/manage-incident/test/manage-incident-list-forwarder.bats`
    — NEW 4 contract assertions for the forwarder contract.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment. Full itil bats suite green (241/241 + 14 new = 255/255).

  Remaining phased-landing slices tracked on P071: `mitigate-incident`,
  `restore-incident`, `close-incident`, `link-incident` (the remaining
  manage-incident splits).

- 248edad: P071 split slice 6a: new `/wr-itil:mitigate-incident` skill

  `/wr-itil:manage-incident <I###> mitigate <action>` is deprecated; the
  mitigate-incident user intent now has its own skill so the `/` autocomplete
  surfaces it directly (JTBD-001 + JTBD-101 + JTBD-201). This is slice 6a of
  the P071 phased-landing plan, mirroring slice 5 (list-incidents) closely
  except that mitigate-incident takes the `<I###> <action>` data parameters
  — permitted under ADR-010 amended (only word-verb-arguments must be split
  out; data parameters like IDs and free-text action strings remain).

  - `packages/itil/skills/mitigate-incident/SKILL.md` — NEW split skill.
    `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion,
Skill` — diverges from list-incidents's read-only set because mitigation
    renames `.investigating.md → .mitigating.md` on the first attempt and
    appends to the Mitigation attempts timeline. Preserves the ADR-011
    evidence-first gate (≥1 hypothesis with cited evidence) on the first
    mitigation transition, the reversible-mitigation preference
    (rollback → feature flag → restart → route traffic → scale → fix), and
    the Sev 4-5 lightweight path per ADR-011 Step 12 edge case.
  - `packages/itil/skills/mitigate-incident/test/mitigate-incident-contract.bats`
    — NEW 13 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
    JTBD-001 + @jtbd JTBD-101 + @jtbd JTBD-201 traceability).
  - `packages/itil/skills/manage-incident/SKILL.md` — Step 1 parser now
    recognises the `<I###> mitigate <action>` shape and delegates via the
    Skill tool; emits the canonical deprecation systemMessage verbatim.
    Step 7 reduced to a thin-router note pointing at the new skill (the
    rename + evidence-gate implementation lives in `/wr-itil:mitigate-incident`
    now). `deprecated-arguments: true` already pinned from slice 5.
  - `packages/itil/skills/manage-incident/test/manage-incident-mitigate-forwarder.bats`
    — NEW 4 contract assertions for the mitigate forwarder.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  Remaining phased-landing slices tracked on P071: `restore-incident`
  (slice 6b), `close-incident` (slice 6c), `link-incident` (slice 6d) —
  the remaining manage-incident splits.

## 0.14.0

### Minor Changes

- 7670ffb: Extend `/wr-itil:work-problems` Step 5 to extract per-iteration cost + token metadata from each `claude -p --output-format json` response. Surface it in Step 6's per-iteration progress line and the ALL_DONE Output Format's new "Session Cost" section.

  **Why:** the subprocess-dispatch swap shipped in 0.13.0 landed real per-iteration cost inside the JSON response alongside `.result`, but the orchestrator was throwing it away. Without surfacing it, the user has no feedback loop for calibrating AFK loop sizing decisions (e.g. the 2026-04-21 "max out the token usage, they are wasted unused" direction needs actuals to calibrate against). Cost metadata is already emitted — this change just wires it into the user-visible output.

  **Extracted fields (explicit list; PII guard):** `.total_cost_usd`, `.duration_ms`, `.usage.input_tokens`, `.usage.output_tokens`, `.usage.cache_creation_input_tokens`, `.usage.cache_read_input_tokens`. SKILL.md names the extraction scope explicitly so future contributors don't unconsciously broaden it to include `session_id`, `model`, `stop_reason`, `permission_denials`, `uuid`, or other subprocess-envelope fields.

  **Step 6 per-iteration format:** `[Iteration N] Worked P<NNN> — <action>. <K> problems remain. ($<cost>, <duration_s>s, <total_tokens_K>K tokens)`.

  **ALL_DONE Session Cost section:** aggregate totals (cost, iterations, mean cost per iteration, input/output/cache-creation/cache-read tokens, duration). Cache-read column surfaces the warm-cache-reuse signal observed across subsequent subprocess invocations in the same Bash session. Renders identically in interactive and AFK modes; no decision branch (output-side only, per ADR-013 Rule 6).

  **Source citation (per ADR-026):** Session Cost numbers are extracted measured-actuals from each iteration's `claude -p` JSON output — not estimates. Cited in the section header so downstream audits can trust the numbers.

  Architect + JTBD reviews PASS (both 2026-04-21). Bats doc-lint: 9 new assertions on the extraction language + Session Cost section shape; 54/54 work-problems suite green.

## 0.13.0

### Minor Changes

- 260768f: P084 fix: `/wr-itil:work-problems` Step 5 dispatches iterations via a `claude -p` subprocess instead of Agent-tool-spawned `general-purpose` subagents.

  **Why:** Agent-tool-spawned subagents do NOT have the Agent tool in their own surface (platform restriction; three-source evidence — ToolSearch probe, Claude Code docs, empirical runtime error). Without Agent, the iteration worker could not satisfy architect + JTBD PreToolUse edit-gate markers (only settable via Agent-tool PostToolUse hook) nor the risk-scorer commit gate. Every AFK iteration on a gate-covered path (`packages/`, ADRs, SKILL.md edits, hook edits) silently halted. The subprocess variant is a full main Claude Code session with Agent available, so governance reviews run at full depth and gate markers set natively.

  **Dispatch command:** `claude -p --permission-mode bypassPermissions --output-format json <iteration-prompt>`.

  **No per-iteration budget cap.** Per user direction, the AFK loop's natural stop condition is quota exhaustion, not an arbitrary dollar cap. A cap would halt iterations before quota is actually exhausted, leaving remaining backlog unprocessed. Quota-exhaust surfaces as a non-zero `claude -p` exit and the orchestrator halts cleanly per Step 6.75's exit-code handling.

  **What stays the same:** the `ITERATION_SUMMARY` return-summary contract is preserved verbatim (orchestrator extracts from the JSON `.result` field instead of the Agent-tool return value). Step 0 preflight (ADR-019), Step 6.5 release-cadence drain (ADR-018), and Step 6.75 inter-iteration verification (P036) all remain in the orchestrator's main turn unchanged. Every non-Step-5 block in the skill is untouched.

  **Adopter-tunable:** adopters with narrower permission scopes may substitute `--permission-mode acceptEdits` / `auto` / `dontAsk` for `bypassPermissions`. Adopters who genuinely need a per-iteration cap (multi-tenant billing, etc.) can add `--max-budget-usd` in their own fork — not the default.

  See `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` for the full subprocess-boundary sub-pattern contract (amendment dated 2026-04-21) and `docs/problems/084-work-problems-iteration-worker-has-no-agent-tool-so-architect-jtbd-gates-block.open.md` for the full diagnosis + probe evidence.

## 0.12.0

### Minor Changes

- 91da109: P071 split slice 4: new `/wr-itil:transition-problem` skill (+ manage-problem forwarder)

  `/wr-itil:manage-problem <NNN> known-error` / `<NNN> verifying` / `<NNN> close`
  is deprecated; the transition-a-ticket user intent now has its own skill so
  Claude Code `/` autocomplete surfaces it directly (JTBD-001 + JTBD-101).
  This is phase 4 of the P071 phased-landing plan.

  - `packages/itil/skills/transition-problem/SKILL.md` — NEW thin-router
    selection skill. Arguments: `<NNN>` (ticket ID) + `<status>` (one of
    `known-error`, `verifying`, `close`). Both are data parameters per the
    P071 split rule (ADR-010 amended); neither is a word-subcommand.
    Execution delegates to `/wr-itil:manage-problem <NNN> <status>` via the
    Skill tool — the authoritative Step 7 block (pre-flight checks + P057
    staging trap + P063 external-root-cause + P062 README refresh) stays
    on the host skill.
  - `packages/itil/skills/transition-problem/test/transition-problem-contract.bats`
    — NEW 14 contract assertions (ADR-037 pattern; @problem P071 +
    @jtbd JTBD-001 + @jtbd JTBD-101 traceability).
  - `packages/itil/skills/manage-problem/SKILL.md` — Step 1 parser updated
    to distinguish bare `<NNN>` (update flow, handled inline by Step 6)
    from `<NNN> <status>` (transition — delegated to the new skill). New
    "Forwarder for `<NNN> <status>` transitions" section added to the
    Deprecated-argument forwarders block, with the canonical deprecation
    notice (per ADR-010 amended template).
  - `packages/itil/skills/manage-problem/test/manage-problem-transition-forwarder.bats`
    — NEW 5 contract assertions for the forwarder contract.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  Remaining phased-landing slices tracked on P071: `list-incidents`,
  `mitigate-incident`, `restore-incident`, `close-incident`,
  `link-incident` (the `manage-incident` splits).

  **Recovery note:** this slice shipped after the iter-5 AFK halt per P036.
  The iteration subagent wrote the files correctly (19/19 bats green) but
  returned prematurely without committing, triggering Step 6.75's
  dirty-for-unknown-reason branch. Work verified sound post-hoc and
  committed here as the halt recovery. A follow-up ticket captures the
  iteration-worker-must-not-ScheduleWakeup contract gap (separate from
  P077's delegation-mechanism fix).

- ffa85a7: feat(itil): P071 split slice 3 — /wr-itil:work-problem (+ manage-problem forwarder)

  Phase 3 of P071's phased-landing plan: the "pick the highest-WSJF ticket and work it" user intent gets its own skill so `/` autocomplete surfaces it directly. Previously hidden behind `/wr-itil:manage-problem work` — a word-argument subcommand that Claude Code autocomplete does not surface.

  CRITICAL naming distinction: `/wr-itil:work-problem` is **singular** — one ticket per invocation, interactive `AskUserQuestion` selection. It is distinct from the already-existing plural `/wr-itil:work-problems` (AFK batch orchestrator). The two names coexist per P071's acknowledged trade-off; the singular skill is the per-iteration execution unit the plural orchestrator delegates into via the Agent tool (P077 + ADR-032).

  `/wr-itil:work-problem` (new skill):

  - Frontmatter: `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent` — the selection tool surface plus delegation to `/wr-itil:review-problems` (refresh) and `/wr-itil:manage-problem <NNN>` (execution).
  - Step 1 reads `docs/problems/README.md` if fresh (git-history staleness test per P031); delegates to `/wr-itil:review-problems` for the refresh if stale (P062 canonical-writer discipline — no fork).
  - Step 2 fires `AskUserQuestion` selection: Recommended single top-WSJF option, or per-tied-ticket peer options for multi-way ties, with per-option rationale. Never prose "(a)/(b)/(c)" (P053 + ADR-013 Rule 1 regression guard).
  - Step 3 delegates the execution to `/wr-itil:manage-problem <NNN>` via the Skill tool — thin-router discipline; the full investigate/transition/fix/release workflow stays on a single authoritative host.
  - Step 4 fires the standard scope-change `AskUserQuestion` (Continue / Re-rank / Pick-different) on effort drift.
  - Step 5 reports the outcome; does NOT loop automatically (that's the plural orchestrator's job).
  - AFK branch (ADR-013 Rule 6): when invoked inside a `/wr-itil:work-problems` iteration, skips `AskUserQuestion` and executes the pre-selected ticket. Within-day tiebreak matches the orchestrator spec.

  `/wr-itil:manage-problem` (deprecated-argument forwarder for `work`):

  - Step 1 `work` argument now delegates to `/wr-itil:work-problem` via the Skill tool and emits the canonical systemMessage verbatim per ADR-010's pinned template: `"/wr-itil:manage-problem work is deprecated; use /wr-itil:work-problem directly. This forwarder will be removed in @windyroad/itil's next major version."`
  - Forwarder does not re-implement the selection logic (thin-router per ADR-010).
  - `deprecated-arguments: true` frontmatter flag already present from slice 1; no change.

  Tests (ADR-037 contract-assertion pattern):

  - `packages/itil/skills/work-problem/test/work-problem-contract.bats` — 19 assertions covering: frontmatter (name singular + regression guard against plural drift; description names pick/highest-WSJF + singular distinction; allowed-tools AskUserQuestion + Skill); singular-vs-plural naming-distinction documentation; delegation to `/wr-itil:manage-problem` (anti-fork); defer-to-`/wr-itil:review-problems` for cache refresh (P062 ownership); git-history freshness test (P031); `AskUserQuestion` selection prompt fires (ADR-013 Rule 1); prose-selection fallback forbidden (P053); AFK branch documented (Rule 6); scope-expansion 3-option shape; one-ticket-per-invocation singular contract; no `deprecated-arguments: true` flag on clean-split skill; no word-argument subcommand branching regression; P071 + ADR-010 + P077 + ADR-032 traceability citations.
  - `packages/itil/skills/manage-problem/test/manage-problem-work-forwarder.bats` — 5 assertions covering: forwarder targets `/wr-itil:work-problem` (singular); singular-vs-plural name-collision guard; canonical deprecation notice emission; no inline re-implementation; parser-line pattern matches slice-1 + slice-2 shape.

  Cross-references:

  - P071 (docs/problems/071-\*.open.md) — originating ticket; phased plan's slice 3.
  - ADR-010 amended (Skill Granularity section) — canonical split-naming + forwarder contract.
  - ADR-013 Rule 1 — structured user interaction; Rule 6 — AFK fallback.
  - ADR-014 — governance skills commit their own work; delegated manage-problem owns per-ticket commits.
  - ADR-032 + P077 — plural AFK orchestrator delegates iterations via Agent tool; this singular skill is the canonical execution unit.
  - P031 — git-history freshness test; P062 — review-problems canonical README cache writer.
  - P053 + ADR-013 Rule 1 — no prose-selection fallback.

## 0.11.0

### Minor Changes

- d8ab4c5: P071 split slice 2: new `/wr-itil:review-problems` skill

  `/wr-itil:manage-problem review` is deprecated; the review-problems user
  intent now has its own skill so the `/` autocomplete surfaces it directly
  (JTBD-001 + JTBD-101). This is phase 2 of the P071 phased-landing plan
  (list-problems shipped as slice 1 in `@windyroad/itil@0.10.0`).

  - `packages/itil/skills/review-problems/SKILL.md` — NEW skill carrying
    the full review stack: re-read `RISK-POLICY.md`, re-score every
    `.open.md` / `.known-error.md` ticket (Impact × Likelihood × Effort →
    WSJF), auto-transition Open → Known Error when root cause + workaround
    are documented, fire the Verification Queue prompt (`.verifying.md`
    per ADR-022 + P048 Candidate 4 `Likely verified?` heuristic), rewrite
    `docs/problems/README.md`, and commit per ADR-014 + ADR-015.
    `allowed-tools`: `Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion,
Skill` — the tool surface the governance-scoped write path demands
    (contrast with `list-problems`'s read-only surface).
  - `packages/itil/skills/review-problems/test/review-problems-contract.bats`
    — NEW 16 contract assertions (ADR-037 pattern; `@problem P071` +
    `@jtbd JTBD-001` + `@jtbd JTBD-101` traceability). Covers: frontmatter
    name, description intent language, allowed-tools surface (Write +
    Edit + Skill + AskUserQuestion required), glob scope (.open.md /
    .known-error.md / .verifying.md / .parked.md), README-refresh ownership
    boundary, Verification Queue prompt contract (ADR-022 fix-summary
    requirement), auto-transition path, ADR-014/015 commit-gate, P057
    staging-trap citation, RISK-POLICY.md reuse (no hardcoded scale),
    P071/ADR-010 citation, clean-split no-deprecated-arguments flag, and
    regression guard against word-argument subcommand branching.
  - `packages/itil/skills/manage-problem/SKILL.md` — Step 1 `review`
    argument now routes to a thin-router forwarder that delegates to
    `/wr-itil:review-problems` via the Skill tool and emits the canonical
    deprecation notice verbatim per ADR-010's pinned template. Parser
    line updated from "run the review (step 9) only" to "delegate to
    `/wr-itil:review-problems`". Step 9's inline review logic stays in
    the file during the deprecation window (for historical reference +
    the inline `work` path that still flows through Step 9 pre-slice 3)
    but is no longer the primary entry point.
  - `packages/itil/skills/manage-problem/test/manage-problem-review-forwarder.bats`
    — NEW 4 contract assertions for the review-forwarder contract:
    target-skill reference, canonical deprecation notice, delegate /
    Skill tool language (no re-implementation), and parser-line shape.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment.

  Remaining phased-landing slices tracked on P071: `work-problem`
  (singular; coexists with `/wr-itil:work-problems` AFK plural),
  `transition-problem`, plus the `manage-incident` splits
  (`list-incidents`, `mitigate-incident`, `restore-incident`,
  `close-incident`, `link-incident`).

## 0.10.1

### Patch Changes

- a0ec231: P077 fix: work-problems Step 5 delegates iterations via the Agent tool

  `/wr-itil:work-problems` Step 5 previously used an ambiguous "Invoke the
  manage-problem skill" line that read as a Skill-tool (in-process) invocation.
  That expanded manage-problem's 500+ line SKILL.md into the main orchestrator's
  context every iteration, accumulated across the AFK loop, and caused silent
  early-stop (`ALL_DONE` without a documented stop condition firing).

  Step 5 now delegates each iteration to a `general-purpose` subagent via the
  Agent tool. Option B per P077 — iteration work is general engineering, not
  specialised domain expertise, so a typed iteration-worker subagent would just
  re-export manage-problem's content. The AFK iteration-isolation wrapper
  sub-pattern is documented in ADR-032 (amended 2026-04-21).

  - `packages/itil/skills/work-problems/SKILL.md` Step 5 — rewritten with
    explicit Agent-tool delegation (`subagent_type: general-purpose`),
    self-contained prompt shape, and structured return-summary contract
    (`ticket_id` / `ticket_title` / `action` / `outcome` / `committed` /
    `commit_sha` / `reason` / `skip_reason_category` / `outstanding_questions` /
    `remaining_backlog_count` / `notes`). Architect R2: commit-state fields keep
    Step 6.75's Dirty-for-known-reason branch evaluable. JTBD extension:
    skip-reason category and outstanding-questions fields let Step 2.5 populate
    the Outstanding Design Questions table deterministically.
  - `allowed-tools` frontmatter — adds `Agent` (closes the pre-existing latent
    bug where Step 6.5 already required Agent-tool delegation).
  - Non-Interactive Decision Making table — new row documents iteration
    delegation default.
  - `## Related` section — new; cites P077, P036, P040, P041, P053, and ADR-013
    / ADR-014 / ADR-015 / ADR-018 / ADR-019 / ADR-022 / ADR-032 / ADR-037.
  - `packages/itil/skills/work-problems/test/work-problems-step-5-delegation.bats`
    — NEW, 10 contract assertions (ADR-037 pattern; `@problem P077` +
    `@jtbd JTBD-006` traceability).
  - `docs/decisions/032-governance-skill-invocation-patterns.proposed.md` —
    amended with the "AFK iteration-isolation wrapper (P077 amendment)"
    sub-pattern under foreground synchronous. No supersession.
  - `docs/problems/077-...open.md` → `.verifying.md` with `## Fix Released`
    section per ADR-022.

  Inter-iteration continuity preserved: Step 6.5 (release cadence / ADR-018)
  and Step 6.75 (inter-iteration verification / P036) stay in the main
  orchestrator's turn. The iteration subagent commits its own work per ADR-014
  but MUST NOT run `push:watch`/`release:watch`.

## 0.10.0

### Minor Changes

- 412443f: P071 split slice 1: new `/wr-itil:list-problems` skill

  `/wr-itil:manage-problem list` is deprecated; the list-problems user intent
  now has its own skill so the `/` autocomplete surfaces it directly (JTBD-001

  - JTBD-101). This is phase 1 of the P071 phased-landing plan (audit landed
    in the prior commit — 2 offenders, both in @windyroad/itil).

  * `packages/itil/skills/list-problems/SKILL.md` — NEW read-only skill
    (`allowed-tools: Read, Bash, Grep, Glob` — no Write, no Edit, no
    AskUserQuestion). Reuses the git-log-based README cache freshness check
    from `manage-problem review` per P031 + architect Q4.
  * `packages/itil/skills/list-problems/test/list-problems-contract.bats` —
    NEW 9 contract assertions (ADR-037 pattern; @problem P071 + @jtbd
    JTBD-001 + @jtbd JTBD-101 traceability).
  * `packages/itil/skills/manage-problem/SKILL.md` — `deprecated-arguments:
true` frontmatter flag per ADR-010 amended; Step 1 `list` argument now
    routes to a thin-router forwarder that delegates via the Skill tool and
    emits the canonical deprecation notice verbatim.
  * `packages/itil/skills/manage-problem/test/manage-problem-list-forwarder.bats`
    — NEW 4 contract assertions for the forwarder contract.

  Deprecation window: until `@windyroad/itil`'s next major version per
  ADR-010 amendment. Full bats suite green (467/467).

  Remaining phased-landing slices tracked on P071: `work-problem`,
  `review-problems`, `transition-problem`, plus the `manage-incident`
  splits (`list-incidents`, `mitigate-incident`, `restore-incident`,
  `close-incident`, `link-incident`).

## 0.9.0

### Minor Changes

- 6ee6adc: **manage-problem + work-problems**: wire the external-root-cause detection surface so `manage-problem` prompts for `/wr-itil:report-upstream` invocation when root cause points upstream (closes P063).

  New behaviour:

  - `manage-problem` Step 7 (Open → Known Error transition) scans Root Cause Analysis for strict external markers: explicit `upstream` / `third-party` / `external` / `vendor` labels, or scoped-npm pattern `@[\w-]+/[\w-]+`. On hit, fires `AskUserQuestion` with three options: invoke `/wr-itil:report-upstream` now, defer and note in ticket, or mark false positive.
  - Parked lifecycle gains a pre-park hook: parking with `upstream-blocked` reason runs the same detection.
  - AFK non-interactive fallback (per ADR-013 Rule 6) appends the stable marker `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` to the ticket's `## Related` section. The skill is NOT auto-invoked (its Step 6 security-path is interactive per ADR-024 Consequences).
  - `work-problems` `upstream-blocked` skip category now runs the AFK fallback before skipping so accumulated upstream dependencies surface in the ticket body when the user returns.
  - Already-noted grep check prevents duplicate marker lines on subsequent runs.

  No new public skill or command; no ADR changes. Closes a discoverability gap between `manage-problem` (caller) and `/wr-itil:report-upstream` (callee, shipped in 0.8.0).

### Patch Changes

- 7e19eab: **manage-problem**: refresh `docs/problems/README.md` on every Step 7 status transition and stage it in the same commit (closes P062).

  Before this change, status transitions (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed, Parked) did NOT refresh the README.md cache — only the `review` operation did. The next session's fast-path freshness check correctly detected the lag and forced a full rescan (self-healing but wasteful), and human readers browsing README.md between sessions saw outdated WSJF rankings and an incomplete Verification Queue.

  SKILL.md Step 7 now includes a dedicated "README.md refresh on every transition (P062)" block describing the mechanism (regenerate in-place with the new filename set and Status; stage in the same commit; update the "Last reviewed" parenthetical). Step 11 commit convention requires `docs/problems/README.md` in the transition commit's stage list — including folded-fix commits where the `.verifying.md` transition rides with a `fix(<scope>): ...` commit.

  The refresh is a render, not a re-rank: existing WSJF values on ticket files are trusted; no full re-scoring pass fires. That remains Step 9's job.

  Cache stays fresh by construction — the Step 9 fast-path freshness check should return empty on any invocation after a transition commit.

## 0.8.0

### Minor Changes

- 8788489: Add `/wr-itil:report-upstream` skill — file a local problem ticket as a structured upstream issue or private security advisory with bidirectional cross-references. Implements the contract in ADR-024 (Cross-project problem-reporting contract).

  The skill discovers upstream `.github/ISSUE_TEMPLATE/` via `gh api`, classifies the local ticket (bug / feature / question / security), picks the best-matching template (or falls through to a structured default when none exist), routes security-classified tickets via the upstream's `SECURITY.md` (GitHub Security Advisories, `security@` mailbox, or other declared channel — never auto-opens a public issue for a security-classified ticket), and back-writes a `## Reported Upstream` section + `## Related` line into the local ticket.

  Three distinct AFK branches are encoded in the skill: public-issue path proceeds (voice-tone gate per ADR-028 may delegate-and-retry); declared-channel security path proceeds via `gh api .../security-advisories`; missing-`SECURITY.md` security path saves the drafted report and halts the orchestrator (loop-stopping event per ADR-024 Consequences). Above-appetite commit-gate uses the ADR-013 Rule 6 fail-safe.

  Step-0 auto-delegation per ADR-027 is deliberately deferred — `report-upstream` is in ADR-027's "held for reassessment" set with the explicit note "narrow workflow; decided at implementation time". The skill's main-agent context is the right place to evaluate the security-path branch and surface the missing-SECURITY.md `AskUserQuestion`.

  Includes a doc-lint bats test (Permitted Exception per ADR-005) covering all five ADR-024 Confirmation criterion 2 assertions plus the architect-required ADR-027 / ADR-028 / three-AFK-branch documentation. Closes P055 Part B; P055 Part A (intake scaffolding) shipped earlier in the same session.

## 0.7.2

### Patch Changes

- f9bfa56: Fix the next-ID origin-max lookup in `manage-problem` Step 3 and `create-adr` Step 3 (P056). The prior bash pipeline ran `git ls-tree origin/main <path>/ | grep -oE '[0-9]{3}'` — default `git ls-tree` output includes the 40-char blob SHA, whose hex run can contain three consecutive decimal digits that the regex falsely matches (observed `origin_max=997` on 2026-04-20 opening P055). The fix adds `--name-only` to drop mode/type/SHA columns and pipes through `sed` to strip the path prefix, so the anchored `grep -oE '^[0-9]+'` only picks up real filename IDs. ADR-019's next-ID invariant and P043's collision guard both presume this pipeline is sound; this change restores the invariant. Two new bats doc-lint tests (8 assertions) guard the contract.
- 3bf2074: Document the `git mv` + Edit + `git add` staging-ordering trap (P057) in `manage-problem` Step 7 and `create-adr` Step 6. `git mv` alone stages only the rename — subsequent `Edit`-tool modifications must be re-staged explicitly (`git add <new>`) before commit. Without the re-stage, transition commits capture the rename but drop the `Status:` / `## Fix Released` content edits, which then leak into an unrelated later commit and corrupt the audit trail (observed 2026-04-19 in P054's `.verifying.md` transition).

  Changes:

  - `manage-problem` Step 7: new warning block applying to all three transition arrows (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed), plus an explicit `git add <new>` line in each code block.
  - `manage-problem` Step 11: commit convention now recommends `git add -u` as a safety-net for tracked modifications.
  - `create-adr` Step 6: supersession rename now instructs authors to `git add` the file again after the frontmatter + "Superseded by" edits.
  - Two new bats doc-lint tests guard the contract in both SKILL.md files.

## 0.7.1

### Patch Changes

- c5f8039: Add inter-iteration verification to `wr-itil:work-problems` AFK orchestrator (closes P036). After the release-cadence check and before the next iteration, the skill now runs `git status --porcelain` and halts the loop if the working tree is dirty for a reason not stated in the last iteration's report. This is defence-in-depth behind P035's fallback: it catches silent subagent commit failures (a failure inside the assess-release skill, a git conflict, a malformed commit message) that would otherwise accumulate across iterations and corrupt the final summary. Non-interactive default recorded in the decision table. Recovery is explicitly out of scope per ADR-013 Rule 6 — the check surfaces the bug, the user decides. Includes a 6-test doc-lint bats regression file.

## 0.7.0

### Minor Changes

- 151b993: manage-problem Verification Queue detection (P048, minimal-scope).

  - **Fast-path cache hit**: step 9d now explicitly fires even when
    `docs/problems/README.md` is fresh (candidate 1). Prevents the prior
    regression where verification prompts were suppressed on cache hit —
    which is exactly when the user is most likely to verify.
  - **Verification Queue presentation**: step 9c now emits a
    `Likely verified?` column in the Verification Queue with
    `yes (N days)` / `no (N days)` values based on release age
    ≥ 14 days (candidate 4). 14-day default documented as a within-skill
    tunable (architect review confirmed not policy-level yet).
  - Step 9d surfaces the highlighted (`yes`) tickets first in the
    verification prompt so the user can batch-close long-standing
    verifications.
  - 5 new structural bats assertions in
    `manage-problem-verification-detection.bats`; full project suite
    269/269 green (+5).
  - Candidates 2 (standalone `verify-fixes` op), 3 (exercise observation
    records — new file-level state dimension), and 5 (AFK-mode
    orchestrator hook) are deferred pending an architect ADR-scope
    decision.

## 0.6.0

### Minor Changes

- 4e93bcf: Add Verification Pending `.verifying.md` problem-lifecycle status per ADR-022
  (P049 — the SKILL.md contract half; existing-file migration follows in a
  separate commit per ADR-022 Scope).

  - **manage-problem SKILL.md**: lifecycle table gains Verification Pending
    status and `.verifying.md` suffix; WSJF multiplier table documents
    Verification Pending = 0 (excluded from dev ranking); Known Error →
    Verification Pending transition documented (git mv + Status field +
    `## Fix Released` in one commit per ADR-014); step 9b skips
    `.verifying.md` files; step 9c gains a Verification Queue section; step
    9d targets `*.verifying.md` via glob; step 9e README template gains the
    Verification Queue section; closing workflow and commit-convention
    prose updated.
  - **work-problems SKILL.md**: step 1 scan excludes `.verifying.md`; step 4
    classifier row `Known Error with ## Fix Released` → `.verifying.md`
    (suffix-based, no file-body scan).
  - **manage-incident SKILL.md**: step 9 linked-problem close gating accepts
    `.verifying.md` alongside `.known-error.md` and `.closed.md`.
  - **docs/problems/README.md**: "Known Errors (Fix Released — pending
    verification)" shadow table replaced with "Verification Queue" citing
    ADR-022.
  - 11 new structural bats assertions in
    `manage-problem-verification-pending.bats`; full project suite
    264/264 green (+11).

## 0.5.0

### Minor Changes

- a0600d9: Surface outstanding design questions at work-problems stop-condition #2 (P053).

  - Step 2 branches on stop-condition: #2 now routes to a new Step 2.5 before
    emitting `ALL_DONE`; #1 and #3 keep the direct-emit behaviour.
  - Step 2.5 extracts user-answerable questions from skipped tickets. In
    interactive invocations, batches up to 4 into one `AskUserQuestion` call
    per ADR-013 Rule 1 (Anthropic's documented per-call cap). In
    non-interactive / AFK invocations (the JTBD-006 persona default), emits
    an `### Outstanding Design Questions` table in the post-stop summary
    per ADR-013 Rule 6 fail-safe.
  - Step 4 classifier gains a skip-reason taxonomy column:
    `user-answerable` / `architect-design` / `upstream-blocked`. Step 2.5
    selects the user-answerable subset to surface.
  - Output Format template includes an `### Outstanding Design Questions`
    section (Ticket / Question / Context), emitted only when
    stop-condition #2 fires with ≥1 user-answerable skip.
  - Non-Interactive Decision Making table documents the AFK-default path.
  - 7 structural bats assertions added in
    `work-problems-stop-condition-questions.bats`; full project suite
    253/253 green (+7).

## 0.4.5

### Patch Changes

- 5c677cc: manage-problem: add XL effort bucket and effort re-rate pre-flight (P047)

  - Effort table in `manage-problem` SKILL.md gains an **XL** bucket (divisor 8) for multi-day or cross-package work, with a new sub-example showing how WSJF flattens at XL and a live-estimate note pointing to steps 7 and 9b.
  - **Step 7** Open → Known Error pre-flight gains a checklist item requiring the effort bucket to be re-rated against the now-documented fix strategy, with the reason captured in the problem file.
  - **Step 9b** step 7 reworded from "Estimate Effort" to "Re-estimate Effort (S / M / L / XL) ... note the reason in a short parenthetical" so the review re-rate is unmissable.
  - `work-problems` SKILL.md example paragraphs updated non-normatively to reference "S to L or XL" for consistency.
  - New doc-lint test `manage-problem-effort-buckets.bats` (4 assertions) guards the new contract.

## 0.4.4

### Patch Changes

- 39e026c: itil: governance skills auto-release when changesets are queued (P028)

  Extends the terminal commit step of `manage-problem` and `manage-incident`
  so non-AFK governance invocations drain the release queue automatically
  after their own commit lands, rather than ending at `git commit` and
  relying on the user to remember `npm run push:watch` and
  `npm run release:watch`.

  Mechanism (per new ADR-020):

  - After commit, delegate to `wr-risk-scorer:assess-release` (subagent
    `wr-risk-scorer:pipeline` with Skill fallback per ADR-015).
  - If `push` and `release` scores are both within appetite (≤ 4/25 per
    `RISK-POLICY.md`) AND `.changeset/` is non-empty, run
    `npm run push:watch` followed by `npm run release:watch`.
  - Fail-safe identical to ADR-018: stop on `release:watch` failure, no
    retry. Above-appetite risk skips the drain and reports clearly.
  - Skipped automatically when the skill is invoked inside an AFK
    orchestrator — those flows handle release cadence via ADR-018 Step 6.5
    and must not double-release.

  Scope matches ADR-014 (manage-problem, manage-incident). The remaining
  governance skills (`create-adr`, `run-retro`, `update-guide`,
  `update-policy`) inherit ADR-020 automatically once they adopt ADR-014.

  Splits the original P028 auto-install concern into P045 (deferred
  pending Claude Code in-session plugin reload). Closes P028 pending user
  verification.

## 0.4.3

### Patch Changes

- 359ec7c: ticket-creators: next-ID collision guard against origin (P043)

  Adds the next-ID collision guard from ADR-019 confirmation criterion 2 to
  both ticket-creator skills:

  - `manage-problem` step 3 (Assign the next ID): now computes max of
    local-max and `git ls-tree origin/<base>` max, then increments. Catches
    collisions between local work and parallel sessions before the ticket
    file is written.
  - `create-adr` step 3 (Determine sequence number): same mechanism applied
    to `docs/decisions/`.

  Both skills cite ADR-019 and log renumber decisions in the user-facing
  report. Sibling fix to P040 (work-problems Step 0 preflight, shipped in
  @windyroad/itil@0.4.2): preflight catches divergence at loop start; this
  ticket catches collisions at ticket-creation time as a defence in depth.

  Adds bats tests (3 assertions per skill) verifying ADR-019 references and
  the collision-guard pattern.

  Closes P043 pending user verification.

## 0.4.2

### Patch Changes

- 9c6019e: work-problems: add preflight to reconcile with origin before iteration (P040)

  Adds Step 0 (Preflight) to the work-problems AFK orchestrator per ADR-019.
  Before opening the work loop, the orchestrator now runs `git fetch origin`
  and compares local HEAD with `origin/<base>`. On trivial fast-forward
  divergence, it pulls non-interactively (`git pull --ff-only`). On
  non-fast-forward divergence (local has unpushed commits AND origin has
  advanced), it stops with a clear divergence report (`git log --oneline
HEAD..origin/<base>` and reverse). Non-interactive rebase or merge is
  explicitly forbidden — the persona requires user judgment for those.

  Network failure on `git fetch origin` defaults to fail-closed (stop and
  report); the user can retry when network is restored.

  Adds row to Non-Interactive Decision Making table covering origin
  divergence. Adds bats test (7 assertions) covering ADR-019 confirmation
  criteria: skill cites ADR-019; references `git fetch origin` and
  `pull --ff-only`; has discrete preflight step; non-interactive table
  covers it; explicitly forbids non-interactive merge/rebase.

  The next-ID collision guard (ADR-019 confirmation criterion 2) belongs in
  ticket-creator skills (manage-problem, wr-architect:create-adr) and is
  tracked in a separate problem ticket.

  Closes P040 pending user verification.

## 0.4.1

### Patch Changes

- 87c2ecf: work-problems: enforce inter-iteration release cadence (P041)

  Adds Step 6.5 (Release-cadence check) to the work-problems AFK orchestrator
  per ADR-018. After each successful iteration, the orchestrator now invokes
  `wr-risk-scorer:assess-release` (or its pipeline subagent) and, if `push` or
  `release` score is at or above appetite (4/25 per RISK-POLICY.md), drains
  the queue with `npm run push:watch` then `npm run release:watch` before
  starting the next iteration. The drain runs non-interactively per ADR-013
  Rule 6 (policy-authorised when within appetite). On `release:watch`
  failure, the loop stops and reports — no non-interactive retry.

  Also adds a row to the Non-Interactive Decision Making table covering the
  new behaviour, and a bats test asserting the SKILL.md references both
  `assess-release` and `release:watch` (ADR-018 confirmation criterion).

  Closes P041 pending user verification of the next AFK loop.

## 0.4.0

### Minor Changes

- a36a084: Add `wr-itil:work-problems` AFK batch orchestrator skill and document a commit-gate fallback in `wr-itil:manage-problem` (JTBD-006).

  - **New skill** `wr-itil:work-problems` — loops through ITIL problem tickets by WSJF priority, delegating each iteration to `wr-itil:manage-problem` non-interactively. Stops gracefully when nothing remains actionable. Emits `ALL_DONE` sentinel for external detection. Deterministic Step 4 classification rules (skip known-errors with Fix Released; work everything else).
  - **Fix** `wr-itil:manage-problem` commit gate now documents a two-path delegation (closes P035). Primary: delegate to `wr-risk-scorer:pipeline` subagent-type via the Agent tool. Fallback: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent-type is unavailable (e.g., when `manage-problem` is itself running inside a spawned subagent). Per ADR-015 both produce equivalent bypass markers. Non-interactive fail-safe preserved for the risk-above-appetite branch only — silent-skip for delegation-unavailable is no longer sanctioned.

## 0.3.3

### Patch Changes

- 83b8be7: fix(manage-problem): add Parked lifecycle status and README.md fast-path cache (closes P027)

  - Adds `.parked.md` suffix and Parked status to problem lifecycle table
  - `problem work` checks README.md freshness before triggering full 18-file re-scan
  - Step 9e writes/overwrites `docs/problems/README.md` after every full re-rank
  - Parked problems excluded from WSJF ranking; shown in separate Parked table

## 0.3.2

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.1

### Patch Changes

- e8216b1: Governance skills now commit their own completed work (P023, ADR-014).

  **@windyroad/itil**: `manage-problem` and `manage-incident` skills no longer end with "Do not commit — the user will commit when ready." They now instruct the agent to stage files, delegate to `wr-risk-scorer:pipeline` for a risk assessment, and commit automatically using a conventional commit message referencing the problem or incident ID. If risk is above appetite, an `AskUserQuestion` prompt is presented before committing. Non-interactive fail-safe per ADR-013 Rule 6.

  New ADR-014 documents the cross-skill commit pattern, commit message convention, and risk-gate delegation sequence.

## 0.3.0

### Minor Changes

- e5eb0bd: Add `manage-incident` skill for evidence-first incident response with automatic handoff to problem management.

  The new `/wr-itil:manage-incident` skill implements an ITIL-aligned incident workflow focused on **restoring service fast** while keeping a disciplined audit trail. Hypotheses must cite evidence before any mitigation. Reversible mitigations (rollback, feature flag, restart) are preferred over forward fixes. On restoration, the skill automatically invokes `manage-problem` to create or update the underlying root-cause ticket, linking the incident to a `P###`.

  Incidents use a separate `I###` namespace in `docs/incidents/` so lifecycles, prioritisation (severity for incidents, WSJF for problems), and audit trails stay clean. See ADR-011 and JTBD-201 for the full design.

### Patch Changes

- 23d0d10: Require structured `AskUserQuestion` prompts at all governance-skill decision branches (P021, ADR-013).

  **@windyroad/itil**: `manage-problem` skill now requires `AskUserQuestion` for WSJF tie-breaks, problem selection, and scope-change decisions. Prose "(a)/(b)/(c)" option lists are prohibited.

  **@windyroad/risk-scorer**: All three scorer agents (pipeline, wip, plan) now enforce below-appetite silence — no advisory prose, "Your call:", or suggestions when scores are within appetite. Above-appetite output uses structured `RISK_REMEDIATIONS:` blocks instead of free-text suggestions.

  New ADR-013 establishes the cross-cutting standard: every governance-skill branch point with ≥2 options must use `AskUserQuestion`; scoring agents stay pure output-only.

## 0.2.0

### Minor Changes

- 6eeef94: Rename `@windyroad/problem` → `@windyroad/itil` (plugin `wr-problem` → `wr-itil`, skill `/wr-problem:update-ticket` → `/wr-itil:manage-problem`). Makes room for peer ITIL skills (incident, change) under the same plugin. Hard rename, no shim — per ADR-010.

  **Migration**: if you had `@windyroad/problem` installed, uninstall it (`npx @windyroad/problem --uninstall`) then install `@windyroad/itil`. The skill command changes from `/wr-problem:update-ticket` to `/wr-itil:manage-problem`. `@windyroad/retrospective`'s dependency is updated automatically.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
