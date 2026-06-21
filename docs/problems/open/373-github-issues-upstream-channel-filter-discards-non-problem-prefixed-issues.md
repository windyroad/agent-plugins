# Problem 373: github-issues upstream-channel filter discards non-`[problem]`-prefixed issues — ALL issues are potential problems

**Status**: Open
**Reported**: 2026-06-21
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: corrective-feedback (this session, /wr-itil:review-problems Step 4.5c)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

The `docs/problems/.upstream-channels.json` `github-issues` channel uses `title_prefix: "[problem]"` as the de-facto report filter (labels were removed 2026-05-15 as unreliable — repo has no `problem-report` label configured, and the `problem-report.yml` template's auto-applied labels also don't exist). The Step 4.5c poll filters `gh issue list` results down to issues whose title starts with `[problem]`.

User correction 2026-06-21 (verbatim): *"FFS it doesn't need a `[problem]` in the title. ALL issues are potential problems"*. The semantic gap: ANY open issue against the project is a potential problem report — the template prefix is a maintainer convention, not a reporter obligation. Issues filed without the template (the common case for one-shot reporters who hit `New Issue` and write plain prose) bypass discovery entirely.

Witnessed regression: issue #273 (filed 2026-06-21T10:38:33Z, plain title "wr-risk-scorer bootstrap-catalog: ID allocation fails once R008+ exists; README hardcodes the suite name") was silently skipped by today's Step 4.5c poll. The same poll surfaced 50 `[problem]`-prefixed issues correctly. The defect missed a legitimate bug report carrying two real fixes.

Fix options for investigation:

- (a) **Remove the filter entirely** — poll ALL open issues; let the JTBD-alignment + dual-axis-risk classifiers (Step 4.5e steps 2–3) filter at the assessment-pipeline boundary instead of the channel boundary.
- (b) **Broaden the matcher** — match `[problem]` OR `[bug]` OR no-prefix-treated-as-default; keeps some signal-filtering but doesn't discard the no-prefix class.
- (c) **Tier the filter** — match `[problem]`-prefixed as Tier 1 (auto-accept into discovery), no-prefix as Tier 2 (surface to maintainer for manual triage decision). Lower-friction than (a), higher-fidelity than (b).

The `$filter-note` annotation already in `.upstream-channels.json` (added 2026-05-15) foreshadowed this gap with the placeholder "missing-labels-and-channels-config-drift" ticket that never materialised — this ticket is the materialisation.

JTBD-301's acknowledgement contract is the load-bearing concern: inbound reports without the template prefix never enter the cache + never get an audit-log entry + never receive an acknowledgement comment.

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

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: ADR-062 (inbound-discovery pipeline contract); JTBD-301 (plugin-user no-pre-classification persona constraint)

## Related

(captured via /wr-itil:capture-problem during /wr-itil:review-problems Step 4.5c via direct user correction; expand at next investigation)

- **Hang-off-check dispatch skipped**: the mechanical pre-filter surfaced 27 candidates (>5 cap), so per the capture-problem latency short-circuit the fresh-context `wr-itil:hang-off-check` subagent was not dispatched; candidate context recorded here for `/wr-itil:review-problems` re-evaluation. Most-relevant candidates:
  - **P229** — `inbound-discovery ack comments are bureaucratic not verdict-shaped (JTBD-301 violation)`; closest sibling on the JTBD-301 acknowledgement-contract axis (different surface — ack-comment shape vs channel-filter inclusion). This ticket is about whether ANY ack fires; P229 is about whether the ack that fires is well-shaped.
  - **P252** — `reconcile-readme false-positive parses Inbound Upstream Reports matched-local-ticket column as Verification Queue`; render-time bug on the same inbound-discovery surface but a different layer (README render, not channel poll).
  - **P249** — `no process for reporters to check responses (symmetric to inbound-discovery)`; the outbound symmetry — this ticket is the inbound completeness gap, P249 is the outbound completeness gap.
  - **P229 + P252 + P249 form an inbound-discovery cluster** worth a `/wr-itil:review-problems` cluster-pass evaluation.
- **#273** (https://github.com/windyroad/agent-plugins/issues/273) — the witness. Filed 2026-06-21T10:38; plain title carrying two real defects (octal eval bug in `extract-risks-from-reports.sh`; hardcoded "Windy Road Agent Plugins suite" in adopter risks README); missed by today's poll.
- **P164** (`docs/problems/known-error/164-...md`) — Phase 2 reopen surfaced by #273 (octal bug, same class as P164's original 6 SKILL.md formulas, missed by the original `\$\(\(\s*\$\(echo` grep pattern).
- **P374** (`docs/problems/open/374-...md`) — sibling capture from #273 (hardcoded-suite-name defect in adopter-generated `docs/risks/README.md`).
- **ADR-062** (`docs/decisions/062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md`) — the discovery pipeline contract this defect undermines.
- **`docs/problems/.upstream-channels.json` `$filter-note`** (2026-05-15 label-removal annotation) — pre-foreshadowed this gap.
- **JTBD-301** (`docs/jtbd/plugin-user/JTBD-301-report-problem-without-pre-classifying.proposed.md`) — the acknowledgement contract violated when reports silently fail to enter the cache.
- **Class**: filter-too-narrow / report-loss-at-channel-boundary; CLAUDE.md P078 capture-on-correction discipline drove this ticket.

## Change Log

- **2026-06-21** — Opened during `/wr-itil:review-problems` Step 4.5c via direct user correction ("FFS it doesn't need a `[problem]` in the title. ALL issues are potential problems"). Witness: #273 (filed same day) silently missed by today's poll. Skeleton ticket; fix strategy deferred to investigation (a/b/c option ladder).
