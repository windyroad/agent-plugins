---
status: in-progress
rfc-id: red-ci-recovery-guidance
reported: 2026-07-23
human-oversight: confirmed
oversight-date: 2026-07-23
decision-makers: [Tom Howard]
problems: [P208]
adrs: [ADR-042, ADR-052, ADR-071, ADR-073, ADR-089, ADR-090, ADR-096]
jtbd: [JTBD-002]
stories: [STORY-046]
---

# RFC-049: Make the red-CI gate explain the CI-repair recovery path

**Status**: in-progress (2026-07-23)
**Reported**: 2026-07-23
**Problems**: P208
**JTBD**: JTBD-002 (Ship AI-Assisted Code with Confidence)

## Summary

Keep the red-CI gate fail-closed while making its denial actionable. A push denial
must say that red CI is not itself a goal blocker: inspect the linked failed run,
verify the outgoing commits directly repair that failure, delegate to
`wr-risk-scorer:pipeline` with CI-recovery context, and retry `npm run push:watch`
only when the scorer classifies the change as net risk-reducing. Unrelated commits
remain blocked. A release denial instead routes through fixing and pushing CI,
waiting for green, and retrying release; the existing live-outage path remains.

## Scope

- Change only the completed-red-CI guidance in `check_ci_status`; do not weaken its
  return value or add an automatic CI-repair classifier.
- Preserve independent `wr-risk-scorer:pipeline` classification and the existing
  `reducing-push` / `reducing-release` marker mechanism.
- Add focused behavioural assertions for push and release denial guidance.
- Ship as a patch release of `@windyroad/risk-scorer`.
## Related

- P208 (red-CI push/release gate) - reopened from Verification Pending after the
  guidance defect was observed in a downstream Codex task.
- ADR-042 - net risk-reducing changes use the scorer-authorised reducing path.
- RFC-029 - removed generic bypasses while retaining sanctioned reducing markers.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-046 | STORY-046: Red-CI denial explains the recovery path | in-progress |
