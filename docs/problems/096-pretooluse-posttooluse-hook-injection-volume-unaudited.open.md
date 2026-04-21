# Problem 096: PreToolUse / PostToolUse hook injection volume across windyroad plugins — unaudited

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: L
**WSJF**: (12 × 1.0) / 4 = **3.0**

> Split from P091 meta (session-wide context budget) on 2026-04-22. This ticket owns the audit + remediation of the per-tool-call hook cluster. Severity estimated pending audit — may revise up or down once measurements land.

## Description

Windyroad plugins register a large inventory of `PreToolUse` and `PostToolUse` hooks that fire on every matching tool call. Many *may* emit prose into the conversation context in the same unconditional-verbose-prose pattern that P095 confirmed for the `UserPromptSubmit` surface. This ticket owns the audit and remediation for the per-tool-call hook cluster.

Hook inventory (from `packages/*/hooks/hooks.json`):

**PreToolUse Edit|Write matcher (8 hooks):**
- `wr-architect/hooks/architect-enforce-edit.sh`
- `wr-jtbd/hooks/jtbd-enforce-edit.sh`
- `wr-tdd/hooks/tdd-enforce-edit.sh`
- `wr-style-guide/hooks/style-guide-enforce-edit.sh`
- `wr-voice-tone/hooks/voice-tone-enforce-edit.sh`
- `wr-risk-scorer/hooks/secret-leak-gate.sh`
- `wr-risk-scorer/hooks/wip-risk-gate.sh`
- `wr-risk-scorer/hooks/risk-policy-enforce-edit.sh`

**PreToolUse Bash matcher (3 hooks):**
- `wr-risk-scorer/hooks/git-push-gate.sh`
- `wr-risk-scorer/hooks/risk-score-commit-gate.sh`

**PreToolUse ExitPlanMode matcher (2 hooks):**
- `wr-architect/hooks/architect-plan-enforce.sh`
- `wr-risk-scorer/hooks/risk-score-plan-enforce.sh`

**PreToolUse EnterPlanMode matcher (1 hook):**
- `wr-risk-scorer/hooks/plan-risk-guidance.sh`

**PostToolUse Agent matcher (5 mark-reviewed hooks):**
- `wr-architect/hooks/architect-mark-reviewed.sh`
- `wr-jtbd/hooks/jtbd-mark-reviewed.sh`
- `wr-style-guide/hooks/style-guide-mark-reviewed.sh`
- `wr-voice-tone/hooks/voice-tone-mark-reviewed.sh`
- `wr-risk-scorer/hooks/risk-score-mark.sh`

**PostToolUse Edit|Write matcher (3 hooks):**
- `wr-architect/hooks/architect-refresh-hash.sh`
- `wr-tdd/hooks/tdd-post-write.sh`
- `wr-risk-scorer/hooks/wip-risk-mark.sh`

**PostToolUse Bash matcher (1 hook):**
- `wr-risk-scorer/hooks/risk-hash-refresh.sh`

**PostToolUse Skill matcher (1 hook):**
- `wr-tdd/hooks/tdd-setup-marker.sh`

**Stop matcher (2 hooks):**
- `wr-tdd/hooks/tdd-reset.sh`
- `wr-retrospective/hooks/retrospective-reminder.sh`

A typical 30-turn session with ~60 tool calls fires these hooks hundreds of times. Even if each emits only a few hundred bytes on average, the per-session total is substantial.

## Symptoms

- Unknown until audited. Hypothesised symptoms mirror P095:
  - Each qualifying tool call prefixes its output with hook prose that the assistant then has to read.
  - Mid-session context growth from per-tool injection compounds with per-prompt injection (P095) and SKILL.md loads (P097).
- Directly observable if a representative session is replayed with a byte-counter attached to each hook's stdout.

## Workaround

None for end-users. Design-space mitigations (depend on audit findings):

1. **Terse-on-success** — most enforce-edit hooks are "gate pass" or "gate fail" decisions. On gate pass, emit nothing (or a single terse "gate passed" line). Only emit verbose instruction prose on gate fail. Many of these hooks may already do this — audit needed.
2. **Once-per-session gating** for any hook that emits standing instructional prose (unlikely on PreToolUse since the scope is per-call, but possible for advisory output).
3. **Once-per-file gating** for enforce-edit hooks that repeat the same message for repeated edits on the same file.
4. **PostToolUse `*-mark-reviewed.sh` silence audit** — these hooks write marker files; they should emit NOTHING into the conversation. Confirm.

## Impact Assessment

- **Who is affected**: Every user of the windyroad plugin set doing any tool-driven work (Edit, Write, Bash). Essentially every session.
- **Frequency**: Every matching tool call — much higher frequency than per-prompt hooks.
- **Severity**: Moderate-to-High cumulative. Lower per-firing prose than UserPromptSubmit (probably), higher firing frequency. Audit needed.
- **Analytics**: Measurement harness from P091 meta is reused for before/after on a representative session.

## Root Cause Analysis

### Preliminary hypothesis (needs audit)

Three hypotheses:

1. Some PreToolUse gates emit verbose instruction prose on every firing, not just on gate-fail.
2. PostToolUse `*-mark-reviewed.sh` hooks may emit status prose that is not useful to the assistant (the side effect is the marker file write; the stdout should be empty).
3. Some hooks that decide per-file (e.g. "this edit targets a governance doc, skip the gate") may emit the skip reason as prose rather than silently returning — each skip line adds up.

### Investigation tasks

- [ ] For each hook in the inventory, measure stdout byte count on a gate-pass case and a gate-fail case. Table the results.
- [ ] Identify hooks that emit instructional prose on gate-pass (candidates for "emit nothing on pass").
- [ ] Identify hooks that emit verbose reasoning on skip (candidates for "silent skip").
- [ ] Identify hooks that could benefit from once-per-file or once-per-session gating (using the shared marker helper from P095 Phase 1).
- [ ] Apply the audit findings to each hook. The shared `session-marker.sh` helper from P095 is reused here.
- [ ] Extend the reproduction-test bats suite to cover per-tool hook cases: assert that a gate-pass emits ≤ N bytes; assert that a repeat gate-pass on the same file after marker emits nothing; etc.

## Fix Strategy

TBD until audit lands. Skeleton:

- **Phase 1 (audit)**: measure and table. No code changes.
- **Phase 2 (per-hook edits)**: apply the audit recommendations. Reuse the `packages/shared/lib/session-marker.sh` helper from P095.
- **Phase 3 (ADR)**: the "Hook injection budget policy" ADR (tracked on P091) extends to cover PreToolUse/PostToolUse budget rules.

## Related

- **P091 (Session-wide context budget — meta)** — parent meta ticket.
- **P095 (UserPromptSubmit hook injection)** — sibling cluster; Known Error; provides the shared session-marker helper this ticket's Phase 2 reuses.
- **P097 (SKILL.md runtime size)** — sibling cluster.
- **P029 (Edit gate overhead disproportionate for governance documentation changes)** — adjacent; scope-exclusion logic is partially shared with the enforce-edit hooks this ticket audits.
- **ADR anchor**: "Hook injection budget policy" (tracked on P091).
