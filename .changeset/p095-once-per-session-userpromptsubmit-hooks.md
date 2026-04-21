---
"@windyroad/architect": minor
"@windyroad/jtbd": minor
"@windyroad/tdd": minor
"@windyroad/style-guide": minor
"@windyroad/voice-tone": minor
---

P095 — UserPromptSubmit hooks across all five windyroad plugins now emit the full MANDATORY instruction block only on the first prompt of a session; subsequent prompts emit a ≤150-byte terse reminder. Reclaims ~120KB / ~30k tokens per 30-turn session in a 3-active-hook project (~80% of the prior per-prompt hook preamble). Detection and enforcement semantics are unchanged — the `PreToolUse` edit gate remains the enforcement surface; only the reminder prose is gated.

**New:**
- Canonical helper `packages/shared/hooks/lib/session-marker.sh` with `has_announced` + `mark_announced` functions (empty-SESSION_ID fallback: no-op, never crashes).
- Five per-plugin byte-identical copies at `packages/<plugin>/hooks/lib/session-marker.sh` for `architect`, `jtbd`, `tdd`, `style-guide`, `voice-tone`. Distributed via `scripts/sync-session-marker.sh` with `--check` mode + `npm run check:session-marker` + CI step per ADR-017 / ADR-028.
- ADR-038 "Progressive disclosure + once-per-session budget for UserPromptSubmit governance prose" codifies the pattern, the marker-path convention (`/tmp/${SYSTEM}-announced-${SESSION_ID}`), the ≤150-byte per-prompt budget, the four-element terse-reminder shape (MANDATORY signal word + gate name + trigger artifact + delegation affordance), and the `tdd-inject.sh` dynamic-state carve-out.

**Changed:**
- `packages/architect/hooks/architect-detect.sh` — gates the full MANDATORY ARCHITECTURE CHECK block behind `has_announced "architect" "$SESSION_ID"`; subsequent prompts emit `MANDATORY architecture gate active (docs/decisions/ present). Delegate to wr-architect:agent before editing project files.` Absent-`docs/decisions/` branch unchanged.
- `packages/jtbd/hooks/jtbd-eval.sh` — same pattern for the JTBD CHECK; terse reminder cites `docs/jtbd/ present` and `wr-jtbd:agent`. Absent-`docs/jtbd/README.md` branch unchanged.
- `packages/tdd/hooks/tdd-inject.sh` — special case per ADR-038 carve-out: static prose (STATE RULES table, WORKFLOW, IMPORTANT) is gated; dynamic TDD state (IDLE/RED/GREEN/BLOCKED) and tracked test files list emit every prompt. No-test-script fallback branch unchanged.
- `packages/style-guide/hooks/style-guide-eval.sh` — same pattern; terse reminder cites `docs/STYLE-GUIDE.md present` and `wr-style-guide:agent`.
- `packages/voice-tone/hooks/voice-tone-eval.sh` — same pattern; terse reminder cites `docs/VOICE-AND-TONE.md present` and `wr-voice-tone:agent`.

**Tests (bats):**
- `packages/shared/test/session-marker.bats` — 9 unit tests for the helper.
- `packages/shared/test/sync-session-marker.bats` — 6 drift-check tests.
- `packages/architect/hooks/test/architect-detect-once-per-session.bats` — 8 behavioural tests.
- `packages/jtbd/hooks/test/jtbd-eval-once-per-session.bats` — 8 behavioural tests.
- `packages/tdd/hooks/test/tdd-inject-once-per-session.bats` — 8 behavioural tests, including the dynamic-state carve-out assertion.
- `packages/style-guide/hooks/test/style-guide-eval-once-per-session.bats` — 7 behavioural tests.
- `packages/voice-tone/hooks/test/voice-tone-eval-once-per-session.bats` — 7 behavioural tests.
- Full suite: 735/735 green.

Backward-compatible for consumers: first-prompt output is byte-identical to the pre-change behaviour; only the second+ prompts see the terse reminder. Downstream tooling that parses the MANDATORY block text (none known) would still see the full text on the first prompt.

Closes P095. Transitions the ticket from `.known-error.md` to `.verifying.md` per ADR-022.
