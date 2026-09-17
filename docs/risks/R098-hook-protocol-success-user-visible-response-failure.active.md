# Risk R098: Hook protocol succeeds while the user-visible response fails

**Status**: Active
**Category**: operational
**Identified**: 2026-09-17
**Owner**: plugin-maintainer
**Last reviewed**: 2026-09-17
**Next review**: 2027-03-17

## Description

An assistant-response hook can load, emit valid protocol output, and run its continuation while the final response shown to the user is empty or does not follow the project guide. Hook registration and shell-level smoke tests can therefore pass while the feature fails at its actual user-visible boundary.

This affects users who opt into assistant voice-and-tone guidance. It matters because protocol success can be mistaken for response-quality evidence, allowing a broken release and an unjustified low residual-risk score.

## Inherent Risk

Impact × Likelihood *before* controls.

- **Impact**: 4 (Significant)
- **Likelihood**: 4 (Likely)
- **Inherent Score**: 16
- **Inherent Band**: High

## Controls

- **Hook protocol tests** — verify guide injection, Stop output, and the one-continuation guard. Implemented in `packages/voice-tone/hooks/test/assistant-voice-tone-response.bats`. These do not reduce this outcome-level risk by themselves.
- **Packed-plugin Codex journey** — runs a real Codex conversation with an observable guide requirement and fails on an empty or missing marked final response. Planned treatment; not credited until it passes for the release candidate.
- **Independent-control check** — prevents protocol tests, package smoke, and the general test suite from being counted as separate controls when they share the same user-visible blind spot. Implemented by `RISK-POLICY.md` control-composition rules.

## Residual Risk

Impact × Likelihood *after currently proven controls.

- **Impact**: 4 (Significant)
- **Likelihood**: 4 (Likely)
- **Residual Score**: 16
- **Residual Band**: High
- **Within appetite?**: No

## Treatment

Mitigate. Require a complete replacement continuation and a passing packed-plugin Codex journey before release. Until that outcome evidence exists, residual risk remains equal to inherent risk; protocol-only evidence cannot reduce it.

## Monitoring

- **Trigger to re-assess**: any assistant-response hook change, Codex or Claude Code hook-runtime change, empty continuation, or final response that misses the journey's observable guide requirement.
- **Metrics**: packed-plugin journey result, final assistant output length, observable marker present or absent, and number of review continuations.

## Related

- Criteria: `RISK-POLICY.md`
- Realised-as: `docs/problems/verifying/540-assistant-responses-cannot-opt-into-project-voice-and-tone-guidance.md`
- Treatment ADRs: pending ratification of the replacement-response decision.
- Personas affected: `docs/jtbd/developer/persona.md`

## Change Log

- 2026-09-17: Initial identification after an installed Codex conversation ended with an empty review continuation despite successful hook protocol execution.
