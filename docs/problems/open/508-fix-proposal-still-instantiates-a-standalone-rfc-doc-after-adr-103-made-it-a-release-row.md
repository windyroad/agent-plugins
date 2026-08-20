# Problem 508: The fix proposal still instantiates a standalone RFC document, after ADR-103 made it a release row

**Status**: Open
**Reported**: 2026-08-20
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: the gate fires at every fix-time surface, including the AFK loop transitively, and instantiates the artefact the current decision says is no longer the vehicle. Worse than redundancy — under ADR-103 the map is the approval surface, so a fix proposed as a standalone document never reaches it, and the approval model the decision installed is bypassed for exactly the proposals the framework creates on the maintainer's behalf. Likelihood 5: known gap, no control, and the contradictory branch is the shipped default on every RFC-less Known Error.
**Origin**: internal
**Effort**: L — derived at capture. The gate branch is small, but the decision it must implement is not: whether the standalone RFC tier survives at all, what `capture-rfc` becomes, and how a gate that currently allocates an id and writes a file instead draws a row on a map that may not exist yet. Sized level with P506 — both reverse a shipped design premise.
**JTBD**: JTBD-001
**Persona**: developer

## Description

ADR-103 (accepted 2026-08-07) collapsed the RFC into the story map:

> **A release row is an RFC.** A row is the set of stories that ship together to fix a problem. It carries an `rfc` identity once a problem proposes it […] **Working a problem** now runs: reach Known Error with a root cause and a workaround, then propose the fix as one or more release rows on new or existing maps, recorded on the problem ticket.

The shipped code does not do this. In `@windyroad/itil@1.1.1`, `manage-problem`'s I13 propose-fix gate still runs the pre-ADR-103 path: on a Known Error whose problem no RFC traces, it delegates to `/wr-itil:capture-rfc --fix-time`, which allocates the next RFC id and writes a new `docs/rfcs/RFC-<NNN>-<slug>.proposed.md`. Nothing in that path draws a release row on any map.

So two contradictory fix-proposal mechanisms are live at once, and the one the framework reaches for automatically is the superseded one.

Maintainer direction 2026-08-20, verbatim: *"The fix proposal is supposed to be the rfc row (or rows), not a new doc."*

## Symptoms

- Every RFC-less Known Error that reaches propose-fix mints a standalone RFC document rather than a row.
- Those documents are born `human-oversight: unconfirmed` and ratified at `manage-rfc accepted` — a second approval surface competing with the map that ADR-103 designated as *the* approval surface.
- 54 RFCs currently lack human oversight (SessionStart nudge, 2026-08-20). Some unknown fraction are this mechanism's output.

## Workaround

Propose the fix as a row by hand and skip the gate's auto-create. Not systematic — the gate fires first and does not ask.

## Impact Assessment

- **Who is affected**: the maintainer on every fix, and adopters identically once they work a Known Error. The AFK loop dispatches its fix work through this same traversal, so it inherits the behaviour without a separate code path.
- **Frequency**: every RFC-less Known Error reaching propose-fix.
- **Severity**: governance-model divergence rather than breakage. Nothing errors; the framework simply keeps building the artefact its own current decision retired.
- **Analytics**: none. Nothing counts RFC documents created after 2026-08-07.

## Root Cause Analysis

ADR-103 amended ADR-060 and superseded ADR-101, and its Decision Outcome rewrote what "propose the fix" means. The `manage-problem` I13 gate was not brought along. Its prose still cites ADR-071 / ADR-072 / ADR-073 — the decision lineage that predates the collapse — and its no-vehicle branch still names `capture-rfc --fix-time` as "the canonical ADR-070-compliant vehicle".

The gate is not broken against the decisions it cites. It is correct against a superseded lineage, which is the harder failure to see.

### What this ticket must NOT re-litigate

The seven blank RFC skeletons (`RFC-021`, `026`, `029`, `030`, `032`, `033`, `034` — `## Scope` and `## Tasks` still carrying `(deferred — populate at /wr-itil:manage-rfc accepted transition)` while their driving problems are closed or in verification) were **already ruled on**. P314's `## Human decision — 2026-07-03` records the maintainer's call: transition them to reflect shipped state, do not flesh them out, and no policy revisit is needed because the creation process was changed to prevent recurrence — that change being the `--fix-time` flag, which makes `capture-rfc` author a real Scope and Tasks at creation.

Two consequences worth stating plainly:

1. **The blanks are a settled outcome awaiting a lifecycle transition, not neglect.** The remaining work on them is transitioning seven files, which the 2026-07-03 decision already authorised.
2. **`check-autocreate-rfc-scope.sh` does not know that.** It re-flags all seven every retro as the ADR-073 under-scoped signal, and reported `under_scoped=7` again on 2026-08-20 — where it was read as fresh evidence that the reassessment criterion had fired. It had fired, and was answered, in July. The detector has no notion of a ruled-on candidate, so it will keep manufacturing that signal every retro until the seven are transitioned.

The genuinely new ground here is ADR-103 plus the 2026-08-20 direction, not the blanks.

## Direction — 2026-08-20

Both blocking design calls were put to the maintainer and answered. Verbatim: *"No standalone rfc doc. Capture-rfc gets repointed"*.

- **The standalone RFC document tier does not survive ADR-103.** No new `docs/rfcs/RFC-<NNN>-*.md` file is created for a fix proposal. The existing corpus becomes historical — the question as put offered "`docs/rfcs/` becomes historical" as the alternative and that is what was chosen, so existing documents are read-only history rather than a live tier to be migrated document-by-document.
- **`/wr-itil:capture-rfc` is repointed, not retired.** It keeps its name and its invocation surface; what it *writes* changes from a document to a release row on a story map.

This resolves the two tasks that blocked the rest of this ticket. The remaining work is now unblocked, and the substance is settled ahead of it per ADR-074.

**Not yet ratified as an ADR.** The direction above is the maintainer's answer to a two-option question, not itself a recorded decision — per P357, applying user direction to a governance artefact does not by itself authorise the oversight marker. The decision is captured as an ADR born `human-oversight: unconfirmed`, and ratified only after the maintainer sees what the ADR body actually says.

### Investigation Tasks

- [x] Decide whether the standalone RFC document tier survives ADR-103 at all — **resolved 2026-08-20: it does not; `docs/rfcs/` becomes historical**
- [x] Decide what `/wr-itil:capture-rfc` becomes — **resolved 2026-08-20: repointed at row-drawing on a map, not retired**
- [ ] Record the two decisions above as an ADR and have it ratified
- [ ] Settle what a repointed `capture-rfc` does when the fix needs a map that does not exist yet — ADR-103 queues implementation for a new map because a new map is new substance needing a human, so the repointed skill cannot mint one silently
- [ ] Settle whether the RFC id series continues across the tier change, or whether row identities allocate from a fresh series
- [ ] Decide what `manage-rfc` becomes — it currently owns the `accepted` ratification of a document tier that is going away, while ADR-103 puts approval on the map
- [ ] Rework the I13 no-vehicle branch to propose rows; settle what it does when the fix needs a map that does not exist yet, given ADR-103 queues implementation for a new map because that is new substance needing a human
- [ ] Re-check ADR-073's auto-create decision against ADR-103 — it authorises auto-creating a vehicle whose definition has since changed
- [ ] Transition the seven blanks per the 2026-07-03 ruling, so the detector stops re-flagging them
- [ ] Give `check-autocreate-rfc-scope.sh` a way to exclude ruled-on candidates, or retire it if the tier goes
- [ ] Audit the 54 unratified RFCs for how many are this mechanism's post-2026-08-07 output
- [ ] **Blast radius, measured 2026-08-20.** 62 documents live under `docs/rfcs/`, and **24 non-test files** across the plugins reference the path: 8 skills (`capture-rfc`, `manage-rfc`, `capture-problem`, `manage-problem`, `capture-story`, `manage-story`, `list-stories`, `work-problems`, plus `run-retro` in the retrospective plugin), 5 hooks (`itil-rfc-oversight-nudge`, `itil-rfc-trailer-advisory`, `itil-commit-trailer-transition-advisory`, `itil-deferral-cadence-gate`, `manage-problem-enforce-create`), and 8 scripts (`reconcile-rfcs`, `mark-rfc-capture-gate`, `check-rfc-rejected-alternatives`, `evaluate-relevance`, `render-story-map.mjs`, and the three `update-*-references-section` helpers). Retiring the tier is a sweep across all of them, not an edit to one gate. Sequence it so the *writers* stop first and the *readers* keep working against the historical corpus, or the reverse-trace helpers break while 62 documents are still on disk.
- [ ] **The fix surface is wider than the I13 branch.** The pre-ADR-103 lineage is asserted at four sites in `packages/itil/skills/manage-problem/SKILL.md` — the lifecycle prose at line 51, the lifecycle **table** at line 58, the I13 gate at line 185, and the closing lifecycle recap at line 680 — each stating that the fix proposal "produces the RFC per ADR-072". Reworking only the gate would leave three sites teaching an agent the superseded model. Sweep all four, and grep the wider corpus for the same phrasing before assuming they are the only ones.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — the two blocking design calls were answered 2026-08-20; see Direction above)
- **Composes with**: P314, P457, P170

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over four candidates; none carries this root cause, and no ticket in the corpus that cites ADR-103 is an I13 or fix-vehicle ticket.

- **P314** (`docs/problems/verifying/314-…md`) — the ticket that *established* the mechanism this one says ADR-103 superseded; its RFC-005 B-tasks all shipped. Absorbing this would grow a shipping ticket's scope to include the invalidation of its own design. Its 2026-07-03 human decision is the ruling quoted above, and stands.
- **P371** (`docs/problems/closed/371-…md`) — closed and verified 2026-07-24. Its root cause is *which* RFC the gate traces to (wire an existing vehicle rather than mint a duplicate); this one is *what an RFC now is*. Orthogonal to the artefact's shape.
- **P457** (`docs/problems/open/457-…md`) — mirror image: ratification ordering on story maps, where a human is asked to approve placeholder text. Shares the skeleton-artefact signal, different defect. Sibling for a `/wr-itil:review-problems` cluster pass rather than a parent.
- **P170** (`docs/problems/known-error/170-…md`) — the RFC tier's origin ticket. This is the reconciliation of what it built with ADR-103's collapse, not a further phase of building it.
- **ADR-103** (`docs/decisions/103-a-release-row-is-the-rfc-and-the-map-is-the-approval-surface.proposed.md`) — the decision the gate contradicts.
- **ADR-107** (`docs/decisions/107-a-story-maps-rfc-list-is-derived-from-its-release-rows.proposed.md`) — derives a map's RFC list from its rows, reinforcing that the row carries the identity.
