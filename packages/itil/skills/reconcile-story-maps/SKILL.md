---
name: wr-itil:reconcile-story-maps
description: Detect and correct drift between docs/story-maps/README.md and the on-disk story-map HTML inventory. Wraps the diagnose-only packages/itil/scripts/reconcile-story-maps.sh script with an agent-applied-edits pattern preserving narrative content.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Reconcile Story Maps Skill

Sibling to `/wr-itil:reconcile-stories` (P170 Phase 2 Slice 9), `/wr-itil:reconcile-rfcs` (ADR-060 Phase 1 item 5), and `/wr-itil:reconcile-readme` (P118 / ADR-014), applied at the story-map tier per P170 Phase 2 Slice 5.

**Diagnose-only mechanic** — wraps `packages/itil/scripts/reconcile-story-maps.sh` via the `wr-itil-reconcile-story-maps` `$PATH` shim per ADR-049. Script reads `docs/story-maps/<state>/STORY-MAP-NNN-*.html` files across 5 lifecycle subdirs (draft, accepted, in-progress, completed, archived), parses `docs/story-maps/README.md`, and reports disagreements. Exit codes: `0` clean, `1` drift detected, `2` parse error.

## When to invoke

- Drift surfaced by another skill's preflight (e.g. `/wr-itil:manage-story-map`).
- Manual drift recovery (e.g. story-map moved between lifecycle subdirs without README refresh).
- CI drift gate against merge target.

## Steps

### 1. Run the diagnose script

```bash
wr-itil-reconcile-story-maps docs/story-maps > /tmp/wr-itil-story-maps-drift-$$.txt
reconcile_exit=$?
```

Exit 0 → clean; exit 1 → drift to address in Step 2; exit 2 → parse error (halt).

### 2. Read drift entries + plan edits

Each line is one of:
- `MISSING  STORY-MAP-NNN README claims it exists but no file on disk` — remove README row.
- `STALE    STORY-MAP-NNN README missing entry; actual=<state>` — add README row.

### 3. Apply edits

Edit `docs/story-maps/README.md` in-place preserving narrative. Use Edit tool with narrow `old_string`/`new_string` pairs targeting only the affected rows.

### 4. Verify + commit

Re-run `wr-itil-reconcile-story-maps` (expect exit 0). Stage README + commit per ADR-014 single-commit grain.

Commit message: `docs(story-maps): reconcile docs/story-maps/README.md drift (N entries)`.

### 5. Report

Report drift entries reconciled + files modified + commit SHA + trailing pointer to `/wr-itil:manage-story-map review` if any maps crossed lifecycle states during the window.

## Ownership boundary

Detects + mechanically repairs `docs/story-maps/README.md` drift. Does NOT:
- Move story-map files between lifecycle subdirs (manage-story-map's surface).
- Edit `<meta>` blocks or `<style>` blocks or HTML body content (manage-story-map's surface).
- Run WSJF (I5 invariant: no WSJF on story-maps).

## Related

- **P170** — driver problem ticket.
- **ADR-060** — Problem-RFC-Story framework; Phase 2 amendment 2026-05-10 introduces story-map tier.
- **ADR-049** — bin/ on PATH.
- **ADR-014** — single-commit grain.
- **ADR-052** — behavioural-tests default; bats at `packages/itil/scripts/test/reconcile-story-maps.bats`.
- **ADR-040** — advisory-exit contract; exit 0 clean / exit 1 drift / exit 2 parse error.
- **`/wr-itil:reconcile-stories`** — sibling at the story tier.
- **`/wr-itil:reconcile-rfcs`** — sibling at the RFC tier.
- **JTBD-008** — Decompose a Fix Into Coordinated Changes.
- **JTBD-302** — Trust That the README Describes the Plugin I Just Installed.

$ARGUMENTS
