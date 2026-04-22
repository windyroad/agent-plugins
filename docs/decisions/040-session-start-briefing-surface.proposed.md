---
status: "proposed"
date: 2026-04-22
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent, claude-code-guide]
informed: [Windy Road plugin users, windyroad-claude-plugin adopters]
reassessment-date: 2026-07-22
---

# Session-start briefing surface — SessionStart hook over tiered directory + indexed README

## Context and Problem Statement

`@windyroad/retrospective` is the canonical surface for capturing cross-session learnings. Until slice 1 of P100 landed (2026-04-22), those learnings accumulated in a single `docs/BRIEFING.md` file that was only read when the user invoked `/wr-retrospective:run-retro` at session end — never at session start. Adopter projects thus had write-only learnings: `run-retro` appended, future sessions never read. The producer wrote; the consumer never discovered.

**P100** captures the gap. Six other windyroad plugins already emit `UserPromptSubmit`-surfaced artefact announcements per **ADR-038** (architect / jtbd / tdd / style-guide / voice-tone); `wr-retrospective` lacked a consumer-side surface. The same "produce without affordance to consume" pattern, inverted.

User direction during P100's 2026-04-22 design session:

- *"we shouldn't have to add these things to CLAUDE.md. It should be automatic"* — the surface must live on the producer plugin, not on downstream CLAUDE.md.
- *"a short header + pointer to docs/BRIEFING.md is NOT progressive disclosure as that would be all or nothing"* — tier the disclosure: per-topic files under a directory, an indexed README, a critical-points roll-up, full files on demand.
- *"basically we want to ask 'what was signal and what was noise' and then adjust accordingly"* — curation signal drives what surfaces at session start (deferred to **P105**).

**Slice 1** (commit 5d367e9, 2026-04-22) migrated `docs/BRIEFING.md` into `docs/briefing/<topic>.md` per-topic files with `docs/briefing/README.md` as a tiered index: Critical Points roll-up + per-topic index + per-topic files. `run-retro` was rewritten writer-side to append into the tree. Architect + JTBD hooks gained `docs/briefing/*` path exemptions.

**Slice 2** (this ADR's scope) ships the **consumer side**: a `SessionStart` hook in `@windyroad/retrospective` that extracts the `## Critical Points (Session-Start Surface)` section from `docs/briefing/README.md` and injects it once per session, at `startup`. Future sessions see the highest-value cross-session learnings without needing to know the file exists.

## Decision Drivers

- **P100** — cross-session learnings must reach the agent at session start in every adopter project without hand-authored CLAUDE.md pointers.
- **ADR-038** (Progressive disclosure + once-per-session budget for `UserPromptSubmit` governance prose) — the architectural pattern this ADR applies to a new surface (cross-cutting artefact announcement at session boot, not a per-prompt governance gate).
- **P104** (`partial-progress` paints release queue into corner) — motivated the slice-1 / slice-2 split. Slice 2's hook + ADR pair with slice 1's migration so adopters receive both or neither.
- **JTBD-001** (Enforce Governance Without Slowing Down) — session-start surfacing of critical rules reduces wasted turns.
- **JTBD-006** (Progress the Backlog While I'm Away) — cross-session learnings are highest-value in AFK loops.
- **Claude Code schema** (confirmed via claude-code-guide agent 2026-04-22, source: [hooks.md](https://code.claude.com/docs/en/hooks.md)): `SessionStart` hook exists; matcher is string `"startup"` on the outer entry; only `type: "command"` supported; fires exactly once per session on `startup`.

## Considered Options

### Option A — `SessionStart` hook with matcher `"startup"` (chosen)

A new hook script (`packages/retrospective/hooks/session-start-briefing.sh`) runs once per session at startup. Extracts `## Critical Points (Session-Start Surface)` from `docs/briefing/README.md` and emits it as prose on stdout. Silent exit if file or section missing.

### Option B — `UserPromptSubmit` hook with once-per-session marker (ADR-038 pattern)

Mirror architect / jtbd / tdd: fire on every prompt, suppress after first via `session-marker.sh`. Rejected: `SessionStart` is the semantically correct event — the briefing surface is a boot-time artefact, not a prompt-time governance gate. Using `UserPromptSubmit` with suppression is redundant when `SessionStart` provides the right lifecycle natively.

### Option C — CLAUDE.md pointer rewritten by `install-updates`

Auto-write a pointer into adopter project CLAUDE.md. Rejected: user direction explicitly against this pattern (*"we shouldn't have to add these things to CLAUDE.md"*).

### Option D — `SessionStart` hook emitting full briefing tree

No tiering. Blows the context budget on every startup. Rejected per P091 / ADR-038.

## Decision Outcome

**Chosen: Option A** — `SessionStart` hook with matcher `"startup"` + tiered disclosure.

### What is reused from ADR-038

- Progressive disclosure as the unifying design pattern — less upfront, explicit affordances for deeper retrieval.
- Tiered loading model — a curated top surface (roll-up) + index + deep files.
- Once-per-session emission discipline — do not re-inject on every prompt.

### What is net-new in this ADR

- **Hook lifecycle**: `SessionStart` (boot, matcher `"startup"`), not `UserPromptSubmit` (every prompt with a marker).
- **Purpose**: artefact announcement (read-side discovery), not governance-gate enforcement.
- **No `session-marker.sh`**: `SessionStart` with matcher `"startup"` fires once by design; no marker needed.
- **No paired enforcement hook**: this surface is announcement-only. Unlike architect / jtbd / tdd, there is no matching `PreToolUse` edit gate enforcing anything about the briefing content.
- **Directory-based source**: the consumer reads a tiered directory (`docs/briefing/`) rather than a single file. Tier boundaries live in content, not in hook scripts.

### Mechanism

1. New hook script `packages/retrospective/hooks/session-start-briefing.sh`:
   - Locates `docs/briefing/README.md` from `${CLAUDE_PROJECT_DIR:-.}`.
   - Extracts the `## Critical Points (Session-Start Surface)` section via awk.
   - Emits as prose on stdout prefixed with a one-line header naming the source.
   - Silent exit if file or section missing (no-op for adopters without retro).
2. `packages/retrospective/hooks/hooks.json` gains a second `SessionStart` entry with `"matcher": "startup"` targeting the new script. The existing `check-deps.sh` entry remains matcher-less (fires on startup / resume / clear / compact — dep check is always worth running).
3. `docs/BRIEFING.md` stub (slice-1 migration redirect) is deleted. Legacy path retires per user direction 2026-04-22 (*"delete it entirely"*).
4. `@windyroad/retrospective` bumps 0.6.0 → 0.7.0 (minor). Writer-side migration from slice 1 + consumer-side hook from slice 2 ship together.

### Tier budget (SessionStart output)

- **Tier 1 (boot injection)**: `## Critical Points (Session-Start Surface)` roll-up. **Budget: ≤ 2 KB / ≤ 500 tokens.** At the time of writing, the roll-up is 8 bullets × ~180 bytes ≈ 1.5 KB. Enforcement via retro convention — the signal-vs-noise pass (**P105**) gates growth beyond 10 bullets.
- **Tier 2 (on demand)**: `docs/briefing/README.md` — topic index + how-to-use. ~3 KB. Agent retrieves when context requires topic navigation.
- **Tier 3 (on demand)**: per-topic files under `docs/briefing/` — 2–5 KB each. Agent retrieves when a specific topic is relevant.

The SessionStart hook emits only Tier 1. Breaching the Tier 1 budget is the reassessment trigger for this ADR.

### Consequences

- **Good**: cross-session learnings reach the agent in every adopter project at session start without hand-authored CLAUDE.md pointers. `P100` verification condition is met.
- **Good**: adopters absorb the migration once (via `@windyroad/retrospective` minor bump); future retros extend the tree.
- **Good**: each tier is independently testable. Extracting the Critical Points section is a line-range grep; the hook's contract is "if README exists, emit the section; else no-op".
- **Good**: the pattern ports to other cross-session artefact plugins (e.g., risk-register seeding per **P102**, if that path chooses SessionStart).
- **Bad**: Critical Points roll-up curation is currently author-judgment. **P105** (signal-vs-noise pass) closes this gap but does not block this ADR.
- **Bad**: SessionStart hook output adds ~1.5 KB to session start overhead. Bounded by the Tier 1 budget above.

## Confirmation

- `docs/briefing/` tree exists and `docs/briefing/README.md` has a `## Critical Points (Session-Start Surface)` section (slice 1, commit 5d367e9).
- `packages/retrospective/hooks/session-start-briefing.sh` exists, extracts the Critical Points section cleanly, emits on stdout.
- `packages/retrospective/hooks/hooks.json` contains a `SessionStart` entry with `"matcher": "startup"` targeting the new script.
- `docs/BRIEFING.md` is deleted.
- `@windyroad/retrospective@0.7.0` published to npm. Adopter projects installing the new version and starting a Claude Code session see the Critical Points prose injected once at startup.
- **Reassessment trigger**: Tier 1 output exceeds 2 KB / 500 tokens. Revisit tiering rules, promote P105 curation work, or add a size-cap check to the hook script.
- **Reassessment date**: 2026-07-22.

## More Information

- **P100** — this ADR's driver; `docs/problems/100-*.verifying.md` after this slice ships.
- **ADR-038** — sibling pattern ADR (UserPromptSubmit governance prose).
- **P091** — session-wide context-budget meta. This ADR is one concrete application of the progressive-disclosure pattern P091 anchors.
- **P104** — partial-progress release-queue hazard. Slice 1 + slice 2 shipping together via this ADR is the structured response.
- **P105** — signal-vs-noise curation loop. Closes the "roll-up drifts stale over time" Bad consequence above.
- **ADR-023** (wr-architect performance review scope) — this ADR's Tier 1 budget is the runtime-path performance envelope for SessionStart-hook output in this plugin.
- **`docs/changesets-holding/README.md`** — provisional holding-area convention used to stage slice 1's retrospective-minor changeset while slice 2 was pending. P103 / P104 resolution may promote to its own ADR (candidate ADR-039).
