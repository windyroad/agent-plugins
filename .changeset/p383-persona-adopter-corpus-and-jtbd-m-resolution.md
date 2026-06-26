---
"@windyroad/itil": patch
"@windyroad/jtbd": patch
---

P383: stop home-repo persona assumptions from leaking into adopter installs (P151/P317 family).

**`@windyroad/itil` — `/wr-itil:capture-problem` Step 1.5b `--persona` validation.** The skill validated `--persona=` against a hardcoded enum `{developer, tech-lead, plugin-developer, plugin-user}` (the plugin's own persona set). An adopter passing a perfectly valid persona that exists under `docs/jtbd/<persona>/` (e.g. `--persona=maintainer`) failed enum validation and halted capture — inverting the contract, since the cited-JTBD derivation path never enum-checked, so the explicit flag was the *less* reliable path. AFK orchestrators that pre-resolve `--persona` hit a halt on a valid value. Validation now runs against the adopter's real persona corpus — the directory names under `docs/jtbd/*/` — and falls back to the home-repo set only when no `docs/jtbd/` directories exist. The free-text JTBD-correction path is also widened to tolerate the maintainer `JTBD-M-NNN` alpha-infix ID scheme.

**`@windyroad/jtbd` — `wr-jtbd-is-job-or-persona-unconfirmed` predicate.** The job-ref resolver extracted only the first numeric run from the ref, dropping the alpha infix of the maintainer `JTBD-M-NNN` scheme and globbing `JTBD-NNN-*.md` (wrong file or no match). Adopters using that scheme could not ratification-check those jobs via the predicate — the build-upon guard failed *open* (no flag fired). Resolution now strips an optional `JTBD-` prefix to a stem that preserves alpha infixes (`JTBD-M-101` → `M-101`) and globs `docs/jtbd/*/JTBD-M-101-*.md`. `JTBD-NNN` and bare-numeric behaviour is unchanged; bare `M-NNN` variants also resolve. Behavioural bats cover the new resolution plus a hyphenated-persona-name boundary lock. Refs: P383.
