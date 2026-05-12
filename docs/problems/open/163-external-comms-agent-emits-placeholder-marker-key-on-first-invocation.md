# Problem 163: `wr-risk-scorer:external-comms` agent emits placeholder marker key on first invocation when prompt doesn't direct shasum computation

**Status**: Open
**Reported**: 2026-05-04
**Priority**: 6 (Medium) — Impact: Moderate (3) x Likelihood: Possible (2)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

**WSJF**: (6 × 1.0) / 2 = **3.0**
**Type**: technical

> Captured 2026-05-04 by `/wr-itil:work-problems` AFK loop iter 7 surfacing pass per user direction "capture all four now". Sibling finding from iter 1 P154 commit gate cycle. See P166 for the related double-invocation cost finding (same surface, same agent).

## Description

The `wr-risk-scorer:external-comms` subagent (per ADR-028 / P064) is invoked at outbound prose risk-leak gate time on every changeset / release / PR-comment surface. The PostToolUse hook expects the agent to emit `EXTERNAL_COMMS_RISK_VERDICT: PASS` with a `marker_key=<sha256-hex>` so the gate can write `/tmp/claude-risk-${SID}/external-comms-reviewed-<sha>` and unblock subsequent identical-content invocations.

Observed iter 1 P154 (and recurring iter 3 P156, iter 4 P157, iter 6 P159, this iter's move-to-holding commit): on first invocation, the agent emits a **placeholder** key string instead of computing `sha256(draft+'\n'+surface)`. PostToolUse hook rejects non-hex keys; the gate stays denied. Workaround: the orchestrator (or invoking agent) computes the sha256 in Bash, re-prompts the agent with the precomputed key explicitly named, agent emits PASS with that key, hook accepts, gate unlocks.

Affects every changeset / release / PR-comment / commit-message review path. Each gate cycle pays the double-invocation cost (~$0.05 per gate per agent fire — see P166).

## Symptoms

- Gate cycles see two `wr-risk-scorer:external-comms` agent fires where one should suffice.
- First fire's verdict carries placeholder/non-hex marker key; second fire (with explicit precomputed key) carries valid key.
- Pattern observed across 5+ commits this AFK loop (P154, P156, P157, P159, c326106 move-to-holding).

## Workaround

Invoking agent precomputes `sha256` in Bash, includes it in the agent prompt explicitly. Single fire then suffices. See iter 1 / iter 3 / iter 4 / iter 6 retro notes for the workaround's exact mechanic.

## Impact Assessment

- **Who is affected**: Plugin-developer authoring changesets / release commits / PR comments. Every commit-gate cycle currently pays the double-fire cost.
- **Frequency**: Every commit-gated surface. ~5+ instances per AFK loop.
- **Severity**: Moderate — workaround works; cost is per-cycle, not catastrophic.
- **Likelihood**: Possible — pattern is repeatable; each new contributor following SKILL.md instructions hits it on first attempt.

## Root Cause Analysis

(Deferred to investigation.)

Hypothesis: the agent's SKILL.md instructs it to compute the sha256 but the agent's tool surface (per ADR-028) does not include Bash, so the computation is impossible inside the agent — the agent emits a placeholder it expects the orchestrator to override. The contract mismatch is between SKILL.md-stated behaviour ("compute sha256(...)") and tool-surface reality ("no Bash available").

### Investigation Tasks

- [ ] Investigate root cause — confirm hypothesis re tool-surface mismatch.
- [x] **Decide fix shape**: ~~(a) grant Bash to the agent~~, (b) move sha256 computation to PostToolUse hook, (c) document explicit-precompute pattern. **User direction 2026-05-13** picked **(a) grant agent Bash for sha256 only** (during `/wr-itil:work-problems` Step 6.75 halt Step 2.5b surfacing — Q2 answer). Narrow tool grant: agent runs `shasum -a 256` via Bash; preserves agent-side key computation. Bundle with TMPDIR-variance fix per Q3 answer — shared helper handles both root causes.
- [ ] Architect review on the chosen direction (grant-Bash-for-sha256-only) — sibling to ADR-028 / P064. Narrow-tool-grant precedent: confirm whether ADR-028's "no Bash" constraint admits a sha256-only subset, or requires amendment.
- [ ] Implement: amend `packages/risk-scorer/agents/external-comms.md` allowed-tools + agent prompt; the agent must `Bash(shasum:*)` (or equivalent narrow grant) and `printf '%s\n%s' "$DRAFT" "$SURFACE" | shasum -a 256 | cut -d' ' -f1` to emit the canonical key.
- [ ] TMPDIR-variance bundle (Q3): shared `${TMPDIR:-/tmp}` resolution helper consumed by ALL gate hooks (external-comms + sibling per-gate marker writers) so PostToolUse and PreToolUse resolve to the SAME path on macOS. Observed 2026-05-04 (P124-sibling — same UUID-stale class, different surface) and 2026-05-13 P185 iter 2 retro (3 distinct dirs per session_id). Per the iter 2 retro's "Pipeline Instability" entry on TMPDIR.
- [ ] Behavioural bats: agent emits sha256 key matching gate-side computation; TMPDIR helper resolves identically across PostToolUse hook and PreToolUse gate; previously-noted manual-marker workaround in `hooks-and-gates-archive.md` becomes obsolete.

## Fix Strategy

**Direction (user 2026-05-13)**: Grant `wr-risk-scorer:external-comms` agent narrow Bash access (`shasum` only) so it computes the canonical sha256 key itself, eliminating the placeholder-key class. Bundle with TMPDIR-variance fix (shared `${TMPDIR}` resolution helper) so PostToolUse marker writes land where PreToolUse gates look. Together they retire the manual-pre-bind workaround documented in `hooks-and-gates-archive.md`.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P064 (parent — external-comms gate), P166 (sibling — precomputed-sha256 helper for the double-invocation cost), ADR-028 (external-comms agent surface), ADR-013 Rule 5 (policy-authorised gate)

## Related

- ADR-028 (`docs/decisions/028-external-comms-risk-scoring.proposed.md`) — parent decision; agent surface contract.
- P064 (`docs/problems/064-no-risk-scoring-gate-on-external-comms.verifying.md`) — parent problem; held in changesets-holding awaiting dogfood evidence.
- P166 (this loop's iter 4 sibling finding — precomputed-sha256 helper).
- iter retros: `docs/retros/2026-05-03-p154-iter.md`, `docs/retros/2026-05-03-p156-iter.md`, `docs/retros/2026-05-03-p157-iter.md`, `docs/retros/2026-05-04-p159-iter.md`.

## Change Log

- **2026-05-04** — Opened by orchestrator's main turn at end of `/wr-itil:work-problems` AFK loop iter 7 per user direction "capture all four now". Skeleton ticket; investigation deferred.
- **2026-05-13** — Updated by orchestrator's main turn at end of `/wr-itil:work-problems` Step 6.75 halt (Step 2.5b surfacing Q2 + Q3 answers). User direction selected fix shape (a) grant agent narrow Bash for sha256; bundled with TMPDIR-variance fix per Q3. Investigation Tasks updated to reflect direction; Fix Strategy section populated. Adjacent friction empirically observed iter 1 + iter 2 of the current session (every changeset-author Write costs 1 extra round-trip; iter 2 retro hit it explicitly when it could not commit its own retro files until orchestrator-side manual marker pre-bind worked the issue).
