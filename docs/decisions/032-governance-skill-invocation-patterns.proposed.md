---
status: "proposed"
date: 2026-04-21
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-21
supersedes: [027-governance-skill-auto-delegation]
---

# Governance skill invocation patterns — foreground + background with deferred-question resumption

## Context and Problem Statement

`ADR-027` (Governance skill auto-delegation) mandated a single execution pattern for every governance skill (`manage-problem`, `create-adr`, `run-retro`, `manage-incident`, `work-problems`): Step 0 delegates to a subagent synchronously; the main agent blocks on the subagent's final report; main agent never executes Steps 1-N in its own context. The model provided strong context isolation and made reviewer subagents the authoritative read-only surface.

In practice the synchronous model conflicts with the user's documented need captured in P014:

> "working on X, notice Y, log Y, keep working on X, don't forget Y"

When an aside-worthy observation surfaces mid-task (a problem noticed in passing, a retro entry, an ADR-worthy decision), the synchronous model forces the user to either (a) invoke the governance skill and consume the current turn on its full intake flow, or (b) accept the friction of remembering to capture the observation later. Both outcomes are the "manually police AI output" pain pattern JTBD-001 is designed against. The user's direction (2026-04-21 interactive): keep the existing foreground skills for full-intake invocations AND add sibling `capture-*` skills that run in background via `Agent(run_in_background: true)`. Supersede ADR-027; don't just layer on top.

Three existing skills get a background-capable sibling or move to a background-oriented default:

- `/wr-itil:capture-problem` — NEW sibling of `manage-problem`; background; captures a problem ticket from aside context.
- `/wr-retrospective:capture-retro` — NEW sibling of `run-retro`; background; captures a retro entry or triggers a background retro pass.
- `/wr-architect:capture-adr` — NEW sibling of `create-adr`; background; captures an ADR from aside context.

Existing synchronous skills (`manage-problem`, `create-adr`, `run-retro`, `manage-incident`, `work-problems`) remain available as foreground invocations for users who want the full interactive flow. The sibling-naming pattern matches `feedback_skill_subcommand_discoverability.md` — each distinct user intent is its own skill discoverable via `/` autocomplete, not an argument-based subcommand (P071).

Interactive branches within background skills (AskUserQuestion prompts) cannot block the main thread — the main agent has moved on; the user doesn't know the subagent is waiting. This ADR defines a **deferred-question resumption contract** that pauses the subagent, surfaces the question through the main agent at its next natural pause, collects the answer, and resumes the subagent with the answer in its input.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — "reviews complete in under 60 seconds so they don't break flow" closes for mid-task captures: the aside goes to a background subagent; the main thread continues.
- **JTBD-003** (Compose Only the Guardrails I Need) — sibling-skill pairs (foreground + background) are independently composable. Projects that want only the heavyweight foreground flow stay on it; projects that want background captures add the `capture-*` skills.
- **JTBD-006** (Progress the Backlog While I'm Away) — AFK orchestrator iterations stay synchronous under this ADR (see Scope). ADR-018 drain-ownership and ADR-019 preflight-ownership untouched.
- **JTBD-101** (Extend the Suite with New Plugins) — the sibling-skill pattern (foreground + `capture-*` background) is the repeatable convention future plugin developers follow when they want to offer both modes. No argumented-subcommand anti-pattern (per P071 and `feedback_skill_subcommand_discoverability.md`).
- **JTBD-201** (Restore Service Fast with an Audit Trail) — foreground edit-gate and commit-gate hooks stay foreground (must block); audit trail integrity preserved.
- **P014** (No lightweight aside invocation for governance skills) — closed at the design level by this ADR.

## Considered Options

1. **Foreground + background with deferred-question resumption (chosen)** — user's pinned direction. Supersedes ADR-027. Sibling `capture-*` skills run in background; existing foreground skills preserved. AskUserQuestion branches inside background skills defer via a pending-questions marker.

2. **Keep ADR-027 synchronous; re-pin P014 to work inside it** — rejected by the user ("happy to supersede previous decisions"). The synchronous model's Step-0 delegation doesn't cleanly support "log Y, keep working on X" because the main agent still blocks on the subagent's final report.

3. **Hybrid: ADR-027 synchronous by default + optional background opt-in pattern** — rejected. Two coexisting patterns multiply the per-skill decision surface; sibling-skill naming is a simpler discoverable alternative.

4. **Fire-and-forget without deferred-question resumption** — rejected on architect review. Background skills that hit AskUserQuestion would silently block the subagent (user doesn't know subagent is waiting), violating ADR-013 Rule 6's fail-safe requirement.

5. **Thin stubs (original P014 framing)** — not what the user wanted. User clarified 2026-04-21: full intake runs in the background; not just a stub that gets fleshed out later.

## Decision Outcome

**Chosen option: Option 1** — foreground preserved; sibling `capture-*` skills run in background; deferred-question resumption contract handles interactive branches.

### Pattern taxonomy

Every governance invocation surface falls into one of these four patterns. Skills pick per invocation, not per skill identity (a single skill can be invoked foreground OR via its `capture-*` sibling).

| Pattern | Main-thread behaviour | Use | Examples |
|---|---|---|---|
| **Foreground synchronous** | Main agent invokes; skill runs; main agent consumes full output and resumes. | Full-intake governance flows; user wants to be in the loop for every step. | `/wr-itil:manage-problem`, `/wr-architect:create-adr`, `/wr-retrospective:run-retro`, `/wr-itil:manage-incident`. |
| **Background capture** | Main agent spawns `Agent(run_in_background: true)`; main agent continues immediately; subagent runs full intake; subagent commits its own work per ADR-014; main agent may notice the completion via file artefacts at its next natural pause. | Mid-task asides; user's cognitive load stays on the main task. | `/wr-itil:capture-problem` (NEW), `/wr-retrospective:capture-retro` (NEW), `/wr-architect:capture-adr` (NEW). |
| **Foreground edit-gate** | PreToolUse hook; blocks the tool call; delegates to a reviewer subagent; permits on PASS. Unchanged by this ADR. | Edit-time governance (architect, jtbd, voice-tone, style-guide review). | `packages/architect/hooks/architect-enforce-edit.sh`, `packages/jtbd/hooks/jtbd-enforce-edit.sh`, etc. |
| **Foreground commit-gate** | PreToolUse hook on git commit; delegates to `wr-risk-scorer:pipeline`. Unchanged by this ADR. | Commit-time risk scoring. | `packages/risk-scorer/hooks/risk-gate.sh` family. |

### Skill-to-pattern assignments under this ADR

**Preserved foreground (unchanged from ADR-027's in-scope list, minus Step 0)**:
- `/wr-itil:manage-problem` — foreground synchronous. No Step 0 delegation. Main agent runs the skill directly.
- `/wr-architect:create-adr` — foreground synchronous. No Step 0 delegation.
- `/wr-retrospective:run-retro` — foreground synchronous. No Step 0 delegation.
- `/wr-itil:manage-incident` — foreground synchronous. No Step 0 delegation.
- `/wr-itil:work-problems` — **special case**. The orchestrator itself runs in a subagent (per the current ADR-027 framing). Under this ADR the orchestrator is still a subagent but its iteration delegations remain synchronous per ADR-018 / ADR-019; AFK-iteration-spawned governance subagents do not use the background pattern (see AFK carve-out below).

**New background siblings**:
- `/wr-itil:capture-problem` — background. Takes an aside payload (one-line description + trigger context) as its prompt, spawns the full manage-problem intake flow as a background subagent, commits the resulting problem ticket per ADR-014.
- `/wr-retrospective:capture-retro` — background. Takes an aside payload (one-line observation + trigger context), spawns a background retrospective-entry subagent that appends to a queue consumed at next foreground `run-retro` OR, if the payload is substantive enough, runs the retro pass directly in background.
- `/wr-architect:capture-adr` — background. Takes an aside payload (decision context + options-considered sketch), spawns a background ADR-drafting subagent that produces an initial draft at `.proposed.md`; the draft becomes the starting point for a subsequent foreground `create-adr` flesh-out OR (if the draft is complete enough) the subagent commits the ADR directly.

### AFK carve-out (per architect option (a))

Background capture pattern does NOT apply inside AFK orchestrator iterations. `/wr-itil:work-problems` iterations stay synchronous: the iteration subagent delegates to `manage-problem` in its own foreground flow; no `capture-*` invocations fire inside the loop; ADR-018 drain-ownership and ADR-019 preflight-ownership remain in orchestrator main context. Rationale: AFK orchestrators depend on synchronous observability-between-iterations (Step 6.5 drain checks, Step 6.75 inter-iteration verification); fire-and-forget breaks those preconditions.

Background pattern is available for USER-INITIATED (non-AFK) invocations only. A background skill launched from a foreground skill (standard `Agent` semantics) is explicitly allowed — the foreground-skill's main agent launches the background subagent and continues its own flow.

### Deferred-question resumption contract

When a background skill hits an `AskUserQuestion` branch:

1. **Subagent pauses**. Writes a pending-questions artefact at a **persistent** location:
   - `docs/problems/open/<NNN>-pending-background-skill-questions-<short-slug>.md` (ADR-031 per-state-subdir path; graceful fallback to flat `docs/problems/<NNN>-...open.md` until P069's migration lands).
   - The artefact carries a standard problem-ticket header (Status: Open, Reported: <date>, Priority: 3 Low — mirroring the "needs-completion" category) PLUS a structured `## Pending Questions` section with the ADR-013-compliant question set (question text, options, multiSelect, header) PLUS a `## Subagent Resumption Context` section with whatever state the subagent needs to resume (e.g. partial draft, captured prior-step output).
   - This replaces architect's earlier suggestion of a `/tmp` marker: persistent storage survives reboots AND makes each paused subagent a first-class trackable item. Pending-questions artefacts appear in the normal problem backlog and in `manage-problem review` output so the user cannot accidentally lose them.

2. **Subagent exits**. Background invocation completes; no resume loop inside the subagent.

3. **Main agent surfaces the questions**. On the main agent's **next natural pause** (next user prompt), a `UserPromptSubmit` hook (`packages/itil/hooks/pending-questions-surface.sh`, NEW, ships with `@windyroad/itil`) checks for `docs/problems/open/*-pending-background-skill-questions-*.md` files. If any are present, the hook injects a systemMessage listing the pending-questions artefacts by ID+title so the main agent invokes `AskUserQuestion` with each artefact's question set **serially** (one AskUserQuestion call per artefact; matches ADR-013's one-decision-per-interaction grain).

4. **Main agent writes the answers**. For each artefact, main agent appends `## User Answers (<timestamp>)` to the artefact with the user's selection. This is a structured patch the resuming subagent can parse.

5. **Main agent spawns the resume subagent**. New `Agent(run_in_background: true)` invocation with the artefact path as its prompt input. The resume subagent reads the `## Subagent Resumption Context` + `## User Answers`, picks up where the original subagent paused, and completes the work.

6. **Resume subagent completes**. Writes the final artefact (e.g. the completed problem ticket, retro entry, or ADR draft), commits per ADR-014, and `git mv`s the pending-questions artefact to `docs/problems/closed/<NNN>-pending-background-skill-questions-<short-slug>.md` with a `## Resolved` section citing the resume commit SHA.

7. **TTL expiry**. If the pending-questions artefact sits unanswered for more than `PENDING_QUESTIONS_TTL` (default 7 days; overridable via envvar), `manage-problem review` surfaces it as a stale-pending-question. The user decides whether to answer (resume), cancel (rename to `docs/problems/parked/<NNN>-...md` with a `## Parked` section citing "background skill abandoned"), or escalate to a foreground `manage-problem` / `run-retro` / `create-adr` invocation that takes the resumption context + any partial work as its starting point.

**Concurrency**: multiple simultaneous pending-questions artefacts are handled serially. The `UserPromptSubmit` hook lists all detected artefacts; main agent invokes `AskUserQuestion` once per artefact. Order: artefact creation date ascending (FIFO). No batching — each artefact's question set is independent and the user reviews them one at a time.

**Precedent**: the TTL+marker primitive reuses ADR-009's gate-marker-lifecycle pattern. This ADR extends the primitive to a new semantic class — pending-subagent-state tokens. ADR-009 markers are clearance tokens (the gate was passed); ADR-032 pending-questions artefacts are paused-subagent-state tokens.

### ADR-013 Rule 6 audit requirement

Before any existing skill moves to (or gains) a background sibling, every AskUserQuestion branch in the skill must pass a Rule 6 audit:

- **(a) Policy-authorise** (ADR-013 Rule 5 variant) — if the branch's options are safely-defaultable in the background context, convert the branch to automatic selection with a policy citation. Background-preferred default matches foreground-interactive default.
- **(b) Defer via pending-questions artefact** — if the branch genuinely needs user input, apply the deferred-question contract above.
- **(c) Reclassify as foreground-only** — if the branch's input is time-sensitive, high-stakes, or depends on context the subagent cannot snapshot, the skill's background variant skips this branch path entirely (`capture-problem` takes only aside-captureable inputs; anything requiring full interactive flow routes to foreground `manage-problem`).

Each skill's SKILL.md under this ADR's model MUST include a "Rule 6 audit" section enumerating each AskUserQuestion branch and its resolution path.

### Observable-output contract

Background skills produce observable artefacts that bats tests + manual audit can assert. The artefact types:

- **Completed artefact** — problem ticket at `docs/problems/open/NNN-<slug>.md` (or the intended post-ADR-031-migration path); retro entry appended to BRIEFING.md; ADR at `docs/decisions/NNN-<slug>.proposed.md`. Standard ADR-014 commit carries the artefact.
- **Pending-questions artefact** — persistent problem ticket per the deferred-question contract above.
- **Background-skill receipt** — short structured file at `docs/problems/open/<NNN>-background-skill-receipt-<short-slug>.md` (or equivalent) naming which background skill fired, when, and what its completed or pending state is. Optional; main agent decides whether to emit based on whether the caller wanted an explicit receipt. Primary use case: AFK orchestrators that want to track "which background captures fired this session" (not relevant under AFK carve-out but reserved for future).

## Scope

### In scope (this ADR)

- Pattern taxonomy (foreground synchronous, background capture, foreground edit-gate, foreground commit-gate).
- Three new `capture-*` skills (`/wr-itil:capture-problem`, `/wr-retrospective:capture-retro`, `/wr-architect:capture-adr`) — ADR-level decision. SKILL.md authoring is the implementation step tracked under P014.
- Deferred-question resumption contract (persistent `docs/problems/open/` pending-questions artefact + UserPromptSubmit surfacing hook + serial AskUserQuestion + resume subagent spawn + Resolved-section commit).
- AFK carve-out: background capture does not apply inside AFK orchestrator iterations.
- Rule 6 audit requirement for each skill's SKILL.md under this ADR's model.
- Removal of ADR-027's Step-0 delegation language from `manage-problem`, `create-adr`, `run-retro`, `manage-incident` SKILL.md files. Those skills go back to executing Steps 1-N in main-agent context (foreground synchronous pattern).
- Supersession administration: rename `027-governance-skill-auto-delegation.proposed.md` → `.superseded.md`; update ADR-027 frontmatter status + superseded-by; add "Superseded by" section to ADR-027 body.
- New UserPromptSubmit hook `packages/itil/hooks/pending-questions-surface.sh` that injects a systemMessage when pending-questions artefacts exist.
- Bats doc-lint coverage for the three new SKILL.md files, the Rule 6 audit section presence, the pending-questions-surface hook's detection logic.

### Out of scope (follow-up tickets)

- Direct-invocation Agent tool changes (e.g. a hypothetical "background by default" flag on the Agent tool itself). This ADR picks the model that fits existing Agent tool semantics; any upstream Claude Code changes are separate.
- Background variants of edit-gate / commit-gate hooks. Those must stay foreground (they MUST block).
- Cross-session pending-questions resume (agent session exits before user answers). The TTL expiry path + foreground-escalation recovery covers it; no need for a cross-session transport layer.
- Background variants for `manage-incident`. Incidents are time-pressure interactive; background doesn't fit the JTBD-201 audit-trail model. Revisit if the pattern emerges.
- Background variants for `work-problems` iterations. AFK carve-out is explicit.

## Consequences

### Good

- P014 closes at design level. User's "log Y, keep working on X" promise delivered via the sibling-skill pattern.
- Existing foreground skills unchanged for users who want full interactive flow.
- Sibling-skill naming matches `feedback_skill_subcommand_discoverability.md` and P071's deprecation of argument-based subcommands.
- Deferred-question contract has an explicit observable artefact (not a `/tmp` file) — pending-questions are first-class items in the problem backlog; auditable, timeout-able, recoverable.
- ADR-009 TTL+marker primitive reused and extended; no new filesystem pattern invented.
- ADR-018 / ADR-019 AFK ownership boundaries preserved via explicit carve-out.
- ADR-014 commit ownership preserved; background subagents still commit their own work.
- Rule 6 audit forces each skill's branch points to be explicitly classified before the background variant ships.

### Neutral

- Three new skill identities in the manifest. `claude plugin list` output grows by three lines per adopter.
- New UserPromptSubmit hook fires on every user prompt (checks for pending-questions artefacts). Hook cost is a single `ls docs/problems/open/*-pending-background-skill-questions-*.md 2>/dev/null` per prompt — sub-millisecond; bounded to problem-ticket directory.
- Foreground skills lose their Step-0 delegation. Main agent executes Steps 1-N directly. This removes an isolation layer but reclaims a main-turn that ADR-027 had consumed for every invocation. Net: the user's "synchronous but don't waste a turn on delegation" observation was already part of P014's pain pattern; this ADR resolves it.

### Bad

- **First-run unfamiliarity**: users accustomed to ADR-027's Step-0 delegation (subagent-first, no-main-context-execution) will see a behavior change in existing skills. Documentation + CHANGELOG entries mitigate; the supersede note in ADR-027's body points forward.
- **Pending-questions backlog growth**: if users frequently abandon background captures mid-resumption, the `docs/problems/open/` directory accumulates stale `*-pending-background-skill-questions-*.md` files. Mitigation: TTL expiry path + `manage-problem review` surfacing + escalation recovery to foreground skills.
- **Sibling-skill discoverability load**: users must know both `/wr-itil:manage-problem` and `/wr-itil:capture-problem` exist. Mitigation: `/wr-itil:` autocomplete surfaces both; the `capture-*` verb is consistent across three skills; one mental model spans all three.
- **Existing AFK orchestrator invariants rely on ADR-027 language**: the `work-problems` SKILL.md currently references "Step 0 subagent" framing inherited from ADR-027. Under this ADR that language is stale. Work-problems's Step 0 (preflight) IS still a thing — but it's main-agent preflight, not subagent delegation. Remove ADR-027 references; keep AFK carve-out text.
- **ADR-031 auto-migration's Step-0 question dissolves**: the P069 execution-time question "where does auto-migration sit given ADR-027's Step 0?" (ADR-031 line 130) no longer applies under this ADR. Migration runs in foreground main-agent context, policy-authorised per ADR-013 Rule 6 + ADR-019 precedent. ADR-031 should be cross-updated when that migration executes.

## Confirmation

A set of structural doc-lint bats assertions validates the ADR's implementation:

### Source review (at implementation time)

- `027-governance-skill-auto-delegation.proposed.md` renamed to `.superseded.md`; `status: superseded`; `superseded-by: [032-governance-skill-invocation-patterns]` in frontmatter; "Superseded by" section at top of body.
- `manage-problem` / `create-adr` / `run-retro` / `manage-incident` SKILL.md files have their Step-0 subagent-delegation language removed; main-agent Step-1-onwards execution flow documented.
- Three new SKILL.md files at `packages/itil/skills/capture-problem/SKILL.md`, `packages/retrospective/skills/capture-retro/SKILL.md`, `packages/architect/skills/capture-adr/SKILL.md`. Each:
  - Names the background pattern in its Context section.
  - Enumerates its AskUserQuestion branches with Rule 6 audit resolution (policy / defer / foreground-only).
  - Cites the deferred-question resumption contract from this ADR.
  - Writes completed artefact via standard foreground-skill commit path (ADR-014).
- `packages/itil/hooks/pending-questions-surface.sh` UserPromptSubmit hook exists; detects `docs/problems/open/*-pending-background-skill-questions-*.md` (or ADR-031-post-migration equivalent path); injects systemMessage with detected artefact IDs + titles in ascending creation-date order.
- `.claude-plugin/plugin.json` entries for `@windyroad/itil`, `@windyroad/retrospective`, `@windyroad/architect` list the new skills.

### Foreground-spawns-N-background fanout (P075 amendment)

`run-retro` Step 4b Stage 1 (ticket every codify-worthy observation) is a **foreground-spawns-N-background-fanout** case: the foreground `run-retro` turn spawns one background capture invocation (`/wr-itil:capture-problem`) per codifiable observation. This is a legitimate extension of the foreground-spawns-single-background pattern already named in this ADR — no semantic change, only arity. The FIFO concurrency paragraph already covers the resulting deferred-question ordering: N Stage-2 pending-question artefacts (one per Stage 1 ticket) queue in serial creation-date order and surface FIFO via the UserPromptSubmit hook. When `/wr-itil:capture-problem` does not yet exist in the suite, `run-retro` Step 4b Stage 1 falls back to synchronous `/wr-itil:manage-problem` invocations; the fanout semantics remain the same, only the background/foreground mode changes. P075 tracks the `run-retro` execution; the ADR-032 contract itself covers the case via this amendment.

### Bats structural tests

- `packages/itil/skills/capture-problem/test/capture-problem-contract.bats`, `packages/retrospective/skills/capture-retro/test/capture-retro-contract.bats`, `packages/architect/skills/capture-adr/test/capture-adr-contract.bats` — each asserts: SKILL.md present; Context section cites the background pattern; Rule 6 audit section present; deferred-question-resumption contract cited; ADR-032 referenced.
- `packages/itil/hooks/test/pending-questions-surface.bats` — asserts: hook fires on UserPromptSubmit; detects pending-questions artefacts via glob; produces systemMessage with correct artefact list (FIFO by creation date); no-ops when no artefacts exist.
- `packages/shared/test/adr-027-superseded.bats` — asserts: ADR-027 file is at `.superseded.md` path; frontmatter status is `superseded`; `superseded-by` names ADR-032; body contains "Superseded by" forward pointer.

### Behavioural replay (at implementation time, for the human tester)

1. Fresh session. Invoke `/wr-itil:capture-problem hook TTL expiry mid-iteration`. Verify: main thread receives a short confirmation ("captured as P-NNN in background"); background subagent writes the problem ticket; main agent continues original task.
2. Invoke `/wr-architect:capture-adr decision about X`. Verify: ADR draft appears at `docs/decisions/NNN-<slug>.proposed.md`; if the capture's payload is thin, the background subagent hits AskUserQuestion on Title/Options; pending-questions artefact appears at `docs/problems/open/`; next user prompt surfaces the questions via UserPromptSubmit hook's systemMessage + AskUserQuestion invocation by the main agent.
3. Interrupt a background capture (kill the subagent before it completes). Verify: the original capture's partial commit (if any) is on disk; no pending-questions artefact written (nothing to resume); user can re-invoke `/wr-itil:capture-problem` to retry from scratch.
4. AFK invocation: run `/wr-itil:work-problems`. Verify: iterations stay synchronous per AFK carve-out; no `capture-*` invocations fire inside the loop; drain + preflight remain in orchestrator main context.
5. Let a pending-questions artefact sit past TTL. Run `/wr-itil:manage-problem review`. Verify: artefact surfaces as stale-pending-question with options to answer, cancel (park), or escalate to foreground.

## Reassessment Criteria

Revisit this decision if:

- Pending-questions backlog grows faster than users can answer (signal: `docs/problems/open/*-pending-background-skill-questions-*.md` count exceeds 20 for any adopter). Consider reducing AskUserQuestion branches (convert more to policy-authorised) or lowering TTL.
- Users consistently prefer foreground over `capture-*` (signal: `capture-problem` invocation count stays near-zero for 3+ months post-release). Consider deprecating a `capture-*` skill whose background model doesn't match user behaviour.
- A governance skill emerges whose background variant cannot cleanly resolve any AskUserQuestion branch via Rule 6 audit (signal: architect review blocks the background sibling's design). That skill stays foreground-only; no sibling ships.
- Pending-questions artefact shape proves insufficient (e.g. subagent state too large to persist in a markdown file; users can't read the Resumption Context). Revisit the persistence format; JSON-in-a-YAML-frontmatter-section is the fallback.
- UserPromptSubmit hook latency becomes noticeable (signal: user reports the prompt-submit feeling slower). Measure; optimise the glob or move to a dedicated daemon.
- Cross-session resumption becomes a real need (users resume a background skill in a new session after a gap longer than TTL). Current TTL + foreground-escalation covers it; if it doesn't, a cross-session resume transport layer becomes the next ADR.
- ADR-031's migration lands and the pending-questions artefact path moves from flat `docs/problems/` to `docs/problems/open/` — update this ADR's Confirmation paths in the same commit.

## Related

- **ADR-027** (Governance skill auto-delegation) — superseded by this ADR. Its synchronous-Step-0 mandate is replaced by the pattern taxonomy above.
- **ADR-009** (Gate marker lifecycle) — TTL+marker primitive precedent; this ADR extends it to pending-subagent-state.
- **ADR-013** (Structured user interaction for governance decisions) — Rule 5 (policy-authorised) + Rule 6 (non-interactive fail-safe) both usable under the Rule 6 audit in this ADR. Rule 1 (AskUserQuestion for mutually-exclusive options) preserved via the deferred-question contract's serial surfacing.
- **ADR-014** (Governance skills commit their own work) — preserved under both foreground and background patterns.
- **ADR-018** (Inter-iteration release cadence for AFK loops) — AFK carve-out explicitly preserves.
- **ADR-019** (AFK orchestrator preflight) — same AFK carve-out.
- **ADR-020** (Governance auto-release for non-AFK flows) — auto-release triggers on foreground-skill commits; background-skill commits trigger the same auto-release path per ADR-014 commit ownership.
- **ADR-024** (Cross-project problem-reporting contract) — `report-upstream` is a foreground-synchronous skill; unchanged.
- **ADR-026** (Agent output grounding) — the observable-output contract satisfies the persist clause.
- **ADR-028** (amended External-comms gate) — reviewer agents (voice-tone, risk-external-comms) remain foreground-blocking via their edit-gate hooks; unaffected.
- **ADR-031** (Problem-ticket directory layout) — pending-questions artefacts live under the per-state-subdir layout (`docs/problems/open/`) post-migration; ADR-031's auto-migration Step-0 open question at lines 128-138 dissolves under this ADR (migration runs in foreground main-agent context per ADR-019 precedent).
- **P014** (No lightweight aside invocation for governance skills) — closed at decision level by this ADR.
- **P071** (Argument-based skill subcommands not discoverable) — reinforced: sibling-skill naming (`capture-*` alongside `manage-*` / `create-*` / `run-*`) is the explicit alternative to argument-based subcommands.
- `feedback_skill_subcommand_discoverability.md` — memory note confirms the user's preference for separate skills over arg-subcommands.
- **JTBD-001** (Enforce Governance Without Slowing Down) — primary beneficiary.
- **JTBD-003** (Compose Only the Guardrails I Need) — independent foreground / background skill composability.
- **JTBD-006** (Progress the Backlog While I'm Away) — AFK carve-out preserves the job's invariants.
- **JTBD-101** (Extend the Suite with New Plugins) — sibling-skill pattern as repeatable convention.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — pending-questions as first-class problem tickets keep the audit trail complete.
