---
status: proposed
job-id: sustain-token-quota
persona: developer
date-created: 2026-07-07
human-oversight: confirmed
oversight-date: 2026-07-07
---

# JTBD-010: Sustain My Token Quota Across the Week and Across Surfaces

> **Ratified 2026-07-07** (user confirmed the job statement + outcomes "as drafted" via a briefed `AskUserQuestion` confirm event — a genuine ratification per ADR-068 / P288 / P357). Authored to ground P160 / P443 (quota-pacing was shipped anchored to the wrong/narrow JTBD-006 "Progress the Backlog While I'm Away"; the throttle actually fires on ALL work, not just AFK). Note: outcome #7 ("works out-of-the-box") is retained as the true desired outcome; the platform ceiling — the statusline is the only surface exposed to `.rate_limits` and no plugin can ship it, so a one-time statusline setup is unavoidable — is a **solution** constraint recorded in P160, not a weakening of the job.

## Job Statement

When I work with Claude across a whole week — in Claude Code and also in chat and Cowork, all drawing on one shared account quota — I want my agent tooling to pace its own token burn against the rolling quota windows, so that I never hit a mid-window hard-stop that halts my work mid-flight and starves my other Claude surfaces for the rest of the week.

## Desired Outcomes

- Token burn is paced **automatically and mechanically** against BOTH rolling windows (the 5-hour and the 7-day) simultaneously — cumulative usage never sprints ahead of elapsed time into a hard-stop; the tighter window governs.
- Pacing applies to **all** work — interactive foreground sessions AND unattended AFK loops alike — not just one surface or one skill. (This is the axis JTBD-006 does NOT cover: JTBD-006 is about AFK backlog progress; this job is about the token budget underneath every kind of work.)
- **Weekly headroom is reserved for non-Claude-Code surfaces** (chat, Cowork) so Claude Code does not consume the whole account's weekly quota — I can still send the important text-based work later in the week.
- When I am **ahead of pace** (burning too fast), the tooling eases the burn **proportionally** (a glide-path: slow down and drift back onto pace, converging before the quota is consumed) and still lets me make progress — rather than stopping dead or blocking.
- When I am **behind pace** (headroom available), work runs at full speed — the pacing adds negligible latency.
- The pacing is **silent** — no status-line glance, no "you're burning fast" nudge, no decision for me to make. The tooling computes the needed delay and takes it.
- It **works out of the box for an adopter**, not only for a maintainer who has hand-wired a data source. Installing the capability is enough to get the behaviour; there is no invisible one-time setup step whose absence silently disables it. *(Names the P160/P443 adopter-inert gap as a first-class outcome.)*

## Persona Constraints

- The developer authenticates **multiple Claude surfaces from one account** (Claude Code + chat + Cowork + any API-backed tools); the token quota is **shared** across all of them, so over-spending in one starves the others.
- Trusts the tooling to pace automatically; does **not** want to babysit a status line or manually downgrade models / defer work to self-throttle.
- The failure mode is **expensive, not merely inconvenient**: a mid-window hard-stop breaks running AFK loops, strands in-flight subprocess work, and forces effortful manual resume — and can force the developer to stay awake to babysit a reset, or waste the hours until it.
- Governance surfaces in the suite (architect / JTBD / risk-scorer / retrospective, hook injection on every prompt) intentionally drive up per-session verbosity for quality; that quality-for-tokens trade is correct per-session but accumulates per-week burn the developer cannot see ahead of time — so it needs a counter-balancing pacing layer.

## Current Solutions

- Manually glancing at the status-line and self-throttling (stopping heavy work when the 7-day bar shows behind) — fails during AFK loops and depends on being present.
- Manually choosing a smaller model (Opus → Sonnet → Haiku) to trade quality for tokens when burn is high.
- Deferring non-essential governance work (retrospectives, audits) to early in the week when headroom is high.
- Accepting mid-week exhaustion as a recoverable failure (wait for reset) — the failure this job exists to prevent.
## Related

- **P160** (Ship quota-pacing surface) — the driving capability; currently anchored to JTBD-006 (wrong/narrow). This job is its correct grounding.
- **P443** (quota-pacing lineage broken) — the ticket that surfaced the missing grounding job; its USM/story-map work builds from this JTBD once ratified.
- **JTBD-006** (Progress the Backlog While I'm Away) — the AFK-only job quota-pacing was mis-anchored to. Related but distinct: JTBD-006 is *what* the agent does unattended; JTBD-010 is the *token budget* that must survive underneath all work, attended or not.
- **JTBD-001** (Enforce Governance Without Slowing Down) — adjacent: governance verbosity is a major quota consumer, so this job is the counter-balance that keeps governance from starving the developer out of tokens. Distinct axis (budget-across-surfaces, not governance-speed).
- **ADR-093** (mechanical quota-pace throttle) — the mechanism serving this job.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-042 | STORY-042: Extract quota-pacing into its own plugin | accepted |
| STORY-039 | STORY-039: Throttle token burn against the quota windows | draft |
| STORY-043 | STORY-043: Self-install the quota-state producer | draft |
