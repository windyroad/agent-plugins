# Problem 373: github-issues upstream-channel filter discards non-`[problem]`-prefixed issues — ALL issues are potential problems

**Status**: Verification Pending
**Reported**: 2026-06-21

## Fix Released

Released 2026-06-28 in `@windyroad/itil@0.54.6` (changeset `p373-github-issues-non-discarding-poll.md`, graduated from holding + shipped this session — version PR #297). Step 4.5c now polls `--state open` with no `[problem]`-prefix discard; `title_prefix` demoted to a soft rank/annotate signal; the Step 4.5d/4.5e classifiers are the de-facto filter (verdict per report). Adopters opt back into the hard channel-boundary filter via `"strict_title_prefix": true`. Paired promptfoo cases (non-discarding-default + strict-opt-in) are GREEN (review-problems suite 9/9). Transitioned K→V manually (P389 — the changeset carried no `**Release vehicle**` seed so the post-release enumerator skipped it).

**Awaiting user verification** — confirm Step 4.5c surfaces a non-`[problem]`-prefixed real inbound issue (e.g. the missed #273) and routes it to a verdict rather than discarding it.
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: corrective-feedback (this session, /wr-itil:review-problems Step 4.5c)
**Effort**: M (confirmed — SKILL.md Step 4.5c + channels config + paired eval cases)
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

The `/wr-itil:review-problems` Step 4.5c github-issues poll discarded any open issue whose title did not start with `[problem]`. Two compounding defects:

1. **Filter-too-narrow at the channel boundary.** ALL open issues are potential problem reports (JTBD-301: the plugin-user persona has low context on repo internals and must not pre-classify). A one-shot reporter who hits "New Issue" and writes plain prose never adds the `[problem]` template prefix (it is a maintainer convention auto-inserted by `problem-report.yml`), so their report was dropped before reaching the assessment pipeline — never cached, never acknowledged (breaks the ADR-062 / JTBD-301 row-6 contract that every submitted report receives a verdict). Witness: #273.

2. **Stale poll command.** SKILL.md line 197 read `gh issue list --repo <repo> --label <label> --state open ...`, but the `label` field was removed from `.upstream-channels.json` on 2026-05-15 — the config carries `title_prefix` instead. The SKILL command was internally inconsistent with its own config schema.

The `$filter-note` already in `.upstream-channels.json` (2026-05-15) had foreshadowed this with the placeholder ticket "missing-labels-and-channels-config-drift" that never materialised; P373 is the materialisation.

### Fix Strategy

Option (a) (remove the hard filter) + adopter opt-in, per the captured option ladder:

- **Step 4.5c**: poll `gh issue list --repo <repo> --state open --json number,title,author,createdAt,body,labels --limit 100` — no title-prefix/label hard discard. `title_prefix` demoted to a SOFT rank/annotate signal; the Step 4.5d semantic-comparator + Step 4.5e JTBD-alignment + dual-axis-risk classifiers are the de-facto filter at the assessment-pipeline boundary.
- **Adopter opt-in**: `"strict_title_prefix": true` on a channel restores the hard channel-boundary pre-filter (`--search "<title_prefix> in:title"`). Default (absent/false) polls all open issues.
- **Step 4.5a bootstrap**: stop prompting for the removed `label` field; github-issues needs only `repo`.
- **`.upstream-channels.json`**: refresh the `$filter-note`; add the `strict_title_prefix` flag (default false).
- **Behavioural test**: two paired promptfoo cases (non-discarding default + strict opt-in) in `packages/itil/skills/review-problems/eval/promptfooconfig.yaml`.

Architect PASS (within-contract config extension, no new ADR — ADR-062 already designates the classifiers as the de-facto filter). JTBD PASS (direct JTBD-301 alignment).

**Release vehicle**: docs/changesets-holding/p373-github-issues-non-discarding-poll.md (held per R009 — graduates with the review-problems SKILL-prose cohort when the paired promptfoo eval runs GREEN).

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (Effort confirmed M; Priority re-rate still deferred to review-problems WSJF pass)
- [x] Investigate root cause
- [x] Create reproduction test (paired promptfoo eval cases)

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
- **2026-06-27** — Worked via `/wr-itil:work-problems` AFK loop. Root cause confirmed (filter-too-narrow at channel boundary + stale `--label` command). Fix implemented (option a + `strict_title_prefix` adopter opt-in): Step 4.5c non-discarding poll, `title_prefix` demoted to soft signal, Step 4.5a bootstrap `label`-prompt removed, `.upstream-channels.json` `$filter-note` + flag, two paired promptfoo eval cases. Architect PASS + JTBD PASS. Changeset held per R009 (review-problems prose cohort with P229). Open → Known Error.
