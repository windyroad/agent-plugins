---
"@windyroad/architect": minor
---

P337 / RFC-014 Phase 1 (Stories A+B+D, C-partial) — architect-on-edit compendium entries

Replaces the programmatic generator-based compendium drift mechanism with a hook pair (ADR-078 Option 9):

- **Story A** — new `PostToolUse:Edit|Write` hook `architect-compendium-update-entry.sh`. On every `docs/decisions/<NNN>-*.md` body edit, spawns `claude -p` (`wr-architect:agent`) to re-author that ADR's `README.md` compendium entry (replace-in-place / sorted-insert / section-migrate) and stages the README for same-commit pairing. Opt-out via `ARCHITECT_AUTO_UPDATE_COMPENDIUM=0`. Degraded-mode-warn never blocks the body edit.
- **Story B** — new `PreToolUse:Bash` hook `architect-readme-pairing-check.sh`. Denies a git-commit that stages an ADR body without the README. Replaces the ADR-077 criterion (g) drift gate.
- **Story D** — retire `architect-compendium-refresh-discipline.sh` (deleted + unregistered from `hooks.json`). Its `--check` generator-match is incompatible with LLM-authored entries — so A+B+D land atomically. The original RFC-014 dogfood-before-D sequence is corrected to A+B+D atomic swap (architect agent independently confirmed; deviation-approval queued for RFC-014 § Sequencing amendment).
- **Story C (partial)** — generator gains an ADR-078 deprecation notice (criterion j); drift-gate bats test 2145 marked skip. Script kept as a backstop until full removal (gated on one-minor-version backstop window).

20 new behavioural bats GREEN (Story A 9 + Story B 6 + registration/portability 5). Full architect hooks+scripts suite 162/164 GREEN (the 2 pre-existing failures relate to oversight-nudge counts and are unrelated to this work).
