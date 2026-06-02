---
"@windyroad/architect": minor
"@windyroad/jtbd": minor
"@windyroad/itil": patch
---

P348: structurally gate `human-oversight: confirmed` writes against a session-scoped substance-confirm evidence marker; add `unconfirmed` as a fourth enum value for AFK-iter-deferred decisions/jobs.

Closes the P348 fix-strategy (user-ratified 2026-06-02). AFK iter subprocesses spawned via `claude -p` have no `AskUserQuestion` access (ADR-013 Rule 6 fail-safe-defer territory) yet were silently authoring ADRs through `/wr-architect:capture-adr` and `/wr-architect:create-adr` and writing `human-oversight: confirmed` without any user confirmation event — contradicting ADR-066's write-once-permanent-on-substance-confirm contract and JTBD-006's "audit trail — every action taken during AFK mode should be traceable" outcome. Sibling failure mode on the JTBD/persona surface contradicts ADR-068 + JTBD-201/202 auditability constraints. The bogus-ratification class P340 captured (ADR-078 born `confirmed` after a draft-quality review answer) was the SKILL-prose-tightening surface; P348 is the structural escalation.

Two prongs ship together:

1. **PreToolUse:Edit|Write structural gate.** `architect-oversight-marker-discipline.sh` and the sibling `jtbd-oversight-marker-discipline.sh` deny any Edit/Write that INTRODUCES `human-oversight: confirmed` into a `docs/decisions/*.md` or `docs/jtbd/**/*.md` frontmatter unless a session-scoped evidence marker `/tmp/oversight-confirmed-<sha256-of-path>-<session-id>` exists for THAT specific artefact under THIS session. Existing-marker Edit/Write paths (re-stamps, status transitions, file moves that preserve the line) are exempted — only INTRODUCING the marker is gated. AFK-fallback writes (`unconfirmed`, `rejected-pending-supersede`) are unconditionally allowed.

2. **`unconfirmed` enum value** on the same `human-oversight:` axis. AFK iter subprocesses MUST write `human-oversight: unconfirmed`, which the drains (`/wr-architect:review-decisions`, `/wr-jtbd:confirm-jobs-and-personas`) later promote interactively. The existing detectors (`detect-unoversighted.sh`) already treat anything-not-`confirmed`-and-not-`rejected-pending-supersede`-with-ticket as unoversighted, so `unconfirmed` flows naturally into the drain queue without a detector change. Naming it explicitly carries the iter's intent — this is NOT a missing marker (a pre-ADR-066 ADR), it is an EXPLICITLY-DEFERRED confirmation the iter knows the user needs to resolve.

Marker namespace `/tmp/oversight-confirmed-<sha>-<sid>` is SHARED between architect and JTBD hooks — data-schema convergence, not code coupling (mirrors the "shared cross-plugin contracts" section in ADR-068). Each plugin's helper script independently writes the same-shape marker file; each plugin's hook independently reads it. Multi-SID write per ADR-050 Option C — the helper enumerates every recent candidate SID and writes one marker per candidate, so concurrent orchestrator + subprocess sessions don't miss the match.

Shipped:

- `packages/architect/hooks/architect-oversight-marker-discipline.sh` + registration in `packages/architect/hooks/hooks.json` (new PreToolUse:Edit|Write entry, sibling of `architect-enforce-edit.sh`).
- `packages/jtbd/hooks/jtbd-oversight-marker-discipline.sh` + registration in `packages/jtbd/hooks/hooks.json` (same shape).
- `packages/architect/scripts/mark-oversight-confirmed.sh` + ADR-049 PATH shim `packages/architect/bin/wr-architect-mark-oversight-confirmed` (regenerated from the ADR-080 highest-version-wins template; `npm run check:shim-wrappers` confirms 42/42 in sync after regeneration).
- `packages/jtbd/scripts/mark-oversight-confirmed.sh` + ADR-049 PATH shim `packages/jtbd/bin/wr-jtbd-mark-oversight-confirmed`.
- 12 behavioural bats for the architect hook (`packages/architect/hooks/test/architect-oversight-marker-discipline.bats`) — positive marker-present-allow paths (Write + Edit), negative marker-absent-deny paths, AFK-`unconfirmed` allow, `rejected-pending-supersede` allow, scope/non-fire paths (non-ADR, README, no-marker-introduction, re-stamp), end-to-end `mark-oversight-confirmed.sh` → hook satisfaction.
- 10 behavioural bats sibling for the JTBD hook (`packages/jtbd/hooks/test/jtbd-oversight-marker-discipline.bats`).
- `docs/decisions/066-human-oversight-marker-and-review-decisions-drain.proposed.md` — Amendment 2026-06-02 codifying the structural guard + the `unconfirmed` enum value. Marker-write authority moves from SKILL-prose discipline to a PreToolUse hook backstop; `unconfirmed` is purely additive (no detector change required).
- `docs/decisions/068-jtbd-persona-human-oversight-marker-and-confirm-drain.proposed.md` — mirror Amendment 2026-06-02 on the JTBD/persona surface.
- `packages/architect/skills/create-adr/SKILL.md` Step 5a — gains explicit step calling `wr-architect-mark-oversight-confirmed <adr-path>` immediately after the substance-confirm `AskUserQuestion` answer lands; AFK fallback prose names `unconfirmed` as the iter-correct enum value.
- `packages/architect/skills/capture-adr/SKILL.md` — skeleton frontmatter now emits `human-oversight: unconfirmed` (capture is the AFK-friendly aside surface with no substance-confirm pass; `confirmed` at capture would be a hollow marker).
- `packages/jtbd/skills/update-guide/SKILL.md` — both persona and job born-confirmed write sites now call `wr-jtbd-mark-oversight-confirmed <artefact-path>` before the marker write; AFK fallback prose names `unconfirmed`.
- `packages/itil/skills/capture-rfc/SKILL.md` — skeleton frontmatter now emits `human-oversight: unconfirmed` (RFCs ratify at `/wr-itil:manage-rfc accepted`, not at capture).
- `packages/itil/skills/work-problems/SKILL.md` Step 2.4 gate (a) — adds an oversight-unconfirmed drain sub-surface alongside the outstanding-questions surface, running `wr-architect-detect-unoversighted` + `wr-jtbd-detect-unoversighted` and nudging the user toward the drain skills when the loop's iters have queued `unconfirmed` markers.

Architect verdict (2026-06-02): PASS. No new ADR required — the structural guard extends ADR-066's existing marker-write authority via amendment, and `unconfirmed` composes with the existing 3-value enum (`confirmed`, `rejected-pending-supersede`, absent) without migration. ADR-049 + ADR-080 shim grammar followed; ADR-002 plugin packaging respected (each plugin self-contained, byte-identical scripts copied per-plugin); ADR-050 multi-SID candidate enumeration applied; ADR-045 Pattern 1 silent-on-pass PreToolUse shape; ADR-052 behavioural-tests default. Two non-blocking advisories honoured (shims registered with sync-shim-wrappers; SKILL prose names `unconfirmed` as the AFK-derived default per the JTBD-101 clear-patterns constraint).

JTBD verdict (2026-06-02): PASS. Primary job served: JTBD-006 (Progress the Backlog While I'm Away — the change directly fixes a P348 defect in this job's core flow, restoring honest signalling so AFK iters can ship work without claiming oversight they didn't earn). Secondary: JTBD-201/202 (auditability persona constraints satisfied by structural enforcement), JTBD-101 (sibling-hook + per-plugin script + ADR-049 PATH-shim is exactly the plugin-self-contained pattern), JTBD-001 (structural PreToolUse deny is "reviewed against relevant policy before it lands" applied to oversight-confirmation writes). No persona conflicts.

Migration audit deferred: 63 ADRs + 17 JTBDs in this repo currently carry `human-oversight: confirmed`. Per the design spec, markers SET in this session are legitimate; markers from prior sessions WITHOUT findable substance-confirm audit trail should flip to `unconfirmed`. The audit + flip pass is captured as a follow-up — implementation iter scope was the structural prongs.
