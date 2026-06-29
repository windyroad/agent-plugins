---
status: "proposed"
date: 2026-06-28
human-oversight: confirmed
oversight-confirmed-date: "2026-06-29 — ratified via AskUserQuestion: self-firing-trigger cadence-annotation contract (±5-line window; advisory-first rollout; trigger-CLASS-not-existence + tickets-excluded limits named) confirmed as written"
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-09-28
---

# Authoring-time cadence-annotation contract — how a deferral declares the self-firing trigger that will fire it

## Context and Problem Statement

P375 generalised the standing root cause (P291/P295, memory `feedback_automatic_cadence_or_it_doesnt_happen`): the repo conflates a **named re-entry point** (a `/skill`, a lifecycle transition, "next review") with a **self-firing cadence**. A deferral that names `/wr-itil:manage-rfc` rots because nothing self-fires `manage-rfc` on that artefact. ADR-084 shipped the surfacing-only Option-A census (a SessionStart surfacer that re-counts accumulated rot every session). The user then ratified **Option C** — the authoring-time enforcement gate that stops a new uncadenced deferral being authored *at source*, the root-cause complement to the census.

Building Option C needs a decision the census did not require: **by what contract does a deferral declare that it is cadenced?** The "correct" test — that the deferral's trigger chain is transitively reachable from a self-firing event — requires a reachability model of the whole trigger graph, which is hard to compute mechanically at authoring time. A tractable contract is needed that an authoring-time hook can actually check, without the full graph.

## Decision Drivers

- **Tractability at authoring time** — the check must run in a Write/Edit hook on the newly-authored text, not require a repo-wide graph walk.
- **Attack the P375 conflation directly** — the contract must REJECT a deferral that cites a bare on-demand skill or ticket ID as its "cadence", because that bare-naming IS the bug.
- **Declarative-first house pattern (ADR-040/045)** + the staged-rollout precedent (ADR-057) for cluster-shaped governance rules (P375 is textbook cluster-shaped — ~12 instances).
- **False-positive safety** — this repo's governance corpus is saturated with descriptive deferral prose (P375's own body, RFC bodies, the census's own marker definitions); a gate that blocks legitimate authoring is high-cost.
- **Plugin self-containment (ADR-002/003)** — the itil hook must not source the `@windyroad/retrospective` census vocabulary lib at runtime.
- **Honest scope boundary** — the core slice cannot prove a cited trigger actually fires; it must not silently pretend otherwise.

## Considered Options

1. **Compute the transitive-reachability graph at authoring time** — for each deferral, walk the trigger graph and prove it terminates in a self-firing event. Most correct; intractable in a per-edit hook; reject for the core slice (kept as a deferred later slice — RFC-035 task B6).
2. **Explicit cadence-annotation contract naming a self-firing CLASS** — a deferral is legal iff its window carries a citation of a self-firing-CLASS trigger (a hook `*.sh`, `SessionStart`, `PreToolUse`/`PostToolUse`, `.github/workflows/`, `cron`, a `work-problems` pre-flight). The recommended carrier is `<!-- cadence: <trigger> -->`; a bare prose mention of a self-firing surface also satisfies. A bare on-demand skill (`/wr-foo:bar`) or ticket ID (`Pnnn`/`RFC-nnn`/`ADR-nnn`) does NOT satisfy.
3. **Reuse the P234 `itil-fictional-defer-detect.sh` citation set as-is** — it already checks for a "scheduled-future-surface" near a deferral. Reject: that set ACCEPTS bare on-demand skills and ticket IDs, which is precisely the P375 conflation; reusing it would bake the bug in.

## Decision Outcome

Chosen option: **Option 2 — explicit cadence-annotation contract naming a self-firing CLASS.** It is checkable in a per-edit hook (no graph walk), it directly rejects the P375 conflation (Option 3's defect), and it leaves the genuinely-hard graph validation as an honest deferred slice rather than over-building it now.

**The contract**:

- A **deferral phrasing** (`deferred to <X>`, `pending review`, `re-rate at next`, `(deferred …`, `next review`, `when ready`, `lands in Slice N`, …) authored into a shipped artefact is **cadenced** iff a self-firing-CLASS citation appears within its +/-5 line window.
- **Self-firing CLASSES** (cadence-satisfying): a hook `*.sh`; `SessionStart`; `PreToolUse`/`PostToolUse`; `.github/workflows/` (CI); `cron`; a `work-problems` Step-0x / pre-flight reference.
- **NOT cadence** (the P375 refinement, deliberately excluded): a bare named on-demand skill (`/wr-foo:bar`), a bare ticket ID, "next review", "when ready". Naming an on-demand re-entry point and treating it as a cadence is the conflation P375 names illegal.
- **Recommended carrier**: `<!-- cadence: <self-firing-trigger> -->`. The comment is documentation sugar; the discriminator is the self-firing-CLASS token, wherever it appears in the window.

**Scope**: shipped authoring surfaces only — `SKILL.md`, `docs/decisions/*.md` (ADRs), `docs/rfcs/*.md` (RFCs), hook `*.sh`. `docs/problems/` tickets are EXCLUDED (they descriptively narrate deferrals as their subject; highest false-positive surface; already covered by the ADR-084 census).

**Rollout mode (core slice)**: **advisory** (PostToolUse, stderr, exit 0), per ADR-040/045 declarative-first + ADR-013 Rule 6 fail-open + ADR-057 staged rollout. The architect review (2026-06-28) judged the user's loop-end ratification was at the *mechanism-class* grain (Option C vs Option A), leaving block-vs-advisory unratified at the *rollout-mode* grain; escalation to a PreToolUse hard block is a queued user-owned decision once the advisory's false-positive rate is measured (RFC-035 task B9 / P375 Outstanding Question).

**The trigger-CLASS-not-existence boundary (named loudly)**: the core slice validates that the cited cadence names a self-firing CLASS — it does NOT validate that the named trigger actually exists or fires on that artefact. Citing a plausible-but-fictional hook name passes this slice. That residual gap (itself a P375 failure mode) is closed by the deferred transitive-reachability graph check (RFC-035 task B6).
<!-- cadence: RFC-035 task B6 is re-surfaced every SessionStart by retrospective-deferral-census.sh until built -->

## Consequences

- **Good**: new uncadenced deferrals are caught at authoring time (root-cause intervention, not just session-start surfacing); the P375 conflation is rejected by construction; the hard graph check is honestly deferred, not faked; advisory rollout absorbs false-positive risk before any hard block.
- **Bad / residual**: a fictional self-firing-CLASS citation (a hook name that doesn't exist) passes the core slice; descriptive deferral prose in newly-authored governance docs can produce advisory false-positives (tolerable because advisory). Both are tracked (RFC-035 B6; rollout-mode B9).
- **Neutral**: the P234 `itil-fictional-defer-detect.sh` retains its own (laxer) vocabulary for now; convergence is RFC-035 task B7, deliberately not done here to avoid cross-plugin coupling (ADR-002/003).

## Confirmation

Verified by the 15 behavioural bats in `packages/itil/hooks/test/itil-deferral-cadence-gate.bats` (per ADR-052 — assert emitted stderr, never source-grep). Substance ratification of this contract design (and the rollout-mode call) is queued to the next interactive drain per P357 — born `human-oversight: unconfirmed` because the user's loop-end ratification was of the Option-C *mechanism class*, not of this as-designed contract.

## More Information

- **P375** — driver problem; the uncadenced-deferral class + 4-agent reachability audit.
- **RFC-035** — the fix vehicle (core slice B1–B5; deferred tail B6–B9).
- **ADR-084** — the shipped Option-A SessionStart census this gate complements.
- **ADR-057** — staged advisory→block rollout precedent for cluster-shaped rules.
- **ADR-040 / ADR-045** — declarative-first / hook injection budget authorities.
- **ADR-013** — Rule 6 fail-open.
- **ADR-002 / ADR-003** — plugin self-containment (why itil keeps its own vocabulary).
- **P234** — the `itil-fictional-defer-detect.sh` sibling (Option 3's source; convergence is RFC-035 B7).
- **P357** — why this ADR is born `unconfirmed` under AFK.
