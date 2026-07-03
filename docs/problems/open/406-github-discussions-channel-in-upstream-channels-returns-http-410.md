# Problem 406: `github-discussions` channel in `.upstream-channels.json` returns HTTP 410

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 5 (Low) — Impact: 1 (Negligible — channel is skipped fail-soft; no discovery from Discussions but the other two channels work) × Likelihood: 5 (Almost certain — fires every poll; deterministic).
**Origin**: internal
**Effort**: S — either drop the channel from `.upstream-channels.json` or re-enable Discussions on the repo. WSJF = 5 / 2 = 2.5.
**JTBD**: JTBD-007
**Persona**: developer

## Description

`/wr-itil:review-problems` Step 4.5c polls a `github-discussions` channel configured against `windyroad/agent-plugins` category `Q&A`. The channel returns:

```
{"message":"Discussions are disabled for this repo","documentation_url":"...","status":"410"}
```

HTTP 410 = Gone. Either Discussions were disabled deliberately (channel config should drop it) or by mistake (Q&A should be re-enabled). Every review pass hits the fail-soft skip branch on this channel.

Not causing harm — fail-soft absorbs the error — but the config lies about the channel being reachable, and every audit-log entry records the skip.

## Symptoms

- Step 4.5c discussions channel poll: HTTP 410 → fail-soft skip.
- Audit log records `github-discussions ... HTTP 410 "Discussions are disabled for this repo"` every pass.

## Workaround

- Ignore — fail-soft covers it. Persistent noise in the audit log.

## Impact Assessment

- **Who**: maintainer running review-problems.
- **Frequency**: every review pass.
- **Severity**: Negligible — noise, not correctness.

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide: are Discussions intentionally off for this repo, or were they turned off by mistake? **(human decision — queued; see Findings)**
- [ ] If intentional: remove the `github-discussions` entry from `docs/problems/.upstream-channels.json`.
- [ ] If mistake: re-enable Discussions in repo Settings + verify the Q&A category exists.

### Findings (2026-07-04 — AFK investigation)

- **Confirmed disabled at the repo level, not a transient outage.** `gh api repos/windyroad/agent-plugins --jq '.has_discussions'` returns `false`; the `/discussions` REST endpoint returns HTTP 410 "Discussions are disabled for this repo" deterministically. GitHub Discussions default to OFF on a new repo, so this is most likely "never enabled" rather than "turned off".
- **The two conditional branches above are NOT symmetric — documented intent favours re-enable over drop.** [JTBD-301](../../jtbd/plugin-user/JTBD-301-report-problem-without-pre-classifying.proposed.md) records the design intent verbatim: *"Usage questions route to GitHub Discussions, not issues, so the issue tracker stays a reliable record of problems."* The `github-discussions` Q&A channel is part of the [ADR-062](../../decisions/062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md) designed intake surface (scaffolded in the P079 config, not an accident). Dropping the channel (Investigation Task branch 2) would silently foreclose the JTBD-301 usage-question routing surface.
- **The JTBD-aligned fix is branch 3 (re-enable), which needs a maintainer action outside the AFK agent's surface.** Re-enabling Discussions + creating the `Q&A` category is a GitHub repo-Settings toggle (repo-admin), not a code/config change — and choosing whether the project offers a Discussions Q&A intake is a community-strategy decision the maintainer owns. The AFK agent cannot perform the settings toggle and must not unilaterally resolve the branch-2-vs-branch-3 decision by editing config.
- **Disposition:** Investigation Task #1 (intentional-vs-mistake) queued to the orchestrator's loop-end `outstanding_questions` as a direction decision. Ticket stays Open pending the maintainer's call; fail-soft continues to absorb the 410 (no correctness impact — Priority 5/Low unchanged).

## Dependencies

- **Composes with**: P405 (same Step 4.5c channel-poll surface).

## Related

- **`docs/problems/.upstream-channels.json`** — the channel entry.
- **ADR-062** — inbound discovery mechanism.
- Captured via `/wr-itil:capture-problem`; rated at capture.
