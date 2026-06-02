---
"@windyroad/itil": patch
---

P328 Option 3: `check-locale-discipline.sh` CI lint warns on `grep` / `sed` / `awk` without preceding `LC_ALL=en_US.UTF-8`

Closes the P328 fix-strategy (user-ratified 2026-06-02). BSD `grep` / `sed` / `awk` on macOS silently mis-process UTF-8 multi-byte characters (em-dash `—`, smart quotes, en-dash) without `LC_ALL=en_US.UTF-8` — the codebase's prose surfaces (ADRs, problem tickets, briefing entries, SKILL.md files) are pervasively em-dash-rich, so any script that grep / sed / awks those surfaces silently mis-processes them. Three distinct incidents in the 2026-05-30 ADR-077 compendium session were the captured trigger; recurrence rate is "every macOS contributor without an `LC_ALL` export".

Option 3 (the cheapest of the three Fix-strategy candidates in the ticket body) ships a CI lint that walks `packages/*/scripts/*.sh`, `packages/*/hooks/*.sh` (incl. nested `lib/`), and `packages/*/lib/*.sh`, then emits `WARN  <relpath>:<line>  <tool> without preceding LC_ALL=en_US.UTF-8` for every unprotected invocation. File-wide `export LC_ALL=...` switches the file to silent-pass mode; inline `LC_ALL=...` prefix on the same line protects only that line. `git grep` is skipped (different binary); comment lines and heredoc bodies are skipped; identifiers containing tool substrings (`grep_helper`, `result_from_sed`) are not flagged. The lint exports `LC_ALL=en_US.UTF-8` at the top of its own body — self-application keeps the lint from reintroducing P328 in itself.

Two-phase rollout per ADR-040 line 92's reusable advisory-then-load-bearing pattern: Phase 1 (current) emits warnings to stderr but exits 0; Phase 2 (after existing scripts migrate) promotes `WR_LOCALE_DISCIPLINE_WARN_ONLY=0` and exits 1 on any violation. Baseline at ship-time: 372 violations across 152 scripts (only `packages/architect/scripts/generate-decisions-compendium.sh` and `packages/itil/scripts/evaluate-relevance.sh` carry `export LC_ALL=en_US.UTF-8` today). The lint surfaces the migration backlog without blocking CI on it.

Shipped:

- `packages/itil/scripts/check-locale-discipline.sh` — the lint (file-wide `export` tracking + inline-prefix recognition + `git grep` skip + comment/heredoc skip + word-boundary tool detection; self-application export at top).
- `packages/itil/scripts/test/check-locale-discipline.bats` — 24 behavioural tests (ADR-052 default) against a synthesised `packages/` fixture tree: positive cases (file-wide `export`, inline `LC_ALL=` prefix), negative cases (raw grep / sed / awk), edge cases (multi-tool-per-line, `git grep`, heredoc bodies, comments, identifier substrings), scope (`scripts/`, `hooks/`, `hooks/lib/`, `lib/`), Phase 1 vs Phase 2 exit semantics, argument handling, output shape, and self-application. 24/24 GREEN locally.
- `packages/itil/bin/wr-itil-check-locale-discipline` — ADR-049 PATH shim regenerated from the ADR-080 highest-version-wins template; `npm run check:shim-wrappers` reports 40/40 shims in sync after regeneration.
- `.github/workflows/ci.yml` — new "Check locale-discipline in bash scripts (P328, advisory)" step between the existing "Check shim-wrapper templates in sync (P343, ADR-080)" step and the "Dry-run meta-installer" step.

Architect verdict (2026-06-02): PASS. No new ADR required — the lint is the fourth instance of the established discipline-lint pattern (`check-problems-readme-budget`, `check-rfc-rejected-alternatives`, `check-upstream-responses`, all with sibling bats + `bin/wr-itil-*` shim). Location `packages/itil/scripts/` confirmed correct over `packages/shared/scripts/` (which doesn't exist; `packages/shared/` is library-only). CI step name cites P328 only — matches the sibling pattern that enforces problem-ticket discipline without citing a dedicated ADR. Advisory-then-load-bearing two-phase rollout aligned with ADR-040 line 92 + 155.

JTBD verdict (2026-06-02): PASS. Primary job served: JTBD-101 (Extend the Suite with New Plugins — *"CI validates required files, package fields, installer dry-runs, and hook tests"*). Secondary: JTBD-001 (Enforce Governance Without Slowing Down — *"Every edit to a project file is reviewed against relevant policy before it lands"*). No persona conflicts.

P328 transitions Open → Known Error in the same commit (`docs/problems/open/328-*.md` → `docs/problems/known-error/328-*.md`, Status field updated, `## Fix Released` section added). README WSJF row updated (Status: Open → Known Error; row repositioned to top of 4.0 tier per Known-Error-first tie-break); line-3 fragment rotated to `docs/problems/README-history.md` per P134 (prior P330 + P343 K→V batch fragment archived under `## 2026-06-02 (P330+P343 K→V batch fragment rotated for P328 Open → Known Error)`).
