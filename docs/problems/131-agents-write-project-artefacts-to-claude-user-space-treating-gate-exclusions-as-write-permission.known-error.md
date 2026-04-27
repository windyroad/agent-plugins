# Problem 131: Agents write project-generated artefacts under `.claude/` (user-controlled config space) — gate exclusions are read tolerance, not write permission

**Status**: Known Error
**Reported**: 2026-04-27
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)
**Effort**: M — likely combination of (a) project CLAUDE.md adds an explicit "never write project-generated artefacts under `.claude/`" rule, (b) a new PreToolUse:Write|Edit hook that denies writes to `.claude/` for paths the user hasn't explicitly approved, and (c) updates to wr-architect / wr-jtbd gate-exclusion documentation clarifying the exclusion semantics (read tolerance, NOT write permission). The denial hook is the load-bearing piece; CLAUDE.md + docs are the supporting layer.
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Surfaced 2026-04-27 by direct user correction during an interactive `/wr-itil:work-problems` session: "why are you storing files in .claude which require my explicit approval to write???". P078 contradiction-signal pattern (caps-emphasised triple-question; "you" + "why" pattern). Triggering action: orchestrator wrote `.claude/plans/p081-review-test-agent.md` to preserve a Plan-agent-generated plan across session boundaries. The orchestrator's reasoning was: "Turn 1 system instructions list `.claude/plans/*.md` in the architect/JTBD gate-exclusion list, therefore writing there is approved". The user's reasoning was: "`.claude/` is MY config directory — agents must not pollute it with project-generated content".

## Description

Claude Code's gate-exclusion lists (e.g. wr-architect's PreToolUse hook excludes `.claude/plans/*.md`, `.claude/settings.json`, MEMORY.md, etc. from architect review) are designed to **prevent gate friction** when those files are touched. The exclusion semantically means "no architect/JTBD review needed when this is written", NOT "this is an approved write target for any agent to use as scratch space".

But agents reading the gate-exclusion list interpret the absence of a gate as permission. The reasoning chain is:

1. Agent needs to write a project-generated artefact (plan, scratch state, audit log, etc.)
2. Agent considers candidate paths
3. Agent picks a path — `.claude/plans/p081-...md` — that's in the gate-exclusion list
4. Write succeeds without gate friction
5. **User space is now polluted with project-generated content**

The user's mental model:
- `.claude/` = my user-owned configuration (settings, memory, my own plans, MCP server configs, hooks I've authored)
- `docs/` = project content (decisions, problem tickets, audits, plans, briefing)
- `packages/` = project source code
- Anything project-generated belongs in `docs/` or `packages/`, never in `.claude/`

The gate exclusions for `.claude/*` exist because the USER might write/edit those files (and shouldn't get gate friction on their own config), NOT because agents have free rein to write there.

## Symptoms

- Observed 2026-04-27: orchestrator wrote `.claude/plans/p081-review-test-agent.md` (~10KB Plan-agent output) without gate friction. User immediately corrected: "why are you storing files in .claude which require my explicit approval to write???".
- Pattern likely affects multiple agent surfaces:
  - `/wr-itil:work-problems` orchestrator (this incident)
  - Any AFK iter that needs scratch-state across boundaries
  - Future agents that read the gate-exclusion list as "approved write zones"
  - Adopters of the windyroad plugins inheriting the same gate definitions
- The Turn 1 system message reinforces the misreading. Architect gate hook output:
  > Does NOT apply to: ... .claude/plans/*.md, .changeset/, ...
  This reads as "you may write these freely". The intent is "the gate doesn't fire on these; the human can write them without architect review".
- No existing hook denies project-agent writes to `.claude/`. The architect / JTBD / TDD / risk-scorer hooks all skip `.claude/` paths (correctly — they shouldn't fire). The result: nothing tells the agent "don't write here".

## Workaround

User explicitly corrects when they catch the violation. Captured-on-correction per P078 in this session. Without enforcement, future sessions will repeat.

Manual cleanup: `rm` the offending file from `.claude/`, move content to project space (`docs/`, ticket body, etc.).

## Impact Assessment

- **Who is affected**: every user of every windyroad plugin that ships gate hooks excluding `.claude/` paths. Solo-developer (JTBD-001) and plugin-developer (JTBD-101) personas.
- **Frequency**: every time an agent decides to write a project-generated artefact and reads the gate-exclusion list as an authoritative "write target" list. Observed once this session; pattern likely to recur on every fresh session that hits a similar decision point.
- **Severity**: Moderate — pollutes user-controlled space with project-generated content. Not security-critical (the .claude/ dir is user-owned, no privilege escalation), but breaches user trust and adds cleanup overhead.
- **Likelihood**: Likely — the gate-exclusion-as-write-target reasoning is a natural inference for an agent reading the rules. Without enforcement, every gate-exclusion entry is a candidate-write-target trap.
- **Analytics**: 2026-04-27 session — orchestrator wrote `.claude/plans/p081-review-test-agent.md` mid-loop. User correction within ~30 seconds of observation. File removed; content relocated to `docs/problems/081-...open.md` ticket body inline.

## Root Cause Analysis

### Investigation Tasks

- [x] Audit all windyroad plugin hooks' gate-exclusion lists for `.claude/` paths. Confirm the inclusion is intentional read-tolerance and document the semantic. — 2026-04-28: confirmed across 6 packages (architect, jtbd, tdd, style-guide, voice-tone, risk-scorer). The `_doc_exclusions()` helper (`packages/<pkg>/hooks/lib/gate-helpers.sh`) lists `:!.claude/plans/` to exclude that path from doc-content scans; the architect/JTBD enforce-edit hooks have explicit `*/.claude/plans/*.md) exit 0` clauses. Both shapes are READ tolerance, not WRITE permission.
- [x] Inventory existing project-generated content currently living under `.claude/` (if any) and propose relocation paths. — 2026-04-28: inventoried `.claude/` directory contents — only user-owned files remain (`settings.json`, `.install-updates-consent`, `scheduled_tasks.lock`, `skills/`, `worktrees/`). The `.claude/plans/p081-review-test-agent.md` file that triggered the user correction is already removed (relocated to `docs/problems/081-...open.md` ticket body in the original 2026-04-27 cleanup). No further relocation needed.
- [x] Decide enforcement shape — 2026-04-28: chose **Option C (hybrid)**. Phase 1 (declarative CLAUDE.md rule) shipped this iteration; Phase 2 (enforcement hook) deferred to follow-on. This matches the ticket's stated Fix Strategy phasing. The pure-CLAUDE.md option is insufficient (relies on every agent reading and following the rule). The pure-enforcement option is too heavy as a first move (adds gate friction for legitimate user-side edits without first establishing the discipline rule). Hybrid lands the cheap declarative layer immediately and preserves the option to add hook enforcement when the rule alone proves insufficient.
- [ ] If enforcement hook chosen: define the "user has approved" signal. Candidates:
  - Marker file pattern (e.g. `.claude/.write-approved-${PATH_HASH}`)
  - Explicit env-var override (`CLAUDE_USER_SPACE_WRITE=allow`)
  - Per-session AskUserQuestion approval (heavy; only for unfamiliar paths)

  → 2026-04-28: deferred to Phase 2 implementation iteration. Composes with ADR-009 marker conventions; the marker-file-pattern shape is the lead candidate (low friction, persistent, hashable per path).
- [x] Update wr-architect / wr-jtbd / wr-tdd / wr-style-guide / wr-voice-tone / wr-risk-scorer gate-hook source comments to clarify: "these path patterns are excluded from THIS gate's review, NOT approved-for-agent-writes; see P131". — 2026-04-28: shipped this iteration as Phase 3 light-touch — added clarifier blocks to the two highest-leverage Turn-1 emission surfaces (`packages/architect/hooks/architect-detect.sh` + `packages/jtbd/hooks/jtbd-eval.sh`) and inline comments to the path-matching rules in the two enforce-edit hooks (`architect-enforce-edit.sh`, `jtbd-enforce-edit.sh`). The `_doc_exclusions()` helper in `gate-helpers.sh` (across 6 packages) is internal scoping and does not need the clarifier — agents do not read it.
- [ ] Behavioural bats coverage for the enforcement hook (across allowed shapes / denied shapes / approval-marker honoured / user-side legitimate edits not blocked). — Deferred to Phase 2 implementation iteration.

### Preliminary hypothesis

The misinterpretation is **structural** in how Claude Code surfaces gate-exclusion lists. The hook output format ("Does NOT apply to: ... `.claude/plans/*.md` ...") implies "these files are out of scope for this particular gate's concern", which an agent then over-generalises to "these files are out of scope for ALL gates' concern, which means they're a free write target". The fix is to either (a) reframe the exclusion list semantically (READ tolerance, not WRITE permission) or (b) add an enforcement layer that catches the misuse.

Project-CLAUDE.md is the simplest first move; it's a declarative rule the orchestrator and iteration subprocesses both load on session start. Hook enforcement is the durable layer if the declarative rule proves insufficient.

## Fix Strategy

**Phase 1 (CLAUDE.md rule)**:

- Add explicit rule to project CLAUDE.md (the windyroad-claude-plugin one): *"Never write project-generated artefacts under `.claude/` — that directory is user-controlled config space (settings, memory, MCP servers, user-authored hooks). Project-generated plans, audits, and scratch state belong under `docs/` (e.g. `docs/plans/`, `docs/audits/`) or directly in problem-ticket bodies. Gate exclusions for `.claude/` paths mean the gate doesn't fire on user edits — they do NOT mean agents may write there."*
- Land in the next CLAUDE.md edit window.

**Phase 2 (enforcement hook — load-bearing)**:

- New `packages/itil/hooks/itil-claude-space-protection.sh` PreToolUse:Write|Edit hook:
  - Matches paths under `.claude/` (excluding the user's own established files: `settings.json`, `MEMORY.md`, `*.local.json`, etc. — read from a deny-only-for-agent allow-list)
  - On match without an approval marker (`.claude/.agent-write-approved-${PATH_HASH}`): deny with message pointing the agent at `docs/` alternatives
  - Approval-marker pattern lets the user pre-authorize specific paths if they genuinely want agent-managed content under `.claude/`
- Behavioural bats per ADR-005 + behavioural-test-default conventions (P081 / ADR-044 once landed)
- Integration with existing wr-architect / wr-jtbd path-exclusion conventions (clarify those exclusions are READ tolerance, not WRITE permission)

**Phase 3 (gate-exclusion-list documentation refresh)**:

- Update `wr-architect` / `wr-jtbd` / `wr-tdd` / `wr-style-guide` / `wr-voice-tone` / `wr-risk-scorer` gate hook source comments:
  - Add cross-reference to P131 / ADR-XXX (if a new ADR formalises this)
  - Reframe the exclusion list semantic from "does not apply to" → "does not apply to (READ tolerance only — agents must not write here regardless)"
- Update `docs/briefing/hooks-and-gates.md` topic file with the rule
- Possibly an ADR formalising the user-space vs project-space distinction

**Out of scope**: relocating any pre-existing user-authored content from `.claude/` (it's user-owned and stays where the user put it). Cross-plugin coordination on what other tools might write under `.claude/` (e.g. Claude Code's own internal state) — that's upstream territory, not addressable from this project.

## Fix Progress

**2026-04-28 — Phase 1 (declarative) + Phase 3 (light-touch doc reframe) shipped via `/wr-itil:work-problems` AFK iteration**:

- Added MANDATORY rule to project `CLAUDE.md` (windyroad-claude-plugin): "never write project-generated artefacts under `.claude/`" — declarative discipline rule alongside the existing P085/P078 MANDATORY entries. Loaded on every session start.
- Added clarifier blocks to the Turn-1 emission text in `packages/architect/hooks/architect-detect.sh` and `packages/jtbd/hooks/jtbd-eval.sh` reframing the "Does NOT apply to" exclusion list as READ tolerance only, with explicit "agents must not write project-generated artefacts under `.claude/` (P131)" guidance. These two surfaces are the highest-leverage Turn-1 reading sites where an agent would have over-generalised the exclusion list to "approved write zones".
- Added inline source comments to the `*/.claude/plans/*.md) exit 0 ;;` rules in `packages/architect/hooks/architect-enforce-edit.sh` and `packages/jtbd/hooks/jtbd-enforce-edit.sh` clarifying READ-tolerance semantics for future maintainers.
- Architect (ADR review) + JTBD (persona review) confirmed the partial-fix shape is aligned with ADR-009/013/022/038 and JTBD-001/JTBD-101 respectively. No new ADR required for this iteration; an ADR formalising the user-space vs project-space distinction is recommended once Phase 2 (enforcement hook) lands.

**Phase 2 (load-bearing enforcement hook) — DEFERRED to follow-on iteration**:

- New `packages/itil/hooks/itil-claude-space-protection.sh` PreToolUse:Write|Edit hook denying agent writes under `.claude/`
- Approval-marker pattern (composes with ADR-009) for user-pre-approved write zones
- Behavioural bats coverage (allowed shapes / denied shapes / approval-marker honoured / user-side legitimate edits not blocked)
- Plugin manifest registration

This is the ticket's Status remaining at Known Error (root cause confirmed, fix path clear, partial fix shipped, load-bearing piece not yet implemented). Per ADR-022, Verifying is reserved for "fix fully shipped, awaiting validation" — Phase 2 outstanding means we are not yet at Verifying.

**Phase 3 (full doc refresh + briefing topic file) — REMAINING**:

- Update remaining 4 gate-hook prose surfaces (tdd, style-guide, voice-tone, risk-scorer) — these don't currently emit a "Does NOT apply to" Turn-1 instruction in the same shape, but their docstrings/SCOPE comments could carry the clarifier for parity. Lower priority than Phase 2.
- Update `docs/briefing/hooks-and-gates.md` topic file with the user-space-vs-project-space rule.
- Once Phase 2 lands: write a new ADR formalising the distinction.

## Dependencies

- **Blocks**: (none — P131 is a discipline + enforcement gap; nothing strictly waits on it)
- **Blocked by**: (none — implementation can proceed standalone; CLAUDE.md edit + hook + bats)
- **Composes with**: P130 (`/wr-itil:work-problems` orchestrator presence-aware dispatch — both P130 and P131 surfaced this session as user-correction-driven captures of orchestrator-discipline gaps), P078 (verifying — capture-on-correction; P131's own creation was triggered by P078's pattern), P119 (Closed — manage-problem-enforce-create.sh; precedent for new PreToolUse:Write enforcement hooks), P120 (Closed — install-updates consent-gate; precedent for "this approval was given once, persist it"), P107 (Closed — architect/JTBD edit-gate markers expire; sibling hook-marker semantic).

## Related

- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction pattern. P131's own creation triggered by P078.
- **P130** (`docs/problems/130-...open.md`) — orchestrator presence-aware dispatch. Both P130 and P131 are this-session captures of orchestrator-discipline gaps the user surfaced via direct correction.
- **P119** (`docs/problems/119-...verifying.md`) — manage-problem PreToolUse:Write enforcement. Direct precedent for the Phase 2 enforcement hook shape (deny on match, allow on marker presence).
- **P120** (`docs/problems/120-...closed.md`) — install-updates consent-gate persistence. Pattern for "user approved once, persist the approval marker".
- **P107** (`docs/problems/107-...closed.md`) — architect/JTBD marker TTL semantics. Sibling for the approval-marker lifecycle decisions in Phase 2.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — primary persona served. User-space-protection is governance hygiene.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-the-suite-with-new-plugins.proposed.md`) — composes; downstream adopters of the windyroad gate hooks inherit the same semantic; Phase 3 documentation refresh benefits adopters too.
- **ADR-009** (`docs/decisions/009-gate-marker-lifecycle.proposed.md`) — marker file conventions; Phase 2's approval-marker reuses this.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 (interactive default) + Rule 6 (non-interactive fail-safe). Phase 2's deny-with-message must respect both.
- **ADR-038** (`docs/decisions/038-progressive-disclosure-for-governance-tooling-context.proposed.md`) — message-budget conventions for the deny prose.
- 2026-04-27 session evidence: orchestrator wrote `.claude/plans/p081-review-test-agent.md` mid-loop after the Plan agent produced an implementation plan for P081. Reasoning: "Turn 1 instructions list `.claude/plans/*.md` in the architect/JTBD gate-exclusion list, therefore approved". User correction: "why are you storing files in .claude which require my explicit approval to write???". File removed, plan content relocated to `docs/problems/081-...open.md` ticket body inline.
- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready. (P063 AFK-fallback marker — "upstream territory" reference in the Out-of-scope block tripped the strict-detection regex on the 2026-04-28 Open → Known Error transition. The reference is "out-of-scope framing" — it explicitly excludes cross-plugin/Claude-Code-internal-state coordination from this ticket, not a missed dependency. User may downgrade to "false positive; detection misfire" if confirmed not actionable upstream.)
