# Problem 069: docs/problems/ flat layout is unskimmable — migrate to per-state subdirectories

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 15 (High) — Impact: Moderate (3) x Likelihood: Certain (5)
**Effort**: L — bulk `git mv` of ~69 existing tickets into per-state subdirectories, update path references across 4+ SKILL.md files (manage-problem, work-problems, report-upstream, run-retro) and their bats tests, update README.md generation, draft an ADR for the directory contract change. Cross-plugin reach but single-repo migration. Architect review may bump to XL if the migration script and the ADR turn out to be more involved than expected.
**WSJF**: 3.75 — (15 × 1.0) / 4 — High severity / ecosystem-wide navigation friction; the migration lift keeps the WSJF below smaller fixes.

## Direction decision (2026-04-20, user — AFK pre-flight via AskUserQuestion)

**Filename suffix**: **drop** the `.<state>.md` suffix. The directory path is the single source of truth for state. Filename is `<NNN>-<title>.md`. Every transition is a single `git mv` between directories — no suffix rename. The Status field in the ticket body frontmatter remains as a human-readable indicator, but machine-readable state comes from `$(basename $(dirname <path>))`.

**Defaults AFK can apply without further user input**:
- New ADR drafts as `docs/decisions/NNN-problem-ticket-directory-layout.proposed.md` (next free number; `/wr-architect:create-adr` handles allocation per ADR-019).
- Subdirectory names (kebab-case): `open`, `known-error`, `verifying`, `closed`, `parked`.
- Single-commit migration (bulk `git mv` + all SKILL.md updates + bats test updates + README.md generation update) so no intermediate state has mixed paths.
- `docs/problems/README.md` stays at the top level — it's the aggregation view.
- Update the `git ls-tree` pipeline in `manage-problem` / `create-adr` next-ID lookups to use `-r` (recursive) so subdirectory files are discovered.
- Ship ordering: land this **after** P062, P063, P066–P068 (SKILL.md edits these tickets require touch the same files); doing P069 last avoids a rebase storm.

## Description

`docs/problems/` is currently a **flat directory of 69 Markdown files** plus a `README.md`. The filename encodes state via a suffix (`.open.md`, `.known-error.md`, `.verifying.md`, `.parked.md`, `.closed.md`). For skimmability this works up to ~20 tickets; beyond that, visual scan of `ls docs/problems/` returns a wall of filenames intermixed by state, requiring the reader to parse suffixes on every line to find, for example, the active dev-work queue.

`ls docs/problems/` output at time of report (2026-04-20): 69 Markdown files, 3 parked, 3 verifying that are clear candidates to close, 10 open tickets (7 of which were opened in the last 24 hours). The mix makes it hard to answer "what's actively in flight" at a glance. README.md mitigates this via the WSJF Rankings / Verification Queue / Parked tables but the on-disk view (which the user sees during every `ls` or file-browse) stays unstructured.

The fix is mechanical: **one subdirectory per problem state**. File names drop the state suffix (the directory encodes it). The transition commands become "move the file between directories" instead of "rename with a new suffix".

## Symptoms

- `ls docs/problems/` returns 69+ files; open / known-error / verifying / closed / parked all interleaved by numeric ID, impossible to skim by state.
- File explorers (VSCode tree, Finder, Codeium sidebar) show the same flat mess.
- New contributors asking "what should I work on next?" have to either read `README.md` (good) or type the exact glob (`ls docs/problems/*.open.md`) — the latter is discoverable only to people who already know the suffix convention.
- Every new ticket compounds the problem; the flat layout cannot scale without hitting a wall.
- Path references in SKILL.md files and bats tests use literal `docs/problems/*.<state>.md` globs that are fragile to filename-suffix drift (e.g. P057 staging trap edge cases).
- The symbolic weight of "we are doing ITIL problem management" is undercut by a directory that looks like a dump of notes.

## Workaround

Readers lean on `docs/problems/README.md` for ranked tables and ignore the directory tree; contributors use exact globs (`ls docs/problems/*.open.md` etc.) when they remember the suffix. Neither is a fix — they route around the flat layout but don't make the directory navigable.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001)** — every `ls docs/problems/` is an ambient friction moment. "Without slowing down" fails at the most basic navigation step.
  - **Plugin-developer persona (JTBD-101)** — adopters cloning the repo to learn the suite's conventions (P055 Part A templates, ADR structure, problem-ticket discipline) see an unstructured `docs/problems/` as anti-pattern. Reputation-relevant.
  - **Tech-lead persona (JTBD-201)** — audit trail browsing (what changed between these dates, what state was P048 in during 2026-04-15's incident) is harder than it needs to be.
  - **Future contributors** — onboarding cost grows linearly with ticket count.
- **Frequency**: Every browse of `docs/problems/`. Certain.
- **Severity**: High for navigation ergonomics; Medium for automation (the path references in SKILL.md and bats tests all need updating, which is the migration cost).
- **Analytics**: N/A; frictional cost is ambient and would require session-level time-on-task measurement to quantify.

## Root Cause Analysis

### Structural

The flat-layout-with-state-suffix convention was set early (P001–P010 era) when ticket count was small and the suffix-in-filename was the simplest way to record state machine-readably. ADR-022 (Verification Pending lifecycle) added a fifth suffix without revisiting whether the container shape still fits. 69 tickets later, the convention has hit its natural ceiling.

The fix is not to add more suffixes or a sixth state — it's to promote state from suffix-in-filename to directory-of-files.

### Candidate fix

**Option 1 (recommended): per-state subdirectories, drop the suffix.**

Layout:

```
docs/problems/
├── README.md                 # aggregation of WSJF / Verification Queue / Parked
├── open/
│   ├── 063-manage-problem-does-not-trigger-report-upstream-for-external-root-cause.md
│   ├── 064-no-risk-scoring-gate-on-external-comms.md
│   └── ...
├── known-error/
│   └── ...
├── verifying/
│   ├── 017-create-adr-should-split-multi-decision-records.md
│   ├── 020-on-demand-assessment-skills.md
│   └── ...
├── closed/
│   ├── 001-architect-gate-marker-consumed-too-quickly.md
│   ├── 002-jtbd-gate-blocks-own-policy-file-creation.md
│   └── ...
└── parked/
    ├── 005-connect-setup-skill-doesnt-match-discord-plugin.md
    └── ...
```

Filename drops the `.<state>.md` suffix — the directory path encodes state. Machine-readability is preserved: the state is `$(basename $(dirname <path>))` instead of `${filename#*.}`.

**Option 2: per-state subdirectories, keep the suffix.**

Layout: `docs/problems/open/063-...open.md`. Redundant but useful as a defence-in-depth against a ticket being in the wrong directory (double-check: does the suffix match the directory?). Lightly considered because it doubles the mutation surface on every transition (now must `git mv` the file AND rename the suffix), which is the opposite of simplification.

**Option 3: flat but hide .closed.md and .parked.md in `archive/`.**

Weaker — still unskimmable once open/verifying alone exceed ~30. Punts the problem rather than solving it.

**Recommendation**: Option 1. The directory IS the state; filename is `<NNN>-<title>.md` and nothing more.

### Migration mechanics

The tricky part is keeping everything machine-readable through the transition. Mitigations:

1. **Single commit for the whole migration** so no intermediate state has half-old, half-new paths. Migration script:
   ```bash
   for state in open known-error verifying parked closed; do
     mkdir -p docs/problems/$state
     for f in docs/problems/*.$state.md; do
       [ -e "$f" ] || continue
       new=$(basename "$f" .$state.md).md
       git mv "$f" docs/problems/$state/$new
     done
   done
   ```

2. **Update the four SKILL.md files that reference paths** in the same commit:
   - `packages/itil/skills/manage-problem/SKILL.md` — file-path globs in Steps 7, 8, 9, 10; transition commands; README-staleness check; next-ID lookup.
   - `packages/itil/skills/work-problems/SKILL.md` — ticket selection globs.
   - `packages/itil/skills/report-upstream/SKILL.md` — `ls docs/problems/<ID>-*.{open,known-error,verifying,closed}.md` lookup in Step 1.
   - `packages/retrospective/skills/run-retro/SKILL.md` — if P068 lands before this migration, the `.verifying.md` glob.

3. **Update bats tests** in `packages/itil/skills/*/test/*.bats` and `packages/retrospective/skills/*/test/*.bats` that assert literal paths.

4. **Update the Status-field in each ticket body** — currently frontmatter carries `**Status**: Open` etc. Stays as a cross-check; the filename no longer redundantly encodes state but the frontmatter still does. No migration edit needed on ticket bodies beyond what's required by the suffix-drop.

5. **Update `docs/problems/README.md` generation** — aggregation now walks subdirs instead of globbing by suffix.

6. **ADR** — draft `docs/decisions/NNN-problem-ticket-directory-layout.proposed.md` covering the convention change, migration, and a cross-reference to ADR-022 (lifecycle) + the suffix-drop rationale.

### Investigation Tasks

- [ ] Draft the ADR for the directory-layout change. Cite ADR-022 as the lifecycle authority being expressed in directory shape rather than filename suffix.
- [ ] Enumerate all path references that need updating. Grep for `docs/problems/` across packages + bats tests; also check if any installers or scripts reference paths.
- [ ] Write the migration script and test it in a scratch branch with a dry-run mode.
- [ ] Decide whether to keep the `.md` suffix on filenames (yes — markdown file) or adopt plain `<NNN>-<title>` (no — Markdown convention matters for GitHub rendering).
- [ ] Decide whether to rename subdirs from `known-error` to `known_error` (underscore) or leave kebab-case. Lean: kebab-case for consistency with the existing suffix pattern and general Unix-friendliness.
- [ ] Decide whether `docs/problems/README.md` stays at the top level or moves under `docs/problems/` with a thin re-export. Lean: stays where it is — it's the aggregation view.
- [ ] Confirm `git mv` preserves history across the moves (expected yes; verify with `git log --follow` on a sample ticket after migration).
- [ ] Update architecture-agent + JTBD-agent exemption rules if any reference `docs/problems/<NNN>-*.md` paths literally. The current hook exemption (`docs/problems/ (problem tickets)`) is directory-scoped so the exemption still holds — but the hook scripts themselves should be audited.
- [ ] Ensure that this ticket does not inadvertently ship alongside P048 / P049 / P068 changes that depend on the old paths; architect review sequences the work.

## Related

- **ADR-022** (problem lifecycle Verification Pending) — the lifecycle authority whose shape this ticket promotes from filename suffix to directory.
- **P048** (manage-problem does not detect verification candidates) — path-reference overlap; cross-check during migration.
- **P049** (Known Error status overloaded with Fix Released substate, ADR-022) — same file-path surface.
- **P057** (git mv + Edit staging ordering trap) — the staging-ordering invariant survives: `git mv` to the new dir + Edit still needs re-stage.
- **P056** (next-ID `--name-only` fix) — the `git ls-tree` pipeline needs to walk subdirs after the migration (`git ls-tree --name-only -r origin/main docs/problems/`).
- **P062** (manage-problem README not refreshed on single-ticket iterations) — the README generation logic is rewritten by this migration anyway; fix can ride along.
- **P068** (run-retro does not close verifying tickets observed verified in-session) — the `.verifying.md` glob in run-retro's housekeeping step needs to change.
- `packages/itil/skills/manage-problem/SKILL.md` — the primary SKILL.md whose path references change.
- `packages/itil/skills/work-problems/SKILL.md`, `packages/itil/skills/report-upstream/SKILL.md`, `packages/retrospective/skills/run-retro/SKILL.md` — all carry path references.
- `packages/itil/skills/*/test/*.bats` and `packages/retrospective/skills/*/test/*.bats` — bats assertions.
- **JTBD-001** (Enforce Governance Without Slowing Down) — navigation ergonomics directly affect this.
- **JTBD-101** (Extend the Suite with Clear Patterns) — the "clear pattern" should include the shape of the directory.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — browsable audit trail.
