# Project: windyroad-claude-plugin

Plugin-development monorepo publishing `@windyroad/*` Claude Code plugins — architecture governance, risk management, ITIL, TDD, JTBD, retrospectives, and delivery quality — by Windy Road Technology. These plugins promote Windy Road's service offering to the community; they are NOT internal project utilities.

Not a web UI project — accessibility-first global guidance does not apply here.

## Where the deep context lives (progressive disclosure per ADR-038)

- **Architecture decisions** — `docs/decisions/` (MADR 4.0). Start at the highest-numbered ADR on a given surface; earlier ADRs may be superseded.
- **Personas and jobs** — `docs/jtbd/` (solo-developer, plugin-developer). `wr-jtbd:agent` consults before editing project files.
- **Risk policy** — `RISK-POLICY.md`. ISO-31000 derived bands; `wr-risk-scorer:pipeline` consults on commit/push/release.
- **Problem backlog** — `docs/problems/README.md` (cached WSJF ranking). Work items: `/wr-itil:work-problem`.
- **Session learnings** — `docs/BRIEFING.md`. Read first each session.
- **Style and voice** — `docs/STYLE-GUIDE.md`, `docs/VOICE-AND-TONE.md`.
- **Product discovery** — `docs/PRODUCT_DISCOVERY.md`.

## Non-negotiable conventions

- Governance skills commit their own work (ADR-014). Don't defer commits.
- Release cadence per ADR-018 (AFK) / ADR-020 (non-AFK). Drain changesets when risk within appetite.
- `git mv` stages rename only — re-stage after `Edit` (P057 staging-trap rule).
- Write behavioural tests; structural greps on SKILL.md / ADR content are wasteful (P081).

Agents consult the right file on demand — do not restate policy inline here.
