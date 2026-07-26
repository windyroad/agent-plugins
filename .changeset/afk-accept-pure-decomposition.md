---
"@windyroad/itil": minor
---

Enforce story ratification before implementation, and let an unattended run accept a story that only breaks down work you already approved.

Two changes to `manage-story` and the commit gate, which are the two sides of one problem.

**An implementing commit against a story you have not ratified is now blocked.** This applies to everyone and needs no configuration. The decision records said this already held; nothing in the code checked it, so a story could reach `accepted` and be built on while its oversight marker still read `unconfirmed`. If a story's content changes after you ratified it, the commit is blocked again until you re-ratify — the marker fingerprints the story's substance, and ticking an acceptance criterion or advancing its status does not count as a change.

**Optionally, an unattended run may now accept a story itself — but only one that adds no new thinking.** Off unless you turn it on, with `{ "afk_accept_pure_decomposition": true }` in `.claude/itil.config.json`. When it is on, a story qualifies only if it declares `afk-accept: pure-decomposition`, every decision, job, persona and story map it traces to already carries your confirmation, and a `## Decomposition basis` section names, for each acceptance criterion, the confirmed clause that criterion breaks down. Anything that introduces a new design choice, persona, job or decision fails and waits for you. Stories accepted this way are marked `oversight-basis: pure-decomposition`, listed by `wr-itil-detect-unratified-stories-maps --with-afk-accepted`, and shown distinctly by `/wr-itil:list-stories`, so you can review them afterwards. Nothing ever writes that config file for you.

The problem this solves: an unattended run previously could not land a code fix at all, however small, because accepting a story required a person and implementation required an accepted story. It could write up the work and stop there.

New: `wr-itil-check-afk-accept-eligible`. Background: ADR-101.
