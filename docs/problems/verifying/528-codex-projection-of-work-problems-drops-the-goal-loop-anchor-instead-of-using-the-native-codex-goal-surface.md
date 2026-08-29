# Problem 528: Codex projection of work-problems drops the Goal loop-anchor instead of using the native Codex Goal surface

**Status**: Verification Pending
**Reported**: 2026-08-29
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 — derived at capture. Impact 3: Step 0e's external-evaluator anchor is the reopened-P390 defense against the orchestrator declaring `ALL_DONE` while dispatchable tickets remain. In Codex that defense is absent, so the loop degrades to the same-actor self-assessment P390 was reopened to fix — an AFK drain can stop early and leave the backlog unworked. This is loop-discipline loss on the AFK surface, not corruption: no ticket, decision, or repository state is damaged, and Gate (0) still fires as the first-line self-check. Impact is not higher because the degradation is honest-by-design in the source contract (`below the floor the loop degrades honestly to Gate (0)-only behaviour`) — the defect is that Codex is treated as below the floor when it is not. Likelihood 5: it is a property of the projection output and the Codex runtime overlay, not of any particular session, so every Codex run of the drain loses the anchor.
**Origin**: internal
**Effort**: S — confirmed at investigation. The Codex build substitutes `packages/itil/scripts/codex-work-problems.md` wholesale, so the smallest runtime-correct fix is confined to that overlay, its generated artifact, one behavioural test, and release metadata. The canonical Claude Code source retains its `claude -p` and `/goal` branch unchanged.
**WSJF**: 15 — (15 × 1.0) / 1
**JTBD**: JTBD-006
**Persona**: developer

## Description

The Codex projection of `/wr-itil:work-problems` treats a durable Goal surface as unavailable and falls back to the Claude Code filesystem-only completion anchor, even though Codex provides a native durable Goal surface of its own.

Step 0e of the source skill anchors the loop's stop decision on Claude Code's native `/goal` command: a per-turn external evaluator judges the canonical backlog-drain completion condition against what the orchestrator has printed in the transcript. That external check is what breaks the P390 same-actor conflation — the working agent no longer decides whether its own stop is justified.

In a Codex session the skill must do the equivalent work against Codex's own Goal surface:

1. **Create or reuse** the active Goal, carrying the canonical backlog-drain completion condition (the same condition Step 0e owns — the Gate (0) table shape and the condition are a coupled contract).
2. **Inspect that Goal** when deciding whether to continue, rather than relying on the orchestrator's own judgement.
3. **Complete the Goal** only after the printed Step 2.4 Gate (0) table shows zero dispatchable tickets, followed by the `ALL_DONE` sentinel.

The Claude Code `/goal` branch must remain in place for Claude Code. This is a second runtime arm, not a replacement.

## Symptoms

- `packages/itil/scripts/codex-work-problems.md` line 15 is the only Goal reference in the Codex runtime overlay, and it is passive and conditional: *"If the task has a persistent Codex goal, keep it active until this drain reaches a genuine terminal state."* It never creates a Goal, never establishes the completion condition, never inspects the Goal as the continuation authority, and never completes it against the Gate (0) evidence.
- **Corrected at investigation.** As captured this bullet read: *"the projected Step 0e text is rewritten by the sanitizer's substitutions, so the generated skill instructs the agent to use Codex's native `/goal` command"*. That is not what happens to the drain. `work-problems` is the one skill whose Codex body is substituted wholesale from an authored overlay, so Step 0e never reaches the projection at all — there is nothing there to mangle. The blind-substitution symptom is real, but it lands on the singular `/wr-itil:work-problem` skill, which has no overlay. See Root Cause Analysis Finding 2.
- Step 0e's honest-degradation clause (*"below the floor the loop degrades honestly to Gate (0)-only behaviour"*) therefore fires in every Codex session. Codex is treated as below the requirements floor by accident of projection, not because it lacks the capability.
- Net effect: a Codex AFK drain runs with Gate (0) self-assessment only — exactly the configuration ADR-094 / RFC-047 / STORY-040 reopened P390 to move away from.

## Workaround

The operator supplies the anchor by hand. Before invoking the drain in a Codex session, create a durable Goal carrying the canonical backlog-drain completion condition verbatim from the source skill's Step 0e:

```
The /wr-itil:work-problems AFK backlog drain is complete: the final summary printed in the conversation contains a Step 2.4 Gate (0) re-scan table (fresh open/known-error glob) classifying every ticket and showing ZERO dispatchable tickets, followed by the ALL_DONE sentinel - or the session ends with a Hard-fail halt directive naming the gate that could not complete - or the summary reports quota exhaustion.
```

Then run `/wr-itil:work-problems` as normal. This restores the external check without touching any code, and is the same posture the Claude Code interactive path already documents as nudge-and-proceed: the anchor is operator-supplied rather than skill-supplied, and Gate (0) keeps firing unconditionally underneath it either way.

Cost of the workaround: it depends on the operator remembering, every run, on a surface that says nothing to remind them, and the passive line the projection *does* carry actively reads as though the Goal is somebody else's job. It restores the check for a careful operator; it does not restore it for the AFK case the anchor exists to protect.

## Impact Assessment

- **Who is affected**: developers running the AFK backlog drain from a Codex session.
- **Frequency**: every Codex invocation of `/wr-itil:work-problems`.
- **Severity**: the loop keeps its first-line objective self-check (Gate (0)) but loses the external check layered over it. Premature `ALL_DONE` becomes possible again on the Codex surface.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Root cause (confirmed 2026-08-29)

**Finding 1 - the root cause.** The Codex build of `work-problems` is not a projection of the source skill body. `packages/itil/scripts/sync-codex-skills.mjs` lines 223-225 substitute `packages/itil/scripts/codex-work-problems.md` wholesale as the projection input for this one skill (`const runtimeSource = skill === "work-problems" ? "codex-work-problems.md" : undefined`); every other skill projects its own `SKILL.md`. So Step 0e is absent from the Codex drain not because the sanitizer rewrites it into something unexecutable, but because the entire source body is replaced by a 47-line authored overlay - and that overlay was never given a Goal contract.

Its only Goal reference is line 15, projected verbatim to line 26 of the generated skill: *"If the task has a persistent Codex goal, keep it active until this drain reaches a genuine terminal state."* Every verb in that sentence is passive. It never **creates** a Goal, never carries the **canonical completion condition**, never **inspects** the Goal as the continue/stop authority, and never **completes** it against printed Gate (0) evidence. The overlay's Loop step 3 does retain Gate (0), so the Codex drain runs on first-line objective self-assessment alone - precisely the configuration the 2026-07-05 reopen of the premature-`ALL_DONE` problem established as insufficient, because the same actor decides both "should I stop" and "is stopping justified".

The honest-degradation clause in Step 0e (*"below the floor the loop degrades honestly to Gate (0)-only behaviour"*) is therefore firing on a runtime that is not below the floor. Codex has a durable Goal surface; the overlay simply never reaches for it.

**Finding 2 - a real defect on a different surface, not fixed in this pass.** The blind-substitution symptom the capture predicted does occur - on the singular `/wr-itil:work-problem` skill, which has no overlay and so projects through `sourceText`. Generated `packages/itil/skills-codex/work-problem/SKILL.md` lines 135-137 instruct the Codex agent to anchor with *"Codex's native `/goal` external evaluator (>= v2.1.139)"* and carry a `code.claude.com/docs/en/goal` link in the heading. Neither the command nor the version floor exists in Codex, so that instruction is unexecutable. Same class as the sibling frontmatter and skill-name defects; different mechanism, because the singular skill has no runtime overlay to author a second arm into, and making the source prose runtime-neutral would strip the concrete affordance the Claude Code path needs. Left as remaining work rather than folded in, so this pass stays the smallest runtime-neutral split.

### Investigation Tasks

- [x] Establish the concrete Codex Goal API surface — how a Goal is created, read, and completed from inside a running skill, and whether it is available to the orchestrator session only (the Claude Code anchor is orchestrator-session-only per Step 0e's placement clause; iters must not inherit a backlog-empty goal).
- [x] Correct the superseded capture conclusion: the Codex Goal arm belongs in the wholesale Codex overlay; the canonical Claude Code Step 0e remains unchanged.
- [x] Make the Codex arm inspect the Goal at the continue/stop decision and complete it only on printed-Gate-(0)-zero-dispatchable + `ALL_DONE` or another canonical ADR-094 terminal condition.
- [x] Replace the passive Goal line in `packages/itil/scripts/codex-work-problems.md` with the active create/inspect/complete contract.
- [x] Establish whether the sanitizer rewrites the Claude-Code-specific `/goal` prose in this skill - it does not; the overlay replaces the whole body first (Finding 1). It does rewrite it in the singular sibling skill (Finding 2), which remains open below.
- [ ] **Separate, nonblocking follow-up (Finding 2; outside P528 / STORY-070 scope)**: give the singular `/wr-itil:work-problem` skill a Codex-executable anchor instruction, or suppress the Claude-Code-only Goal paragraph from its projection. It needs its own mechanism because the singular skill has no runtime overlay; this released slice covers only the plural `/wr-itil:work-problems` overlay.
- [x] Add a generator-exercising contract check that the projected Codex skill does not instruct the agent to invoke `/goal` or cite a `code.claude.com` URL.
- [x] Create a reproduction test - a generator-exercising check in `packages/itil/scripts/test/codex-pack-install.bats` that builds the projection and asserts the drain's Goal contract is active rather than passive.
- [x] Exercise the Codex overlay through the existing Promptfoo harness for Goal creation, continued dispatch, and all three ADR-094 terminal conditions.

## Fix Strategy

RFC-076 — *Keep the Codex backlog drain running until no dispatchable work remains* — is a release row on confirmed STORY-MAP-011 under activity D, *Close it out*. It carries in-progress STORY-070, *Leave the Codex backlog draining until no dispatchable work remains*.

The row limits the implementation to the Codex projection overlay: create or reuse the persisted Goal with ADR-094's canonical completion condition, read it at continuation decisions, and clear it only at a ratified terminal condition. The Claude Code skill, including `claude -p` and its `/goal` branch, remains unchanged.

**Release vehicle**: `.changeset/steady-goals-anchor.md`

## Fix Released

Released in `@windyroad/itil@2.1.2` (merge commit `fa8a43f77fd07e57015df8155a81f4bbb5ba6a14`, PR #456, released 2026-08-29).

The Codex `/wr-itil:work-problems` overlay now creates or reuses the persisted Goal, inspects it at continuation decisions, and completes it only at a canonical terminal condition. The singular `/wr-itil:work-problem` projection defect remains separate, nonblocking follow-up work.

Awaiting user verification.

Release evidence: `.changeset/steady-goals-anchor.md` was consumed by version-packages commit `87fa432d9b1c91008a9e8322d22449dcb89363c2`; the released 2.1.2 changelog cites fix commit `98d01c0a`.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P526, P527

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P390** (`docs/problems/known-error/390-agent-declares-all-done-prematurely-while-actionable-backlog-remains.md`) — the driver behind Step 0e. Its 2026-07-05 reopen established that Gate (0) alone is insufficient because the same actor decides both "should I stop" and "is stopping justified". The Codex projection reinstates exactly that configuration.
- **ADR-094 / RFC-047 / STORY-040** — the decision, RFC and story that landed the `/goal` external-evaluator anchor.
- **P526** (`docs/problems/open/526-codex-projection-sanitizer-corrupts-yaml-frontmatter.md`) — same projection pipeline, same blind-substitution root shape, different surface (YAML frontmatter vs. runtime-specific prose).
- **P527** (`docs/problems/open/527-codex-skill-names-render-with-a-duplicated-plugin-prefix-and-title-case-branding.md`) — same projection pipeline, name field.
- `packages/itil/skills/work-problems/SKILL.md` Step 0e — the source contract and the canonical completion condition.
- `packages/itil/scripts/codex-work-problems.md` — the Codex runtime overlay carrying the passive Goal line.
- `packages/itil/scripts/sync-codex-skills.mjs` lines 116-133 — the substitution table that rewrites the Claude Code anchor prose.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-070 | STORY-070: Leave the Codex backlog draining until no dispatchable work remains | in-progress |

**Hang-off check (Step 2b)**: not dispatched. The mechanical pre-filter on the `/wr-itil:work-problems` signal returned more than 40 candidates, over the 5-candidate cap, so the candidate-cap short-circuit fired per the SKILL contract. The nearest absorb candidates are the Codex-projection cluster P526 and P527; both are transform-level defects in the sanitizer's field handling, whereas this is a missing runtime branch in the skill body and overlay, so a sibling ticket is the honest shape. Re-evaluate the cluster at the next `/wr-itil:review-problems` pass.
