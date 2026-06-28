# Problem 375: Repo conflates a "named re-entry point" with a self-firing cadence — deferrals not transitively reachable from an automatic trigger rot

**Status**: Known Error
**Reported**: 2026-06-23
**Transitioned to Known Error**: 2026-06-28 (root cause documented via the 2026-06-23 4-agent reachability audit; workaround now recorded — ADR-084 SessionStart deferral census re-surfaces the rot every session. Generic-mechanism choice + rollup-parent decision queued as outstanding design questions per ADR-074.)
**Priority**: 16 (High) — Impact: 4 (High) × Likelihood: 4 (Likely). **Rated at capture from observed evidence, NOT deferred** (re-rating this ticket "at next /wr-itil:review-problems" would itself be the bug — nothing self-fires review-problems). Impact 4: defeats the repo's central value proposition (feedback loops that build intelligence) AND ships the rot-generator into adopter projects via the deferral-emitting skills. Likelihood 4: ~12 observed instances (see Related cluster); structural and recurring.
**Origin**: internal
**Effort**: L — cross-package design (authoring-time enforcement check spanning architect/itil/retrospective) + rollup-parent decision + capture-skill default fix. WSJF = (16 × 1.0) / 4 = 4.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

Agent (and repo SKILL authoring) conflates a "named re-entry point" with a self-firing cadence. Deferrals like "deferred to `/wr-itil:manage-rfc` accepted transition" or "(deferred to `/wr-architect:create-adr` canonical review)" name a skill/transition but **nothing automatically fires that skill on the deferred artefact** — it waits for a human or AFK loop to *choose* to run it, which is on-demand, which per P291/P295 (memory: `feedback_automatic_cadence_or_it_doesnt_happen`) never happens. The deferred work rots.

**Correct rot test**: a deferral is only legal if its trigger chain is **transitively reachable from something SELF-FIRING** (hook / SessionStart nudge / cron / AFK loop), not just a named on-demand command. "Defers to `/wr-itil:manage-rfc`" is illegal *unless* something self-firing runs `manage-rfc` on that RFC. The test bottoms out in: does the chain terminate in an automatic event, or in a human who has to remember?

Surfaced 2026-06-23 when the agent defended these deferrals as "names the next event that pulls the work forward" and the user corrected: **"BUT NOTHING TRIGGERS THAT WORK!!!"**

## Symptoms

- Captured-but-never-expanded RFCs/ADRs sit with `(deferred to …)` placeholders indefinitely.
- The same uncadenced-deferral failure has been re-discovered ~12+ times as single-instance tickets (see `## Related`) rather than fixed once as a class.
- This very ticket's capture flow **defaulted** Priority/Effort to `Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)` — an uncadenced deferral *and* a false-low that buried the meta-ticket at WSJF 1.5. The capture skill is a rot-generator. Re-rated by hand at capture (the correct behaviour); fixing the skill default is an Investigation Task below.

## Workaround

**In place now (partial mitigation, surfacing-only):** ADR-084 `retrospective-deferral-census.sh` (SessionStart hook, shipped 2026-06-23, commit `0e8a2787`) greps `docs/` + `packages/` markdown for deferred-work markers and re-surfaces a bounded census every session. This clones the proven class-B self-surfacing pattern (`jtbd-oversight-nudge.sh` etc.) and converts the bulk of the silent class-C rot into visible-every-session backlog — so a stranded deferral can no longer rot *invisibly*. The risk-scorer arm (`risk-scorer-scaffold-nudge.sh` now counts `**Curation**: pending review` entries, 2026-06-27) extends the same pattern to a second rot surface.

**What the workaround does NOT do:** the census *surfaces* but does not *execute* — it is a louder reminder, not a self-draining mechanism, and it does not stop new uncadenced deferrals being *authored* (the rot-generator at source). Those gaps are the open design decisions below. Until they land, the operating discipline is: rate at capture (never `Likelihood: 1 (deferred — re-rate …)`), and treat every census line as actionable backlog on the next AFK drain.

## Impact Assessment

- **Who is affected**: maintainers (rotted governance backlog), and the repo's core ethos (feedback loops that build intelligence over time) — undermined when the loop's tail never fires.
- **Frequency**: structural / pervasive (see instance cluster).
- **Severity**: (deferred to investigation)
- **Analytics**: instance-ticket count is the running tally — ~12 single-site captures of this class to date.

## Root Cause Analysis

### Investigation Tasks

- [x] Rate Priority and Effort — done at capture (Impact 4 × Likelihood 4, Effort L, WSJF 4.0); NOT deferred
- [x] Audit every deferral in shipped skills/hooks/agents — done 2026-06-23 (4-agent reachability sweep); results in `## Audit` below
- [x] **First immune-system brick SHIPPED 2026-06-23** — `retrospective-deferral-census.sh` SessionStart hook (ADR-084) clones the class-B self-surfacing pattern: greps docs/+packages/ .md for deferred-work markers and re-surfaces a bounded census every session so the bulk of the class-C rot becomes durably visible. 11/11 bats green; commit `0e8a2787`; ADR-084 commit `0b540e06` (human-oversight: unconfirmed — needs canonical ratification per P357).
- [ ] Converge `itil-fictional-defer-detect.sh` onto the shared `lib/deferral-markers.sh` vocabulary (the authoring-time / write-time half — the census is the surfacing half). Deliberately NOT done in the ADR-084 change to avoid cross-plugin coupling (ADR-002/003).
- [ ] Surface the census count in the AFK return summary (work-problems / run-retro) so it's visible on return, not just per-iter (the JTBD-006 reviewer note).
- [ ] Add the same class-B self-surfacer to the other rot surfaces the audit found: **[x] risk-scorer pending-review register — DONE 2026-06-27** (`risk-scorer-scaffold-nudge.sh` now counts `**Curation**: pending review` entries once `docs/risks/` exists instead of going silent — surfaces 51 in this repo; 11/11 bats green; AFK guard preserved; changeset seeded; architect PASS [ADR-047-amendment-note + Option-A-vs-B drain-skill question queued], jtbd PASS); **[ ] still open** — RFC/story/story-map README staleness; the architect `(deferred to …)` pointer detector + un-mask the oversight-nudge confirm-vs-expand conflation.
- [x] **Stop the biggest leak — capture default (2026-06-24)**: capture-problem + capture-story now DERIVE a real Impact×Likelihood+Effort at capture (ADR-067 silent-derivation), dropping the `Likelihood: 1 (deferred — re-rate…)` false-low entirely. ADR-032 amendment recorded. **Mid-fix correction**: the first attempt re-introduced the deferral as an ADR-026 `not estimated — no prior data` sentinel (architect-recommended) — user caught it: *"that's just another deferral."* Class-of-behaviour: agent/architect reintroduces a deferral under a new name (sentinel/placeholder/flag) when told to eliminate one; governance-tidiness reasoning overrode the user's explicit "drop the flag entirely" pin. Corrected to: always derive a real value, no marker of any kind.
- [ ] **P271 per-capture re-rate cadence is now obsolete** (every capture is rated; nothing to re-rate). Decide: (a) retire the `check-deferred-placeholder-staleness.sh` machinery as dead, or (b) replace with a genuine periodic full-backlog re-rate heartbeat (the separate "review-problems/run-retro has no self-firing cadence" problem). Do NOT fake it with a marker. Helper currently left unchanged + inert.
- [ ] Decide whether P375 becomes a rollup PARENT for the instance cluster (P295/P271/P234/P236/P184/P189/P110/P220/P253/P148) or a sibling that supersedes them.
- [ ] Fix the capture-problem (and manage-problem) deferred-placeholder default — `Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)` is both an uncadenced deferral and a false-low that buries captures; either rate at capture or make review-problems self-firing
- [ ] Create reproduction test (behavioural: a SKILL with an on-demand-only deferral fails the check; one with a self-firing trigger passes)

## Audit (2026-06-23 — 4-agent reachability sweep)

**Self-firing inventory** (the ONLY things that run without a human typing a command): SessionStart hooks (all *surfacers* — oversight nudges count unconfirmed markers, briefing surfaces Critical Points, pending-questions surfaces the AFK queue); PreToolUse write/commit gates (block bad writes); Stop hooks (the retro Stop hook only *reminds*, does not run a retro); the AFK `/wr-itil:work-problems` loop (the only thing that *executes* deferred backlog work — and it is user-initiated). **No cron exists.**

**Class A (self-executing) — correct, keep**: in-flow README refresh (same invocation); release-cadence defer to work-problems Step 6.5 (within a loop run); PreToolUse `retrospective-readme-jtbd-currency.sh` commit gate.

**Class B (self-surfacing — THE FIX TEMPLATE THAT ALREADY WORKS)**: exactly three — `jtbd-oversight-nudge.sh`, `architect-oversight-nudge.sh`, `itil-pending-questions-surface.sh`. Each counts *content/marker state* and re-surfaces it every SessionStart so it cannot silently rot. jtbd is the model (SKILL even says reject cases are "intentionally re-asked so it doesn't silently rot").

**Class C (ON-DEMAND-ONLY = ROT)** — the bulk:
- **itil**: RFC/story/story-map README staleness (only `docs/problems/README.md` has an auto-fire path); RFC `## Scope`/`## Tasks` deferred to `manage-rfc accepted`; story INVEST fields + `estimated-effort: deferred`; problem `(deferred to investigation)` placeholders; **Phase-N conditional deferral with lifted gating condition — highest severity, failure mode is silent work LOSS not just staleness (P184)**; the **capture-problem priority/effort default — largest rot generator by volume** (the very bug this ticket hit); upstream defer-and-note markers; check-upstream Phase 2; work-problems Branch 2 auto-commit; REFERENCE.md splits (ADR-054); stale "deferred until X ships" prose that has already shipped (report-upstream); review-problems P129 Phase 2.
- **architect**: capture-adr defers Considered Options/Drivers/Consequences/Confirmation to `create-adr` via a literal `(deferred to …)` pointer whose detecting consumer **was never built**; reassessment-date passing has no cadence. **The oversight nudge actively MASKS this**: `review-decisions` writes `human-oversight: confirmed` from frontmatter+title+Decision-Outcome alone, silencing the nudge forever while leaving the deferred sections frozen.
- **retrospective**: **HEADLINE — `run-retro`, the engine of the feedback loop, has no self-firing cadence; only the (user-initiated) AFK loop runs it.** Tier-3 briefing rotation; tickets-deferred (P148 lost-observation hazard); skill-md / briefing budget rotations; auto-created skeleton RFCs. Five policing scripts (`check-tickets-deferred-cause.sh`, `check-briefing-budgets.sh`, etc.) are wired to NO hook — they run only inside run-retro.
- **risk-scorer**: standing-risk register entries born `Curation: pending review` with all scoring deferred; the named `/wr-risk-scorer:review-register` drain **does not exist**; `risk-scorer-scaffold-nudge.sh` only checks directory *existence* (goes silent once stubs exist) — it stopped one step short of the jtbd pattern it cites as its model.

**Clean (0 live deferrals)**: style-guide, c4, wardley, connect, tdd, shared.

**The fix the repo already designed for and never wired**: clone the class-B pattern — a SessionStart "deferral census" that greps the repo for deferred markers (`(deferred …)`, `pending review`, stale READMEs) and re-surfaces a count + worst offenders every session. One such hook converts most of the class-C list C→B. Targeted siblings: build the architect `(deferred to …)` pointer detector; extend risk-scorer's nudge to count pending-review content; resolve run-retro's missing cadence.

## Sibling Survey (2026-06-28 — orchestrator-named tickets vs the true class)

The AFK orchestrator named P370/P371/P376/P379/P381/P386/P391/P392 as candidate rollup children. Applying the rot-test (a deferral is a class member only if it strands work whose trigger chain never reaches a SELF-FIRING event) shows **only ONE of the eight is a genuine class member.** The other seven are simply co-captured tickets from the same recent AFK sessions — ordinary defects, not self-firing-cadence rot. The *real* cluster is the one already enumerated in `## Related` (P295/P271/P234/P236/P189/P184/P110/P220/P253/P148/P291).

| Ticket | What's deferred / broken | Self-fires? | Class member? |
|--------|--------------------------|-------------|----------------|
| **P379** | Adopter with no `RISK-POLICY.md` is never auto-interviewed; `risk-scorer-scaffold-nudge.sh` silent-skips the policy-absent case. Intent ("auto-interview if policy missing") has **no self-firing surface**. Ticket itself defers the absorb/sibling call "at review time via review-problems" — an uncadenced deferral. | **No** | **YES — direct class member.** Same shape as the risk-scorer arm already fixed under this ticket (count content, don't silent-skip). Fix = extend the nudge to the policy-absent predicate. |
| P370 | `claude -p` iter ends turn waiting on a backgrounded task, no auto-resume → staged work lost. | Loop self-fires, but the failure is single-shot-CLI non-resumption, not deferred-marker rot. | No — adjacent (work-loss), different root cause. |
| P371 | I13 gate has no branch for "existing RFC is the fix vehicle but trace edge unwired" → auto-creates duplicate RFC. | n/a — gate-branch logic bug. | No. |
| P376 | Catchup scanner is outbound-only; misses the inbound `Origin: inbound-reported` direction. | n/a — scanner coverage/parity gap. | No. |
| P381 | update-policy Step 6a SKILL prose lacks a paired promptfoo eval (R009 floor). | n/a — test-coverage gap. | No. |
| P386 | review-problems Step 4.6 cites a dangling `work-problems Step 6.5` cross-reference. | n/a — broken doc cross-reference. | No. |
| P391 | oversight-nudge bats non-hermetic against inherited `WR_SUPPRESS_OVERSIGHT_NUDGE`. | n/a — test-hermeticity flake. | No. |
| P392 | `awk -v section="$multiline"` fails on BSD awk (macOS). | n/a — shell portability bug. | No. |

**Finding:** the orchestrator's sibling list is mostly noise — recapture risk if it drives a rollup. Fold **P379** under this ticket's class (or wire it as the next risk-scorer-nudge arm); leave the other seven as independent tickets. The authoritative child cluster remains `## Related`.

## Remedy option-ladder — generic self-firing-cadence mechanism (DESIGN DECISION — queued, not built per ADR-074)

The class needs a generic mechanism so the rot is fixed once, not re-discovered per instance. Four rungs, cheapest-first:

- **Option A — SessionStart "deferral census" surfacer (class-B clone).** *Already partially shipped* (ADR-084 census + risk-scorer-nudge arm). Greps the repo for deferred markers and re-surfaces a count + worst offenders every session. **Pro:** zero new infra; proven pattern; adopter-portable; converts silent C→B. **Con:** surfaces but does not execute — a louder reminder, still relies on a human/AFK loop to act; does not stop new deferrals being authored. *Mitigates rot-invisibility, not rot.*
- **Option B — work-problems Step 0x "drain stranded-deferrals" pre-flight.** A loop pre-flight that scans for named-but-uncadenced re-entry points and enqueues them as actionable backlog. **Pro:** self-*executing* within the AFK loop (closes the execute-gap Option A leaves). **Con:** only fires when the loop runs (still user-initiated, not a true cron); pre-flight latency; false-positive scan risk.
- **Option C — authoring-time enforcement gate (PreToolUse / converge `itil-fictional-defer-detect.sh` onto shared `lib/deferral-markers.sh`).** A write-time check that REJECTS a new deferral whose trigger chain is not transitively reachable from a self-firing trigger. **Pro:** the only option that attacks the root cause — stops new C-class deferrals at source. **Con:** hardest to build (needs a reachability model of the trigger graph); false-block risk on legitimate class-A self-executing deferrals; cross-plugin coupling concern (ADR-002/003).
- **Option D — true cron / scheduled cadence.** A real scheduler that periodically fires review-problems / run-retro / census drains. **Pro:** the only genuinely self-firing-without-any-human option. **Con:** no cron infra exists; adopter-environment portability concern (adopters may lack a scheduler); heaviest lift; the repo has a standing ban on ScheduleWakeup-style self-scheduling for AFK iters.

**Leaning (for the human's decision, not committed):** A is the visible-every-session floor and is already live; C is the durable root-cause fix and is where the remaining design effort belongs (with B as a cheaper interim execute-gap closer). D is out of appetite/infra. The A+C pair is the likely shape, but the choice is a genuine ≥2-option decision → see Outstanding Questions.

## Outstanding Questions (queued per ADR-074 — do NOT build until ratified)

1. **`category:direction` — generic-mechanism choice.** Which rung(s) of the A/B/C/D ladder above do we commit to? A is partially shipped; the open call is whether to invest in C (authoring-time enforcement gate, root-cause) now, add B (loop pre-flight execute-gap) as an interim, or stop at A (surfacing-only). Warrants a `/wr-architect:create-adr` once chosen. *Trade-offs briefed in the option-ladder above.*
2. **`category:direction` — rollup-parent decision.** Should P375 become a rollup PARENT for the `## Related` cluster (P295/P271/P234/P236/P189/P184/P110/P220/P253/P148/P291), or a sibling that supersedes them? Plus: fold P379 in as the next risk-scorer-nudge arm (sibling survey above). Affects backlog accounting (closing children vs leaving them as tracked instances).

## Dependencies

- **Blocks**: (none yet)
- **Blocked by**: (none)
- **Composes with**: `itil-fictional-defer-detect.sh` hook (existing partial enforcement)

## Related

This is the **systemic / meta** ticket for a class previously captured only as single instances. Candidate rollup children (≥1 shared signal: P291/P295/cadence/self-firing/on-demand-only; >5 candidates so hang-off-check skipped per capture-problem sub-step 2b candidate-cap, recorded here for `/wr-itil:review-problems` re-evaluation):

- **P295** (verifying) — ADR-043 deep-context-analysis needs automatic cadence not on-demand-only. Direct instance.
- **P271** (verifying) — review-problems not auto-fired when needed; user has to remember. Direct instance.
- **P234** — agent defers framework-required mechanical work with rationalization; "defer is fictional". Behavioural instance.
- **P236** — iter queues proceed-vs-defer as direction when framework trigger already fired.
- **P189** — agent invents deferred framing on tracked phases without user deferral direction.
- **P184** — agent treats conditionally-deferred work as permanently out of scope.
- **P110** — risk register has no passive trigger; slash-command alone (partial JTBD-001).
- **P220** — manage-problem has no cadence for checking upstream-bound tickets.
- **P253** — no house-cleaning cadence for cruft/deprecation removal.
- **P148** — agent defers ticket creation to retro summary instead of immediately invoking manage-problem.
- **P291** — root-cause sibling to P295 (cadence-or-it-doesn't-happen).
- Memory `feedback_automatic_cadence_or_it_doesnt_happen` — the prior statement of this root cause.
- `packages/itil/hooks/itil-fictional-defer-detect.sh` — existing partial enforcement; the authoring-time check likely extends this.

(captured via /wr-itil:capture-problem; expand at next investigation)
