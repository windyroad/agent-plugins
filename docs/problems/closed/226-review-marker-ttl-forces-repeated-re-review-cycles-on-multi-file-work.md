# Problem 226: Review-marker TTL forces repeated re-review cycles on multi-file work

**Status**: Closed
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Closed as no longer relevant

**Closure date**: 2026-06-08 (AFK work-problems iter, evidence-based close-as-superseded per ADR-079 + task-brief authorisation)
**Closure reason**: fix-shipped-under-sibling-tickets — P226's stated concern is mechanically covered by the combination of P111 (sliding-window refresh + subprocess-completion refresh on Agent|Bash) and P213 (Skill matcher expansion on the slide-marker PostToolUse hook). Both fixes landed in the same five-plugin matcher-expansion release this turn (commit 9a1f96c lineage for P111; commit 9a6e6e6/this-iter for P213). P226 was reported 2026-05-15 — three weeks AFTER P111 landed — citing a stale "1800s TTL" symptom that P107 had already inflated to 3600s on 2026-04-23. The investigation task "Extend TTL OR add sliding-window refresh (P111 pattern) OR scope marker per-batch rather than per-action" enumerates exactly the three fixes already in place at report time.

**Evidence (per ADR-026 grounding + ADR-079 evidence-based relevance-close pass)**:

- **TTL inflation already in place**: `packages/{architect,jtbd,style-guide,voice-tone}/hooks/lib/{architect-gate.sh,review-gate.sh}` all declare `local TTL_SECONDS="${ARCHITECT_TTL:-3600}"` / `"${REVIEW_TTL:-3600}"` — P226's description of "1800s TTL" is stale; the effective TTL is 1 hour, not 30 minutes (P107 fix 2026-04-23).
- **Sliding-window refresh already in place across all four review gates**: `packages/architect/hooks/lib/architect-gate.sh:51` and `packages/{jtbd,style-guide,voice-tone}/hooks/lib/review-gate.sh:54` all execute `touch "$MARKER"` on every successful PreToolUse:Edit|Write check — continuous edit work cannot expire the marker. This is the exact "sliding-window refresh (P111 pattern)" the investigation task enumerates as a candidate fix; it has been the gate behaviour since P111 landed.
- **Subprocess-completion refresh already in place**: `packages/{architect,jtbd,style-guide,voice-tone,risk-scorer}/hooks/{architect,jtbd,style-guide,voice-tone,risk}-slide-marker.sh` PostToolUse hooks registered in each plugin's `hooks.json` slide the parent's marker on every successful subprocess return (P111 fix, ADR-009 amendment 2026-04-25).
- **Skill matcher expansion shipped this turn**: P213 (released commit lineage 9a6e6e6 → @windyroad/{architect@0.15.5, jtbd@0.12.5, risk-scorer@0.12.8, style-guide@0.4.6, voice-tone@0.5.10}) widened the slide-marker PostToolUse matcher from `Agent|Bash` to `Agent|Bash|Skill` across all five review-gate plugins, plus ADR-009 amendment "PostToolUse:Skill matcher coverage (P213 Option D)". Confirmed via `grep -n "slide-marker" packages/{architect,jtbd,style-guide,voice-tone}/hooks/hooks.json` — all four review-gate plugins now carry the widened matcher.
- **Drift-based invalidation already orthogonal**: the gate-helpers.sh substance-aware hash check (ADR-009 amendment 2026-06-06) handles policy-file changes independently of TTL — so TTL expiry never "lets stale reviews ride" when policy actually changes.

**Relevance evidence shape**: fix-shipped-under-sibling-tickets (ADR-079 Phase 2 family; closest taxonomy match to "driver-child-ticket-closed" inverted — the mechanical fix shipped via siblings P111 + P213 rather than under P226's own ticket). The combination of TTL inflation (P107) + sliding-window touch (P111) + subprocess-completion refresh (P111) + Skill matcher coverage (P213) covers every fix-shape P226's Investigation Tasks enumerated; no separate code change is required.

**Reversibility**: `git revert` of the closure commit restores the Known Error file; if future operational evidence shows residual TTL friction the gates can't absorb (e.g. >2h orchestrator turns where the `<action>-born` 2×TTL hard cap in `risk-gate.sh` Band C still bites), capture a fresh focused ticket naming the specific failure mode — do NOT reopen P226 (the stated "1800s TTL multi-file work" mode is not the failure mode that would surface).

**Authorising decision**: ADR-079 (proposed, human-oversight confirmed 2026-06-08) — evidence-based relevance-close pass authorises Open|Known Error → Closed direct transition when sibling-shipped-fix evidence is observable. Task-brief authorisation 2026-06-08 work-problems iter: *"If P111+P213 covers P226 → close as superseded."*

## Description

The four review gates installed by `wr-architect`, `wr-jtbd`, `wr-style-guide`, and `wr-voice-tone` each produce a review marker with an 1800s (30-minute) TTL. Every edit to a covered file re-checks the marker; once it expires, the edit is blocked with `review expired (Ns old, TTL 1800s)`. Multi-file work routinely exceeds 30 minutes, forcing re-review cycles per gate per file batch.

## Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Extend TTL OR add sliding-window refresh (P111 pattern) OR scope marker per-batch rather than per-action.
- [ ] Coordinate with P213/#82 (risk-scorer TTL sibling).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/57
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: all four gate plugins.
- **Sibling**: P213/#82.
