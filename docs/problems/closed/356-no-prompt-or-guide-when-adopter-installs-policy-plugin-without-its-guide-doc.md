# Problem 356: No prompt or guide when an adopter installs a policy-plugin without its guide doc (silent no-op instead of guided onboarding)

**Status**: Closed
**Reported**: 2026-06-08
**Closed**: 2026-06-16 (duplicate-of-P297 — folded into P297 Phase 2 as Option D + JTBD-302 lens)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-302
**Persona**: plugin-user

## Closed as no longer relevant — duplicate of P297 (same decision-space; investigation subsumed by P297 Phase 2)

**Closure date**: 2026-06-16 (AFK work-problems iter-28, agent-consolidated backlog hygiene — the SUBSTANCE decision stays queued for the user in P297, only the ticket home is consolidated)

**Closure reason**: duplicate-of-P297. P356 and P297 Phase 2 (both captured 2026-06-08) occupy the **same decision-space** — what onboarding surface, if any, should fire when an adopter has a policy-plugin installed but has not authored its guide doc, across the four policy-plugins (voice-tone / style-guide / jtbd / architect). P356's two Investigation Tasks — *audit the four sibling plugins for a missing-guide → update-guide surface* and *decide where the prompt/guide should fire* — were **already completed in P297 Phase 2** (investigated 2026-06-08). Maintaining two open tickets for one user decision is the inflow-discipline anti-pattern [[feedback_hang_off_existing_ticket_before_capturing_new]]; P356 is hung off P297 as the wider-framing input rather than persisting as a sibling.

**Relevance evidence shape**: `duplicate-of` (P356's guided-onboarding decision IS P297 Phase 2's A/B/C decision — surfaced by reading P297's body, exactly the discipline the narrow title-only dup-check misses; cf. P347→P346 precedent). Nothing lost: P356's distinct contribution is **preserved in P297** as a new **Option D** (strengthen existing reactive surfaces into guided invocations) plus the **JTBD-302 framing lens** (README-describes-the-plugin trust outcome). The single Phase 2 user decision (Option A/B/C/D) now resolves both tickets.

**Empirical correction to P356's premise (verified iter-28):** P356's "silent no-op" framing is accurate for only **one** of four plugins. Three of four actively BLOCK the edit and name the update-guide skill in the deny message:
- voice-tone — `packages/voice-tone/hooks/voice-tone-enforce-edit.sh:71-72` (BLOCK + "Run /wr-voice-tone:update-guide"); voice-tone agent also emits P200 PASS-with-advisory naming the skill.
- style-guide — `packages/style-guide/hooks/style-guide-enforce-edit.sh:69-70` (BLOCK + "Run /wr-style-guide:update-guide").
- jtbd — `packages/jtbd/hooks/jtbd-enforce-edit.sh:197-199` (BLOCK + "Run /wr-jtbd:update-guide").
- architect — `packages/architect/hooks/architect-enforce-edit.sh:48-49` fails **OPEN** (exit 0) when `docs/decisions/` is missing — the **one genuine silent gap** (= P297 Phase 2 Option C).

So the gap P356 raises is narrower than its title suggests: not "silent no-op across four plugins" but "(a) architect alone is silently fail-open, and (b) the other three surface the skill in **prose** rather than as a **guided invocation**." Both are folded into P297's decision (Option C covers (a); Option D covers (b)).

**Recovery**: `/wr-itil:transition-problem 356 open` if the consolidation is judged wrong; the operative decision lives in P297 Phase 2 either way.

---


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
