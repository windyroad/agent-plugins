# Problem 356: No prompt or guide when an adopter installs a policy-plugin without its guide doc (silent no-op instead of guided onboarding)

**Status**: Open
**Reported**: 2026-06-08
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

When an adopter installs a policy-plugin (wr-voice-tone is the witnessed instance; wr-style-guide / wr-jtbd / wr-architect have the same shape) but has NOT yet authored the plugin's policy doc (`docs/VOICE-AND-TONE.md` / `docs/STYLE-GUIDE.md` / `docs/jtbd/` / `docs/decisions/`), the plugin does not prompt them to create it, nor guide them through creating it. The user is left with no surfaced affordance.

The corresponding `update-guide` skills exist (`/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-jtbd:update-guide`) — they are the interactive guided-authoring path. But discovery of those skills is left entirely to the adopter; nothing in the install flow surfaces them.

Post-P200 (2026-06-04), the voice-tone agent now emits PASS-with-advisory on a missing guide instead of blanket-FAIL — but that just stops the gate-block; it does not actually walk the adopter through creating the guide. The agent's advisory may name the update-guide skill in prose, but a prose mention buried in a verdict is far weaker than an actual guided invocation.

The latter — **being guided through creating the guide** — is what should happen.

## Symptoms

- Adopter installs wr-voice-tone (or sibling), opens a project file in a context where the voice-tone gate would normally fire, and either gets the post-P200 PASS-with-advisory (silent success) or the pre-P200 blanket FAIL (silent friction) — in neither case are they actively prompted/guided to invoke `/wr-voice-tone:update-guide` to create the missing doc.
- Same shape across the four sibling policy-plugins (voice-tone / style-guide / jtbd / architect).
- The `update-guide` skill ships and works — but its existence is invisible to adopters who don't already know about it.

## Workaround

(deferred to investigation)

Likely candidates:
- Adopter reads the plugin README and discovers `/wr-voice-tone:update-guide` on their own.
- Adopter waits until they hit the gate, reads the (post-P200) PASS-with-advisory output, sees the skill named in prose, and manually invokes it.

Both depend on adopter initiative; neither is a prompt or guide.

## Impact Assessment

- **Who is affected**: plugin-user persona — adopters installing policy-plugins for the first time. Frequency: every fresh adopter of `wr-voice-tone` / `wr-style-guide` / `wr-jtbd` / `wr-architect` who has not yet authored the policy doc. Severity: low-to-moderate (the gate degrades gracefully post-P200, but the onboarding path is invisible — JTBD-302 outcome "the plugin behaves as the README describes" is violated when the README implies governance enforcement and the installed plugin silently no-ops).
- (Quantitative impact deferred to investigation.)

## Root Cause Analysis

### Preliminary hypothesis

There is no install-time / first-edit-time / SessionStart prompt that detects "policy doc missing" AND surfaces "run `/wr-<plugin>:update-guide` to author it interactively." The plugins all SHIP the `update-guide` skill but never tell the adopter it exists at the moment they'd need it. The agent's PASS-with-advisory (P200) is the closest surface but is verdict prose, not a guided invocation.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Audit the four sibling policy-plugins (voice-tone / style-guide / jtbd / architect) for an existing "missing guide-doc → prompt to invoke update-guide" surface. If absent across the class, this is a class-wide gap.
- [ ] Decide where the prompt/guide should fire: SessionStart hook (consistent with `architect-detect.sh` / `jtbd-eval.sh` SessionStart class), first-edit PreToolUse advisory, post-install `/install-updates` step, or a dedicated `scaffold-policy` skill (sibling of `/wr-itil:scaffold-intake`).
- [ ] Decide whether the post-P200 PASS-with-advisory text should EXPLICITLY direct the user to invoke `/wr-<plugin>:update-guide` (a small refinement of the P200 fix) versus a separate surface.
- [ ] Composes with: P200 (graceful no-op on missing guide — already shipped), the four `update-guide` skills (existing), `/wr-itil:scaffold-intake` (the sibling onboarding-scaffold precedent for OSS intake artefacts — same shape, different domain).

## Dependencies

- **Blocks**: smooth adopter onboarding for the four policy-plugins.
- **Blocked by**: (none)
- **Composes with**: P200 (closed/verifying — voice-tone agent graceful no-op on missing guide), `/wr-voice-tone:update-guide` + `/wr-style-guide:update-guide` + `/wr-jtbd:update-guide` (the existing guided-authoring skills this ticket would surface), `/wr-itil:scaffold-intake` (sibling onboarding-scaffold precedent — ADR-036), JTBD-302 (Trust That the README Describes the Plugin I Just Installed — the load-bearing Job that this gap violates).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- P200 (sibling, closed/verifying): wr-voice-tone agent now PASS-with-advisory on missing guide — same surface, narrower fix (verdict shape, not user-facing prompt).
- `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-jtbd:update-guide` — the existing guided-authoring skills this ticket's fix would surface to adopters.
- ADR-036 (`/wr-itil:scaffold-intake`) — the sibling adopter-scaffold precedent for OSS intake artefacts; same "make the plugin's setup affordance discoverable at install time" shape.
- JTBD-302 (plugin-user — Trust That the README Describes the Plugin I Just Installed) — the load-bearing Job: README implies governance; installed plugin silently no-ops; JTBD-302 expectation broken.
