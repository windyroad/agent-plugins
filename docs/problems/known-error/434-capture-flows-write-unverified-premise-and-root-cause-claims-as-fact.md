# Problem 434: Capture flows write unverified claims (premise + root-cause mechanism) as established fact

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#202, #339)
**Effort**: L — re-rated M → L 2026-07-26 at the Open → Known Error transition (P047 live-estimate rule). The documented Fix Strategy resolves to multiple files within one plugin: a new committed predicate + its behavioural bats, plus SKILL + template edits on BOTH capture surfaces (`capture-problem`, `manage-problem`). Grounded on the scope-shape of P347 (extend `evaluate-relevance.sh` with four evidence shapes — rated L for script + per-shape bats + SKILL amendment + changeset, the same brick set); P347 carries no `Actual Effort:` field, so per ADR-026 this citation grounds the **scope shape**, not a measured duration.
**WSJF**: 6 — (12 × 2.0) / 4 (re-rated 2026-07-26 at K→E transition; Known Error multiplier 2.0 offsets the L divisor, so rank is unchanged)
**JTBD**: JTBD-002
**Persona**: developer

> **Anchoring re-derived 2026-07-26** (`wr-jtbd:agent` ruling, this iteration). The captured `JTBD-101` / `plugin-developer` pair was the AFK auto-capture default, not a considered anchor. JTBD-101 is about plugin-package structure and skill-authoring templates and does not touch claim truthfulness. **JTBD-002 (Ship AI-Assisted Code with Confidence)** is the precedented home: ADR-026's own Decision Drivers cite JTBD-002 for this exact concern — *"confidence erodes when users discover agent outputs were fabricated"* — and used it to ground a rule reaching non-code agent output, so P434 widens an established scope rather than opening a new one. Persona corrected to `developer` per JTBD-002's own frontmatter and the `developer` persona's no-dedicated-review-process constraint. JTBD-006 stays a cross-reference, not the anchor. Both anchors are already `human-oversight: confirmed`, so no ratification is queued for them.

## Description

`/wr-itil:capture-problem` (and the `manage-problem` new-problem path) commit tickets without (a) falsifying the reporter's *premise* against the local tree (#202: "component X is missing" when X is in fact exported → phantom ticket), and (b) marking unexecuted *root-cause mechanism* claims as hypotheses rather than fact (#339: a false mechanism replicated into multiple body locations nearly steered a fix at a non-existent problem). Both are the same capture-time truth-discipline defect: reporter/agent assertions land as fact with no verification step.

## Symptoms

- A ticket asserts a premise ("X missing") that a quick grep would falsify, and states an unexecuted root-cause mechanism as established fact — both surviving into the committed ticket and downstream fix planning.
- **2026-07-26 (P425 iter) — the same gap on the ROOT-CAUSE / FIX-STRATEGY authoring path, and for a distinct claim class: *governance-status* claims.** Drafting P425's Reproduction section, the agent wrote two false claims in the established-fact voice: (a) that ADR-052's `structural-permitted` carve-out was available as justification for shipping a structural test, when ADR-052 line 133 **repealed** both escape hatches on 2026-06-09 and line 187 lists the very test cited as precedent (RFC-010 T3) as a P290-tracked violation; and (b) that the guard was "not behaviourally testable until the promptfoo harness lands", when `packages/architect/agents/eval/promptfooconfig.yaml` had existed for roughly a month carrying two `[Unratified Dependency]` cases. Both were one `grep` / `ls` from falsification. Neither was caught by any capture- or authoring-time check — the architect gate caught them on review, i.e. by luck of that gate firing on a different file in the same change set. Two scope extensions this witness adds: **(1) the trigger is not confined to capture.** The current framing covers `capture-problem` / `capture-incident` intake; this instance was a Known Error's `## Root Cause Analysis` + `## Fix Strategy` authored during `manage-problem`, so the same discipline is owed at fix-authoring time, not only at intake. **(2) governance-status claims are their own class.** "This ADR clause permits X", "this carve-out applies", "this harness does not exist yet" are existence/status claims about the repo's *own governance surface*, and they rot precisely because superseded prose stays on disk and reads identically to live prose. The planned existence-claim-falsification brick would catch class (b); class (a) needs the sharper check — before citing an ADR clause as permission, confirm no later amendment *within the same ADR* has repealed it.

- **2026-08-20/21 — a third scope extension: the claim need not be the agent's own invention. It arrives from a trusted intermediary, and is repeated in the established-fact voice without opening the artefact it describes.** Four instances in one session, all one `Read` from falsification:
  1. **A queue entry.** The SessionStart pending-questions hook surfaced an entry queued 2026-07-29 asserting *"ADR-090's Decision Outcome still reads 'Any change'"*. It was repeated to the maintainer as fact and put to them as a live decision. The ADR was never opened. It had been reconciled 2026-07-30 in commit `dd78d937` and carries `human-oversight: confirmed`; the maintainer was asked to re-decide a settled question. Recorded on P452 and P474.
  2. **A detector's output.** `check-autocreate-rfc-scope.sh` reported `under_scoped=7`, which was relayed as the ADR-073 reassessment criterion "firing for real". P314's `## Human decision — 2026-07-03` had already ruled on that exact population. The detector has no notion of a ruled-on candidate, so it re-emits the signal every retro — and the signal was read as fresh without checking what it referred to.
  3. **A reviewer's figure.** The JTBD reviewer's *"12 shipped skills, hooks and scripts"* was carried verbatim into ADR-119, landing 31 lines from the agent's own *30* for the same population. The real number is 28 code files. The reviewer flagged its own error on re-review; the agent had propagated it without a recount.
  4. **A pre-filter's path.** The hang-off dispatch supplied `docs/problems/open/371-…md` for a ticket that lives under `closed/`. The arbiter caught it.
- **The common shape**: an assertion sourced from a hook, a detector, a subagent, or a queue is treated as pre-verified because *something in the system produced it*. It is not. Each of these carries a timestamp older than the artefact it describes, and none re-validates on read. The falsification cost is one `Read` or one `grep` in every case.
- **Also witnessed at the argument level, not just the claim level.** Two of ADR-119's load-bearing arguments reasoned from mechanisms that do not fire: a collision argument from *series sparseness* against an allocator that uses `max()+1` (immune to sparseness — the real defect was live and worse), and a *"closes the bypass"* consequence contradicted by the same document's own Confirmation criterion three sections later. Both read plausibly. Neither survived review. A premise-falsification check on individual claims would not have caught either.

## Workaround

Before working an `inbound-reported` ticket, manually grep the local tree for every existence-claim the `## Description` makes, and treat any un-cited `## Root Cause Analysis` prose as a hypothesis until re-derived. Costs a few minutes per ticket and depends on the maintainer remembering; it is the reason the defect keeps reaching fix-planning rather than being caught at intake.

Partial automated coverage exists but at the wrong end of the lifecycle: `/wr-itil:work-problems` Step 3.6 + `/wr-itil:review-problems` Step 4.6 run `evaluate-relevance.sh`, whose `file-no-longer-exists` shape is a world-space check — but it fires at *close* time, not capture time, and P463 records it currently over-firing at a 76% false-positive rate, so it cannot be leaned on.

## Impact Assessment

- **Who is affected**: maintainer + adopters; phantom tickets and misdirected fixes.
- **Frequency**: any capture where the premise/mechanism is asserted without a verification pass.
- **Severity**: High — wrong-premise tickets waste whole iters and can ship fixes at non-problems.

## Root Cause Analysis

Confirmed 2026-07-26 by reading the two capture surfaces end to end. Findings are split **observed** (read off the committed SKILL sources, cited by file:line) vs **inferred** (reasoning not executed against the original inbound captures) per ADR-026.

### Finding 1 — no world-space verification step exists on either capture path (observed)

`packages/itil/skills/capture-problem/SKILL.md` runs Step 0 (README preflight) → 1 (parse flags) → 1.5b (persona/JTBD) → 2 (duplicate + hang-off) → 3 (next ID) → 4/4a (template + rating) → 5 (write) → 6 (commit) → 7 (report). No step between parsing and writing reads the local tree to test any claim the description makes. The description is transcribed verbatim: the Step 4 template's `## Description` body is literally `<full description from $ARGUMENTS, with leading recognised flags stripped>` (`capture-problem/SKILL.md:264`).

`/wr-itil:manage-problem`'s new-problem path has the same shape. Its Step 4 derive-first dispatch table resolves Description as *"Pull verbatim from `$ARGUMENTS` prose into Step 5's `## Description` section"* (`manage-problem/SKILL.md:476`) and Symptoms as *"infer from description verbatim"* (`manage-problem/SKILL.md:483`). Step 4b is a concern-boundary (multi-concern split) check only (`manage-problem/SKILL.md:494-516`).

The decisive detail: **both capture paths already contain verification-shaped steps, and every one of them tests ticket-space rather than world-space.** Sub-step 2a greps ticket *filenames* for duplicates; sub-step 2b dispatches the `wr-itil:hang-off-check` subagent to ask whether an existing parent ticket should absorb the scope (`capture-problem/SKILL.md:127-213`). Both answer *"does another ticket already cover this?"*. Neither answers *"is what this ticket asserts actually true of the tree?"*. The gap is not an oversight in an otherwise unverified flow — it is a whole missing axis in a flow that is otherwise carefully verified.

### Finding 2 — the framework already owns the hypothesis-marking shape, on the incident surface only (observed)

The evidence discipline P434(b) asks for is **already decided and already shipped** — for incidents. Per ADR-011, `/wr-itil:mitigate-incident` blocks the first mitigation attempt until the incident's `## Hypotheses` section carries at least one entry in the shape

```
- [ranked] <hypothesis> — Evidence: <log/repro/diff/metric reference>. Confidence: <low|med|high>.
```

(`mitigate-incident/SKILL.md:80-88`, gate prose at `:39-43`). The incident surface therefore cannot act on an unevidenced mechanism claim.

The problem surface has no counterpart. Neither ticket template (`manage-problem/SKILL.md:518-568`, `capture-problem/SKILL.md:251-297`) contains a `## Hypotheses` section at all. Root-cause claims land in `## Description` or `## Root Cause Analysis` free prose with no evidence field and no confidence marker, and nothing distinguishes an executed finding from an unexecuted guess. The only nod to the distinction is downstream and prose-only: `/wr-itil:transition-problem`'s Known-Error checklist asks that root cause be documented *"not just 'Preliminary Hypothesis'"* (`transition-problem/SKILL.md:81`) — which presumes a hypothesis/fact distinction the capture templates give the agent no way to record.

So the fix for half (b) is a **port, not an invention**: apply the ADR-011 `Evidence:` + `Confidence:` entry shape to the problem-capture template. No new vocabulary, no new gate mechanism.

### Finding 3 — ADR-026's grounding rule is scoped to estimates, not to claims of fact (observed)

ADR-026 (Agent output grounding, `human-oversight: confirmed` 2026-05-25) is the obvious candidate for already covering this, and it does not. Its in-scope clause binds *"a quantitative estimate (duration, cost, latency, frequency, size, percentage, or any other numeric value)"* plus qualitative **magnitude** descriptors (`"load is negligible"`, `"microseconds only"`), requiring cite + persist + uncertainty or an explicit `not estimated — no prior data` marker.

Neither failing claim class is an estimate. *"Component X is missing"* is an **existence claim** about the tree; *"the root cause is Y"* is a **causal claim** about a mechanism. Both are truth-apt assertions with no numeric content, so a ticket can be fully ADR-026-compliant and still assert a falsifiable premise as fact. This is the scope gap that lets the defect through, and it is why the fix cannot simply cite ADR-026 as existing authority — whether to widen ADR-026 or record a new decision is an open question (Q1 below).

### Root cause statement

Capture-time truth discipline is **unassigned**. The problem-capture surfaces verify ticket-space (duplicates, hang-off parents) but never world-space; the evidence-marking machinery that would express an unverified mechanism claim exists but was only ever wired to the incident surface (ADR-011); and the cross-cutting grounding rule that would forbid the fabrication (ADR-026) is scoped to numeric estimates and does not reach existence or causal claims. All three gaps have to be closed at the same place — intake — because every downstream consumer (WSJF ranking, `## Fix Strategy`, the I13 RFC auto-create, the ADR-060 story traversal) reads the committed ticket body as ground truth.

### Not verified (inferred — flagged per ADR-026)

- **Hypothesis, unexecuted**: that a Step-1.7 grep pass would in fact have falsified #202's premise. The original capture cannot be replayed from the local tree and the inbound issue bodies were not re-read this iteration. The claim is plausible from the ticket's own account ("X is in fact exported") but is *not* an observed result. Verification task queued below.
- **Hypothesis, unexecuted**: that #339's false mechanism was replicated into multiple body locations *because* nothing marked it as unexecuted, rather than for an unrelated authoring reason. Only the correlation is recorded on the ticket.

### Reproduction

**Field reproductions (already observed)**: inbound #202 (falsified premise survived into a committed ticket) and #339 (unexecuted mechanism replicated as fact). These are the reports that drove the capture; they are historical and cannot be re-run from the current tree, which is why the two claims in "Not verified" above stay marked as inferred.

**Static reproduction of the gap (observed 2026-07-26, re-runnable)**:

```
$ grep -rniE 'falsif|premise' packages/*/skills/ packages/*/agents/
packages/itil/skills/work-problems/SKILL.md:662: … (an unrelated prose use of "falsified")
```

No capture surface matches. Contrast the incident surface, where the same query for the evidence discipline hits a live gate:

```
$ grep -rniE 'hypothes' packages/itil/skills/mitigate-incident/SKILL.md
… :39,:80-88  evidence-first gate; "Evidence:" + "Confidence:" required before first mitigation
```

This is a structural observation used as a *reproduction of an absence*, not as a regression test — per ADR-052 / P081 the shipped coverage must be behavioural.

**Behavioural coverage the fix must add** (the real regression tests, written RED-first when the hold lifts):

- Given a description asserting `X is missing` where `X` **is** present in the tree, the captured ticket body carries the `**Premise (falsified at capture)**` line naming the contradicting evidence — and the ticket is still created (P401 never-discard).
- Given a description asserting a root-cause mechanism with no cited evidence, the captured ticket records it under `## Hypotheses` with `Evidence: none — unexecuted`, and `## Root Cause Analysis` does **not** contain the claim.
- Given a description with no existence-claims, capture output is byte-identical to today's (no regression on the common path).

### Investigation Tasks

- [x] Confirm no premise-falsification step exists on either capture path — Finding 1 (`capture-problem/SKILL.md:264`, `manage-problem/SKILL.md:476,483`).
- [x] Confirm no hypothesis/fact distinction is recordable in the problem-ticket template — Finding 2 (`manage-problem/SKILL.md:518-568`; contrast `mitigate-incident/SKILL.md:80-88`).
- [x] Determine whether ADR-026 already binds these claim classes — Finding 3: it does not; it is scoped to numeric estimates + magnitude descriptors.
- [ ] Replay #202 / #339 against the tree at their capture SHAs to convert the two inferred claims above into observed ones (verification, not a fix blocker).
- [ ] Ship the Step 1.7 premise-falsification pass per the Fix Strategy below (**held** — see Fix Strategy § AFK hold).
- [ ] Ship the `## Hypotheses` template port per the Fix Strategy below (**held**).

## Fix Strategy

Two bricks, both at intake, both advisory-and-silent-proceed so neither can block an AFK capture (ADR-013 Rule 6 queue-and-continue).

### Brick 1 — premise-falsification pass (new `capture-problem` Step 1.7; same pass reused by `manage-problem` Step 4b)

Extract **existence/absence claims** from the post-flag-strip description — the assertion shapes (`is missing`, `does not exist`, `is not exported`, `no such`, `absent`, `never <verb>s`) plus any file path, package path, or symbol token the description names. For each, run one bounded read against the local tree (`ls` / `grep -r` on the named token, capped so the check stays inside the lightweight-capture latency budget ADR-032 sets for this surface). Classify each claim `falsified` / `corroborated` / `untestable`.

On a **falsified** claim the ticket is still captured — P401's never-discard rule holds, and a wrong premise usually wraps a real friction worth recording. What changes is that the falsification travels with the ticket instead of being lost: the claim is rewritten in-body as

```
**Premise (falsified at capture)**: reporter states "<claim>"; local tree shows <finding> (evidence: `<command>` → <result>).
```

so the next reader sees the contradiction before the fix planning, not after.

Claim extraction and the bounded tree reads are mechanical and belong in committed shell with behavioural bats coverage (ADR-052). The falsified/corroborated/untestable **classification** is a judgement call over natural-language claims, and the on-point precedent is **ADR-032's fifth invocation pattern** (fresh-context-subagent-as-decision-arbiter), demonstrated by the sub-step 2b hang-off check. The architect's lean is toward that split rather than a fully-mechanical predicate, on the strength of P463: a structurally similar fully-mechanical world-space check (`evaluate-relevance.sh`'s `file-no-longer-exists` shape) is currently running at a 76% false-positive rate. The final pick is Q3 below.

> **Correction (architect review, 2026-07-26).** An earlier draft of this section cited *"ADR-060 I1 load-bearing-from-the-start"* as the authority for putting detection in committed shell. That citation is wrong: ADR-060's **I1 is the RFC-must-trace-to-a-problem invariant** and says nothing about invocation-pattern architecture. Recorded here rather than silently deleted, because writing an unverified mechanism claim in an authoritative voice is precisely the defect this ticket is about.

### Brick 2 — hypothesis marking for unexecuted mechanism claims

Port the ADR-011 incident shape to the problem templates. Add a `## Hypotheses` section to both capture templates carrying entries in the existing incident vocabulary:

```
- [ranked] <mechanism claim> — Evidence: <reference, or "none — unexecuted">. Confidence: <low|med|high>.
```

Any root-cause mechanism the capture did not execute goes here, not into `## Root Cause Analysis`. `## Root Cause Analysis` is thereby reserved for executed, cited findings — which is what `/wr-itil:transition-problem`'s Known-Error checklist (`transition-problem/SKILL.md:81`) already assumes but cannot currently enforce, because the templates give the agent nowhere else to put a guess.

Reusing ADR-011's exact entry shape is deliberate: one evidence vocabulary across incidents and problems, no second dialect to learn or lint.

### AFK hold (ADR-096)

Both bricks edit shipped plugin surfaces (`packages/itil/skills/*/SKILL.md` + a new committed predicate + bats), so they are code. Per ADR-071 the fix routes through an RFC; ADR-089 requires ≥1 story; ADR-095 requires story-map membership at capture; ADR-090 + ADR-096 put human ratification at the story's `accepted` gate and implementation requires `accepted`. Ratification has no AFK path. This iteration therefore authors the vehicle and **holds the code**; Q1–Q3 below are queued for the interactive drain.

### Outstanding design questions (queued — do not decide under AFK)

- **Q1 — where does the decision home? SETTLED 2026-07-26 by architect review: a new ADR.** Widening ADR-026's Scope was foreclosed (it is `human-oversight: confirmed`, so a Scope amendment is a P357 substance change with no AFK path, and citing it as-is would misrepresent coverage it does not have). "No new decision" was also foreclosed: ADR-073's Decision Outcome states that a choice falling outside existing ADR coverage *is* captured in a new ADR, and Finding 3 already establishes these claim-classes fall outside ADR-026. **ADR-100** is therefore authored this iteration, born `human-oversight: unconfirmed`, carrying Q2 and Q3 as its Considered Options. Its ratification is queued — ADR-073 requires the ADR be ratified *before implementation*, which the ADR-096 hold already enforces.
- **Q2 — what does a falsified premise do to the capture?** Capture-with-banner (the Fix Strategy's assumption, following P401 never-discard) versus halt-and-report-to-reporter (which is what would actually have kept #202's phantom ticket out of the backlog). A genuine two-option trade-off between backlog hygiene and never losing a finding.
- **Q3 — how much of Brick 1 is committed shell?** Fully mechanical predicate + bats, versus mechanical claim-extraction in shell with a fresh-context subagent making the falsified/corroborated call (ADR-032's fifth invocation pattern, the sub-step 2b split). Affects adopter portability and the ADR-052 behavioural-coverage shape. Architect leans to the subagent split, citing P463's 76% false-positive rate on a comparable fully-mechanical world-space check.

Q1 is settled by the architect ruling below and is no longer open; **Q2 and Q3 are the live substance choices**, and they home in ADR-100 as its Considered Options rather than in this ticket or in RFC-057 (ADR-070 bars decisions from living in RFCs).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P463 (relevance-close evaluator over-fires — a bare ADR/skill citation read as "fix shipped"). Same evidence-vs-inference honesty class, opposite end of the lifecycle: P434 is intake writing an unverified claim as fact, P463 is close-time reading a citation as fix evidence. Both fail by treating a mention as a verified finding, so the fix vehicle is scoped to hold both. Also distinct from the capture-problem family P185 (classification) / P199 (halt) / P281 (path) / P383 (persona-enum) — none covers premise or claim verification.

## Related

- Inbound issues #202, #339.
- **ADR-011** — incident evidence-first gate; source of the `Evidence:` + `Confidence:` hypothesis entry shape Brick 2 ports.
- **ADR-026** — agent output grounding; scoped to numeric estimates, does not reach existence/causal claims (Finding 3). Widening it was considered and rejected as the vehicle (Q1, settled).
- **ADR-032** — two bearings: the fifth invocation pattern (fresh-context-subagent-as-decision-arbiter) is the on-point precedent for Brick 1's implementation split (Q3), and the lightweight-capture flow budget bounds how much tree-reading the pass may do. This bullet previously miscited "ADR-060 I1" for the split; struck per the architect correction recorded in the Fix Strategy above.
- **ADR-052** — behavioural-coverage-by-default (with P081), governing the shape of Brick 1's tests.
- **ADR-100** — the decision this fix homes in, authored 2026-07-26, born `human-oversight: unconfirmed`; carries Q2 and Q3 as its Considered Options.
- **RFC-057** / **STORY-MAP-010** / **STORY-053** — the fix vehicle authored 2026-07-26 and held pending ratification.
- `packages/itil/skills/capture-problem/SKILL.md`, `packages/itil/skills/manage-problem/SKILL.md` — the two surfaces to change.
- `packages/itil/skills/mitigate-incident/SKILL.md` — the shipped prior art Brick 2 mirrors.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-057 | proposed | Capture-time truth discipline — falsify premises, mark unexecuted mechanisms |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-053 | STORY-053: Test claims against the tree at capture and label the untested ones | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
