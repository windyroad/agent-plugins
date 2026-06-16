# Problem 363: Inbound-reported tickets never receive fix-released verdict on originating issue

**Status**: Known Error
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

Inbound-reported tickets reaching fix-released never deliver the JTBD-301 verdict to the originating inbound issue. ADR-062's assessment pipeline defines intake-time branches only (acknowledge / pushback / policy-violation-close); /wr-itil:update-upstream owns the outbound axis only (consumes the `## Reported Upstream` section written by report-upstream). A ticket with `Origin: inbound-reported (#NN)` carries the inbound issue URL only as a `- **Reported Upstream**:` bullet under `## Related`, so even transition-problem Step 7b's unconditional update-upstream dispatch no-ops — the reporter never hears the fix shipped. Witnessed 2026-06-11 AFK iter 2: P220 K→V left #63 un-notified; P211 V→Closed left #97 un-notified (and unclosed). JTBD-301 line 31 promises every report is "eventually responded to with a verdict (fix released / parked / duplicate / won't-fix / policy-violation)" — no surface executes the fix-released verdict leg.

## Symptoms

A ticket created by ADR-062's safe-and-valid branch carries `**Origin**: inbound-reported (#NN)` plus a `matched_local_ticket` cache entry, but **no `## Reported Upstream` section**. When that ticket later transitions Open → Known Error → Verifying (fix released), the transition-time update-upstream dispatch (transition-problem Step 7 / manage-problem Step 7) runs `grep -q '^## Reported Upstream'` against the ticket, finds nothing, and skips the dispatch entirely. The reporter who filed the inbound issue never receives the fix-released verdict JTBD-301 promises. Witnessed 2026-06-11: P220 K→V left #63 silent; P211 V→Closed left #97 silent and unclosed.

## Workaround

Manually `gh issue comment <inbound-issue> --body "..."` the fix-released verdict by hand at transition time. `/wr-itil:update-upstream <NNN>` does NOT help — its Step 1 no-op-exits because the inbound ticket has no `## Reported Upstream` section for it to read (it parses `- **URL**:` lines under that section, not the `**Origin**: inbound-reported (#NN)` field).

## Impact Assessment

- **Who is affected**: plugin-user persona (inbound reporters who file `problem-report` issues against an adopter repo). Maintainers running the AFK loop unknowingly ship fixes without notifying reporters.
- **Frequency**: every inbound-reported ticket that reaches fix-released without having ALSO been routed through `/wr-itil:report-upstream` (which would write the section). In this monorepo: ≥2 confirmed (P220 #63, P211 #97).
- **Severity**: Medium — silent verdict-drop breaks the JTBD-301 "eventually responded to with a verdict" promise; reporters re-file or churn, eroding the inbound-discovery trust loop.
- **Analytics**: detectable by diffing `## Inbound Upstream Reports` cache entries (`safe-and-valid-local-ticket-created`) whose `matched_local_ticket` reached `closed/` against the originating issue's comment history — no fix-released comment present.

## Root Cause Analysis

**Reconciled framing (supersedes the capture-time framing).** P363's original claim — "JTBD-301 fix-released verdict leg has no executing surface" — is **incomplete**. The executing surface DOES exist: `/wr-itil:update-upstream` posts the fix-released lifecycle comment, and transition-problem/manage-problem Step 7 already dispatch it unconditionally on transition. The real defect is a **direction asymmetry in what feeds that surface**:

- **Outbound path works**: `/wr-itil:report-upstream` Step 7 writes a `## Reported Upstream` SECTION (`- **URL**: <url>` lines). Transition Step 7's `grep -q '^## Reported Upstream'` matches → update-upstream Step 1 reads the section → posts the verdict. ✅
- **Inbound path is starved**: ADR-062's safe-and-valid branch (`review-problems` Step 4.5e step 6, `packages/itil/skills/review-problems/SKILL.md:271`) records the originating issue ONLY as the `**Origin**: inbound-reported (#NN)` field + cache entry. It never writes a `## Reported Upstream` section. So the transition-time grep misses and update-upstream is never invoked. ❌

**Iter-3 counter-witness corrected.** P228 received its verdict NOT because of a `- **Reported Upstream**:` *bullet* under `## Related` (iter-3's phrasing was imprecise), but because it carried a `## Reported Upstream` *SECTION* — update-upstream Step 1 and the transition grep both key off the SECTION (`^## Reported Upstream` + `- **URL**:` lines), never the `## Related` bullet. P228 had been routed through report-upstream's outbound write. The capture-time `## Related` bullet form is irrelevant to verdict delivery; iter-3 finding (b) ("teach update-upstream Step 1 to recognise the bullet") rests on a misread and is withdrawn.

**New finding — naive section-reuse is unsafe (cross-surface contamination).** Iter-3 fix shape (a) ("ADR-062 intake writes the originating issue into the `## Reported Upstream` contract at ticket creation") cannot be applied verbatim, because `## Reported Upstream` is a **direction-specific, multi-consumer** contract surface meaning *"we filed this issue on someone ELSE's repo"*:
  1. `/wr-itil:check-upstream-responses` (P249) scans `docs/problems/**` for `## Reported Upstream` and polls each URL via `gh issue view` as an OUTBOUND issue we filed elsewhere (`packages/itil/skills/check-upstream-responses/SKILL.md:16,65,114`). Writing an inbound own-repo issue there would make P249 poll our own issue as if it were upstream — contamination.
  2. `/wr-itil:update-upstream` is outbound-worded ("Post a lifecycle-update comment to an **upstream** issue"); its section name and disclosure-path/cross-reference fields don't apply to a self-repo inbound issue.

**Fix-shape options (genuine ≥2-option design decision — needs human substance-confirm per ADR-074; NOT applied this iteration):**
  - **(a) Reuse `## Reported Upstream` at inbound intake** — minimal surface, but semantically incoherent (own-repo issue in an "upstream" section) and contaminates P249's outbound poller. **Not recommended.**
  - **(b) Teach the verdict machinery to also consume `**Origin**: inbound-reported (#NN)`** — extend update-upstream Step 1 + both transition-time grep pre-checks (transition-problem + manage-problem) to recognise the Origin field and resolve the inbound issue URL (from the field or the cache). Keeps inbound/outbound data shapes distinct; touches 3 surfaces + needs inbound-appropriate verdict wording.
  - **(c) Dedicated inbound-verdict surface** — write a distinct back-link section at intake (e.g. `## Reported By` / `## Inbound Origin`) consumed by an inbound-verdict dispatch (new or branched from update-upstream) with downstream-reporter-appropriate comment templates. Cleanest semantics + no P249 contamination; most surface area.

  Recommendation leans (b) or (c). This is a structural decision with cross-surface (P249, update-upstream wording, ADR-062 intake) implications — surfaced here and queued for human substance-confirm; an ADR may be warranted before implementation.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (investigation suggests Effort M — design-decision-gated, 1–3 surfaces depending on chosen option)
- [x] Investigate root cause — direction asymmetry: inbound intake (review-problems Step 4.5e step 6) doesn't write the `## Reported Upstream` section the existing update-upstream verdict surface consumes
- [ ] Human substance-confirm of fix shape (a) / (b) / (c) — queued (ADR-074); may warrant an ADR
- [ ] Implement chosen fix shape + behavioural test (inbound ticket at fix-released → verdict comment posted to originating issue)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check skipped — candidate-cap short-circuit (P346 sub-step 2b)**: mechanical pre-filter on shared signals (ADR-062 / /wr-itil:update-upstream / /wr-itil:report-upstream / JTBD-301) matched 31 open/verifying candidates (> 5 cap); subagent dispatch skipped per SKILL contract; re-evaluate absorption at next /wr-itil:review-problems. Nearest candidates by scope: P229 (inbound-discovery ack comments not verdict-shaped — intake-time ack shape, verifying), P249 (reporters can't check for responses — outbound polling axis, verifying), P129 (inbound pipeline lacks version-aware classification — intake-time classification, known-error), P079 (inbound discovery leg, closed), P080 (outbound lifecycle updates — /wr-itil:update-upstream, known-error). None covers the transition-time inbound-verdict leg this ticket names.
- **Witnesses**: P220 (manage-problem has no cadence for checking upstream-bound tickets) K→V 2026-06-11 commit 345880d8 — inbound issue #63 silent; P211 (work-problems iter-prompt re-grounding) V→Closed 2026-06-11 commit 6635120f — inbound issue #97 silent and still open upstream.
- **Counter-witness + contract gap (2026-06-11, AFK iter 3)**: P228 (inbound #42) DID receive its fix-released verdict at K→V — via `/wr-itil:update-upstream 228` in the manage-problem Step 7 P080 block — because the capture had recorded the originating issue as `- **Reported Upstream**: <url>` in `## Related`. Two findings: (a) the existing outbound surface CAN execute the inbound verdict leg whenever the originating-issue URL is recorded in Reported Upstream form, so one fix shape is "ADR-062 intake writes the originating issue into the Reported Upstream contract at ticket creation"; (b) `/wr-itil:update-upstream` Step 1's no-op exit checks for a `## Reported Upstream` SECTION only — the capture-time BULLET form (`- **Reported Upstream**:` in `## Related`, which manage-problem's already-noted check recognises) would no-op-exit. The agent proceeded on substance this iter; an adopter following the SKILL verbatim would have silently skipped the verdict. Fix should recognise both forms (mirror the already-noted check's dual-form grep).
- **Root-cause investigation + reconciliation (2026-06-16, AFK iter 34) → Known Error**: full surface trace (ADR-062 intake, update-upstream, report-upstream, transition-problem/manage-problem Step 7, manage-problem already-noted check, JTBD-301, check-upstream-responses). Root cause confirmed as a **direction asymmetry** (see RCA): the verdict surface (`update-upstream`) exists and fires for outbound tickets; inbound intake (`review-problems` Step 4.5e step 6, `SKILL.md:271`) never writes the `## Reported Upstream` section that transition-time grep + update-upstream Step 1 consume. **Corrections to iter-3**: (i) update-upstream keys off the `## Reported Upstream` *SECTION*, not the `## Related` bullet — P228 worked because it had the section (it had been report-upstream'd), so iter-3 finding (b)'s "bullet form" premise is withdrawn; (ii) iter-3 fix shape (a) is unsafe — `## Reported Upstream` is consumed by `/wr-itil:check-upstream-responses` (P249) as an OUTBOUND poll target, so writing an inbound own-repo issue there contaminates that poller, and update-upstream's wording/section-name are outbound-specific. Fix is now a genuine ≥2-option design decision ((a)/(b)/(c) in RCA); **queued for human substance-confirm per ADR-074, NOT built this iteration** (AFK born-proposed-unconfirmed-decision skip). May warrant an ADR. No code change shipped; ticket transitioned Open → Known Error (root cause identified, permanent fix design-gated).
