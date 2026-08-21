# Problem 487: The loop overwrites the ranking that justified its own choices, so afterwards you cannot see why it worked what it worked

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 4 (Low) — Impact: 2 × Likelihood: 2. Rated down 2026-08-09 on maintainer direction: this is a **diagnostic reached for on surprise**, not a standing need. Nobody audits a run they are happy with. Likelihood 2: the evidence is destroyed on every run, but it is only *missed* when something looks wrong — and the trigger is usually not "why that one" but **"why not the other one"**. Impact 2: when it does bite you cannot answer the question and have to replay git history, which is annoying rather than damaging; nothing produced is wrong.
**Origin**: internal
**Effort**: M — record the decision at the moment it is made; the inputs are all in hand, nothing needs recomputing
**WSJF**: 2 — (4 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-006
**Persona**: developer

## Description

The loop's choice of what to work next is fully determined and fully documented. Step 3 partitions the backlog into three tiers — critical-bypass, inbound-reported, internal — works the highest non-empty tier, and within it applies a multi-key sort: WSJF descending, Known-Error first, effort-divisor ascending, reported-date ascending, id ascending. There is no judgement in it.

So the choice is legible **in principle**. The problem is that it is not legible **afterwards**.

The SKILL states the shortcut plainly: *"the cache-fresh path can therefore read the rendered table top-to-bottom and the first row is the orchestrator's pick"*. The pick is the top row of `docs/problems/README.md`'s WSJF Rankings **as it stood at that moment**.

And the loop rewrites that table constantly. Capturing a problem regenerates it. Transitioning one regenerates it. A single overnight run does both many times. By the time anyone reads the summary, the ranking that produced every choice in it has been overwritten by the choices themselves.

### What the summary does and does not carry

The end-of-run summary reports **Completed** (problem, action, result), **Skipped** (problem, skip-reason category, reason), and **Reported Upstream**. Skipping is explained. Choosing is not — because it was never a judgement, it was a sort, and nobody records the state of a sort.

The result: you can see that it worked P029 and skipped P016 for a stated reason. You cannot see what else was dispatchable at that moment, where P029 sat relative to them, or whether a higher-ranked ticket was passed over. Reconstructing it means replaying the backlog's state from git history, ticket by ticket, which nobody will do.

### The question is usually about an omission

The maintainer's framing, and it inverts the emphasis this ticket was first written with: you do not go looking because you wonder why P029 was worked. You go looking because something you expected to be worked **was not**, and you need to find out whether it was ranked below the line, skipped for a stated reason, or never seen at all.

Those three outcomes are indistinguishable afterwards. The summary's Skipped table covers the middle one. The first and third — outranked, or invisible — leave no trace at all, and the third is the one that matters, because a ticket the loop never saw is a ticket that will keep not being seen.

### Why this is a trust problem rather than a reporting one

The map this sits on is called *"Trust the AFK loop's autonomous conduct"*. The loop's authority to work unattended rests on its selection being defensible. Defensible-in-principle and inspectable-afterwards are different properties, and only the second survives contact with a morning.

It also hides the failure mode the tiering exists to prevent. There is recorded precedent of a Tier-1 inbound-reported ticket being skipped entirely — the gate-(0) re-scan was added because of it. A skipped tier is exactly the error this evidence gap makes unnoticeable.

## Symptoms

- A summary listing work done, with no way to tell what was passed over.
- Reconstructing a night's decisions by replaying git history over the backlog.
- Being unable to answer "why did it do that one first?" without re-deriving the ranking.
- A tier skip going unnoticed because nothing recorded which tier was non-empty at the time.

## Workaround

Read the summary for what was done, and accept the ordering on trust. There is no record to check it against.

## Impact Assessment

- **Who is affected**: whoever returns to an unattended run and has to decide whether to trust what it did.
- **Frequency**: the evidence is lost on every multi-iteration run; it is missed only when a run's output is surprising, which is uncommon.
- **Severity**: trust and auditability. Nothing produced is wrong; the reasoning behind it is simply gone.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the ranking is treated as derived state — regenerable from the tickets — so nothing thought to preserve it. That is true at any instant and false across time, because the loop mutates the tickets it derives from. The decision record was implicit in a surface that the decision itself changes.

### Investigation Tasks

- [ ] Decide what gets recorded, and where. The minimum that answers the question is: the tier worked, the dispatchable set at that moment, and the winning ticket's position in it. The inputs are all in hand at Step 3 — this is recording a decision, not recomputing one.
- [ ] Make the record answer the **omission** question first, since that is what sends anyone looking. Given a ticket the maintainer expected to see worked, the record should distinguish outranked, skipped-with-reason, and never-considered. The third is the serious one and currently the least visible.
- [ ] Decide where it lives. Candidates: the iteration's entry in the summary, a line on the worked ticket itself, or a run log. The summary is where someone will look; the ticket is where it stays attached to the work.
- [ ] Check the tier-skip case specifically. Whatever is recorded should make "a non-empty higher tier was passed over" visible, since that is the error the tiering exists to prevent and the one this gap conceals.
- [ ] Keep it proportionate. A full backlog snapshot per iteration would be noise nobody reads; the goal is to answer one question, not to archive state.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **P442** — the rankings table distinguishes tiers only by row order and the Origin column. Adjacent: that is about reading the table now, this is about the table not existing later. Both are legibility of the same surface.
- **P248** — WSJF effort as time and token cost rather than t-shirt sizes. Changes an input to the sort; does not make the sort's output inspectable.
- **JTBD-002** — its outcome that an audit trail exists showing governance was followed. Selection is the one governed step of the loop with no trail.
- **STORY-MAP-011** — this backs the "Decide what to do" card on the map named for trusting the loop's autonomous conduct.

(captured via /wr-itil:capture-problem; the duplicate-check surfaced twelve matches on wsjf/rank/select/audit, of which P442 and P248 are the only near ones — both concern the ranking's inputs and presentation, neither its survival past the run that used it.)


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-059 | STORY-059: See why the loop did not work what I expected | draft |
