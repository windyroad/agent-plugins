# Problem 038: No voice-and-tone gate on external communications

**Status**: Open
**Reported**: 2026-04-17
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: XL — multi-surface PreToolUse hook (gh, npm, RapidAPI, marketplace) + pre-flight rewrite skill + voice profile integration + ADR for new enforcement surface + regression fixtures; cross-plugin with voice-tone
**WSJF**: 1.5 — (12 × 1.0) / 8

## Direction decision (2026-04-20, user — AFK loop stop-condition #2)

**Enforcement surface**: **Both — hook + skill**. PreToolUse hook intercepts `gh issue comment`, `gh pr create`, `gh pr comment`, `npm publish` (with README diff), and RapidAPI/marketplace update calls, firing the gate deterministically. A companion skill provides the rewrite logic (strip AI-tell patterns, apply the voice profile, run age/context check on target issues). The hook invokes the skill before allowing the tool call.

Implication: new ADR needed (extending ADR-009 gate-marker lifecycle and ADR-015 on-demand assessment). Scope: (1) external-comms surface inventory, (2) hook design with gate-marker pattern, (3) rewrite skill with voice profile integration, (4) regression fixtures from historical "FFS" outputs, (5) per-package cross-plugin coordination with `@windyroad/voice-tone`.

## Description

The `wr-voice-tone` plugin and `docs/VOICE-AND-TONE.md` govern voice-and-tone only for in-repo text (READMEs, docs, commit messages). There is no gate on text produced for **external** surfaces: GitHub issue comments, PR descriptions, npm README updates, RapidAPI listings, Shopify/marketplace product pages. Claude's output on these surfaces defaults to generic "AI voice" — em-dashes, hedging phrases, overly-polite closers, and context-blind suggestions like "let's keep this ticket open" on 2-year-old issues.

Observed pattern over the 30-day window covered by `/Users/tomhoward/.claude/usage-data/report.html` (1,464 messages across 86 sessions): voice-and-tone checks were skipped before every external-comms tool call, triggering repeated "FFS" corrections from the user. The insights report identifies this as one of three top friction categories ("Missing voice/risk checks on external output") and recommends a mandatory pre-flight voice/tone check on every external surface.

The gate should:
- Intercept `gh issue comment`, `gh pr create`, `gh pr comment`, `npm publish` (with README diff), RapidAPI/Shopify update calls
- Strip AI-tell patterns (em-dashes, "it seems", "I'd suggest", excessive hedging)
- Rewrite to match the voice profile in `docs/VOICE-AND-TONE.md`
- Run an age/context check on target issues before comments ("keep open" on a 2024 ticket is almost always wrong)
- Block the tool call until rewrite is approved

## Symptoms

- GitHub comments posted with em-dashes, hedging, and generic-AI-voice phrases
- "Keep ticket open" or "happy to help further" suggested on stale (>1yr) issues
- README updates published without tone review
- User frustration ("FFS") surfaces repeatedly as a late-stage correction rather than a pre-flight gate
- Voice-and-tone enforcement is inconsistent — present for in-repo docs, absent for outbound surfaces

## Workaround

The user manually reviews every external-comms output before publishing and rewrites as needed. This is the "manually police AI output" pain point explicitly called out in the solo-developer persona.

## Impact Assessment

- **Who is affected**: Solo-developer persona when Claude posts to external surfaces on their behalf (JTBD-001 — "Enforce Governance Without Slowing Down")
- **Frequency**: Every external-comms tool call; observed dozens of times over 30 days per insights report
- **Severity**: High for the persona — external surfaces are the public face of the user's work; AI-tell patterns damage credibility and compound the "AI slop" concern
- **Analytics**: `/Users/tomhoward/.claude/usage-data/report.html` — friction category "Missing voice/risk checks on external output" is one of three top friction types

## Root Cause Analysis

### Investigation Tasks

- [ ] Inventory the external-comms surfaces Claude uses (`gh` subcommands, `npm` publish paths, RapidAPI CLI/API, any Shopify/marketplace pushes)
- [ ] Decide implementation surface: PreToolUse hook (runs the gate deterministically) vs. skill (author discipline) vs. both
- [ ] Design the voice profile format — reuse `docs/VOICE-AND-TONE.md` or create a tighter rewrite-rules file
- [ ] Build a regression fixture set from past "FFS" outputs captured in session logs
- [ ] Create an ADR if the chosen mechanism is a new hook pattern (per wr-architect advisory — ADR-009 gate-marker lifecycle and ADR-015 on-demand assessment both inform this)
- [ ] Create a reproduction test (feed a known-AI-voice draft, assert the gate rewrites or blocks it)
- [ ] Create INVEST story for permanent fix

## Related

- [JTBD-001](../jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md) — "Every edit to a project file is reviewed against relevant policy before it lands" generalises to external-comms policy enforcement
- [ADR-009](../decisions/009-gate-marker-lifecycle.proposed.md) — gate marker patterns apply if this becomes a hook
- [ADR-015](../decisions/015-on-demand-assessment-skills.proposed.md) — on-demand assessment pattern informs the gate design
- `docs/VOICE-AND-TONE.md` — existing voice profile (in-repo text scope)
- `packages/voice-tone/skills/update-guide/SKILL.md` — existing skill scope
- `/Users/tomhoward/.claude/usage-data/report.html` — insights report identifying the pattern (2026-03-17 to 2026-04-16, 1,464 messages across 86 sessions)
- P034 — centralise risk reports (shares cross-project analytics-driven pattern)
