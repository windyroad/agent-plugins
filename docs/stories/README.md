# Story Backlog

> Last reviewed: 2026-08-29 **STORY-072 accepted** — I6-I10 and map-derived I12 passed; all three criteria are backed by the committed P368 evidence.
>
> Run `/wr-itil:manage-story review` to re-rank, or `/wr-itil:reconcile-stories` to repair index drift against filesystem truth.

## Jobs to be Done

This index serves two persona-jobs per ADR-051 sibling pattern (JTBD-anchored README rule):

### developer

- **JTBD-008 (Decompose a Fix Into Coordinated Changes)** — primary fit. Stories are the INVEST-shaped + JTBD-anchored sub-workstream entities a story map decomposes into. Each story names a slice of value that can be implemented, tested, and traced to its driving problem + RFC + JTBD. The story-level surface is where the `/wr-itil:work-problem` traversal lands ("first not-done story") so dispatch is unambiguous.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — secondary fit. Story files carry their own INVEST checks at acceptance (per I10); acceptance criteria all-ticked + linked-RFC-closes auto-transitions a story from in-progress → done. Per-edit governance applies to story files via the same hook exemption surface as problem tickets.

## Status

`docs/stories/` is the canonical home for **user story** artefacts per ADR-060 (Problem-RFC-Story framework) Phase 2. Stories are the *slices a story map decomposes into* layer of the four-tier governance hierarchy:

| Tier | Surface | Encoding | Lifecycle | Captures |
|------|---------|----------|-----------|----------|
| Problem | `docs/problems/<state>/` | markdown | `Open → Known Error → Verifying → Closed` (or `Parked`) | What hurts |
| ADR | `docs/decisions/` | markdown | `proposed → accepted → superseded` | How we decided to solve it |
| RFC | legacy `docs/rfcs/` file or ADR-103 story-map release row | markdown / map JSON island | legacy lifecycle or row-derived status | What we're shipping to solve it |
| Story Map | `docs/story-maps/<state>/` | HTML (`*.html`) | `draft → accepted → in-progress → completed → archived` | How the work decomposes spatially across backbone × ribs × slices |
| **Story** | **`docs/stories/<state>/`** | **markdown (`*.md`)** | **`draft → accepted → in-progress → done → archived`** | **One slice of a story map; INVEST-shaped + JTBD-anchored** |

This directory is **live**. P170 Phase 2 Slice 4 shipped `/wr-itil:capture-story` + `/wr-itil:manage-story`, Slice 8 migrated the P170 bootstrap slices, and Slice 9 shipped `/wr-itil:reconcile-stories`. Capture stories with `/wr-itil:capture-story`, move them through the lifecycle with `/wr-itil:manage-story`, and repair index drift with `/wr-itil:reconcile-stories`.

## Story filename grammar

`docs/stories/<state>/STORY-<NNN>-<kebab-case-title>.md`

- `<state>` — one of `draft`, `accepted`, `in-progress`, `done`, `archived`. Note: stories use `done` (not `completed`) at the terminal state, mirroring INVEST acceptance vocabulary; story maps use `completed` because a map "completes" when all its stories reach `done`.
- `<NNN>` — three-digit zero-padded ID. ID-collision-guard extension to story enumeration in `docs/stories/` per ADR-019 (P170 Phase 2 Slice 2 work).
- `<kebab-case-title>` — kebab-slug derived from the story's user-value statement.

## Story markdown frontmatter shape

YAML frontmatter at the top of every story file. Required fields are non-optional; optional fields may be omitted at draft and become required at accepted via I7 + I8 hard-block.

```yaml
---
status: draft | accepted | in-progress | done | archived
story-id: <kebab-slug>             # matches the title slug in the filename
reported: YYYY-MM-DD               # date the story was captured
decision-makers: [<name>, ...]     # who can move the story through lifecycle states
problems: [P<NNN>, ...]            # REQUIRED (I7 invariant) — driving problem(s)
jtbd: [JTBD-<NNN>, ...]            # REQUIRED at accepted (I8 invariant) — anchor persona-job(s)
rfcs: [RFC-<NNN>, ...]             # REQUIRED at accepted (I9 invariant) — the RFC(s) shipping this story
story-maps: [STORY-MAP-<NNN>, ...] # REQUIRED at accepted (I9 invariant) — the story map(s) this story belongs to
estimated-effort: S | M | L | XL   # REQUIRED at accepted (I10 INVEST Estimable)
---
```

## Story body structure

Sections appear top-to-bottom in this order. Required sections must be present at capture time; sections marked **(accepted-gate)** must be present at the `draft → accepted` transition to satisfy I10 INVEST checks.

> **No `**Status**:` body line.** Lifecycle state lives in frontmatter `status:` only. It used to be mirrored here, and because the oversight fingerprint excludes the frontmatter key but hashed the body copy, advancing a story from `draft` to `accepted` drifted its own hash — so a story that had just been ratified read as unratified and the no-implement gate denied its own implementing commit. Do not reintroduce the line; `wr-itil-migrate-story-status-mirror` removes it from an existing corpus. See ADR-090's 2026-07-29 amendment and P474.

```markdown
# STORY-<NNN>: <Title>

**Reported**: <YYYY-MM-DD>
**Problems**: <P<NNN> [, P<NNN>, ...]>
**JTBD**: <JTBD-<NNN> [, ...]>
**RFCs**: <RFC-<NNN> [, ...]>
**Story Maps**: <STORY-MAP-<NNN> [, ...]>
**Estimated effort**: <S|M|L|XL>

## User value (required, INVEST Valuable)

One-paragraph user-facing value statement. "As a <persona>, I want <capability> so that <outcome>" is one shape; not mandatory but the structure must surface the persona, capability, and outcome.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Criterion 1 (observable, behavioural — not "code path X exists")
- [ ] Criterion 2
- ...

## Driving problem trace (required — I7 invariant)

Explicit prose linking each `problems:` entry to the symptom or RCA finding this story addresses.

## JTBD trace (accepted-gate — I8 invariant)

Explicit prose linking each `jtbd:` entry to the persona-job's desired-outcome that this story serves.

## Implementation notes (optional)

Free-form. Architecture sketches, code pointers, library decisions, considered-alternatives summary.

## Dependencies

- **Blocks**: (none) | <story-ID(s) that cannot start until this one is done>
- **Blocked by**: (none) | <story-ID(s) that must complete first> — Phase 2 I-invariants prohibit `Blocked by` references to unaccepted stories at acceptance time (INVEST Independent)

## Related

Links to ADRs, JTBDs, retro docs, sibling stories, and the parent story map.
```

## Commit-grain composition (per ADR-060 + ADR-014)

- **Mapping**: one story = N × ADR-014-grain commits, ordered. Stories decompose into commits via the existing single-purpose grain at the implementation layer.
- **One commit advances at most one story**. If a single commit attempts to advance two stories, the commit is mis-scoped; split.
- **Commit-message Story trailer**: commits that advance a story carry a `Refs: STORY-<NNN>` trailer. Story files' commit-history section is auto-maintained off the trailer parsing (sibling to the RFC trailer pattern from ADR-060 Phase 1 item 12).

## Story Rankings

Active (non-done) stories, from filesystem truth. Terminal stories are listed under `## Done` below.

| Status | ID | Title | Effort | Problems | RFCs | Story Map |
|--------|-----|-------|--------|----------|------|-----------|
| accepted | STORY-044 | See what cruise is doing — status/telemetry skill | M | P160, P446 | RFC-046 | STORY-MAP-003 |
| draft | STORY-045 | Outbound lifecycle comments generated from real issue context | M | P376 | RFC-028 | STORY-MAP-004 |
| accepted | STORY-047 | Gate the correction nudge on prompt authorship | S | P430 | RFC-050 | STORY-MAP-005 |
| draft | STORY-048 | Gate the inbound-discovery pre-flight on the channel list | S | P431 | RFC-051 | STORY-MAP-006 |
| draft | STORY-049 | Ask for a URL in a shape I can paste into | M | P438 | RFC-052 | STORY-MAP-007 |
| draft | STORY-050 | Have my reviewer read the version I actually have | M | P439 | RFC-053 | STORY-MAP-007 |
| draft | STORY-051 | Have generated content respect my project's conventions | M | P424 | RFC-054 | STORY-MAP-008 |
| draft | STORY-052 | Surface still-outstanding family members before a close | M | P433 | RFC-056 | STORY-MAP-009 |
| draft | STORY-053 | Test claims against the tree at capture and label the untested ones | L | P434 | RFC-057 | STORY-MAP-010 |
| draft | STORY-056 | Clear a block with a command my repository actually has | M | P435 | RFC-062 | STORY-MAP-008 |
| draft | STORY-057 | Get the fix by upgrading, not by patching a cache | M | P369 | RFC-063 | STORY-MAP-008 |
| draft | STORY-058 | Read a README that describes the version I installed | M | P152 | RFC-064 | STORY-MAP-008 |
| draft | STORY-059 | See why the loop did not work what I expected | M | P487 | RFC-065 | STORY-MAP-011 |
| draft | STORY-060 | Pick up a captured ticket and know what was observed | M | P375 | RFC-066 | STORY-MAP-011 |
| in-progress | STORY-062 | Keep problem ranking correct after a status transition | S | P498 | RFC-068 | STORY-MAP-002 |
| accepted | STORY-054 | Lifecycle transitions preserve a story's ratification | M | P474 | RFC-059 | STORY-MAP-002 |
| accepted | STORY-055 | One definition of what the oversight fingerprint ignores | M | P474 | RFC-059 | STORY-MAP-002 |
| accepted | STORY-061 | See why a SubagentStop risk receipt was not written | S | P477 | RFC-067 | STORY-MAP-002 |
| accepted | STORY-065 | A fix proposal draws a release row, not a document | M | P508 | RFC-071 | STORY-MAP-002 |
| accepted | STORY-066 | A fix I can prove works gets closed without me | M | P519 | RFC-072 | STORY-MAP-002 |
| accepted | STORY-067 | Publish packages without expiring secrets | S | P284 | RFC-073 | STORY-MAP-002 |
| in-progress | STORY-069 | Drain one Codex ticket through an isolated Codex CLI | M | P529 | RFC-075 | STORY-MAP-002 |
| in-progress | STORY-068 | Invoke a Codex skill by the name the card shows | S | P527 | RFC-074 | STORY-MAP-008 |
| in-progress | STORY-070 | Leave the Codex backlog draining until no dispatchable work remains | S | P528 | RFC-076 | STORY-MAP-011 |
| accepted | STORY-072 | Record oversight evidence only for the confirming session | M | P368 | RFC-078 | STORY-MAP-002 |
| draft | STORY-064 | A ticket that only names a decision as background stays open | M | P463 | RFC-070 | STORY-MAP-011 |
| draft | STORY-012 | Can't start coding without an RFC — the gate makes me create one first | S | P251, P314 | RFC-005 | STORY-MAP-002 |
| draft | STORY-013 | Full gate: an RFC exists → I proceed; none → I create it first | M | P251, P314 | RFC-005 | STORY-MAP-002 |
| draft | STORY-014 | Unattended, the agent works the plan and pauses for real decisions | M | P251, P314 | RFC-005 | STORY-MAP-002 |
| draft | STORY-015 | The RFC lists its stories before any code is written | M | P251, P399 | RFC-005 | STORY-MAP-002 |
| draft | STORY-016 | Every step is regression-proven | S | P251 | RFC-005 | STORY-MAP-002 |
| draft | STORY-017 | Backfill-or-supersede the skeleton RFCs the repudiated mechanism left behind | M | P399, P375 | RFC-005 | STORY-MAP-002 |
| draft | STORY-028 | Acknowledge the report on capture | S | P170 | — | STORY-MAP-002 |
| draft | STORY-029 | Share the workaround with the reporter | S | P170 | — | STORY-MAP-002 |
| draft | STORY-030 | Tell the reporter a fix is underway | S | P170 | — | STORY-MAP-002 |
| draft | STORY-031 | Tell the reporter it's released → verify → close the loop | M | P170 | — | STORY-MAP-002 |
| draft | STORY-032 | Triage the report's disposition — accept, elicit a new job, or decline | M | P170, P401 | — | STORY-MAP-002 |
| draft | STORY-033 | Loud cold-path diagnostic for oversight-marker shims | S | P368 | RFC-038 | — |
| draft | STORY-034 | Warn once per new version when a session runs stale plugin code | M | P045, P375 | RFC-036 | — |
| draft | STORY-035 | Home RFC decisions in ADRs and make the RFC-first trace unconditional | L | P310, P251 | RFC-006 | — |
| draft | STORY-036 | Write the create-gate marker under every candidate session id | M | P260 | RFC-007 | — |
| draft | STORY-037 | Commit gate honours the RISK-POLICY stated review cadence for staleness | S | P408 | RFC-043 | — |
| draft | STORY-038 | Fix-titled commits surface a lifecycle-drift advisory | deferred | P345 | RFC-044 | — |
| draft | STORY-040 | AFK loop anchored with the native `/goal` external evaluator | M | P390 | RFC-047 | STORY-MAP-002 |
| in-progress | STORY-046 | Red-CI denial explains the recovery path | S | P208 | RFC-049 | STORY-MAP-002 |


## Done

Terminal stories, from filesystem truth (`docs/stories/done/`). `Done` is the date the story file landed in `done/`.

| ID | Title | Done | Driving problems |
|----|-------|------|------------------|
| STORY-071 | Review the complete commit message once | 2026-08-29 | P415 |
| STORY-063 | Check ADR pairing in the checkout being committed | 2026-08-21 | P499 |
| STORY-042 | Extract quota-pacing into its own plugin | 2026-08-09 | P160, P443 |
| STORY-043 | Pacing starts working the moment I install it, with nothing to configure | 2026-08-09 | P160, P443 |
| STORY-001 | Hook exemption globs for docs/story-maps + docs/stories | 2026-05-12 | P170 |
| STORY-002 | `/wr-itil:capture-story` lightweight aside skill | 2026-05-12 | P170 |
| STORY-003 | `/wr-itil:list-stories` read-only display skill | 2026-05-12 | P170 |
| STORY-004 | RFC frontmatter `stories:` extension + capture-rfc / manage-rfc updates | 2026-05-12 | P170 |
| STORY-005 | Working-the-problem traversal rewrite (manage-problem + work-problem) | 2026-05-12 | P170 |
| STORY-006 | `/wr-itil:reconcile-stories` trio (skill + script + bin shim) | 2026-05-12 | P170 |
| STORY-007 | `/wr-itil:manage-story` heavyweight story lifecycle skill | 2026-05-12 | P170 |
| STORY-020 | Start the job's story map | 2026-07-03 | P170 |
| STORY-021 | Add the fix's new stories to the map | 2026-07-03 | P170 |
| STORY-022 | Ratify the story map and its stories after any change | 2026-07-03 | P170 |
| STORY-024 | Reuse stories already on the map | 2026-07-03 | P170 |
| STORY-025 | Slice the fix's stories into releases | 2026-07-03 | P170 |
| STORY-018 | Capture the problem in seconds, mid-flow | 2026-08-05 | P155 |
| STORY-019 | Find the root cause and a workaround → Known Error | 2026-08-05 | P170 |
| STORY-023 | Ship → verify → problem closes with a real trace | 2026-08-05 | P170 |
| STORY-026 | Work the RFC's stories one at a time | 2026-08-05 | P170 |
| STORY-027 | Capture a problem reported through an inbound channel | 2026-08-05 | P170 |

**Frontmatter/directory divergence — repaired 2026-08-06.** STORY-018, STORY-019, STORY-023, STORY-026 and STORY-027 carried `status: done` in frontmatter while sitting in `docs/stories/draft/`. The files were moved to `done/` so both agree, and the rows above follow. Worth knowing for next time: `wr-itil-reconcile-stories` compares the Rankings and Done tables against the filesystem, but never compares a story's own frontmatter against its containing directory — so those two can disagree indefinitely with nothing reporting it. That gap is what let a story map under-report its Live band by five. Tracked on P417.

## Reconciliation

`docs/stories/README.md` is reconciled against on-disk markdown story files by `wr-itil-reconcile-stories` (P170 Phase 2 Slice 5; `$PATH` shim per ADR-049). The reconciliation contract mirrors `wr-itil-reconcile-readme docs/problems` per P118: diagnose-only mechanical drift detector that runs as a Step 0 preflight in `/wr-itil:manage-story` invocations.

Reverse-trace pass (sibling to the RFC reverse-trace pass per ADR-060): `wr-itil-reconcile-stories docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps` detects drift in auto-maintained `## Stories` sections on problem, JTBD and legacy RFC files. For ADR-103 row-backed RFCs it verifies that the release row exists and contains the story card.

- `MISSING_REVERSE_TRACE STORY-<NNN> in <parent> ## Stories`
- `STALE_REVERSE_TRACE STORY-<NNN> in <parent> ## Stories`
- `STATUS_MISMATCH STORY-<NNN> in <parent> ## Stories claims=<X> actual=<Y>`

## Related

- **ADR-060** — Problem-RFC-Story framework. The decision that introduces this directory.
- **ADR-060 amendment 2026-05-12** — HTML for story-maps; markdown for stories (this directory's encoding stays markdown).
- **ADR-031** — per-state-subdirectory encoding pattern.
- **ADR-049** — plugin-bundled scripts via `bin/` on `$PATH`.
- **ADR-051** — JTBD-anchored README rule. This README anchors on JTBD-008 + JTBD-001.
- **ADR-052** — behavioural-tests default.
- **JTBD-008** — Decompose a Fix Into Coordinated Changes. Primary persona-job.
- **JTBD-001** — Enforce Governance Without Slowing Down. Secondary persona-job.
- **P170** — driver problem ticket.
- **`docs/story-maps/README.md`** — parent / sibling directory's lifecycle index (HTML encoding).
- **`docs/rfcs/README.md`** — sibling at the RFC tier; `stories:` frontmatter extension per ADR-060 amendment 2026-05-10.
- **Jeff Patton**, *User Story Mapping* (O'Reilly, 2014).
