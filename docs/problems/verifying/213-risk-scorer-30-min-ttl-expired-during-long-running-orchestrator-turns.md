# Problem 213: risk-scorer 30-min TTL expired during long-running orchestrator turns

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**WSJF**: 0 (Verification Pending multiplier 0.0; held for verification only)

## Fix Released

**Release vehicle**: pending — code lands this iter; release scheduled for next `/wr-itil:work-problems` Step 6.5 drain across `@windyroad/{architect,jtbd,style-guide,voice-tone,risk-scorer}` patch bundle.

**Direction**: User ratified Option D (matcher expansion) 2026-06-08 after weighing four options (A status-quo, B Band-A-slide-unification, C RISK_HARDCAP_MULT env knob, D P111 matcher expansion). Picked D for architectural cleanliness — addresses TTL expiry by reducing the number of marker-consumption events through wider PostToolUse hook coverage rather than knob-tuning.

**Fix**:
- ADR-009 amendment 2026-06-08 ("PostToolUse:Skill matcher coverage (P213 Option D)") records the ratified contract.
- `packages/{architect,jtbd,style-guide,voice-tone,risk-scorer}/hooks/hooks.json` — slide-marker matcher widened from `Agent|Bash` to `Agent|Bash|Skill`. One line per file, five files total.
- `packages/{architect,jtbd,style-guide,voice-tone,risk-scorer}/hooks/*-slide-marker.sh` — comment header updated (`PostToolUse:Agent|Bash` → `PostToolUse:Agent|Bash|Skill (P111 + P213)`). No code changes; the helper `slide_marker_on_subprocess_return` is matcher-agnostic and composes without changes.
- `gate-helpers.sh` unchanged (matcher-agnostic). ADR-017 byte-identity invariant preserved across the four shared lib copies.
- Behavioural bats: each plugin's `hooks/test/slide-marker-on-subprocess-return.bats` gains one new test (`slide: triggers correctly on Skill tool_response shape`) — 5 new tests across the byte-identical bats files. `packages/architect/hooks/test/architect-slide-marker.bats` gains one hook-level integration test (`hook: P213 — slides on Skill tool_name`). 6 new bats total; existing 35 slide-marker bats remain green (42/42 with the new tests).
- Architect (PASS) + JTBD (PASS) reviews 2026-06-08.

**Verification path**: run an AFK `/wr-itil:work-problems` session that invokes multiple `/wr-risk-scorer:assess-*` sibling-assessor SKILLs in sequence (the typical end-of-loop sequence: `assess-release` → `release:watch` → `install-updates`). The parent's gate markers should remain fresh across SKILL boundaries — TTL-expiry-during-orchestrator-turn events should drop relative to the pre-amendment baseline. Confirm via `stat` on `/tmp/{architect,jtbd}-reviewed-<SID>` that mtimes advance after each SKILL completes (not only after Agent/Bash subprocesses as before). The 2×TTL hard-cap from `<action>-born` still bounds total marker life — long enough orchestrator runs may still exhaust it; that residual is acceptable per the ADR-009 amendment scope (deferred items list options B/C if residual friction persists).

## Description

The risk-scorer commit gate uses a 1800s (30 min) TTL on the cached score marker. During long orchestrator turns (multi-iteration AFK loops, batched skill invocations), the score expires mid-turn even when no commits happen between scoring and the eventual commit. This forces a fresh `wr-risk-scorer:pipeline` subagent invocation just to satisfy the gate, wasting a turn and re-asking the user to wait.

## Workaround

Re-invoke the pipeline subagent whenever the gate denies on TTL expiry. Visible friction but recoverable.

## Impact Assessment

- **Severity**: Moderate — wasted turns; AFK loop tempo degraded.

## Root Cause Analysis

### Investigation (2026-06-07, AFK iter)

Current state — partially resolved by prior fixes since the upstream report:
- **P107 (2026-04-23)** — bumped default `RISK_TTL` 1800s → 3600s. Ticket description's "30-min TTL" is stale.
- **P090 (2026-04-25)** — three-band TTL refinement in `risk-gate.sh`: Band A (age<TTL/2) pass silently, Band B (TTL/2≤age<TTL) pass + slide marker on hash-invariance, Band C (age≥TTL) deny. 2×TTL hard cap via `<action>-born`.
- **P111 (2026-04-25)** — `risk-slide-marker.sh` PostToolUse:Agent|Bash refreshes score markers on every successful subprocess return.

Remaining failure mode: the 2×TTL hard cap from `<action>-born` (2h) terminates riding regardless of slide. Long AFK orchestrator sessions (`work-problems` overnight) exceed this ceiling.

### Substance decision required (architect ISSUES_FOUND on AFK iter 2026-06-07)

ADR-009 "Three-band TTL refinement (P090, risk-scorer only)" ratifies the asymmetry between risk-gate (three-band, Band A no slide) and review-gate (binary TTL, always slide on success). Resolving P213 requires picking one of:

- **Option A — Status quo**: Accept the 2h ceiling; long AFK sessions occasionally rescore. Closes P213 as "won't fix".
- **Option B — Band A slide**: Amend ADR-009 to unify Band A with Band B (slide on every successful gate check). Matches review-gate.sh precedent. Hard cap from `<action>-born` preserved. Cost: +1 `touch` syscall per Band A check (sub-ms). Architect lean.
- **Option C — Configurable hard-cap multiplier**: Introduce `RISK_HARDCAP_MULT` env var (default 2, preserving current default). Adopters running long AFK can opt in via env. ADR-009 amendment needed to ratify the new knob.
- **Option D — P111 expansion**: Slide on more PostToolUse matchers (Edit|Write). May not actually move the needle — gate checks already slide via Band B and the existing subprocess hook.

Architect requires ADR-009 amendment (not new ADR) before any code change. Per the substance-confirm-before-build pattern, the chosen option needs human ratification — AFK orchestrator cannot pick.

### Investigation Tasks

- [ ] User picks Option A/B/C/D above (substance decision).
- [ ] If B or C: author ADR-009 amendment subsection; implement code + behavioural bats.
- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/82
- **Pipeline classification**: JTBD-aligned (JTBD-006); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/risk-scorer.
- **Governing ADR**: ADR-009 (Gate Marker Lifecycle), specifically "Three-band TTL refinement" subsection.
