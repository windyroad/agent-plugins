---
name: wr-itil:reconcile-stories
description: Detect and correct drift between docs/stories/README.md and the on-disk story inventory. Wraps the diagnose-only packages/itil/scripts/reconcile-stories.sh script with an agent-applied-edits pattern that preserves narrative content (the "Last reviewed" prose paragraph). Use when docs/stories/README.md Story Rankings or Done sections drift from filesystem state — typically detected by manage-story Step 0 preflight or work-problems preflight on RFC iters with story-tier traces.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Reconcile Stories Skill

Sibling to `/wr-itil:reconcile-readme` (P118 / ADR-014) and `/wr-itil:reconcile-rfcs` (ADR-060 Phase 1 item 5), applied at the story tier per P170 Phase 2 Slice 9.

**Diagnose-only mechanic** — wraps `packages/itil/scripts/reconcile-stories.sh` (resolved via `wr-itil-reconcile-stories` `$PATH` shim per ADR-049). The script reads `docs/stories/<state>/STORY-NNN-*.md` files across all 5 lifecycle subdirs (draft, accepted, in-progress, done, archived), parses `docs/stories/README.md`'s Story Rankings + Done tables, and reports each disagreement. Exit codes: `0` clean, `1` drift detected (structured stdout), `2` parse error.

**Reverse-trace pass** — when the parent directories exist, the reconciler checks auto-maintained `## Stories` sections on problem, JTBD and legacy RFC files. For an ADR-103 row-backed RFC, it checks the map row instead: the RFC must resolve and the row must contain the story card.
- `MISSING_REVERSE_TRACE STORY-NNN in <PARENT-ID> ## Stories` — story claims parent but parent's `## Stories` table doesn't list the story
- `UNRESOLVED_RFC_TRACE STORY-NNN claims=RFC-NNN` — neither a legacy RFC file nor a story-map release row exists
- `MISSING_REVERSE_TRACE STORY-NNN in RFC-NNN release row` — the release row exists but does not contain the story card

**Which stories the legacy-RFC leg covers** — only APPROVED ones, and a story is approved when every story map it names is ratified (ADR-103). ADR-090 forbids an RFC from referencing a story whose map is not ratified, so for such a story the `## Stories` row is *correctly absent* — a `MISSING_REVERSE_TRACE` against it would be a finding no compliant action could clear, since satisfying it means breaking the rule it exists to protect (P472 / STORY-099). The problem and JTBD legs are not narrowed; no ratification rule governs those pairs. The release-row leg is not narrowed either: a story card is compelled onto its map at capture (ADR-095) and cards sit outside the map's fingerprint basis (ADR-103), so a card's absence from its row is never correct.

**The run says which population it checked**, on stderr, whether or not there was drift — so a clean result can be read as "checked and clean" rather than "quietly skipped":

```
reconcile-stories: RFC ## Stories reverse trace checked 15 of 30 story/RFC pairs.
reconcile-stories:   12 skipped because the story's map is not ratified, so the row is correctly absent.
reconcile-stories:   3 skipped because the story names no story map at all; that is a corpus defect, not a correct absence.
```

The two corpus-defect counts — a story naming no map, and a story naming a map id that does not resolve to exactly one file — are reported apart from the correct-absence count on purpose. Folding either in would hide a real defect behind an explanation that does not apply to it.

## When to invoke

- **Drift detected by another skill's preflight** — `/wr-itil:manage-story` or `/wr-itil:work-problems` Step 0 preflight may surface `docs/stories/README.md` drift; this skill is the recovery path.
- **Manual drift recovery** — user notices the README is stale (e.g. story moved between lifecycle subdirs without README refresh; reverse-trace `## Stories` section out of date on a problem ticket).
- **CI drift gate** — a CI step running `wr-itil-reconcile-stories` against the merge target would surface drift before merge; this skill is the in-repo recovery path.

## Composition with manage-story

`manage-story` (P170 Phase 2 Slice 8) owns the inline P094 / P062 README refresh on every lifecycle transition (draft → accepted → in-progress → done). When the inline refresh is satisfied, the README stays current and `reconcile-stories` reports clean. The reconcile skill is the *recovery* path when inline refresh was missed (typically when story files are moved manually, or when frontmatter trace edits don't ride through `manage-story`).

## Steps

### 1. Run the diagnose script

```bash
wr-itil-reconcile-stories docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps > /tmp/wr-itil-stories-drift-$$.txt
reconcile_exit=$?
```

- **Exit 0**: README is clean. Report "no drift detected" and exit.
- **Exit 1**: drift detected. Continue to Step 2.
- **Exit 2**: parse error (README missing or malformed). Halt; the README needs structural repair which this skill doesn't own (the `manage-story review` flow handles structural-rebuild semantics).

### 2. Read drift entries + plan edits

Read `/tmp/wr-itil-stories-drift-$$.txt` line by line. Each line is one of:
- `DRIFT    STORY-NNN rankings: claims=<X> actual=<Y>` — Story Rankings row has wrong Status; update the row.
- `STALE    STORY-NNN rankings: actual=<state>` — Story Rankings table is missing a row; add it.
- `MISMATCH STORY-NNN done: actual=<state>` — Done table has wrong row OR an extra row; remove/adjust.
- `MISSING_REVERSE_TRACE STORY-NNN in <PARENT-ID> ## Stories` — parent's `## Stories` section needs the story added; call `update-<parent-kind>-references-section.sh <parent-file> "Stories"` to refresh. The helper regenerates the whole section and admits only approved stories, so it can never write in a reference ADR-090 forbids. When it withholds one it says so on stderr: the remedy is to **ratify that story's MAP** (ADR-103), never to hand-add the row.
- `UNRESOLVED_RFC_TRACE` / row `MISSING_REVERSE_TRACE` — repair the map's release row or card through `/wr-itil:manage-story-map`; do not create an empty RFC file.

### 3. Apply edits

For README drift entries — edit `docs/stories/README.md` in-place preserving the "Last reviewed" prose paragraph at the top. Use the Edit tool with narrow `old_string` / `new_string` pairs targeting only the table row(s) affected.

For reverse-trace drift entries — invoke the appropriate Slice 2a/2b helper for each parent file:

```bash
# Problem parent
wr-itil-update-problem-references-section "$problem_file" "Stories"
# RFC parent
wr-itil-update-rfc-references-section "$rfc_file" "Stories"
# JTBD parent
wr-itil-update-jtbd-references-section "$jtbd_file" "Stories"
```

### 4. Verify + commit

Re-run `wr-itil-reconcile-stories` after edits. Exit 0 expected. Stage all modified files (README + parent files) and commit per ADR-014 single-commit grain.

Commit message:

```
docs(stories): reconcile docs/stories/README.md drift (N entries)

Refs: <relevant problem/RFC/story IDs derived from the drift entries>
```

The ADR-014 commit grain is "one reconciliation pass per commit" — covers README + N parent files all in one commit since they're all reconciling to filesystem truth, a single coherent action.

### 5. Report

After commit, report:
- Number of drift entries reconciled.
- Files modified (README + each parent reverse-trace surface touched).
- Commit SHA.
- Trailing pointer: `Run /wr-itil:manage-story review next to refresh story rankings + INVEST scoring if any stories crossed the accepted gate during the reconciliation window.`

## Ownership boundary

`reconcile-stories` owns drift DETECTION and MECHANICAL REPAIR of `docs/stories/README.md` + reverse-trace sections. It does NOT:
- Move story files between lifecycle subdirs (that's `manage-story` § Status transitions).
- Edit story frontmatter (that's `manage-story` at lifecycle transitions OR `capture-story` at capture-time).
- Refresh story body sections (User value / Acceptance criteria / Implementation notes are owned by `manage-story` lifecycle transitions per I10 INVEST gates).
- Run WSJF computation (I11 invariant: stories MUST NOT carry a WSJF field in Phase 2 per ADR-060 line 253).

## Related

- **P170** — driver problem ticket.
- **ADR-060** — Problem-RFC-Story framework. Phase 2 amendment 2026-05-10 introduces the story tier; line 270 names the auto-maintained `## Stories` reverse-trace section contract.
- **ADR-049** — plugin-bundled scripts via `bin/` on `$PATH`. `wr-itil-reconcile-stories` shim follows this grammar.
- **ADR-014** — single-commit grain. The reconciliation pass is a single coherent action; one commit per pass.
- **ADR-052** — behavioural-tests default. Bats coverage at `packages/itil/scripts/test/reconcile-stories.bats` (P170 Phase 2 Slice 9).
- **Exit-code convention** — exit-1 on drift, exit-0 on clean, exit-2 on parse error. Shared unchanged with `reconcile-readme.sh`, `reconcile-rfcs.sh` and `check-rfc-stories-ratified.sh`; no ADR records it, and none should — a convention with one viable shape, already implemented uniformly, is not decision-bearing. (This line cited ADR-040 until 2026-09-19; ADR-040 is the session-start briefing surface and says nothing about exit codes.)
- **ADR-090** / **ADR-103** / **ADR-095** — the rules that set the legacy-RFC leg's population: an RFC references only approved stories; approval reaches a story through its map; a story card is on its map from capture.
- **P472** / **STORY-099** — the narrowing, and the stderr population report that makes a clean result readable.
- **P118** / `reconcile-readme.sh` — sibling at the problems tier.
- **ADR-060 Phase 1 item 5** / `reconcile-rfcs.sh` — sibling at the RFC tier.
- **Slice 2a/2b helpers** — `update-problem-references-section.sh`, `update-rfc-references-section.sh`, `update-jtbd-references-section.sh` are the load-bearing reverse-trace refresh helpers this skill invokes; all three accept `"Stories"` as a section-name token per their lookup tables.
- **JTBD-001** — Enforce Governance Without Slowing Down. Drift detection is an automated governance enforcement surface; mechanical repair preserves the spirit while removing manual toil.
- **JTBD-006** — Progress the Backlog While I'm Away. The legacy-RFC-leg narrowing (P472 / STORY-099) exists so an unattended loop can read a clean result as "checked and clean" rather than "quietly skipped", and so no finding demands an action the ratified-stories rule forbids.
- **JTBD-008** — Decompose a Fix Into Coordinated Changes. Story tier reverse-trace integrity is load-bearing for the working-the-problem flow's per-story dispatch (Slice 13 traversal).

$ARGUMENTS
