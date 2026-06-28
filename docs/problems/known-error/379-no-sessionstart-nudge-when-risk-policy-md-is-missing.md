# Problem 379: No SessionStart nudge fires when RISK-POLICY.md is missing

**Status**: Known Error
**Reported**: 2026-06-26
**Fix implemented**: 2026-06-28 (held changeset — see Root Cause Analysis)
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-003
**Persona**: developer

## Description

The user's stated intent for the risk-scorer plugin is that if `RISK-POLICY.md` is absent in an adopter project, the adopter should be auto-interviewed by `/wr-risk-scorer:update-policy` and a policy created. Today there is no enforcement surface for that intent.

The existing `risk-scorer-scaffold-nudge.sh` SessionStart hook nudges when `RISK-POLICY.md` exists AND `docs/risks/` is missing (the register-missing case, Phase 1 of P297). It explicitly silent-skips when the policy file itself is missing: *"Silent when the project does not have a risk policy. The policy file presence is the user authorisation for the register to exist; without it, the absence of docs/risks/ is not a governance gap."* That guard is correct for the register-missing case but means the policy-absent case is the inverse uncovered Phase.

Consequence: an adopter who installs `@windyroad/risk-scorer`, never writes a `RISK-POLICY.md`, and runs sessions for weeks gets the gate's default appetite (5 per ADR-086; was 4 per ADR-065) silently — no surfacing of "you don't have a policy; want to interview now?" Surfaced as a Bad/watch in ADR-086 § Consequences during the band-rebalance work 2026-06-25.

Closest existing ticket is **P297** — "ADR-047 governance-artefact scaffold should be a SessionStart hook". Phase 1 of P297 landed the policy-exists-register-missing nudge; Phase 2 (sibling plugins) was investigated and parked pending substance-confirm. The policy-absent case fits naturally as **P297 Phase 2.5** or **P297 Phase 3** rather than as a standalone ticket — open question whether to absorb (close this as duplicate of P297) or proceed as a sibling phase tracking the inverse-coverage gap specifically. Surfaced at review time via `/wr-itil:review-problems`.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause**: `risk-scorer-scaffold-nudge.sh` short-circuited on bare policy-absence (`[ -f "$POLICY_FILE" ] || exit 0`) by design — the Phase 1 (P297) rationale "policy presence is the user authorisation for the register to exist" is correct for the *register* concern but left the *capability-discoverability* concern uncovered. An adopter who installs the plugin and never authors a `RISK-POLICY.md` runs the gate at its default appetite (5 per ADR-086) with no signal that the capability exists or how to activate it.

**Fix (implemented 2026-06-28, proceed-new resolved as Option A)**: extended the same hook with a project-dir-exists guard followed by a policy-absent arm that emits a one-line stderr advisory citing `/wr-risk-scorer:update-policy`. Read-only; respects `WR_SUPPRESS_OVERSIGHT_NUDGE=1`. Recorded as ADR-047 Amendment 2026-06-28 (P379). The architect's Option B narrowing (gate the nudge on `.risk-reports/`-usage evidence to avoid firing every session on deliberately-policy-free adopters) is queued to the next `/wr-architect:review-decisions` drain.

**Release risk**: the pipeline scorer rated commit/push/release at **4/25 (Low) — within appetite (5 per ADR-086)**: the new arm is a read-only stderr advisory (Minor impact, not a blocking gate), the behavioural bats cover both predicate directions, and this is an existing-hook *modification* (no first-landing modulator). The changeset ships **clean** — no ADR-042 Rule 2 hold triggered.

**Verification status**: stays Known Error pending release + a first nudge-fire observation. This monorepo HAS a `RISK-POLICY.md`, so the new arm cannot fire in-repo; verification needs an adopter session with no policy file (or a deliberate in-repo fixture run) to observe the advisory. Known Error → Verifying on release; → Closed on the first observed fire.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Decide hang-off vs proceed → **proceed-new** (Step 2b hang-off-check short-circuited; P297 Phase 2 is parked on a different sibling-plugin axis). Recorded as ADR-047 amendment rather than a new ADR.
- [x] Design the SessionStart nudge for policy-absent — fires on `!POLICY_FILE_EXISTS`, cites `/wr-risk-scorer:update-policy`. Done.
- [x] AFK self-suppress via `WR_SUPPRESS_OVERSIGHT_NUDGE=1` per ADR-068 — inherited from the top-of-file guard. Done.
- [x] Behavioural bats: policy-absent → nudge cites update-policy; policy-absent + register-dir present → nudge wins; AFK guard → silent; non-existent dir → silent. 12/12 green.
- [x] Create reproduction test — done (the bats above, RED-then-GREEN).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P297 (likely Phase 2.5 / Phase 3 candidate)

## Related

- **P297** (`docs/problems/open/297-adr-047-governance-artefact-scaffold-should-be-sessionstart-hook-not-inline-install-updates-step.md`) — strongest hang-off candidate. Phase 1 shipped the register-missing nudge (sibling case); Phase 2 (sibling plugins design) is parked on options A/B/C/D pending substance-confirm. This ticket's substance fits naturally as a Phase in P297.
- **ADR-086** (`docs/decisions/086-risk-label-bands-rebalanced-default-appetite-5.proposed.md`) — surfaced the gap in § Consequences Bad/watch + § Related during the band-rebalance work 2026-06-25.
- **ADR-047** — governance-artefact scaffold (the parent contract).
- **ADR-068** — suite-wide oversight-nudge suppress env var.
- `packages/risk-scorer/hooks/risk-scorer-scaffold-nudge.sh` — the sibling Phase 1 hook (register-missing case).
- `packages/risk-scorer/skills/update-policy/SKILL.md` — the action the nudge would cite.
- **Step 2b hang-off-check** result: short-circuit fired (>5 broad candidates on `RISK-POLICY.md` signal); subagent dispatch skipped per ADR-032 5th invocation pattern. P297 carries the highest semantic overlap; review-problems re-evaluation is the canonical absorb-vs-proceed surface.
- Captured via /wr-itil:capture-problem; expand at next investigation.
