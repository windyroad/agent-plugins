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

- [ ] Decide: are Discussions intentionally off for this repo, or were they turned off by mistake?
- [ ] If intentional: remove the `github-discussions` entry from `docs/problems/.upstream-channels.json`.
- [ ] If mistake: re-enable Discussions in repo Settings + verify the Q&A category exists.

## Dependencies

- **Composes with**: P405 (same Step 4.5c channel-poll surface).

## Related

- **`docs/problems/.upstream-channels.json`** — the channel entry.
- **ADR-062** — inbound discovery mechanism.
- Captured via `/wr-itil:capture-problem`; rated at capture.
