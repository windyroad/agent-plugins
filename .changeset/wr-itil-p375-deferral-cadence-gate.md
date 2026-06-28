---
"@windyroad/itil": patch
---

Add an authoring-time deferral-cadence advisory hook (P375).

A new `PostToolUse:Write|Edit|MultiEdit` hook
(`itil-deferral-cadence-gate.sh`) fires when an uncadenced deferral is
authored into a shipped artefact — a `SKILL.md`, an ADR, an RFC, or a hook
`*.sh`. It scans only the newly-authored text (diff-aware, so existing prose
never re-triggers) and emits a stderr advisory when a deferral phrasing
(`deferred to …`, `pending review`, `re-rate at next`, `lands in Slice N`) is
introduced without a cadence annotation naming a self-firing trigger within
the surrounding window. Crucially — and unlike the existing retro-only
fictional-defer advisory — a bare on-demand skill (`/wr-foo:bar`) or a bare
ticket ID does NOT count as a cadence: naming a re-entry point that nothing
self-fires is the exact rot P375 captures. A cadence is satisfied only by a
self-firing class — a hook `*.sh`, `SessionStart`, `PreToolUse`/`PostToolUse`,
a CI workflow, `cron`, or a `work-problems` pre-flight — carried as
`<!-- cadence: <trigger> -->` or named in prose. `docs/problems/` tickets are
out of scope (they narrate deferrals descriptively). Advisory only, never
blocks; AFK self-suppress via `WR_SUPPRESS_DEFERRAL_CADENCE_GATE=1`.

This is the core slice of the ratified Option-C authoring-time enforcement
gate (ADR-087, RFC-035). The transitive-reachability graph check (does the
named trigger actually fire?), the convergence with the fictional-defer
sibling, and escalation from advisory to a hard block are deferred follow-ons.
