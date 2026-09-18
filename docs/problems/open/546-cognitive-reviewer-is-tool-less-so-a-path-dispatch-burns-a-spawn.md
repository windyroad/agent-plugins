# Problem 546: The cognitive-accessibility reviewer is tool-less, so dispatching it a file path burns a reviewer spawn

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 2: the cost is one wasted reviewer spawn and a round-trip; the agent refuses honestly rather than returning a verdict it has no basis for, so no hollow PASS ships and no artefact degrades. Likelihood 4: ADR-124 puts this review ahead of every ADR ratification, and dispatching by path is the natural shape because every sibling reviewer reads files itself — so the default caller behaviour is the failing one.
**Origin**: internal
**Effort**: S — derived at capture per Step 4a. One caller-side sentence in the skills that dispatch the reviewer, plus ADR-124's Confirmation naming the inline-text contract.
**WSJF**: 8 — (8 × 1.0) / 1
**JTBD**: JTBD-001
**Persona**: developer

## Description

`wr-architect:cog-a11y` is declared `tools: []`. Its own prompt says so plainly — *"Review the complete ADR text provided by the caller... You have no tools and must not access or change project files."* It is a text-in reviewer by design, and that design is defensible: a reviewer judging whether a document reads correctly from its own bytes has no business resolving anything outside them.

The problem is that nothing on the **caller** side says this. A caller dispatching the reviewer with a file path gets a refusal instead of a verdict, and loses the spawn.

Observed 2026-09-19 while capturing a decision record during the P509 iteration. The dispatch named the draft's path; the reviewer replied:

> I cannot run this review as dispatched... I am the tool-less fallback reviewer. I have no Read, no Bash, no filesystem access of any kind. A path is not a document to me.

It then declined to return a verdict at all, on the grounds that a PASS with no basis would be a hollow marker — the right call, and the reason this ticket is Minor rather than worse.

The asymmetry is what makes it easy to walk into. `wr-architect:agent` and `wr-jtbd:agent` were dispatched in the same message, by path, and both read the file themselves. Nothing distinguishes the three dispatches at the call site. The caller discovers the difference by burning a round.

Re-dispatching with the document pasted inline worked, and the review was worth having: it found sixteen issues on the first pass, including a substantive defect the architect reviewer had passed over twice — an admissible-evidence list written as an open set where a closed one was meant, which would have readmitted exactly the evidence the decision existed to refuse. So the cost here is friction on a review that earns its place, not an argument against the review.

## Symptoms

- A dispatch to `wr-architect:cog-a11y` naming a file path returns a refusal that names its own tool-lessness, and no verdict.
- The refusal costs a full reviewer spawn and a round-trip.
- Nothing at the call site distinguishes this reviewer from the sibling reviewers that read files themselves.
- The caller-side documentation — ADR-124, `/wr-architect:capture-adr`, `/wr-architect:create-adr` — names the reviewer but not the inline-text contract, so the knowledge lives only in the agent definition the caller has no reason to open.

## Workaround

Paste the document's full text into the prompt, front matter and all. Budget for the paste rather than a path on any decision record headed for ratification.

## Impact Assessment

- **Who is affected**: anyone recording or ratifying a decision record. ADR-124 puts the review ahead of every ratification, so this is the common path, not a corner.
- **Frequency**: every first dispatch that follows the sibling reviewers' shape — which is the natural shape.
- **Severity**: Minor. One wasted spawn per caller who has not hit it before. It does not produce a wrong verdict, because the reviewer refuses rather than guessing.
- **Analytics**: one observation, 2026-09-19, on first use in this session.

## Root Cause Analysis

The reviewer's input contract lives in the agent definition and nowhere the caller reads. `tools: []` is the agent's declaration about itself; the caller's instruction to paste the text inline is a separate statement that was never written down. Every other governance reviewer in the suite reads its own inputs, so the call-site convention the caller has learned is the wrong one here.

This is the **read-side** sibling of P469, which fixed the write-side of the same class — reviewers whose tool surface could not satisfy their gate contract. P469 deliberately scoped read-side out, classifying the pipeline scorer's inability to read a staged index as *"a separate input-contract treatment"*. That treatment is still unwritten; this ticket is a second instance of it.

### Investigation Tasks

- [ ] Decide where the caller-side contract belongs: the skills that dispatch the reviewer (`capture-adr`, `create-adr`), ADR-124's Confirmation, or both
- [ ] Check whether any other agent in the suite declares `tools: []` or otherwise needs its inputs inline, and whether those callers carry the same gap
- [ ] Decide whether the general read-side input-contract rule P469 deferred is worth stating once, rather than per-reviewer
- [ ] Behavioural coverage per ADR-052 for whichever surface carries the contract

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P469

## Related

Captured via `/wr-itil:capture-problem` from a retro-surfaced observation during the P509 iteration, 2026-09-19.

The mechanical signal pre-filter found no candidates in `open/` or `verifying/` sharing this description's `ADR-124` or `wr-architect:cog-a11y` signals, so no hang-off arbitration was dispatched. A wider manual search surfaced two near neighbours and neither absorbs this scope:

- **P469** (`docs/problems/verifying/469-…md`) — the write-side of the same class: reviewers spawned without Bash that cannot write the verdict marker their gate reads. Its fix shipped in `@windyroad/style-guide@0.6.1` and `@windyroad/voice-tone@0.8.2` and it is awaiting verification, so it is not a live parent. It also explicitly declined the read-side scope, classifying the pipeline scorer's read-side inability as needing separate treatment. Hanging this off a released ticket would reopen a closed fix for scope it deliberately excluded.
- **P510** (`docs/problems/known-error/510-…md`) — matched on the phrase "input contract" only; its subject is where a retraction gets applied, which is unrelated.

- **ADR-124** — makes the cognitive-accessibility review a precondition of ratification, which is what puts this friction on the common path.
- **P509** — the iteration that surfaced it.
