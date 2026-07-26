---
status: proposed
rfc-id: capture-time-truth-discipline
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P434]
adrs: [ADR-100, ADR-011, ADR-026, ADR-032, ADR-049, ADR-052, ADR-071, ADR-089, ADR-090, ADR-096]
jtbd: [JTBD-002, JTBD-006]
stories: []
---

# RFC-057: Capture-time truth discipline — falsify premises, mark unexecuted mechanisms

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P434
**ADRs**: ADR-100 (the decision this fix implements — capture-time truth discipline, born unconfirmed), ADR-011 (incident evidence-first gate; source of the entry shape being ported), ADR-026 (agent output grounding — the sibling rule whose scope stops short of these claim classes), ADR-032 (lightweight-capture flow budget + fifth invocation pattern), ADR-049 (`bin/` shim on `$PATH` for adopter-safe resolution), ADR-052 (behavioural tests), ADR-071 (unconditional RFC-first), ADR-089 (every RFC has ≥1 story), ADR-090 (an RFC references only ratified stories), ADR-096 (a draft story is not implementable)
**JTBD**: JTBD-002 (primary — ship AI-assisted code with confidence), JTBD-006 (secondary — progress the backlog while I'm away)

## Summary

Give problem capture a way to tell a tested claim from an untested one.

Today it has neither. Both capture surfaces transcribe the reporter's or the agent's assertions straight into the committed ticket: a report that a component is missing is never checked against the tree, and a root cause nobody executed is written in the same voice as one that was. Two inbound reports record the cost — #202 produced a phantom ticket for a component that was in fact exported, and #339 saw a false mechanism replicated across a ticket body and nearly steer a fix at a problem that did not exist.

This RFC scopes two intake bricks: a **premise-falsification pass** that tests the claims which can be tested, and a **`## Hypotheses` section** that gives the ones which cannot a place to sit that is honestly labelled. The substantive choices inside both bricks are recorded in ADR-100 and are **not settled** — this RFC scopes and decomposes the work; it decides nothing (ADR-070).

## Driving problem trace

- **P434** (`docs/problems/known-error/434-capture-flows-write-unverified-premise-and-root-cause-claims-as-fact.md`) — Known Error, root cause confirmed 2026-07-26, `Origin: inbound-reported (#202, #339)`. The ticket carries the three confirmed findings, the reproduction, the two-brick design, and the two live design questions.

The shape of the gap is what makes this a real hole rather than an oversight: both capture paths already contain verification-shaped steps — `capture-problem` sub-step 2a greps ticket filenames for duplicates, sub-step 2b dispatches the `hang-off-check` subagent to ask whether a parent should absorb the scope — and **every one of them asks a ticket-space question**. None asks the world-space one. The description is transcribed verbatim (`capture-problem/SKILL.md:264`; `manage-problem/SKILL.md:476,483`).

Two adjacent decisions look like they cover it and do not. ADR-011 ships exactly the evidence discipline needed, but only on the incident surface (`mitigate-incident/SKILL.md:80-88`) — the problem templates have no `## Hypotheses` section, though `transition-problem/SKILL.md:81`'s Known-Error checklist already presumes the distinction. ADR-026 binds numeric estimates and magnitude descriptors, so a truth-apt non-numeric claim passes it untouched. ADR-100 records the decision that fills that gap.

## Scope

The fix is two bricks, both at intake, both advisory so neither can block an AFK capture (ADR-013 Rule 6 queue-and-continue).

**Brick 1 — the premise-falsification pass.** A new `capture-problem` Step 1.7, reused by `manage-problem`'s new-problem path around Step 4b. It extracts existence and absence claims from the post-flag-strip description — the assertion shapes plus any named file, package or symbol token — runs bounded tree reads against them, and classifies each claim `falsified`, `corroborated` or `untestable`. On a falsified claim the ticket is still captured (P401 never-discard) and the contradiction travels with it in-body, so the next reader meets it before fix planning rather than after. The bound on those tree reads is ADR-032's lightweight-capture flow budget: this is an aside surface, and a pass that blows the budget defeats the surface it protects.

**Brick 2 — the `## Hypotheses` section.** ADR-011's entry shape is ported verbatim onto both problem templates — `- [ranked] <claim> — Evidence: <ref, or "none — unexecuted">. Confidence: <low|med|high>.` — and `## Root Cause Analysis` is reserved for executed, cited findings. Reusing the incident surface's exact vocabulary is the point: one evidence dialect across incidents and problems, nothing new to learn or lint.

One implementation, two call sites. Drift between the two capture surfaces is its own recurring defect class in this repo, so the pass is written once and invoked twice rather than transcribed. Whatever detection lands in committed shell resolves through an ADR-049 `$PATH` shim — never a repo-relative `packages/...` path from a shipped SKILL, which resolves only in this monorepo and not in an adopter install.

Implementation is **held** pending ADR-100's ratification. Two of its three axes are open, and they determine what gets built: what a falsified premise does to the capture (Axis 1) and how much of the pass is committed shell versus a fresh-context subagent (Axis 2). ADR-073 requires the decision ratified before implementation; ADR-096's draft-story gate is the mechanism that enforces it. Behavioural coverage per ADR-052 — the three criteria in ADR-100's Confirmation section, including the no-existence-claims regression case — is part of the same story, not a follow-on. Structural greps over SKILL prose do not count (P081). A changeset for `@windyroad/itil` ships both bricks; adopters inherit them on release.

Out of scope:

- **Close-time truth discipline.** The same evidence-versus-inference failure recurs where the relevance-close evaluator reads a bare decision citation as proof a fix shipped (P463). Same class, opposite end of the lifecycle, separate surface (`evaluate-relevance.sh`), separate ticket. It lands as a second rib on STORY-MAP-010 when it drives a story — not folded in here.
- **Widening ADR-026.** Considered and foreclosed in ADR-100's Considered Options; ADR-026 is `human-oversight: confirmed`, so a Scope amendment is a P357 substance change with no AFK path.
- **The incident surface.** ADR-011 already covers it; this RFC ports from it and does not change it.
- **Story, story-map and RFC capture surfaces.** Their own intake carries the same theoretical gap; ship under separate tickets when demand emerges.

## Stories

Brick 1 and Brick 2 are decomposed as a single story on **STORY-MAP-010** (Trust that a ticket states only what was verified) — they share one surface, one release and one set of acceptance criteria, so splitting them would produce two stories neither of which is independently shippable.

The `stories:` array stays empty in this iteration. An RFC may reference only ratified stories, and a story captured under AFK is born `human-oversight: unconfirmed` (ADR-090). This RFC therefore stays `proposed` and lists no stories; the array and the story's `accepted` transition are both wired at the ratification drain, after which implementation may begin (ADR-096 — a draft story is never implementable).

## Commits

(rendered from `git log --grep "Refs: RFC-057"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no implementation commits yet; the governance commits that preceded this one are `e6f1697c` for P434's root cause and `ab73735a` for ADR-100.)

## Related

- **ADR-100** (`docs/decisions/100-capture-time-truth-discipline-for-problem-tickets.proposed.md`) — the decision. Axis 1 (what a falsified premise does to the capture) and Axis 2 (how much of the pass is committed shell) are the open substance choices; Axis 3 (where hypothesis-marking homes) is near-settled. Queued for the interactive ratification drain.
- **P463** — the close-time sibling; same evidence-versus-inference class, deliberately out of scope here.
- **P401** — never-discard; binds Axis 1 and is why a falsified premise still produces a ticket.
- **RFC-013** — P346's backlog-flow-control multi-phase RFC, whose Phase 3 put the `hang-off-check` on the same Step 2 of the same two skills. Considered as a host for this work and **rejected** on architect ruling: its phases are P346's phases and its checks verify ticket-space, so wiring P434 into its `problems:` array would claim a fix vehicle it does not carry — P371's failure mode inverted.
- `packages/itil/skills/capture-problem/SKILL.md`, `packages/itil/skills/manage-problem/SKILL.md` — the two surfaces to change.
- `packages/itil/skills/mitigate-incident/SKILL.md` — the shipped prior art Brick 2 ports.
</content>
