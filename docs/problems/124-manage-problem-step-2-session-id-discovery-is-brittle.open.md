# Problem 124: `/wr-itil:manage-problem` Step 2 substep 7 session-id discovery is brittle — agent has no env var, must scrape marker filenames

**Status**: Open
**Reported**: 2026-04-26
**Priority**: 6 (Med) — Impact: Minor (2) x Likelihood: Likely (3)
**Effort**: S — extend `packages/itil/skills/manage-problem/SKILL.md` Step 2 substep 7 with a documented session-id discovery pattern that does NOT depend on `${CLAUDE_SESSION_ID}` being in the agent's env (it is not, in main-turn or subprocess contexts). The pattern: read an existing marker filename under `/tmp/<existing-marker>-<UUID>`, extract the UUID, and use that. Reference implementation: list `/tmp/architect-plan-reviewed-*` (or any other gate marker reliably set this session) and parse the trailing UUID. New helper script in `packages/itil/hooks/lib/session-id.sh` (or extend an existing detector lib) exporting a deterministic `get_current_session_id()` function. SKILL.md Step 2 substep 7 cites the helper rather than the brittle `${CLAUDE_SESSION_ID:-default}` fallback.
**WSJF**: (6 × 1.0) / 1 = **6.0**

> Surfaced 2026-04-26 during P122 retro session: the assistant attempted to write `docs/problems/122-*.open.md` after running Step 2's grep, but the create-gate hook (P119, `/wr-itil:manage-problem` enforcement) blocked the Write because the per-session marker `/tmp/manage-problem-grep-${SESSION_ID}` did not match the hook's stdin-JSON `session_id`. The SKILL.md Step 2 substep 7 fallback is `${CLAUDE_SESSION_ID:-default}` which evaluated to `default` (env not set), but the hook reads the actual session UUID from its stdin JSON payload (`60331245-5d4e-461c-b95b-67b9a5b95c4b`). The agent had to scrape an existing `/tmp/architect-plan-reviewed-<UUID>` filename to discover the correct UUID, then re-touch the marker with the right name before retrying. Same friction would fire for any agent invoking manage-problem from a context where `CLAUDE_SESSION_ID` is not exported.

## Description

`packages/itil/skills/manage-problem/SKILL.md` Step 2 substep 7 instructs the agent to write the per-session create-gate marker:

```bash
: > "/tmp/manage-problem-grep-${CLAUDE_SESSION_ID:-$(echo "${CLAUDE_HOOK_SESSION_ID:-default}")}"
```

The fallback chain `${CLAUDE_SESSION_ID:-${CLAUDE_HOOK_SESSION_ID:-default}}` exits to `default` when neither env var is set, which is the typical case in agent contexts. The SKILL.md acknowledges this — *"In practice the session ID is supplied by the hook payload, not as an env var — the simplest portable pattern is to ask Claude Code to run a one-line Bash that touches the marker using whatever session_id is available in the current invocation."* — but does not name the actual portable pattern, leaving the agent to discover one ad-hoc.

The hook (`packages/itil/hooks/manage-problem-enforce-create.sh` line 58-62) reads `session_id` from the stdin JSON payload via Python:

```bash
SESSION_ID=$(echo "$INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('session_id', ''))
")
```

The hook then checks `/tmp/manage-problem-grep-${SESSION_ID}` exists. The mismatch between the marker name the agent writes (`/tmp/manage-problem-grep-default`) and the marker name the hook checks (`/tmp/manage-problem-grep-60331245-...`) causes the deny.

## Symptoms

- Agent runs Step 2 grep, writes the marker per the SKILL.md fallback, attempts the Write of the new ticket file, gets blocked: `BLOCKED: Cannot Write '<NNN>-...' under docs/problems/ without running /wr-itil:manage-problem Step 2 (duplicate-check) first. (P119)`.
- Investigation reveals the marker exists but with the wrong name (`/tmp/manage-problem-grep-default` instead of `/tmp/manage-problem-grep-<actual-UUID>`).
- Recovery requires the agent to discover the actual session UUID through some other artefact — the most reliable signal is an existing `/tmp/<gate>-reviewed-<UUID>` marker from another hook in the same session (architect, JTBD, or risk-scorer markers all carry the UUID by construction).
- Once the agent extracts the UUID, the second marker-touch + Write succeeds.

## Workaround

Per-invocation, the agent runs `ls /tmp/architect-plan-reviewed-* 2>/dev/null | head -1` (or any equivalent UUID-bearing marker), extracts the trailing UUID, and writes `/tmp/manage-problem-grep-<UUID>` directly. Costs one Bash round-trip per ticket-creation attempt where the env var isn't set.

## Impact Assessment

- **Who is affected**: every agent invoking `/wr-itil:manage-problem` for ticket creation in a context where `CLAUDE_SESSION_ID` is not set in the env. Empirically: every agent context observed so far in this repo.
- **Frequency**: every ticket-creation attempt that doesn't follow a prior successful manage-problem invocation in the same session (the marker persists once set, so subsequent creations in the same session work fine).
- **Severity**: Minor — one Bash round-trip per first ticket of a session to discover the UUID. Not a hard block; a documented workaround.
- **Likelihood**: Likely — most agent contexts don't export `CLAUDE_SESSION_ID`; the SKILL.md fallback chain doesn't help.
- **Analytics**: Direct in-session evidence (P122 ticket creation this session blocked once until UUID was extracted).

## Root Cause Analysis

### Structural

The SKILL.md substep 7 prose acknowledges the env var is unreliable but does not commit to a specific discovery pattern. Each agent invents its own (or fails). The hook contract is correct — checking a session-scoped marker is the right design — but the agent-side discovery story is undocumented.

### Investigation Tasks

- [ ] Confirm `CLAUDE_HOOK_SESSION_ID` is NOT exported in agent main-turn or subprocess contexts (verify across Opus 4.7, Sonnet 4.6, Haiku 4.5).
- [ ] Decide the canonical discovery pattern. Candidates:
  - **(a) Scrape existing markers**: parse `/tmp/architect-plan-reviewed-*` (or any reliably-set gate marker). Lean: the architect marker is set early in any session that touches `docs/decisions/`-adjacent files. Falls back to JTBD or risk-scorer if architect is absent.
  - **(b) New helper script** that wraps (a): `packages/itil/hooks/lib/session-id.sh` exports `get_current_session_id()`. SKILL.md cites the helper.
  - **(c) New hook** that ALWAYS sets a session-marker on session start (`SessionStart` hook with no other purpose than to write `/tmp/wr-session-${UUID}`). Reliable but adds a hook for marker-shape only.
  - **(d) Agent-side capability**: if Claude Code exposes the session UUID via some agent-readable surface (e.g., a magic env var or a tool), use that. Requires Anthropic feature gap if not present today.
- [ ] Compose with `packages/architect/hooks/lib/session-marker.sh` (the cross-plugin shared session-marker pattern from ADR-038) — likely the right home for the helper.
- [ ] Add a behavioural bats covering the discovery contract: in a context with no env var set + an existing `/tmp/architect-plan-reviewed-<UUID>` marker, the helper returns `<UUID>` deterministically.
- [ ] Update SKILL.md Step 2 substep 7 to cite the helper instead of the brittle env-var fallback.

### Fix Strategy

**Kind**: improve

**Shape**: skill (improvement stub) + new shared helper (lib/session-id.sh)

**Target files**:
- `packages/itil/skills/manage-problem/SKILL.md` — Step 2 substep 7 rewrite to cite the helper.
- `packages/itil/hooks/lib/session-id.sh` (NEW) — exports `get_current_session_id()` returning the canonical UUID; primary detection via `/tmp/architect-plan-reviewed-*` glob; fallback chain through other gate-marker globs.
- `packages/itil/hooks/test/session-id.bats` (NEW) — 4-6 behavioural assertions covering: env-var present, env-var absent + architect-marker present, env-var absent + no-markers (returns empty + non-zero), multiple-markers (returns the most-recent UUID).
- `.changeset/wr-itil-p124-*.md` — patch entry.

**Out of scope**: extending the helper to other plugins (architect/jtbd/risk-scorer) — they don't need it (their hooks read session_id directly from stdin payloads). Discovery via Anthropic-feature-gap remediation — out of scope until the feature ships.

## Dependencies

- **Blocks**: P119 (verifying — the create-gate hook contract; this ticket addresses the agent-side discovery gap that P119 surfaces but doesn't itself solve)
- **Blocked by**: (none)
- **Composes with**: P119 (verifying — same surface; this ticket is the agent-side companion to P119's hook-side enforcement), ADR-038 (session-marker pattern; helper likely lives in the same lib directory)

## Related

- **P119** (`docs/problems/119-agent-bypasses-manage-problem-step-2.verifying.md`) — created the create-gate hook this ticket's discovery gap surfaces. Composable, not duplicative.
- **ADR-038** (`docs/decisions/038-progressive-disclosure-and-once-per-session-budget-for-userpromptsubmit.proposed.md`) — defines the session-marker pattern; the new helper inherits the shared-lib placement.
- `packages/itil/skills/manage-problem/SKILL.md` Step 2 substep 7 — primary fix target.
- `packages/itil/hooks/manage-problem-enforce-create.sh` lines 58-62 — hook side that reads session_id from stdin JSON.
- **JTBD-001** (Enforce Governance Without Slowing Down) — primary fit. The current friction is one round-trip per first ticket of a session.
- **JTBD-006** (Progress the Backlog While I'm Away) — composes; AFK loops that create tickets mid-iter pay the same friction without an interactive UUID-extraction surface.
- 2026-04-26 session evidence: P122 ticket creation blocked on the first Write attempt; UUID extracted from `/tmp/architect-plan-reviewed-60331245-5d4e-461c-b95b-67b9a5b95c4b` and re-touched as `/tmp/manage-problem-grep-60331245-5d4e-461c-b95b-67b9a5b95c4b`; second Write succeeded. Same friction did NOT recur for P123 creation in the same session because the marker persisted once set.
