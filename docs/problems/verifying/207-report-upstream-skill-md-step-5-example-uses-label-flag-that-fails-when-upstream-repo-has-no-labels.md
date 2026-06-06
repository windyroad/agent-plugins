# Problem 207: report-upstream SKILL.md Step 5 example uses --label flag that fails when upstream repo has no labels

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Fix shipped

Known Error → Verification Pending fold-fix per ADR-022 P143 amendment (2026-06-06, AFK `/wr-itil:work-problems` iter).

`packages/itil/skills/report-upstream/SKILL.md` Step 5 example no longer passes `--label "${MATCHED_TEMPLATE_LABEL_IF_ANY}"` to `gh issue create`. The flag is replaced with an inline note explaining that `gh issue create --label <name>` hard-fails with `could not add label: '<name>' not found` on any upstream that has not pre-created the matching label, and pointing at the matched issue template's YAML `labels:` frontmatter as the authoritative source of labels (GitHub auto-applies those labels on submit). For the structured-default (template-less) path, the note records that labels are omitted entirely so the upstream maintainer's existing routing handles triage.

Architect PASS (no new ADR — example-fidelity fix inside ADR-024 Step 5 surface; ADR-028 voice-tone gate keys on the `gh issue create` subcommand, not on `--label` argv, so the gate firing surface is unchanged). JTBD PASS (JTBD-004 cross-repo coordination + JTBD-001 governance-without-slowing-down + JTBD-006 AFK persona — removes a hard-fail surface that obstructed the very jobs Step 5 serves; no capability removed). risk-scorer external-comms PASS + voice-tone external-comms PASS on the changeset draft.

Sibling `packages/itil/skills/review-problems/SKILL.md` `gh issue list --label <label>` invocation is out of scope — `gh issue list --label` filters on existing labels and returns empty on miss (no hard-fail surface).

`@windyroad/itil` patch changeset `.changeset/p207-drop-label-flag-from-step-5-example.md` queued; orchestrator Step 6.5 drains release.

## Description

`packages/itil/skills/report-upstream/SKILL.md` Step 5 demonstrates the `gh issue create` invocation with a `--label "${MATCHED_TEMPLATE_LABEL_IF_ANY}"` line. When the upstream repo has not pre-created the label name in repo settings (the default for new repos), `gh issue create --label <unknown-label>` fails with `could not add label: 'X' not found`. The flag is also redundant when the matched issue template carries `labels:` in its frontmatter, because the form auto-applies those labels on submit. The skill's example is therefore wrong on two grounds: redundant when the upstream is configured correctly, and a hard fail when it is not.

## Workaround

Drop the `--label` flag from the `gh issue create` invocation. The matched template's frontmatter `labels:` field is authoritative.

## Impact Assessment

- **Who is affected**: every `/wr-itil:report-upstream` invocation against an upstream whose label names have not been pre-created.
- **Frequency**: every first attempt against such an upstream.
- **Severity**: Moderate (hard-fail on first attempt; workaround is trivial).

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Remove `--label` flag from `packages/itil/skills/report-upstream/SKILL.md` Step 5 (and any sibling SKILL.md that demonstrates the same pattern). 2026-06-06: removed the flag from the single Step 5 example; `review-problems/SKILL.md`'s `--label` occurrence is `gh issue list --label` (filter on existing labels — empty result on miss, no hard fail), out of scope. Added an explicit in-skill note (Step 5) explaining why the flag is omitted and that template `labels:` frontmatter is authoritative.
- [ ] Behavioural test asserting the documented example posts successfully against an upstream without pre-created labels. Deferred — needs an upstream fixture or `gh` mock; tracked as remaining work on this Known Error before verification close.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/87
- **Pipeline classification**: JTBD-aligned; safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Sibling**: P198/#125 — same template/label-ecosystem drift class observed at the inbound-discovery filter; this ticket's outbound-side counterpart.
