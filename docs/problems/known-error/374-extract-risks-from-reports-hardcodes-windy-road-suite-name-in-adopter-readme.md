# Problem 374: `extract-risks-from-reports.sh` hardcodes "Windy Road Agent Plugins suite" branding in the adopter-generated `docs/risks/README.md`

**Status**: Known Error
**Reported**: 2026-06-21
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: inbound-reported (#273)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The `scripts/extract-risks-from-reports.sh` bootstrap helper (run by `/wr-risk-scorer:bootstrap-catalog`) emits a heredoc at line 350 containing the literal string:

> This directory is the persistent risk register for the Windy Road Agent Plugins suite.

In an adopter project the generated `docs/risks/README.md` should name the adopter project (derive from repo-root basename) or use project-neutral phrasing — not the publishing suite's brand. The file is overwritten on every run so a manual maintainer correction in an adopter tree does not survive a subsequent `bootstrap-catalog` invocation.

Reported by external user via #273 (https://github.com/windyroad/agent-plugins/issues/273): *"In an adopter project the generated `docs/risks/README.md` should name the adopter, not the suite, and it is overwritten on every run (so a manual correction does not survive)."* The reporter ran `/wr-risk-scorer:bootstrap-catalog` against an adopter project and observed the hardcoded brand text in their generated README.

This is the **second defect** in #273. The first (octal eval bug in the same script's ID-allocation path) is folded into P164 as Phase 2 per user direction 2026-06-21.

Class: **published-artefacts-reference-repo-internal-text** — sibling of P151 / P153 / P219 / P317 (all "shipped artefact contains source-monorepo-only text/paths"). Same root-cause family: source-repo dogfooding masks the bug because in the source monorepo the brand name IS accurate; the friction only surfaces in adopter installs. P317 closed this class on the `source: packages/...` path-resolution axis; P374 is the same class on the **brand-name-in-prose** axis.

Fix candidates for investigation:

- (a) **Derive project name** from `git rev-parse --show-toplevel | xargs basename` (or `npm pkg get name` from `package.json`) at bootstrap time; substitute into the heredoc.
- (b) **Project-neutral phrasing** — replace the suite-naming sentence with neutral wording (e.g. "This directory is the persistent risk register for this project.") that needs no substitution and reads correctly in both source-monorepo and adopter contexts.
- (c) **Env-var override** — accept `RISK_REGISTER_PROJECT_NAME` env-var; default to neutral phrasing when unset.

Option (b) is the simplest no-substitution path and aligns with the published-artefacts discipline (don't ship the source-monorepo's vocabulary; ship neutral language an adopter can adopt as-is). Architect/JTBD review needed before pinning.

## Symptoms

(deferred to investigation)

## Workaround

Adopter maintainer manually edits `docs/risks/README.md` after each `bootstrap-catalog` run to replace the brand name with their project's name — but the edit is overwritten on the next run. Effectively no durable workaround; the maintainer must accept either the wrong branding in committed README or never re-run bootstrap-catalog.

## Impact Assessment

- **Who is affected**: Every adopter project using `/wr-risk-scorer:bootstrap-catalog` to (re-)generate `docs/risks/README.md`.
- **Frequency**: Every bootstrap-catalog run that lands the heredoc — at least once per project (initial setup) and any subsequent re-run.
- **Severity**: Moderate — published-artefacts violation; ships the publisher's brand into adopter-controlled prose; erodes trust in the plugin's adopter-portability claim.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Decide fix candidate (a) / (b) / (c) — **(b) project-neutral phrasing chosen** (2026-06-22). Architect/JTBD/voice-tone/style-guide gates all PASS; no substitution code, reads correctly in both source-monorepo and adopter contexts.
- [x] Survey the broader `scripts/extract-risks-from-reports.sh` heredoc for any other source-monorepo-only language — **done** (2026-06-22). `grep -niE "windy road|windyroad|agent plugins suite|this suite"` over the script returns only line 350. The other README-body references (`docs/problems/`, `docs/decisions/ADR-<NNN>`, `per ADR-059`) are generic-shape framework references, not brand leaks — left as-is.
- [x] Create reproduction test — **done** (2026-06-22). Behavioural bats test `emitted README does NOT leak the publishing-suite brand name (P374 published-artefacts)` in `packages/risk-scorer/scripts/test/extract-risks-from-reports.bats` asserts the `Windy Road Agent Plugins suite` substring is absent from the emitted README and the neutral phrasing is present.
- [x] Audit other bootstrap scripts in the suite for the same class — **done** (2026-06-22). `grep -rliE "windy road agent plugins|windy road technology"` over `packages/*/scripts/` + `scripts/` (excluding tests) returns no matches. No sibling defects.

## Fix Strategy

**Applied (2026-06-22) — option (b) project-neutral phrasing.**

Root cause: `packages/risk-scorer/scripts/extract-risks-from-reports.sh` line 350 hardcoded the publishing suite's brand string in the README heredoc emitted into adopter-controlled `docs/risks/README.md`. Source-repo dogfooding masked it (in the source monorepo the brand name is accurate).

Fix: single one-line Edit of the heredoc — `for the Windy Road Agent Plugins suite.` → `for this project.`. No substitution code; reads correctly in both source-monorepo and adopter contexts. Behavioural bats test added asserting the brand substring is absent from (and the neutral phrasing present in) the emitted README. Sibling-script audit clean. Single commit per ADR-014. No ADR amendment needed (existing published-artefacts discipline — P317's structural-prevention precedent — covers the substantive policy; the fix is mechanical conformance).

All four edit gates (architect / JTBD / voice-tone / style-guide) returned PASS for the change.

## Dependencies

- **Blocks**: (none directly; published-artefacts-discipline carries the broader programmatic intent)
- **Blocked by**: (none)
- **Composes with**: P373 (the channel-filter ticket that would have surfaced #273 earlier had the filter been broader — sibling capture); the P151/P153/P219/P317 cluster (same published-artefacts class, different surfaces).

## Related

(captured via /wr-itil:capture-problem during /wr-itil:review-problems Step 4.5c, routed from #273 per user direction 2026-06-21; expand at next investigation)

- **Hang-off-check dispatch skipped**: the mechanical pre-filter surfaced 26 candidates (>5 cap), so per the capture-problem latency short-circuit the fresh-context `wr-itil:hang-off-check` subagent was not dispatched; candidate context recorded here for `/wr-itil:review-problems` re-evaluation. Most-relevant candidates (the published-artefacts cluster):
  - **P151** (`docs/problems/verifying/151-...md`) — published-skills-reference-repo-relative-script-paths. Same class on the script-path axis.
  - **P153** (`docs/problems/verifying/153-...md`) — published-skills-enumerate-repo-relative-directories. Same class on the directory-enumeration axis.
  - **P219** (`docs/problems/verifying/219-...md`) — manage-problem skill.md uses repo-relative script path that fails for plugin-installed users. Same class on the script-path axis.
  - **P317** (closed via RFC-009; cited in `docs/problems/closed/317-...md`) — capture-skills-create-gate-marker-sources-repo-relative-lib-paths-fail-in-adopter-installs. The class-of-class closer; established the structural-prevention lint pattern that P374 should follow.
  - **P137** (`docs/problems/verifying/137-...md`) — published-plugin-artifacts-reference-internal-ids. Adjacent class (internal IDs in prose vs brand-name in prose); cluster-related.
  - **P168** (`docs/problems/verifying/168-...md`) — risk-scorer-doesnt-consume-catalog-or-bootstrap. Adjacent surface (same `bootstrap-catalog` helper that emits the heredoc); cluster-related.
  - **P151+P153+P219+P317+P374 form a published-artefacts cluster** worth a `/wr-itil:review-problems` cluster-pass evaluation.
- **#273** (https://github.com/windyroad/agent-plugins/issues/273) — origin. Filed by external user 2026-06-21T10:38; bundles this defect with the unrelated P164-class octal eval bug. Inbound report; first acknowledged via gated `gh issue comment` cross-referencing P164 + P374 (this iter).
- **P164** (`docs/problems/known-error/164-...md`) — the OTHER defect in #273 (octal eval bug); reopened Verifying → Known Error with Phase 2 scope expansion per user direction 2026-06-21.
- **P373** (`docs/problems/open/373-...md`) — sibling capture from this iter (channel-filter-too-narrow that caused #273 to slip past today's poll).
- **Class**: published-artefacts-reference-repo-internal-text; covered by the broader published-artefacts-no-repo-internal-references discipline established by P317's structural-prevention lint precedent.

## Change Log

- **2026-06-21** — Opened during `/wr-itil:review-problems` Step 4 routing of inbound issue #273 per user direction. Skeleton ticket; fix strategy deferred to investigation ((a) derive / (b) neutral phrasing / (c) env-var override ladder). Captured via `/wr-itil:capture-problem` with `--jtbd=JTBD-101 --persona=plugin-developer` pre-resolution.
- **2026-06-22** — AFK `/wr-itil:work-problems` iter. Applied option (b) project-neutral phrasing: edited `extract-risks-from-reports.sh:350` heredoc to drop the brand string, added a behavioural bats absence test (suite now 22 tests, all green), swept the full script + sibling bootstrap/extract scripts for the class (only line 350 affected; no sibling defects). Architect/JTBD/voice-tone/style-guide gates all PASS. Transitioned Open → Known Error (root cause confirmed, workaround documented, fix applied). Verification pending release of `@windyroad/risk-scorer`.
