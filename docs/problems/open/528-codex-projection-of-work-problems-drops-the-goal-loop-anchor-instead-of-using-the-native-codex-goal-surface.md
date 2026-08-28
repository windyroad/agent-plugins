# Problem 528: Codex projection of work-problems drops the Goal loop-anchor instead of using the native Codex Goal surface

**Status**: Open
**Reported**: 2026-08-29
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 — derived at capture. Impact 3: Step 0e's external-evaluator anchor is the reopened-P390 defense against the orchestrator declaring `ALL_DONE` while dispatchable tickets remain. In Codex that defense is absent, so the loop degrades to the same-actor self-assessment P390 was reopened to fix — an AFK drain can stop early and leave the backlog unworked. This is loop-discipline loss on the AFK surface, not corruption: no ticket, decision, or repository state is damaged, and Gate (0) still fires as the first-line self-check. Impact is not higher because the degradation is honest-by-design in the source contract (`below the floor the loop degrades honestly to Gate (0)-only behaviour`) — the defect is that Codex is treated as below the floor when it is not. Likelihood 5: it is a property of the projection output and the Codex runtime overlay, not of any particular session, so every Codex run of the drain loses the anchor.
**Origin**: internal
**Effort**: S — derived at capture. Two files: a runtime-branch in `packages/itil/skills/work-problems/SKILL.md` Step 0e giving Codex its own arm alongside the existing Claude Code arm, and the Codex runtime overlay `packages/itil/scripts/codex-work-problems.md` (47 lines) whose one Goal line is passive and conditional. The canonical completion condition already exists and is reused verbatim; nothing new has to be designed. Sized alongside P526 and P527, which touch the same Codex projection pipeline for the same reason — cf. P527.
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
- The projected Step 0e text is rewritten by the sanitizer's `Claude Code` → `Codex` and `\bClaude\b` → `Codex` substitutions (`packages/itil/scripts/sync-codex-skills.mjs` lines 122-123), so the generated skill instructs the agent to use *"Codex's native `/goal` command (>= v2.1.139)"* and links to `code.claude.com/docs/en/goal`. Neither the command nor the version floor exists in Codex, so the instruction is unexecutable.
- Step 0e's honest-degradation clause (*"below the floor the loop degrades honestly to Gate (0)-only behaviour"*) therefore fires in every Codex session. Codex is treated as below the requirements floor by accident of projection, not because it lacks the capability.
- Net effect: a Codex AFK drain runs with Gate (0) self-assessment only — exactly the configuration ADR-094 / RFC-047 / STORY-040 reopened P390 to move away from.

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: developers running the AFK backlog drain from a Codex session.
- **Frequency**: every Codex invocation of `/wr-itil:work-problems`.
- **Severity**: the loop keeps its first-line objective self-check (Gate (0)) but loses the external check layered over it. Premature `ALL_DONE` becomes possible again on the Codex surface.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Establish the concrete Codex Goal API surface — how a Goal is created, read, and completed from inside a running skill, and whether it is available to the orchestrator session only (the Claude Code anchor is orchestrator-session-only per Step 0e's placement clause; iters must not inherit a backlog-empty goal).
- [ ] Add a Codex arm to Step 0e that creates-or-reuses the Goal with the canonical completion condition verbatim, alongside the retained Claude Code `/goal` arm.
- [ ] Make the Codex arm inspect the Goal at the continue/stop decision and complete it only on printed-Gate-(0)-zero-dispatchable + `ALL_DONE`.
- [ ] Replace the passive line 15 in `packages/itil/scripts/codex-work-problems.md` with the active create/inspect/complete contract.
- [ ] Stop the sanitizer from rewriting the Claude-Code-specific `/goal` prose into an unexecutable Codex instruction — the runtime branch should be authored, not substituted (composes with P526, which is the same class of blind-substitution damage in frontmatter).
- [ ] Add a behavioural check that the projected Codex skill does not instruct the agent to invoke `/goal` or cite a `code.claude.com` URL.
- [ ] Create a reproduction test.

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

**Hang-off check (Step 2b)**: not dispatched. The mechanical pre-filter on the `/wr-itil:work-problems` signal returned more than 40 candidates, over the 5-candidate cap, so the candidate-cap short-circuit fired per the SKILL contract. The nearest absorb candidates are the Codex-projection cluster P526 and P527; both are transform-level defects in the sanitizer's field handling, whereas this is a missing runtime branch in the skill body and overlay, so a sibling ticket is the honest shape. Re-evaluate the cluster at the next `/wr-itil:review-problems` pass.
