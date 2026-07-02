# Story Backlog

> Last reviewed: 2026-07-03 — **STORY-020/021/022/024/025 accepted** — RFC-037 Phase-2 cohort transitioned draft→accepted (INVEST gate I7 RFC-005 + I8 STORY-MAP-002 + I10 shape all passed); ready for implementation. Rankings-table build + parent reverse-trace deferred to a reconcile pass (README is scaffold-state; STORY-MAP-002 is HTML).
>
> Run `/wr-itil:manage-story review` to refresh once the manage-story skill ships.

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
| RFC | `docs/rfcs/` | markdown | `proposed → accepted → in-progress → verifying → closed` | What we're shipping to solve it |
| Story Map | `docs/story-maps/<state>/` | HTML (`*.html`) | `draft → accepted → in-progress → completed → archived` | How the work decomposes spatially across backbone × ribs × slices |
| **Story** | **`docs/stories/<state>/`** | **markdown (`*.md`)** | **`draft → accepted → in-progress → done → archived`** | **One slice of a story map; INVEST-shaped + JTBD-anchored** |

This directory is **scaffold-only** until P170 Phase 2 Slice 4 ships `/wr-itil:capture-story` + `/wr-itil:manage-story` and Slice 8 migrates the existing P170 bootstrap slices.

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

```markdown
# STORY-<NNN>: <Title>

**Status**: <status>
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

(Empty — no stories captured yet. Bootstrap stories from P170 Phase 1 land in P170 Phase 2 Slice 8.)

| Status | ID | Title | Effort | Problems | RFCs | Story Map |
|--------|-----|-------|--------|----------|------|-----------|

## Done

(Empty — no completed stories yet.)

| ID | Title | Done | Driving problems |
|----|-------|------|------------------|

## Reconciliation

`docs/stories/README.md` is reconciled against on-disk markdown story files by `wr-itil-reconcile-stories` (P170 Phase 2 Slice 5; `$PATH` shim per ADR-049). The reconciliation contract mirrors `wr-itil-reconcile-readme docs/problems` per P118: diagnose-only mechanical drift detector that runs as a Step 0 preflight in `/wr-itil:manage-story` invocations.

Reverse-trace pass (sibling to the RFC reverse-trace pass per ADR-060): `wr-itil-reconcile-stories docs/stories docs/problems docs/rfcs docs/story-maps` extends to detect drift in the auto-maintained `## Stories` reverse-trace section on each problem ticket / RFC / story-map. Three drift kinds (mirroring the RFC-tier reverse-trace contract):

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
