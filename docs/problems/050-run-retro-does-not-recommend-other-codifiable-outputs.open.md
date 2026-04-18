# Problem 050: run-retro does not recommend new agents, hooks, or other codifiable outputs (generalises P044)

**Status**: Open
**Reported**: 2026-04-19
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: 4.0 — (8 × 1.0) / 2

## Description

P044 (`run-retro does not recommend new skills when it should`) added a "Skill Candidate" reflection category and a Step 4b branch that routes skill-worthy patterns through `AskUserQuestion` with create / track / skip options. It solved one specific codification gap.

The same gap exists for every other **codifiable output** the Windy Road plugin suite supports. The retrospective skill still has no branch for recommending:

- **New sub-agents** — patterns where the main agent would delegate a bounded investigation or review to a sub-agent (e.g. a performance-specialist that the architect calls in for runtime-path changes; see P046). Packages with `agents/` directories: risk-scorer, jtbd, voice-tone, architect. The pattern exists; `run-retro` doesn't surface it.
- **New hooks** — pre-tool-use / post-tool-use / user-prompt-submit hook scripts. A recurring friction pattern observed in a session (e.g. "I keep forgetting to X before Y") is often better solved by a hook than by more memory. Packages with `hooks/` directories: risk-scorer, jtbd, itil, retrospective, voice-tone, architect, connect, tdd, style-guide — i.e. most of them. Again, `run-retro` never prompts "this looks hook-shaped".
- **Settings.json entries** — allowlisted commands, env vars, hook wiring. These are a close cousin to hooks; when a session repeatedly hits permission prompts for the same tool, the fix is a settings allowlist entry.
- **Shell scripts / Node scripts** (`scripts/*.sh`, `scripts/*.mjs`) — reusable repo-level tooling (examples in this repo: `sync-install-utils.sh`, `sync-plugin-manifests.mjs`, `release-watch.sh`). A retrospective might observe a multi-step shell sequence worth scripting.
- **CI workflow steps** (`.github/workflows/*.yml`) — a session retro might surface "we'd have caught that earlier with a CI step", e.g. the ADR-021 fix that added `npm run check:plugin-manifests` to `ci.yml`. run-retro doesn't prompt for this class of codification.
- **Bats test fixtures** — if a recurring failure pattern is observed, it's often worth a regression test. Currently run-retro routes this implicitly through problem tickets but doesn't name it as a first-class output.
- **Memory templates** — cross-session memory is already a codification target (`~/.claude/...memory/*.md`), but it's implicit and per-user. A project-level memory template might become relevant once JTBD or other project files need cross-session persistence.

Existing dedicated codification skills already exist for some outputs and run-retro should **route through them rather than duplicate intake**:

- **ADRs** → `/wr-architect:create-adr`
- **JTBD records** → `/wr-jtbd:update-guide`
- **Voice / Style / Risk policy** → `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-risk-scorer:update-policy`
- **Problem tickets** → `/wr-itil:manage-problem` (already wired via Step 4)

The unifying observation: **run-retro's output universe is not closed**. Every codifiable artifact the suite supports should be a potential recommendation target, either directly (record a stub) or by routing to the dedicated skill.

User phrasing (2026-04-19): "it doesn't recommend new agents and hooks either or anything else that I've forgotten to explicitly list" — the spec is deliberately open. This ticket generalises P044 rather than enumerating once more.

## Symptoms

- Sessions where the same multi-step pattern would benefit from a hook, sub-agent, settings entry, or script are closed with BRIEFING.md notes or problem tickets — the codification opportunity is not named.
- Step 2 of run-retro asks "what should we make easier or automate?" — but automation has more than one shape, and the skill picks exactly one (problem ticket) regardless of which shape fits.
- The P044 fix introduced exactly one additional shape (skill candidate). Today's Step 2 has no slot for the other six-plus shapes listed above.
- Maintainers who know the suite's codification surface (agents, hooks, scripts, etc.) mentally translate "this should be a hook" / "this is sub-agent-shaped" during retro but the prompt never asks.
- New contributors to the suite don't know the full range of outputs and default to filing problem tickets for everything.

## Workaround

- Operator vigilance: after running `/wr-retrospective:run-retro`, the user (or assistant) reviews the output list and manually proposes additional codifications — a second pass.
- Memory hints: user carries per-project memory of "this was probably hook-shaped" observations.

Both repeat per session; neither scales.

## Impact Assessment

- **Who is affected**: solo-developer persona (JTBD-001, JTBD-006) — misses codification opportunities that would pay back across sessions; plugin-developer persona (JTBD-101) — inconsistent signal about which outputs the suite should grow.
- **Frequency**: every retrospective session that surfaces a recurring pattern whose best shape isn't a skill. Given the suite has 3+ component types per plugin (agents/hooks/skills) and 9+ dedicated codification surfaces in total, "skill" is one option out of many.
- **Severity**: Minor per occurrence (a missed codification is not user-visible breakage), but Likely per session. Cumulative effect: the suite grows slower than it could, and it grows lopsided toward whatever P044's one-output-type happened to capture.
- **Analytics**: this session (2026-04-19) produced candidates of several non-skill shapes — a performance-specialist sub-agent (P046 Candidate 3), a possible new hook for exercise-annotation (P048), and a CI step (already shipped as part of P042/ADR-021). Each could have been surfaced by run-retro if the branch existed.

## Root Cause Analysis

### Structural: Step 2 enumerates one codification type

After P044, Step 2 of `packages/retrospective/skills/run-retro/SKILL.md` reads (roughly): "What recurring workflow did I (or the assistant) perform that would be better as a skill?" — with criteria (multi-invocation, deterministic sequence, cross-project reuse).

Those criteria are good. What's missing is the **shape question**: given that criteria are met, which codification shape fits best? A deterministic sequence might be a skill, a shell script, a hook, or a sub-agent depending on the invocation model. The retro skill has no branch that asks.

### Structural: Step 4b is one-output-type wide

Step 4b post-P044 presents three options (create skill / track as problem / skip). Good pattern, but the type is fixed to "skill" before the user sees the options. A generalised Step 4b would ask the type first, then route.

### Candidate fixes

1. **Generalise Step 2's reflection category** to "What recurring pattern did I (or the assistant) observe that would be better codified?" with a secondary prompt to identify the best shape (skill / agent / hook / settings / script / CI step / ADR / JTBD / guide / problem / test fixture). Examples per shape help contributors pick.

2. **Generalise Step 4b** to "Recommend new codified outputs". The `AskUserQuestion` gains an additional question (or a two-step flow): first pick the codification shape, then the action. Option surface per shape:
   - **Skill** → create candidate record (existing P044 behaviour)
   - **Agent** → create stub agent record with suggested name, scope, trigger (e.g. "when architect reviews runtime-path changes, delegate to this"). Scaffolding out of scope, same as P044.
   - **Hook** → create stub hook record with event (PreToolUse/PostToolUse/UserPromptSubmit), trigger conditions, action summary.
   - **Settings entry** → propose a `.claude/settings.json` change (allowlist / env / hook wiring). Record as a stub for later.
   - **Shell/Node script** → record in `scripts/` as a stub shebang + TODO, or just file a candidate.
   - **CI step** → propose a `.github/workflows/ci.yml` insertion.
   - **ADR** → invoke `/wr-architect:create-adr` (route, don't duplicate).
   - **JTBD** → invoke `/wr-jtbd:update-guide`.
   - **Voice / Style / Risk guide** → invoke `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-risk-scorer:update-policy`.
   - **Problem ticket** → invoke `/wr-itil:manage-problem` (existing Step 4 behaviour).
   - **Test fixture / bats test** → record as a problem with a "codify as regression test" recommendation.
   - **Memory template** → record as a BRIEFING.md suggestion or a memory-write candidate.
   - **Skip** — not codify-worthy.

3. **Extend Step 5 summary** with a per-shape sub-section or a unified "Codification Candidates" table with a `Shape` column. Keep the existing "Skill Candidates" for backward compatibility OR migrate it into the unified table. Architect call.

4. **Bats test extensions**: existing `run-retro-skill-candidates.bats` covers the skill path. Add tests for at least two additional shapes (agent + hook) to prove the generalisation; leave exhaustive per-shape coverage for a follow-up.

Candidates 1 + 2 + 3 are complementary. Candidate 4 is the test discipline.

### Relationship to P044 and other tickets

- **P044** (Fix Released) solved the skill shape. P050 extends that pattern; architect review should confirm whether to supersede P044's specific language (Step 2 "skill candidate") with the generalised language, or layer the general over the specific.
- **P014** (no aside invocation for governance skills) — if a retro surfaces an agent / hook / script candidate, the user may want to capture-without-interrupt, which is exactly what P014's aside pattern would enable. P050's routing to dedicated skills (create-adr, update-guide, etc.) interacts with the aside mechanism.
- **P046** (architect-agent misses performance implications) — this session's Candidate 3 (performance-specialist sub-agent) is an agent-shaped recommendation run-retro should eventually surface.
- **P012** (skill testing harness) — if P050 generates agent / hook candidates that later get scaffolded, the harness question applies to those too. Out of scope for P050 directly; note for later.

### Investigation Tasks

- [ ] Architect review: is this a supersede-P044 (rewrite Step 2 / 4b generalised) or a layer-on-top (keep P044's skill language, add parallel branches for other shapes)? Expected: supersede is cleaner; P044's test coverage is a starting pattern for the generalised tests.
- [ ] Enumerate the full shape list and write an example per shape (2-3 sentences each) so contributors can pick confidently. Candidate list above is a first draft; review for completeness against this repo's actual surface.
- [ ] Decide routing semantics: which shapes create stubs (skill-style record) vs which invoke dedicated skills (ADR, JTBD, update-guide). Current draft above is a starting point.
- [ ] Architect on the AskUserQuestion shape. Two-step flow (type → action) is cleaner but adds a step; single flow with type-prefixed option labels is terser but longer. Pick one.
- [ ] Draft SKILL.md edits. Preserve P044's Skill Candidates behaviour as a specific instance of the general flow so existing users don't regress.
- [ ] Add bats tests covering at least three shapes end-to-end (skill / agent / hook). Extend the existing 10-assertion `run-retro-skill-candidates.bats` or add a parallel file.
- [ ] Decide whether to update the existing P044 file to note the generalisation, vs leave P044 as-is and let P050 carry the superseding work. P044 is in Fix Released state awaiting verification — changing its scope is risky.
- [ ] Cross-check with P014 — aside invocation might be the preferred entry point for recommending agents / hooks mid-session; P050 focuses on the end-of-session retro path.

## Related

- P044: `docs/problems/044-run-retro-does-not-recommend-new-skills.known-error.md` — direct predecessor; P050 generalises P044's Step 2 / 4b / 5 pattern from skills to arbitrary codifiable outputs.
- P014: `docs/problems/014-aside-invocation-for-governance-skills.open.md` — aside pattern for mid-session capture; complementary entry point to the end-of-session retro path.
- P046: `docs/problems/046-architect-agent-misses-performance-implications.open.md` — this session's example of an agent-shaped recommendation run-retro could surface.
- P012: `docs/problems/012-skill-testing-harness.open.md` — any future scaffolding for agents/hooks/scripts inherits harness needs.
- `packages/retrospective/skills/run-retro/SKILL.md` — primary fix target; Step 2 reflection category, Step 4b recommendation branch, Step 5 summary slot.
- `packages/retrospective/skills/run-retro/test/run-retro-skill-candidates.bats` — test pattern to generalise.
- Codification-skill routing targets: `/wr-architect:create-adr`, `/wr-jtbd:update-guide`, `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-risk-scorer:update-policy`, `/wr-itil:manage-problem`.
- ADR-013: `docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md` — Rule 1 (AskUserQuestion) + Rule 6 (non-interactive fallback) apply to the generalised Step 4b.
- ADR-014: `docs/decisions/014-governance-skills-commit-their-own-work.proposed.md` — retrospective skill remains out of scope; any retro-driven changes are committed by the user or by the invoked dedicated skill.
