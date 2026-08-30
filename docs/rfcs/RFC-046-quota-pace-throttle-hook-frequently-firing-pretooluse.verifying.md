---
status: verifying
rfc-id: quota-pace-throttle-hook-frequently-firing-pretooluse
reported: 2026-07-06
human-oversight: confirmed
oversight-date: 2026-07-09
decision-makers: [Tom Howard]
problems: [P160, P443, P446]
adrs: [ADR-093]
jtbd: [JTBD-010]
stories: [STORY-039, STORY-042, STORY-043, STORY-044]
story-maps: [STORY-MAP-003]
---

# RFC-046: Quota-pace throttle — mechanical PreToolUse pacing, extracted into `@windyroad/cruise`

**Status**: verifying (2026-08-30)
**Reported**: 2026-07-06
**Problems**: P160, P443, P446
**ADRs**: ADR-093
**JTBD**: JTBD-010
**Stories**: STORY-039, STORY-042, STORY-043, STORY-044
**Story Maps**: STORY-MAP-003

## Summary

The mechanical quota-pace throttle (ADR-093): a matcher-less `PreToolUse` hook that fires before every tool call across ALL work — interactive and AFK. Each firing reads the statusline-written quota cache (`~/.claude/quota-state.json`), compares cumulative 5h/7d window usage% against elapsed%, and when ahead of pace sleeps the calculated glide-path catch-up (proportional ease-back, capped 60s per firing). Headroom is env-tunable (`WR_QUOTA_HEADROOM_7D_PP` / `WR_QUOTA_HEADROOM_5H_PP`), **defaults 5pp weekly / 0pp 5h** — the weekly reserve protects non-Claude-Code surfaces (chat/Cowork). Behind pace = fast no-op; fail-open on every abnormal path; never blocks, never asks.

**Release 1** shipped the throttle 2026-07-06 (STORY-039). **The ADR-093 2026-07-08 amendment** then revised its home and adopter path on two axes (grounded in JTBD-010, replacing the wrong/narrow JTBD-006 AFK anchor — P443):

1. **Own opt-in plugin `@windyroad/cruise`** (STORY-042) — retiring the seven-plugin sync; throttling becomes a capability installed on purpose.
2. **Self-installing producer** (STORY-043) — a SessionStart hook installs the statusline cache-writer (implied-at-install consent + opt-out), closing the P160/P443 adopter-inert gap (the throttle previously worked only on a maintainer's hand-wired machine).

## Driving problem trace

- **P160** (Ship quota-pacing surface — Known Error, reopened Sev 20) — hitting a rate-limit window halts work mid-flight (AFK loops break; effortful resume; forced-waking). The throttle converts the statusline's diagnostic burn-rate data into mechanical pacing so work lands at each window reset with headroom instead of hard-stopping.
- **P443** (quota-pacing lineage broken) — the throttle shipped without a grounded problem → JTBD → USM → RFC → story lineage: mis-anchored to JTBD-006 (AFK-only) when it fires on ALL work, inert for adopters, and mis-placed across 7 plugins. This RFC is the repaired lineage: **JTBD-010** (Sustain My Token Quota Across the Week and Across Surfaces) → **STORY-MAP-003** → the three stories below.
- **P446** (throttle glide too weak to hold the pace line — a real hard weekly-limit stop occurred with the throttle running) — trace edge wired 2026-07-15 per the I13 gate: this RFC was already P446's fix vehicle (the corrected controller — deficit-aware position gate, feedback controller, asymmetric instant recovery — shipped in `@windyroad/cruise` 0.3.4/0.3.5 through this RFC's vehicle, with the ADR-093 amendment landed 2026-07-13), but the `problems:` array named only the original drivers.

## Scope

- **Release 1 — the throttle (shipped, STORY-039):** the canonical hook, calculated glide-path sleep, env-tunable headroom (defaults above), fail-open, behavioural bats.
- **Release 2 — the fix (STORY-042 + STORY-043, both ratified 2026-07-08):**
  - Extract the hook into a dedicated, opt-in `@windyroad/cruise` plugin; retire `scripts/sync-quota-pace-throttle.sh` + the 7-plugin sync; ADR-002 inventory / `marketplace.json` / `install.mjs` wiring; rework the machine-wide recent-check marker for per-session grip under concurrent sessions.
  - A **config file** for the knobs (headroom / cap / kill-switch) resolved **project → machine → built-in defaults** (env vars a final override). The config *mechanism* (exact keys, file name/location, precedence) is deferred to its own build-time ADR (P444) — not baked in silently.
  - A self-installing producer (SessionStart hook: create/patch the statusline cache-writer / agent-merge fallback), gated on its own mechanism ADR (write shape + consent) before build.
## Deferred (non-story slices, pending their own decisions)

- Config-mechanism ADR (P444) — settles the config-file shape before STORY-042's config work.
- Self-installer mechanism ADR — settles the write shape + consent before STORY-043.
- `/wr-itil:work-problems` between-iter pacing checkpoint (complementary coarse surface per ADR-093 slot note / P160 Correction 1).
- Cross-surface, account-wide quota read (beyond the statusline cache) — P160 Q6/Q7.

## Commits

- `abbc2717` feat(itil): transition STORY-044 accepted → in-progress — cruise status telemetry — 2026-08-30

## Verification

- **Published release:** `npm view @windyroad/cruise version` returned `0.4.11` on 2026-08-30; the published changelog includes implementation commit `60b252a4` for `/wr-cruise:status`.
- **Behavioral regression:** the focused Cruise suites (`cruise-status`, producer install, throttle pacing, and Codex quota state) pass 79/79.
- **Story evidence:** STORY-042 and STORY-043 are done; STORY-044's eight acceptance criteria are checked and its implementation is bound to commit `60b252a4`.
- **Trace evidence:** STORY-044 is present once in RFC-046's existing `pace` / `r1` row on STORY-MAP-003, with P160 and P446 traces rendered from repository state.
- **Problem boundary:** this RFC's shipped implementation is verifiable, but P160 remains Known Error until P443's separately owned lineage ticket reaches an honest lifecycle outcome.

## Related

- **ADR-093** (mechanical quota-pace throttle — normative mechanics; amended + ratified 2026-07-08 with the own-plugin + self-installing-producer axes).
- **STORY-MAP-003** (Sustain My Token Quota — the ratified USM; five activities all traced to JTBD-010).
- **JTBD-010** (Sustain My Token Quota Across the Week and Across Surfaces — the driver, ratified).
- **JTBD-006** (Progress the Backlog While I'm Away) — the AFK-only job this was originally *mis-anchored* to (P443); related but not the driver, since the throttle fires on interactive work too. JTBD-001 / JTBD-302 — adjacent.
- `~/.claude/statusline-command.sh` — the diagnostic read surface / cache-writer host (self-installed per STORY-043).
## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-039 | STORY-039: Throttle token burn against the quota windows | archived |
| STORY-042 | STORY-042: Extract quota-pacing into its own plugin | done |
| STORY-043 | STORY-043: Self-install the quota-state producer | done |
| STORY-044 | STORY-044: See what cruise is doing — a status/telemetry skill | in-progress |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-003 | STORY-MAP-003: Sustain my token quota across the week and across surfaces | draft |
| STORY-MAP-008 | STORY-MAP-008: Have a plugin behave like a guest in my repository | draft |
