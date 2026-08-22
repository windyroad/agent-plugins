---
name: wr-itil:capture-rfc
description: Draw a problem-traced RFC release row on a story map and attach at least one delivery story. Uses the existing delivery-planning vehicle instead of creating an RFC document.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Skill, AskUserQuestion
---

# Capture RFC

Draw a lightweight RFC release row on an existing story map. An RFC is a planning row, not a standalone document.

## Arguments

```text
/wr-itil:capture-rfc <problem-trace> <description> [--story-map STORY-MAP-NNN] [--stories STORY-NNN,...] [--fix-time]
```

`<problem-trace>` is one or more comma-separated `P<NNN>` identifiers. `--fix-time` is retained as a compatibility alias and does not change the row-based workflow.

## Workflow

1. Require every problem trace to resolve under `docs/problems/`. If a trace is missing, stop and direct the caller to `/wr-itil:capture-problem`; never infer or create a problem silently.
2. Reuse the existing delivery-planning vehicle. Prefer the supplied `--story-map`; otherwise select an approved story map whose journey contains the fix. Never create a duplicate vehicle.
3. If no existing map, activity, job, or ratified decision can carry the proposed work, brief the missing substance and use `AskUserQuestion`. In unattended work, queue the question and continue with other actionable work. Do not create a row until the direction is supplied.
4. Allocate the RFC identity mechanically with `wr-itil-next-rfc-id`; never scan one directory or reuse a retired identity.
5. Reuse the ordered stories supplied by `--stories`, or capture the smallest delivery stories needed for the fix. Every story must name the driving problem trace.
6. Run `wr-itil-story-map add-band` to add one release row and `wr-itil-story-map add-card` for each story. The row must include the RFC identity, description, problem trace, and ordered story identifiers.
7. Render the story map, update the driving problem's RFC references, and run the relevant reconciliation checks.
8. Commit the map, stories, problem references, and regenerated render together in one focused commit.

## Prohibitions

- Never create a new file under `docs/rfcs/`.
- Never amend a ratified decision to introduce new substance. Create a proposed superseding decision and obtain ratification first.
- Never treat `--fix-time` as permission to bypass the story map, story, or decision gates.
