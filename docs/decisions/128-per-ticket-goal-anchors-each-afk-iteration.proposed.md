---
status: "proposed"
date: 2026-09-18
decision-makers: [Tom Howard]
consulted: []
informed: []
supersedes: ["ADR-094 (in part — the orchestrator-session-only goal-placement rule at Decision Outcome item 1, and the item-2 premise sentence that no agent-settable goal surface exists; the rest of ADR-094 stands)"]
reassessment-date: 2026-12-18
human-oversight: confirmed
oversight-date: 2026-09-18
---

# Per-ticket goal anchors each AFK iteration

**Supersedes:** [ADR-094](094-afk-loops-anchor-completion-with-native-goal-evaluator.proposed.md) (in part — the orchestrator-session-only goal-placement rule, and the premise that no agent-settable goal surface exists; the rest of ADR-094 stands, and it is deliberately not renamed, because partial supersession leaves a decision in force).

## Context and Problem Statement

The AFK backlog loop dispatches one subprocess per ticket. Today only the *orchestrator* session carries a completion anchor; each iteration subprocess runs unanchored, relying on its own judgement to decide it is finished with the ticket. That is the same single-actor conflation the orchestrator-level anchor was introduced to break — one level down, and still open.

Three things prompted revisiting it.

First, the two skills disagree about how iteration even works. The singular work-a-problem skill states that the plural orchestrator "loops through the backlog by WSJF, delegating each iteration to this skill" and that it is "the plural orchestrator's per-iteration unit". The plural orchestrator does no such thing: its dispatch step hand-rolls a prompt that invokes the manage-a-problem workflow directly and never names the singular skill. The documented contract and the implementation have drifted apart, and the documented one is what a maintainer remembers.

Second, the earlier decision's placement rule is written wider than the reasoning that produced it. Its text says the goal lives on the orchestrator session and *never* on an iteration subprocess. Its stated reason is narrower: a goal scoped to *backlog-empty* would push an iteration past the one-ticket carve-out that makes iterations cheap and isolated. A goal scoped to *this one ticket* does the opposite — it holds the iteration to exactly the carve-out. The blanket prohibition therefore forecloses a shape its own rationale does not argue against.

Third, the earlier decision's premise that no agent-settable goal surface exists has since become false on one of the two runtimes this repo ships for. That runtime exposes goal read, set and clear directly, and the eval suite already exercises all three. A decision resting on the impossibility of a thing the test suite demonstrates needs correcting.

The earlier decision is ratified, so its body is immutable and cannot be narrowed in place. This decision supersedes those two parts of it and leaves the rest standing.

## Decision Drivers

- An iteration that stalls part-way through a ticket has no external check on its self-assessment; the orchestrator's anchor cannot see inside a subprocess.
- Whatever anchors an iteration must reinforce the one-ticket carve-out, never push past it. An anchor that keeps an iteration working after its ticket is done is worse than no anchor.
- The orchestrator's idle-timeout guard must keep working. It infers "stuck" from absence of new commits against wall-clock; anything that legitimately holds an iteration open after its final commit is indistinguishable from a hang, and a false kill loses the subprocess's result metadata entirely.
- The two runtimes this repo supports differ in whether an agent can set a goal for itself. A rule that silently assumes one of them will be wrong on the other.
- Moving the evaluator from one stream per loop to one per iteration is a recurring background spend the developer cannot see coming. The job that owns token budget across the week covers unattended loops as well as foreground sessions, and explicitly carves this axis out of the backlog-progress job — so the earlier decision's "negligible" cannot be inherited, it has to be re-argued or measured.
- The refresh of the backlog ranking is already assigned to the orchestrator's pre-flight, before the work loop opens. An iteration that re-runs it is duplicating work the framework gave to someone else.
- The documented relationship between the two skills should become true rather than be quietly deleted.

## Considered Options

1. **Per-ticket goal, discharged by the iteration's own end-of-run summary** — the orchestrator dispatches the singular work-a-problem skill pinned to the selected ticket, anchored by a goal naming that ticket's legitimate printed end states. The condition is written so that it is satisfied by exactly the summary block the iteration already prints, so it falls away at the moment the iteration would have exited anyway.
2. **Leave placement alone (do nothing)** — keep the anchor on the orchestrator only. Iterations stay bounded by their natural one-ticket exit and the orchestrator's own backlog re-scan.
3. **Per-ticket goal plus a goal-aware idle guard** — same anchor as option 1, but additionally teach the orchestrator's poll loop a new activity signal so that an iteration held open by an unmet goal is not mistaken for a hang.
4. **Per-ticket goal bounded by a turn cap** — anchor the iteration but cap the number of turns it may take.

## Decision Outcome

Chosen option: **"Per-ticket goal, discharged by the iteration's own end-of-run summary"**, because it adds the missing external check at the iteration level without adding any new machinery, and because tying the condition to an artefact the iteration already emits is what keeps it clear of the idle guard.

Six points follow.

**Placement — one rule.** A goal scoped to a single ticket is permitted on an iteration and becomes the default dispatch shape. A goal scoped to draining the backlog remains forbidden on an iteration — that is the shape the superseded rule was actually arguing against, and it still stands. The orchestrator keeps its own drain-scoped anchor unchanged. This rule is about goal *scope*, and scope is independent of runtime; it holds everywhere.

**Carrier — two mechanisms.** How the per-ticket goal reaches an iteration differs by runtime, and only the mechanism differs, never the rule. On the Claude Code surface prose cannot observe a terminal and a print-mode subprocess offers nothing to sniff, so the carrier is a declaration the dispatcher makes in the iteration prompt, and the singular skill keys its behaviour on that declaration being present. This is a property of that runtime's surface, not of goals generally — the Codex surface exposes goal read, set and clear directly, and carries the same rule by setting the per-ticket goal natively at dispatch. Naming the carrier matters: a rule keyed on something the skill cannot observe would silently collapse to always or never.

**Discharge, and the idle guard.** The per-ticket condition must be satisfiable by exactly the artefacts the iteration already prints. The orchestrator's idle guard infers progress from new commits; an iteration held open past its final commit by an unmet condition presents precisely the signature the guard kills on, and a kill at that point loses the run's metadata. Binding the condition to the end-of-run summary means it is discharged in the same breath as the summary is printed, so the guard never sees the ambiguous state. The rejected alternative — teaching the guard a new goal-aware activity signal — adds machinery for a state this framing prevents from arising.

**Condition text, and what it deliberately does not cover.** The condition must enumerate every way an iteration can legitimately end *while still running*, or it will push an iteration that genuinely cannot progress into expanding its scope rather than reporting a clean skip. Those are three: worked, carrying a commit reference; skipped, carrying a skip-reason category (the return contract already makes that mandatory on a skip); and halted, naming a concrete blocker. Quota exhaustion is **not** among them and must not be written into the condition. It surfaces as a non-zero subprocess exit with no summary printed at all — the process and its evaluator are simply gone — so it is detected out-of-band by the orchestrator's existing exit-code check, which is the only surface that can see it. A condition naming an end state the iteration cannot print is unsatisfiable by construction. Note this is a genuine difference from the orchestrator's own condition, where quota exhaustion *is* reported in the summary and therefore *can* be named; the two conditions are different conditions, not two copies of one.

**Scope of the pinned short-circuit.** The singular skill skips its ranking-freshness check when it is invoked against a pinned ticket **and** the dispatch declares the run unattended. It is the absent user, not the pin, that makes the refresh wrong there: the refresh delegates to the review skill, whose verification prompt is unanswerable in a subprocess, and whose ranking rewrite is an off-grain commit inside a per-ticket unit of work. On the *interactive* pinned path the user is present, the prompt is answerable, and it is a deliberate piggyback that keeps pending verifications from accumulating off-ledger. That path is left exactly as it is. Narrowing here matters: the unattended loop has other surfaces carrying the verification cadence, and the interactive singular path has none, so a blanket short-circuit would delete a self-firing cadence and hand the developer something to remember.

**Evaluator cost.** The superseded decision characterised evaluator spend as typically negligible against main-turn spend. That characterisation was scoped to a single goal on a single orchestrator session and is **not** carried forward to per-iteration placement, which multiplies it by iteration count; applying the ratified phrase to this surface would be exactly the ungrounded qualitative claim our grounding rule bans. The position is to measure rather than pre-budget. That obligation is concrete, not aspirational: the per-invocation result carries the evaluator's usage as its own model entry, but the orchestrator's cost extraction is a deliberately closed, named-fields allowlist, so an entry not named there is spent and never counted. The evaluator's usage entry is therefore added to that allowlist in the same change and reported as its own line, distinct from the worker's. Without that, "measured" would be true in principle and false in practice, and the reported session cost would under-report what the loop actually spent. Whether that spend falls inside the window the burn-rate throttle reads is **unverified**. Both branches are live: if it does, heavier loops will brake sooner; if it does not, the increase is invisible to the pacing machinery. Resolving this is named in the reassessment criteria rather than guessed at here.

### Empirical grounding

Probed 2026-09-18 on Claude Code 2.1.276. A single print-mode invocation carrying a goal condition followed by the work instruction both set the anchor and executed the work: the named artefact was created, and the run ended on its own once it existed. The result envelope carried two model entries — the worker, and the small fast model performing the evaluation, at roughly twenty-four thousand cache-creation tokens for one trivial turn.

That establishes the three things this decision rests on: one invocation can both anchor and work; the condition discharges the moment the named artefact exists, which is what keeps it clear of the idle guard; and the evaluator's spend is observable per invocation from the envelope the orchestrator already parses, which is what makes measure-rather-than-pre-budget a real option instead of an aspiration.

The Codex carrier is not a projection either — the eval suite already exercises goal read, set and clear on that runtime, and a shipped instruction pack carries it.

## Consequences

### Good

- Each iteration gains an external check on its own completion, closing the same single-actor gap at the iteration level that the orchestrator anchor closed at the loop level.
- The documented relationship between the two skills becomes true: the orchestrator really does dispatch the singular skill as its per-iteration unit.
- An iteration that cannot progress is pushed toward an explicit skip with a stated reason rather than a silent early exit.
- Removes an interactive prompt and an off-grain ranking commit from the unattended dispatch path, without touching the interactive path that relies on them.
- One rule covers both runtimes, so the next runtime difference is a carrier question rather than a reopened decision.
- No new orchestrator machinery. The idle guard, the poll loop, the return contract and the commit grain are all untouched.
- Iteration-workflow naming moves out of the orchestrator's very large skill body and into the skill that owns it.

### Neutral

- Each iteration acquires a second model's usage in its result envelope. It is visible and attributable, but it is a new number in the cost report that readers will need to interpret.
- The dispatch prompt keeps its full constraint block. Only the invocation target changes, so the prompt does not get shorter.
- The pinned path now behaves differently depending on whether the dispatch declares the run unattended. That is the correct distinction, but it is one more branch to hold in mind when reading the singular skill.

### Bad

- Evaluator spend per iteration is unmeasured today and is not assumed negligible. It scales with transcript length and turn count, and an iteration transcript is the full working context. The first loops under this decision are the measurement.
- Whether that spend is seen by the burn-rate throttle is unknown, so one of two consequences will be discovered rather than chosen.
- A condition whose enumeration of end states is wrong in either direction causes harm: too narrow and a stuck iteration is pushed into scope expansion; too wide — naming an end state the iteration cannot print, such as quota exhaustion — and it is unsatisfiable by construction. The enumeration is load-bearing prose, not a mechanism.
- The relationship between the goal condition and the return-summary contract becomes a coupled pair: change the summary shape and the condition must change with it.
- Two carriers mean a runtime can drift from the rule without the rule looking wrong. The carriers need checking separately.

## Confirmation

- The orchestrator's dispatch step names the singular work-a-problem skill pinned to the selected ticket, and the existing constraint block is retained verbatim.
- The orchestrator's skill body states the placement rule in its narrowed form — a goal scoped to the whole backlog drain belongs on the orchestrator session and never on an iteration; a goal scoped to the single ticket an iteration is working belongs on that iteration. The displaced blanket form is removed from the shipped surface rather than left standing alongside the new one. (This restates, narrowed, the confirmation criterion the superseded decision placed on the same surface.)
- The delivery artefacts that still assert the blanket form — the draft story's unchecked acceptance criterion and the corresponding proposal line — are rewritten to the narrowed cross-runtime form, so no open criterion can re-introduce the displaced rule.
- The per-ticket condition enumerates the three printed end states named above, and does **not** name quota exhaustion.
- No iteration is ever dispatched with a backlog-drain-scoped condition.
- The singular skill short-circuits its freshness check only when invoked against a pinned ticket **and** the dispatch declares the run unattended, and it names the declaration it keys on. On that path it does not consult the ranking, does not delegate a refresh, does not prompt, and does not commit. The interactive pinned path is unchanged and still fires the verification prompt.
- Every statement that no agent-settable goal surface exists is scoped to the Claude Code surface rather than stated absolutely, in both skills.
- The three stale claims in the singular skill that the orchestrator delegates via the agent-spawn mechanism are corrected to the subprocess mechanism.
- The evaluator's usage entry is named in the orchestrator's cost-extraction allowlist, and each iteration's reported cost carries it as its own line, distinct from the worker's.
- Both copy-paste blocks in the loop-anchor step embed the canonical condition text verbatim as a substring, with the invocation carrier only as prefix or suffix; the canonical block carries a source marker in the existing in-repo convention.
- A containment check asserts that embedding mechanically: it exits non-zero on divergence, a CI step runs it, and a test set covers its divergence-detection mode. It is proven to fail against a synthetic divergence before being wired, so it cannot pass vacuously on an empty extraction. This is the check-only variant of that shape — there is no sync script, because a prose block carrying a prefix or suffix invocation carrier cannot be mechanically regenerated from the canonical.
- The loop-anchor eval rubric asserts the surfacing invariants rather than a line count, and scopes its no-programmatic-surface claim to the Claude Code runtime so the sibling native-tool cases stay consistent.
- The singular skill traces the backlog-progress job in its Related section and inline on the new short-circuit branch.
- A behavioural check shows that an iteration dispatched against a ticket it cannot progress emits a skip carrying a skip-reason category, rather than expanding its scope.

## Pros and Cons of the Options

### Option 1 — Per-ticket goal, discharged by the iteration's own summary

- Good: adds the external check exactly where it is missing.
- Good: no new machinery; the idle guard is untouched because the ambiguous state never arises.
- Good: makes the documented skill relationship true.
- Bad: evaluator cost per iteration is unmeasured and not assumed small.
- Bad: couples the condition text to the return-summary shape.
- Bad: cannot cover an end state the iteration never prints, so quota exhaustion stays on a separate detection path.

### Option 2 — Leave placement alone

- Good: zero change, zero new cost, no new coupling.
- Good: the ratified placement rule stays untouched.
- Bad: leaves the iteration-level self-assessment gap open, which is the whole point.
- Bad: leaves the two skills contradicting each other, and leaves the interactive prompt on the unattended dispatch path.
- Bad: leaves a premise standing that this repo's own eval suite falsifies.

### Option 3 — Per-ticket goal plus a goal-aware idle guard

- Good: tolerates conditions that are not tied to a printed artefact.
- Bad: new machinery in the most delicate part of the orchestrator, for a state option 1 prevents from occurring.
- Bad: a second progress signal to keep correct alongside the commit-timestamp one.

### Option 4 — Per-ticket goal bounded by a turn cap

- Good: bounds evaluator spend directly.
- Bad: re-creates the premature-stop failure a turn cap was already rejected for once; a cap stops an iteration for arithmetic reasons rather than because the work reached an end state.

## Reassessment Criteria

Revisit when any of these hold:

- Measured evaluator spend per iteration proves material against worker spend, in which case a budget position is needed rather than the measure-and-watch stance taken here.
- The question of whether evaluator spend is seen by the burn-rate throttle is answered, since each answer implies a different follow-up.
- The return-summary contract changes shape, since the condition text is coupled to it.
- Iterations are observed being killed by the idle guard while productively turning, which would falsify the claim that binding the condition to the printed summary keeps the ambiguous state from arising.
- The Claude Code surface gains a programmatic mid-session goal surface, which would collapse the declaration carrier into a direct set and leave one mechanism instead of two.
- The interactive singular path gains another surface carrying the verification cadence, which would make the blanket short-circuit safe after all.
- A third runtime is supported, since the carrier question reopens per runtime even though the rule does not.

## Related

- [ADR-094](094-afk-loops-anchor-completion-with-native-goal-evaluator.proposed.md) — superseded in part by this decision; the rest stands and it is deliberately not renamed.
- [ADR-116](116-ratified-decisions-change-only-by-supersession.proposed.md) — the authority requiring this be a new decision rather than an edit to the ratified one; partial supersession is permitted and precedented, and the scope-qualified frontmatter form follows that precedent.
- [ADR-017](017-shared-code-duplicated-into-per-package-lib-kept-in-sync.proposed.md) — the canonical-plus-check shape the containment drift check inherits, taken here in its check-only variant.
- [ADR-075](075-promptfoo-agent-prose-verdict-eval-harness.proposed.md) — the harness authority for the loop-anchor rubric. The superseded decision anchored its eval floor on a decision that has since been superseded on an unrelated subject; that stale pointer is not carried forward.
- JTBD-006 (Progress the Backlog While I'm Away) — the job the iteration-level anchor and the unattended short-circuit serve.
- JTBD-010 (Sustain My Token Quota Across the Week and Across Surfaces) — the job the evaluator-cost position rests on; it covers unattended loops as well as foreground sessions and explicitly carves that axis out of JTBD-006.
