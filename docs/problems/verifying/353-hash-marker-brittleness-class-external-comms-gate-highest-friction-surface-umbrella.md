# Problem 353: hash-marker brittleness class — external-comms gate is the highest-friction surface in the project (umbrella ticket tying P276 + P303 + P181 sibling-instances + upstream #125)

**Status**: Verification Pending
**Reported**: 2026-06-03 (user direction with screenshot evidence quoting a sibling-session's retro observation; user direction: *"these have been reported (you'll need to look), but there is important verbatim in this image worth considering"*)
**Priority**: 16 (High) — Impact: 4 (Significant) × Likelihood: 4 (Likely)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-001
**Effort**: M
**WSJF**: 8.0 (Verification Pending multiplier 0.0; held for verification only)

## Fix Released

**Released**: 2026-06-06 — class root cause closed (substance-aware marker + atomic verdict-write).

**Direction**: User ratified the substance-aware design on 2026-06-06. The user-approved contract explicitly addresses the three class-level failure modes the umbrella captured:

- **"Marker doesn't land after PASS"** (sub-cause 1) — closed by the atomic verdict-write helper `_atomic_mark_with_hash`. The mark hook now writes the marker + hash file as a single atomic mktemp + rename pair; either both land or neither does. No more silent failure → no more `BYPASS_RISK_GATE=1` after a legitimate PASS.
- **"Marker invalidated by body-edit"** (sub-cause 2) — closed for the policy-file-drift surface by the substance-aware `_substance_hash_path` (normalises CRLF / trailing whitespace / trailing newlines before hashing). Trivial PASS-class edits (whitespace, line-ending) no longer invalidate the marker. Conservative boundary preserved: single-numeral edits and frontmatter-key changes are still treated as substantive (re-review fires).
- **"Drift-relock compound"** (sub-cause 3) — closed by the same substance-aware hash applied per-gate. Multi-file commits where each file's policy hash is computed independently no longer compound trivial-edit invalidations.

**Fix**:
- ADR-009 amendment 2026-06-06 ("Substance-aware drift + atomic verdict-write") records the ratified contract.
- ADR-028 amendment 2026-06-06 records the external-comms inheritance.
- `packages/<architect|jtbd|voice-tone|style-guide|risk-scorer>/hooks/lib/gate-helpers.sh` gains the two shared helpers — byte-identical across all five copies per ADR-017.
- `packages/<jtbd|voice-tone|style-guide>/hooks/lib/review-gate.sh` + `packages/architect/hooks/lib/architect-gate.sh` route drift detection through `_substance_hash_path`.
- `packages/architect/hooks/architect-mark-reviewed.sh` + `architect-refresh-hash.sh` route the verdict-write through `_atomic_mark_with_hash`.
- Behavioural bats at `packages/<architect|jtbd|voice-tone|style-guide>/hooks/test/substance-aware-drift.bats` exercise (a) trivial-edit-no-refire, (b) substantive-edit-refires, (c) atomic-write persists, (d) conservative fallback. 25 new bats; existing 259 hook bats remain green.

**Sub-instance status**:
- **P276** (Open — body-edit marker invalidation) — class root cause closed by this release; sibling-ticket may still ship the per-instance whitespace normalisation in `compute_external_comms_key` independently. Mark for re-rank.
- **P303** (Verification Pending — sibling release in the same commit) — drift-relock facet closed. Sibling P181/P217 still tracks the verdict-grep facet.
- **P181** (Verifying) — independent fix already released.
- **#125 upstream** — out of scope (Claude Code SDK-level marker propagation); local class root cause closed without dependency on upstream resolution.

**Friction-tax recovery target**: the next 3-filing AFK session should fire 3 subagent invocations (one per filing) with 0 `BYPASS_RISK_GATE=1` uses — down from the measured ~12 invocations + 3 BYPASS uses. Confirms the class root cause closure.

**Verification**:
- Run the behavioural bats: `node_modules/.bin/bats packages/{architect,jtbd,voice-tone,style-guide}/hooks/test/substance-aware-drift.bats` → 25/25 PASS.
- Observe an AFK session authoring external comms — marker persists after PASS; no fallback to BYPASS required.
- Trivial whitespace edits on ADR / JTBD / VOICE-AND-TONE / STYLE-GUIDE files between successive gated edits no longer re-fire the review.

## Description

User direction 2026-06-03 with verbatim retro evidence (screenshot from a sibling session):

> *"Notable: hit P074 live on every upstream filing — markers didn't land after PASS verdicts despite both subagents (wr-risk-scorer:external-comms + wr-voice-tone:external-comms) explicitly returning PASS. Used the documented `BYPASS_RISK_GATE=1` workaround after legitimate review. This is the third active issue at the external-comms gate (P074 existing, P085 new, plus #125 upstream sibling) — they form a class of "hash-marker brittleness" friction worth umbrella-tracking."*
>
> *"Friction tax this session: ~12 subagent invocations across the 3 upstream filings just for gate clearance, plus 3 BYPASS_RISK_GATE=1 uses. Each filing requires 2 sequential subagent reviews + 1 BYPASS retry. The combination of P074 (marker doesn't land) + P085 (marker invalidated when body changes) makes the external-comms gate currently the highest-friction surface in the project — would be a high-leverage upstream fix."*

The screenshot's P074 / P085 / #125 reference a sibling-project ticket-numbering space. In THIS project (windyroad-claude-plugin), the analogous sub-instances are:

- **P276** (Open) — `external-comms gate marker over-fires on PASS-class content edits` — matches the screenshot's "marker invalidated when body changes" (P085-sibling). Content-hash marker invalidates on any file change including PASS-class trivial edits (whitespace, single-numeral, frontmatter shape).
- **P303** (Open) — `Architect gate deadlocks multi-decision-file change — verdict-grep + drift-relock + disk-state-review deadlock compound` — adjacent architect-side compound of marker-friction; references P181/P217 verdict-grep + P215/P216/P226 drift-relock sub-bugs.
- **P181** (Verifying) — architect-mark-reviewed verdict-grep fragility (fix released; sibling-pattern precedent that applies to external-comms-side too).
- **#125 upstream** — referenced as upstream sibling in the screenshot. Likely a Claude Code SDK-level issue with hook marker propagation (P173 BYPASS env vars not propagating from Bash subshell is a related class).

The **friction tax** is measurable and high: ~12 subagent invocations + 3 BYPASS uses across 3 upstream filings in a single session, exclusively for gate clearance (not for actual review value). Each upstream filing under the current gate shape requires 2 sequential subagent reviews + 1 BYPASS retry. The pattern recurs on every external-comms-bearing commit.

## Symptoms

- After both `wr-risk-scorer:external-comms` and `wr-voice-tone:external-comms` subagents explicitly return PASS, the hook's content-hash markers nevertheless don't land — the next Edit/Write to the same file re-fires both reviews.
- BYPASS_RISK_GATE=1 used as documented workaround after legitimate PASS — adopters lose the safety guarantee BYPASS was meant to be a last-resort for.
- Trivial post-PASS edits (whitespace, single-numeral) invalidate the marker and force re-review, even when the edit cannot meaningfully change the agent's verdict.
- Aggregated cost: 2 subagent calls (risk + voice-tone) × N filings + (3 BYPASS retries) = ~12 invocations + 3 BYPASS uses per session of 3 filings. Token + wall-clock + author-attention cost scales with filing count.

## Workaround

`BYPASS_RISK_GATE=1` after the legitimate review-cycle has PASSed. Documented but erodes the gate's safety guarantee — every BYPASS use is a trust loss the gate cannot recover from on the next call.

## Impact Assessment

- **Who is affected**: every maintainer authoring external-comms (changeset bodies, gh issue/PR/advisory prose, npm publish content). Persona: developer (governance enforcement). JTBD: JTBD-001 (enforce governance without slowing down — VIOLATED by the current friction shape).
- **Frequency**: every external-comms commit in every session. The umbrella accumulates pain across all sibling instances.
- **Severity**: High. External-comms gate is on the load-bearing release-prose path; friction here taxes every release. Measured friction (12 invocations + 3 BYPASS uses per 3-filing session) makes this empirically the highest-friction surface in the project.
- **Analytics**: cross-instance pattern — fixing per-instance (P276 only, or P303 only) leaves the class active. Class fix needs to address the marker-derivation contract + the verdict-grep parsing + the body-edit invalidation semantics together.

## Root Cause Analysis

### Class root cause (hypothesis)

The **hash-marker contract** that the external-comms (and architect, JTBD, voice-tone, style-guide) gates rely on derives the marker key from the FILE CONTENT HASH at the moment of subagent review. Three independent failure modes compound:

1. **Marker doesn't land after PASS** (P276-class for external-comms specifically; sibling at architect-side per P181 verdict-grep fragility): subagent returns PASS verbatim but the hook's post-review write fails to compute a matching marker — possibly due to (a) hash derivation off-by-one (computed before agent fully wrote the verdict file vs after), (b) verdict-grep parsing fragility (treats "ISSUES FOUND" substring anywhere as FAIL even within a PASS prose), or (c) the SDK-level marker propagation issue referenced as #125 upstream.

2. **Marker invalidated by body-edit** (P276 directly): any file content change between review-time and commit-time invalidates the content-hash marker, triggering re-review. Trivial PASS-class edits (whitespace, single-numeral, frontmatter shape) shouldn't require fresh review but currently do.

3. **Drift-relock compound** (P303): on multi-file commits the gates re-lock on every Edit/Write because each file's marker is independent. Compound of (1) + (2) across N files = N × M friction multiplier.

### Investigation Tasks

- [ ] Confirm P276 (this project) is the "marker invalidated when body changes" instance (P085-sibling-in-screenshot).
- [ ] Identify the local instance of "marker doesn't land after PASS verdicts" (P074-sibling-in-screenshot). Likely a new sub-ticket if not P276 (P276 is about over-fire on trivial edits, not about marker not landing on first PASS). Possibly need to capture a new sub-ticket.
- [ ] Identify the upstream #125 reference (likely Claude Code SDK marker-propagation; possibly P173 BYPASS env propagation).
- [ ] Class-level structural-fix scoping: shape of fix (normalise pre-hash content? semantic-hash instead of byte-hash? agent-emits-verdict-then-hook-writes-marker-atomic? different gate contract entirely?). Will require ADR — defer to ratification when scoped.

## Fix Strategy

**Kind**: prevent (class fix; umbrella tracking)

**Shape**: This is an UMBRELLA ticket. The class-level structural fix needs an ADR (the per-instance fixes — P276 + P303 + any new "marker doesn't land" sub-ticket — can ship per their own fix strategies; the umbrella tracks that NONE of them in isolation closes the class root cause).

Per-instance vs class fix:

- **Per-instance**: P276's proposed normalise-whitespace-before-hash addresses sub-cause (2); P303's amend to architect-side verdict-grep addresses sub-cause (1) at architect; #125 upstream addresses the SDK-side propagation. Shipping each independently reduces friction but doesn't close the class.
- **Class fix**: a structural change to the marker-derivation contract that addresses all three sub-causes together — likely a new ADR amending ADR-009 (gate marker lifecycle) + ADR-028 (external-comms gate scope). Substance needs user ratification.

**Recommendation**: ship the per-instance fixes incrementally (P276 already has a fix strategy; P303 has a composite fix path; #125 upstream needs filing if not already filed); track class closure via this umbrella ticket; the class structural fix gets ratified + dispatched once the per-instance work is in flight.

## Dependencies

- **Blocks**: trust + throughput on the external-comms gate (load-bearing for every external-comms commit).
- **Blocked by**: (per-instance tickets P276 + P303 + new "marker doesn't land" sub-ticket if needed). UMBRELLA tracks; doesn't directly block.
- **Composes with**: P276 (sibling — body-edit marker invalidation), P303 (sibling — multi-file marker drift-relock), P181 (Verifying — architect-side verdict-grep fragility precedent), P217 (Closed — architect-side verdict-grep), P173 (Verifying — BYPASS env propagation), ADR-009 (gate marker lifecycle — likely needs amendment to close the class), ADR-028 (external-comms gate scope — composes with ADR-009 amendment).

## Related

- 2026-06-03 user direction (verbatim quoted in Description) — sibling-session retro observation that identified the umbrella class. Sibling-project ticket-numbers (P074 + P085 + #125) are NOT this project's numbering; the local analogues are P276 + P303 + an unidentified "marker doesn't land" instance.
- **P276** (Open) — local-analogue for "marker invalidated when body changes" (screenshot's P085-sibling).
- **P303** (Open) — architect-side compound; verdict-grep + drift-relock + disk-state-review deadlock.
- **P181** (Verifying) — architect-mark-reviewed verdict-grep fragility (sibling precedent fix).
- **P173** (Verifying) — BYPASS env vars not propagating from Bash subshell to PreToolUse hook context.
- **ADR-009** — gate marker lifecycle (likely needs amendment for class closure).
- **ADR-028** — external-comms gate scope (composes with ADR-009 for class fix).
- Sibling-project screenshot evidence (2026-06-03): friction tax ~12 subagent invocations + 3 BYPASS uses across 3 upstream filings in a single session. External-comms gate identified as highest-friction surface in the project. *"would be a high-leverage upstream fix"*.
