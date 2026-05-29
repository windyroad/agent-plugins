---
"@windyroad/architect": minor
---

ADR-077 Slice 2: compendium enforcement hook + two-section format + skill integrations.

**Two-section compendium.** `docs/decisions/README.md` now splits ADRs into an **In-force decisions** section (`proposed` + `accepted` — the current rules to follow) and a **Historical decisions** section (`superseded` + `rejected` + `deprecated` — direction for what NOT to do, useful when a proposed change re-treads a path already tried). The status badge on each entry signals which kind it is. Both sections share the compact per-ADR format from Slice 1 (chosen option + confirmation criteria + relationship graph). All 75 ADRs in the dogfood repo are present (68 in-force, 7 historical).

**Skills + agent are primary; hook is safety net.** `/wr-architect:create-adr` Step 5 and `/wr-architect:capture-adr` Step 4.5 now invoke `wr-architect-generate-decisions-compendium` after writing the ADR and stage `docs/decisions/README.md` in the same commit. The `wr-architect:agent` reviewer carries an explicit check for compendium freshness when reviewing ADR changes. These are the PRIMARY mechanism for keeping the compendium current.

**Safety net: `architect-compendium-refresh-discipline.sh`.** New PreToolUse:Bash hook (mirroring the P165 `itil-readme-refresh-discipline.sh` pattern at the decisions surface) denies `git commit` invocations whose staged set includes a `docs/decisions/<NNN>-*.md` change but either (a) does NOT also stage `docs/decisions/README.md`, or (b) the staged compendium does not match the generator output for the current ADR bodies (stale). The hook catches edits that bypass the skill/agent flows — hand-edits via Edit/Write, off-skill bulk renames, direct file modifications. Override: `RISK_BYPASS: architect-compendium-deferred` in the commit message (intentional follow-up split) or `BYPASS_COMPENDIUM_REFRESH_GATE=1` env (batch/migration).

**Generator gains `--check` flag.** `wr-architect-generate-decisions-compendium --check` writes to a temp file and diffs against the on-disk compendium. Exits 0 if up-to-date, 1 if stale (with a diff hint), 2 on directory error. Used by the enforcement hook to verify the staged compendium matches the working-tree ADR bodies without mutating any file. Idempotency contract preserved: same input bodies produce byte-identical output (sha1-verified across consecutive runs).

ADR-077 amended in-place with both substance refinements (two-section format + skills-primary / hook-safety-net split). Next slice deferred: `/wr-architect:review-decisions` integration (regenerate on status transitions) + drift-detection CI bats.
