# Problem 071: Argument-based skill subcommands are not discoverable in Claude Code autocomplete

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M — inventory all skills with argumented subcommands across all `@windyroad/*` plugins, split each distinct user intent into its own named skill, leave a thin forwarder path on the original skill for backward compatibility during a deprecation window, update the primary SKILL.md Operations tables, ADR-010 naming convention, and the bats doc-lint tests. Mechanical but touches 6–10 SKILL.md files across 3–4 plugins.
**WSJF**: 6.0 — (12 × 1.0) / 2 — High-severity discoverability friction on every subcommanded invocation; moderate split-and-forwarder effort.

## Description

Claude Code's skill-completion surface shows skill names (`/<plugin>:<skill>`) in autocomplete but does NOT surface skill arguments. A user who types `/wr-itil:` sees `manage-problem`, `manage-incident`, `report-upstream`, `work-problems` in the picker — but they do NOT see that `manage-problem` has `list`, `work`, `review` sub-operations, or that `<NNN>` arguments trigger update / transition paths. The sub-operations exist only inside SKILL.md, so users have to read the skill file (or remember from last session) to discover them.

User feedback (2026-04-20, verbatim): *"`/wr-itil:manage-problem pre-afk` is shit — generally `/<skill> <argument>` is shit as it's not discoverable"*. Captured in the user's feedback memory (`feedback_skill_subcommand_discoverability.md`). The principle: distinct user intents belong in distinct skills; argumented subcommands should only be used for verb-variations on a single primary flow or for data parameters (IDs, paths, URLs).

Current offenders (initial inventory — full audit is part of the fix):

| Skill | Subcommand-style argument | Shape |
|-------|---------------------------|-------|
| `/wr-itil:manage-problem` | `list` / `work` / `review` / `<NNN>` / `<NNN> known-error` | `list` / `work` / `review` are distinct user intents that should be their own skills; `<NNN>` is a data parameter (keep); `<NNN> known-error` is another distinct transition (could be `/wr-itil:transition-problem`). |
| `/wr-itil:manage-incident` | likely similar (list / work / review) | Needs audit. |
| `/wr-<plugin>:update-guide` (voice-tone, style-guide, jtbd) | may support subcommands | Needs audit. |
| `/wr-risk-scorer:update-policy` | may support subcommands | Needs audit. |

The fix is mechanical: split each distinct user intent into a named skill using the `/<plugin>:<verb>-<object>` convention already declared in ADR-010, then leave the original skill's subcommand routes as thin forwarders that delegate to the new named skills during a deprecation window.

This ticket is the flipside of the P068 / P065 "codification stub" pattern: P068 and P065 proposed NEW skills with sensible names; this ticket retrofits EXISTING skills to match the same naming discipline.

## Symptoms

- Claude Code autocomplete on `/wr-itil:` shows 4 skills; the reality is closer to 7–9 distinct user intents hidden behind subcommand arguments.
- Users who want to list open problems type `/wr-itil:manage-problem list` — which requires remembering (a) that `manage-problem` is the host skill, (b) that `list` is the subcommand name, (c) that the argument is a word, not a flag. Three memory loads per invocation.
- New adopters of the suite cannot discover sub-operations without reading SKILL.md files. The "clear patterns, not reverse-engineering" promise (JTBD-101) fails at the skill-invocation surface.
- Agents invoking skills programmatically also fail discoverability — the skill-completion surface is the same for agents and humans. Agents fall back to reading SKILL.md or guessing.
- Documentation and retrospective summaries like to reference `/wr-itil:manage-problem work` — the reference works, but it's a name the reader also has to parse: is `work` the verb or the subcommand or both?
- User's own retro (this session) rejected a proposed `/wr-itil:manage-problem pre-afk` codification because it would extend the same anti-pattern — directly motivating this ticket.

## Workaround

Users read SKILL.md, remember subcommand names from session to session, or re-derive by trial and error. Autocomplete gives no help. In practice: the user builds a mental index of subcommands per skill that they have to refresh each time they return to the project.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001)** — every subcommand invocation requires recall from memory or SKILL.md reference. "Enforce governance without slowing down" fails at the most frequent entry point.
  - **Plugin-developer persona (JTBD-101)** — "clear patterns, not reverse-engineering" is violated at the skill-invocation surface. Adopters build their own muscle memory for each subcommand layout per plugin.
  - **Tech-lead persona (JTBD-201)** — onboarding new contributors, the subcommand layout is undocumented friction.
  - **Agents invoking skills on behalf of the user** — same discoverability surface as humans; no shortcut. Agents often guess subcommand names based on pattern inference, which is lossy.
- **Frequency**: Every subcommand invocation. Across the suite, this is multiple times per session, every session.
- **Severity**: High for discoverability; Medium for correctness (the subcommands DO work; they're just hidden). Cumulative friction cost scales with invocation frequency.
- **Analytics**: N/A today; the Claude Code insights report might surface "I tried to invoke X but couldn't find it" as a friction pattern if we had the data — worth revisiting after a sample of sessions lands after the split.

## Root Cause Analysis

### Structural

`manage-problem` was built early (P001–P010 era) as a single-skill container for all problem-management operations. Subcommands were the cheapest way to layer operations without a proliferation of skill files. ADR-010 (rename `wr-problem` to `wr-itil`) established the `<verb>-<object>` naming convention but did not retroactively audit existing skills for subcommand patterns that should become separate skills. ADR-011 (manage-incident skill-wrapping precedent) followed manage-problem's subcommand convention, propagating the pattern rather than replacing it.

The result: the naming convention applies at the skill-file level but not at the user-intent level. A skill can have N user intents and Claude Code's surface only sees the skill name.

### Distinct user intents vs verb-variations — the split rule

Per the user's feedback memory:

- **Separate skill** when the operation is a distinct noun-ish user intent the user would reasonably type on its own (e.g. "list problems", "work the next problem", "review all problems", "transition this one to closed").
- **Argument** when it's a data parameter (e.g. `/wr-itil:manage-problem 063` where `063` names the ticket being acted on) or a verb-variation that the primary flow's documentation always presents together (e.g. `--verbose`, `--dry-run`).

Applying the rule to `manage-problem`:

| Current form | After split | Rationale |
|---|---|---|
| `/wr-itil:manage-problem` (no args) | `/wr-itil:manage-problem` | Create-problem flow; the primary entry. |
| `/wr-itil:manage-problem list` | `/wr-itil:list-problems` | Distinct user intent: "show me all open problems". |
| `/wr-itil:manage-problem work` | `/wr-itil:work-problem` (singular) | Distinct user intent: "work the highest-WSJF one". Note: `/wr-itil:work-problems` (plural) already exists as the AFK orchestrator — keep it, rename or consolidate in audit. |
| `/wr-itil:manage-problem review` | `/wr-itil:review-problems` | Distinct user intent: "re-rank the backlog". |
| `/wr-itil:manage-problem <NNN>` | `/wr-itil:manage-problem <NNN>` | Data parameter — keep argumented. |
| `/wr-itil:manage-problem <NNN> known-error` | `/wr-itil:transition-problem <NNN> known-error` (or `/wr-itil:resolve-problem <NNN>`) | Distinct user intent: "advance this ticket's lifecycle". |
| (proposed P068 retro) `/wr-itil:manage-problem pre-afk` | `/wr-itil:pin-afk-direction` | Distinct user intent: "pin direction decisions before AFK". |

### Candidate fix

1. **Audit every SKILL.md** across all `@windyroad/*` plugins for argumented subcommands. Build an inventory: skill name × subcommand list × suggested split.
2. **For each distinct user intent**, create a new SKILL.md using the `/<plugin>:<verb>-<object>` convention. Each new skill's logic reuses the existing SKILL.md's step block for that subcommand.
3. **On the original skill**, retain the subcommand routes as thin forwarders: Step 1's parser recognises the old argument and delegates to the new skill via the Skill tool, logging a deprecation notice to the user ("This form will be removed in N releases; use /<new-skill> instead").
4. **Update ADR-010** or add a sibling ADR codifying the "one skill per distinct user intent" rule so future skills don't regress.
5. **Update bats doc-lint tests**: assert each new skill exists, asserts each original skill's forwarder documentation is in place, assert the deprecation notice wording.
6. **Update session-doc cross-references**: SKILL.md files that mention `/wr-itil:manage-problem work` etc. get swapped to the new form.
7. **Deprecation window**: keep forwarders for 2 minor releases after split-release, then remove in a major release (or at a policy-declared milestone).

**Out of scope** for this ticket:
- Consolidating `/wr-itil:work-problem` (singular, interactive) vs `/wr-itil:work-problems` (plural, AFK orchestrator) naming — if confusing, file a separate ticket.
- Renaming skills with distinct argumented parameters (no fix needed).
- Changing the `/<plugin>:<verb>-<object>` convention itself — ADR-010 already covers it.

### Investigation Tasks

- [ ] Audit all SKILL.md files across `@windyroad/*` plugins for subcommand-style arguments. List them. Classify each as `distinct intent → split` vs `data parameter → keep` vs `verb variation → keep`.
- [ ] For each split candidate, propose the new skill name using `/<plugin>:<verb>-<object>`.
- [ ] Architect review on the split names and on whether the deprecation window is 1 release, 2 minor releases, or policy-tied.
- [ ] Draft the ADR update (or sibling to ADR-010) codifying "one skill per distinct user intent".
- [ ] Decide whether forwarders are thin routers (re-invoke via Skill tool) or hard-fail with a redirect message (stricter). Lean: thin routers for the deprecation window.
- [ ] Update bats doc-lint tests across affected plugins.
- [ ] Sweep `docs/` for cross-references that mention old argument forms and update them post-split.
- [ ] Update this project's codification candidate for the pre-AFK pinning pattern (session retro 2026-04-20) to use `/wr-itil:pin-afk-direction` instead of `/wr-itil:manage-problem pre-afk`. Already noted in the user's feedback memory; this ticket captures the broader rule.

## Decision record

**ADR-010 (amended 2026-04-21, P071 amendment)** — new "Skill Granularity" section codifies "one skill per distinct user intent". Argument-subcommands permitted only for data parameters (IDs, paths, URLs). Word-arguments that act as verbs (`list`, `work`, `review`, `close`, etc.) must be split into separate skills. **Deprecation window**: until next major version bump of each affected plugin. **Forwarder shape**: thin-router — original skill's subcommand routes re-invoke the new named skill via the Skill tool AND emit a one-line systemMessage deprecation notice. Bats doc-lint assertion with `deprecated-arguments: true` frontmatter allowlist during the deprecation window.

This ticket (P071) remains **Open** as the implementation tracker. Closes when:
- Every `@windyroad/*` plugin's argumented skills (audit identified: `manage-problem`, `manage-incident`, possibly `update-guide` variants) have been split into named sibling skills.
- Thin-router forwarders land on the original skill's subcommand routes with the one-line systemMessage.
- Each affected SKILL.md carries the `deprecated-arguments: true` frontmatter flag.
- Bats doc-lint assertion lands per ADR-010's amended Confirmation section.
- Plugin manifests list the new skill names.

## Related

- **ADR-010 (amended 2026-04-21)** — decision record for this ticket. Closes the design question; P071 tracks execution.
- **ADR-032** (Governance skill invocation patterns) — pre-committed to the same rule; the capture-* sibling pattern IS the canonical application of "one skill per distinct user intent".
- **P044** — run-retro does not recommend new skills; sibling pattern. The skill-creation axis this ticket protects.
- **P050** — run-retro does not recommend other codifiable outputs; same retro-codification family.
- **P051** — run-retro does not recommend improvements to existing codifiables. Tangential — improvement rather than creation.
- **P068** (run-retro session-verification-close, 2026-04-20) — session retro proposed `/wr-itil:manage-problem pre-afk` which user rejected under this ticket's principle. That codification stub is redirected to `/wr-itil:pin-afk-direction` (a new standalone skill) per user's feedback memory.
- **P065** — scaffold-intake; proposed as a new skill `/wr-itil:scaffold-intake` — matches this ticket's discipline naturally.
- **ADR-010** — rename `wr-problem` to `wr-itil`; established `<verb>-<object>` naming convention at the skill-file level. This ticket extends it to the user-intent level.
- **ADR-011** — manage-incident skill-wrapping precedent. Likely inherited the subcommand anti-pattern from manage-problem; needs audit.
- `packages/itil/skills/manage-problem/SKILL.md` — primary current offender.
- `packages/itil/skills/manage-incident/SKILL.md` — suspected offender; audit.
- `packages/*/skills/update-guide/SKILL.md` (voice-tone, style-guide, jtbd) — suspected offenders; audit.
- `packages/risk-scorer/skills/update-policy/SKILL.md` — suspected offender; audit.
- `~/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/feedback_skill_subcommand_discoverability.md` — user feedback memory capturing the principle.
- **JTBD-001** (Enforce Governance Without Slowing Down) — discoverability is the "without slowing down" axis at the skill-invocation surface.
- **JTBD-101** (Extend the Suite with Clear Patterns) — "clear patterns" includes the skill-invocation shape users see.
