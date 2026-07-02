---
status: proposed
job-id: extend-suite
persona: plugin-developer
date-created: 2026-04-14
human-oversight: confirmed
oversight-date: 2026-05-26
oversight-confirmed-date: "2026-07-02 — re-ratified via AskUserQuestion (P357 batched pass) after the ADR-089 atomic-representation amendment"
oversight-downgraded: "2026-07-02 — ADR-089 lockstep: the atomic-fix-adopter framing is reframed — an RFC always has ≥1 story; the coordination surface scales up, the RFC never scales below one story; no atomic-fix exemption. P357 re-ratification batched this session."
---

# JTBD-101: Extend the Suite with New Plugins

> **Amendment 2026-07-02 (ADR-089 — every RFC has ≥1 story).** Any clause below framing atomic/single-commit fixes as paying *less* RFC/story ceremony is **superseded**: an RFC always has **≥1 story**. The multi-commit *coordination* surface (multiple stories / a story map) scales **up** when the work needs it; the RFC never scales **down** below one story, and there is no atomic-fix exemption. `human-oversight` downgraded to `unconfirmed` pending P357 re-ratify (batched this session).

## Job Statement

When I'm building a new plugin, I want to follow a clear template and have CI validate my package structure, so I know it will install correctly for users.

## Desired Outcomes

- Every plugin follows the same structure (package.json, plugin.json, hooks.json, install.mjs, BATS tests)
- CI validates required files, package fields, installer dry-runs, and hook tests
- Changesets handle versioning; the pipeline handles publishing
- ADRs document structural decisions so contributors understand the "why"
- Plugins that expose assessment agents also expose corresponding user-invocable assessment skills — the capability is discoverable via `/` autocomplete, not just accessible via hooks or manual Task-tool invocations
- I can see which of my plugin's surfaces (skills, agents, hooks) are most and least exercised in real-world use, so I know where to invest hardening effort versus where the surface is so well-trodden that the marginal-test ROI is low (P087 / ADR-053 / ADR-058 — surfaces this signal via the maturity-band taxonomy and the `wr-itil-skill-invocations` + `wr-itil-plugin-exercise-index` measurement scripts)
- **(Amended in P087 Phase 3 — closes ADR-053 §Confirmation #4 deferred bullet)** Promotion criteria are documented so contributors know the bar to clear when authoring a new skill or splitting an existing one — the maturity-band thresholds (Experimental → Alpha → Beta → Stable) and their evidence requirements (`invocations_30d`, `days_shipped`, `closed_tickets_window`, `breaking_change_age_days`) are spelled out in ADR-053 §Promotion criteria, so a contributor can predict where their new surface will land and what hardening it needs to graduate.

## Persona Constraints

- Must not break existing plugins when adding new ones
- Needs clear patterns, not reverse-engineering
- **Framework ceremony scales by surfacing the multi-commit *coordination* tier (stories / story maps) only when the work needs it — NOT by exempting atomic adopters from the RFC trace.** The RFC-trace primitive has **no opt-out**: every fix goes through an RFC (per ADR-071 — every problem is fixed only via an RFC, unconditionally; the atomic-fix carve-out was disavowed by the user 2026-05-26, P311). Atomic-change adopters pay the same RFC ceremony as anyone; what they don't pay is the story / story-map *coordination* ceremony, because their work isn't decomposed into stories. The `type` tag remains a classification facet only (ADR-060 I2), never a workflow exemption. (Added 2026-05-05 per ADR-060 RFC framework — JTBD-review finding 3; reframed 2026-05-26 per ADR-071 — no opt-out, no scale-down of the RFC trace.)

## Current Solutions

Copy an existing plugin and modify it, read ADRs and BRIEFING.md
