# Session Retrospective — 2026-06-17 post-ALL_DONE extension

Tight retro covering the post-`ALL_DONE` exchange that ran `/wr-architect:review-decisions` + drained ADR-082 + captured RFC-025 + captured P368.

## What happened

- `/wr-architect:review-decisions` drain found 1 unoversighted ADR (ADR-082, born-proposed in the earlier session).
- Surfaced ADR-082's substance via `AskUserQuestion` per the SKILL contract; user picked **(b) Real shipment control** with the follow-up question "are there libraries we can use that supports this? I don't want to create bespoke code".
- I proposed `.held-paths` manifest + prepack-strip; user rejected with the corrective question: *"how do we programmatically produce different versions of SKILL.md so we can toggle features AND test with the feature enabled and disabled?"*
- I revised to a markered-block + Mustache templating shape; user corrected again with the unfounded-constraint catch: *"You say 'doesn't preserve the ship the markdown file as-is contract Claude Code expects'. Why does claude code expect that? It should be agnostic on how the markdown file is produced?"* — they were right; Claude Code is agnostic about the file's provenance.
- Refined again toward Sphinx/MkDocs/Antora category; honestly assessed remark-directive ecosystem as a closer fit; user picked option 1 (open RFC + investigation as first slice).
- Captured **RFC-025** (Real shipment control via build-time feature toggles) tracing P359 + ADR-082.
- Attempted ADR-082 Decision Outcome amendment — blocked by `architect-oversight-marker-discipline` hook because `wr-architect-mark-oversight-confirmed` exited 0 silently (no candidate SID discoverable: `$CLAUDE_SESSION_ID` empty + no announce markers from this session in `/tmp`).
- Captured **P368** for the session-id discoverability gap (sibling-class to P260 / ADR-050 Option C).

## Reflections

**What I wish I'd been told up front**: Claude Code is agnostic about how SKILL.md is produced — it reads the file from the plugin cache path; the file can be hand-written, build-generated, copied, or anything else. The "ship the markdown as-is" mental model I had was an unfounded conflation between "we currently hand-write it" and "the framework requires hand-writing". This belongs in the briefing tree under plugin-distribution or a new build-output topic.

**What surprised me**: the `wr-architect-mark-oversight-confirmed` helper exits 0 silently when it cannot discover a session-id, leaving the calling skill no observable failure to act on. The downstream hook then denies with a directive that points back at the helper — a loop with no recovery affordance other than the documented external-terminal landing path. The Step 4 protocol assumes the marker write succeeds (or fails loudly); the actual silent-success-without-marker shape is a hidden third state.

**What was harder than it should have been**:
- Proposing mechanism designs (file-level strip vs templating vs feature-branches) without first asking "what's the required property?" — the user had to twice correct toward "test both states" before I got the framing right. Belongs in retro as a recurring class-of-behaviour: jumping to mechanism without enumerating the testability requirement.
- The capture-on-correction hook fires on `\bDON'T\b` for benign preference statements ("I don't want bespoke code"). Multiple false-positives in this exchange. Worth noting; not capturing as a new ticket — likely already covered by an existing hook-friction class.

**What failed**:
- The ADR-082 amendment write was denied; the session-id gap (now P368) blocked the in-session confirmation flow.

**What should we make easier or automate**:
- Captured as P368 — the helper should either accept SID via stdin/env from the calling skill, or fail loudly.

## Codification candidates

| Kind | Shape | Target | Substance | Decision |
|------|-------|--------|-----------|----------|
| improve | script | `packages/architect/scripts/mark-oversight-confirmed.sh` | accept SID via stdin/env OR fail loudly when no candidate SID discoverable | Captured as P368 (Fix Strategy: improve script — Option 3 free-text in ticket body) |
| (none) | briefing | `docs/briefing/plugin-distribution.md` or `docs/briefing/agent-interaction-patterns.md` | Claude Code is agnostic about how SKILL.md is produced — build artifacts are first-class | Deferred to next interactive briefing edit (signal worth recording; defer to maintain retro budget) |

## Pipeline Instability

| Signal | Category | Citation | Decision |
|--------|----------|----------|----------|
| `wr-architect-mark-oversight-confirmed` exits 0 silently when candidate-SID enumeration is empty; downstream hook denies subsequent Edit | Hook-protocol friction | 2026-06-17 ADR-082 amendment attempt; helper invocation produced no marker; Edit denied with "no substance-confirm evidence marker exists" | Ticketed as P368 |

README inventory currency: clean (13 packages, 0 drift).

## Context Usage (Cheap Layer)

| Bucket | Bytes | % of total |
|--------|------:|-----------:|
| problems | 5,129,607 | 56% |
| decisions | 1,957,154 | 21% |
| skills | 1,236,787 | 14% |
| hooks | 541,274 | 6% |
| memory | 439,805 | 5% |
| briefing | 115,135 | 1% |
| jtbd | 55,947 | <1% |
| project-claude-md | 5,897 | <1% |

No meaningful delta from the prior session-wrap retro measurement (same buckets within rounding).

## Ask Hygiene

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | ADR-082 pick | direction | Gap: ADR-074 substance-confirm-before-build — genuine ≥2-option decision (a/b/c) user must own |

**Lazy count: 0**
**Direction count: 1**

## Briefing Changes

Scanned the post-ALL_DONE exchange for briefing-worthy observations. Two candidates:

- **Add** to `docs/briefing/plugin-distribution.md` or similar: "Claude Code is agnostic about how SKILL.md is produced — it reads the file from the plugin cache path; the file can be hand-written, build-generated, copied, or anything else. The 'ship as-is' mental model is unfounded." Deferred to next interactive briefing edit (kept this retro tight; the observation is captured here for the next briefing pass to absorb).
- **Removed**: none.
- **Updated**: none.

(Scan evidence: re-screened "What You Need to Know" / "What Will Surprise You" against the two retro-eligible observations; the agnostic-file-production point is new; nothing was made stale by this exchange.)

## Tickets Captured

- **P368** — wr-architect-mark-oversight-confirmed session-id discoverability gap. Persona: plugin-developer; JTBD: JTBD-001, JTBD-006. Committed `73eeb014`.

## Tickets Deferred

(none)

## No Action Needed

- ADR-082 amendment substance is captured in the conversation transcript + RFC-025's body + this retro. The `human-oversight: confirmed` marker write awaits external-terminal landing OR a fresh session's announce markers per the documented workaround.
- RFC-025 captured cleanly (`5b076cbe`). Slice 1 (investigation) is the next-highest WSJF actionable item for the next session.
