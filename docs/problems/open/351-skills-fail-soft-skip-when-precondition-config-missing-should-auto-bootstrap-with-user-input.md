# Problem 351: skills fail-soft-skip when their precondition config is missing — should auto-bootstrap with user input as needed rather than silently skipping

**Status**: Open
**Reported**: 2026-06-03 (user direction with screenshot evidence — `/wr-itil:review-problems` Step 4.5 inbound-discovery pass output: *"No inbound-discovery pass — no docs/problems/.upstream-channels.json configured (Step 4.5 fail-soft skip)"*)
**Priority**: 12 (High) — Impact: 4 (Significant — load-bearing pass silently bypassed; user has no visible signal that a desired capability is unavailable in their session; auto-bootstrap would close the gap with minimal user friction) × Likelihood: 3 (Possible — fires on every adopter install that has NOT yet configured the precondition file; class-of-pattern recurrence high across skills with config-file preconditions)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-101
**Effort**: M (per-skill scan for fail-soft-skip patterns + auto-bootstrap routine — likely 3-5 skill surfaces; structural lint optional)
**WSJF**: 6.0 (12 × 1.0 / 2)

## Description

User direction 2026-06-03 with screenshot evidence: `/wr-itil:review-problems` Step 4.5 inbound-discovery pass emits *"No inbound-discovery pass — no docs/problems/.upstream-channels.json configured (Step 4.5 fail-soft skip)"* and silently skips the entire pass. The user's direction: *"this is a problem. the skill should auto-bootstrap (with user input as needed) rather than skipping."*

The pattern is broader than this one instance: any skill that depends on a config file precondition (e.g. `.upstream-channels.json`, `docs/risks/`, `docs/jtbd/`, `docs/changesets-holding/README.md`, `RISK-POLICY.md`) currently fail-soft-skips when the file is missing. The right behaviour is to recognise the gap and **auto-bootstrap** the missing config — invoking the relevant SessionStart-hook / capture-* / scaffold-intake / update-guide flow, surfacing `AskUserQuestion` for any required user input, then proceeding with the original pass against the just-bootstrapped config.

## Symptoms

- Skill output shows *"No <feature> pass — no <config-file> configured (fail-soft skip)"* or equivalent prose.
- Downstream capability the skill was supposed to deliver silently doesn't fire.
- User has no signal that the config gap exists until they happen to read the skill's output prose.
- Adopter installs accumulate skipped passes indefinitely; no nudge to configure.

## Workaround

User reads skill output, recognises the skip, manually creates the config file (often without clear guidance on what fields are required), re-invokes the skill.

## Impact Assessment

- **Who is affected**: every adopter of every `@windyroad/*` skill with a config-file precondition. Specifically: developers and tech-leads who installed plugins but haven't yet configured their per-project metadata.
- **Frequency**: every skill invocation against a project that lacks the config — recurrent until the user manually bootstraps. Aggregates over time across multiple skills + projects.
- **Severity**: Significant. Skipped passes mean capabilities the adopter installed for don't actually fire. The silent skip class is a JTBD-101 ("Extend the Suite" / "Keep Plugins Current") violation by inversion — adopters install plugins to get features, and silent skips give them less than they paid for.
- **Analytics**: pattern is self-similar across skills; auto-bootstrap is a class fix.

## Root Cause Analysis

### Hypotheses

1. **Defensive-skip pattern overgeneralized**: skill authors adopt fail-soft-skip as the safe default when config is missing, on the principle of "don't break the orchestrator". The principle is right but the implementation is wrong — fail-soft should be a LAST resort after auto-bootstrap fails, not the FIRST response.

2. **No standardized auto-bootstrap helper**: skills lack a shared pattern for "config-file is missing → propose scaffold + collect required fields via AskUserQuestion + write file + resume". Each skill would have to author its own bootstrap inline; the friction makes fail-soft-skip cheaper to ship.

3. **AFK contract ambiguity**: in AFK mode, AskUserQuestion is forbidden by the iter contract. Skill authors may have generalized "AFK can't bootstrap" to "always fail-soft-skip" — but the right answer is "auto-bootstrap when interactive, fail-soft + halt-with-stderr-directive when AFK".

4. **No structural lint detection**: no PreToolUse hook that flags skill emissions matching `(fail-soft skip|silently skip|skipping|not configured)` against precondition-config paths.

### Investigation Tasks

- [ ] Catalogue all skill surfaces that fail-soft-skip on missing config — start with `/wr-itil:review-problems` Step 4.5 (the witnessed instance), expand to sibling skills (`/wr-architect:review-decisions`, `/wr-jtbd:confirm-jobs-and-personas`, `/wr-risk-scorer:assess-release`, `/wr-itil:report-upstream`, scaffold-intake).
- [ ] Design the shared auto-bootstrap helper contract: per-skill bootstrap function takes (config-path, required-fields-spec, surface-mode) and either writes the config + resumes OR halts-with-directive in AFK.
- [ ] AFK behaviour decision: when AFK + no config + no flags, should iter halt with a clear directive ("re-run in interactive mode with --bootstrap" or similar) OR queue a config-direction outstanding_question for orchestrator-main-turn surface?
- [ ] Per-skill ratification: each affected skill's bootstrap shape needs the architect/JTBD review (new SessionStart-hook-like obligations, who owns the config file's authoritative content, etc.).

## Fix Strategy

**Kind**: prevent (pattern fix) + per-skill amend

**Shape**:

1. **Audit + catalogue**: identify all affected skill surfaces. Initial known instance: `/wr-itil:review-problems` Step 4.5 inbound-discovery (`.upstream-channels.json` precondition). Suspected siblings: any skill that mentions "fail-soft skip" or "not configured" in its output.

2. **Per-skill auto-bootstrap amendment**: for each affected skill, replace the fail-soft-skip with an auto-bootstrap routine:
   - Interactive mode: AskUserQuestion for required fields → write config → resume original pass.
   - AFK mode: halt-with-stderr-directive naming the missing config + the bootstrap path the user can run on return.

3. **Possibly shared helper**: `packages/itil/lib/auto-bootstrap-config.sh` providing the canonical pattern (path-check → propose-scaffold → AskUserQuestion-or-halt → write → resume).

4. **Possibly structural lint**: PreToolUse hook that flags new skill prose containing fail-soft-skip patterns without paired auto-bootstrap. Optional; SKILL-prose review may suffice.

**Candidate options for AFK behaviour**:

1. **Halt-with-stderr-directive naming the bootstrap path** — iter exits cleanly with directive; orchestrator surfaces at loop end via Step 2.5 batched AskUserQuestion. Conservative.
2. **Queue config-direction outstanding_question** — iter completes its other work + queues a "configure X" entry in outstanding_questions; orchestrator drains at loop end. More flexible.
3. **Default-skeleton scaffold + flag for review** — iter writes a minimal scaffold with placeholder values + queues a review question; later session refines. Most forward-progress but risks adopters never reviewing the placeholder.

## Dependencies

- **Blocks**: trustworthiness of every config-preconditioned skill — adopters get silent under-delivery.
- **Blocked by**: (none).
- **Composes with**: P065 (closed; intake-scaffold sibling pattern), JTBD-101 (plugin-developer "Extend the Suite" outcome — silent-skip violates the deliver-what-was-installed expectation), ADR-013 (structured user-interaction; AskUserQuestion is the standardized bootstrap surface), ADR-044 (decision-delegation contract; classification of "auto-bootstrap vs halt" by AFK-mode), ADR-074 (substance-confirm-before-build; config bootstrap is itself substantive — needs ratification for any non-trivial scaffold).

## Related

- 2026-06-03 user direction with screenshot evidence (this capture's authoring context): *"this is a problem. the skill should auto-bootstrap (with user input as needed) rather than skipping."*
- Witnessed instance: `/wr-itil:review-problems` Step 4.5 inbound-discovery pass output line "No inbound-discovery pass — no docs/problems/.upstream-channels.json configured (Step 4.5 fail-soft skip)".
- **P065** (closed) — `/wr-itil:scaffold-intake` skill — sibling-pattern precedent for bootstrapping config artefacts at adopter install time. Different surface (intake templates vs runtime config) but same auto-bootstrap principle.
- **JTBD-101** — plugin-developer "Extend the Suite" outcome; silent-skip violates the deliver-installed-features expectation.
- **ADR-013** — AskUserQuestion as standardized user-input surface for config bootstrap.
- **ADR-044** — decision-delegation contract; AFK-vs-interactive routing for the bootstrap-or-halt decision.
- **ADR-074** — substance-confirm-before-build; config bootstrap that touches architectural surface needs ratification.
