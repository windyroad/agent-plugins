---
status: done
story-id: capture-a-problem-from-an-inbound-channel
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-301]
adrs: [ADR-062]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass, inbound thread)"
---

# STORY-027: Capture a problem reported through an inbound channel

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A1 (Release 1) — inbound variation
**Backbone (inbound thread):** A1 capture-inbound · [A1 acknowledge](028-acknowledge-the-inbound-report.md) · [A2 share workaround](029-share-the-workaround-with-the-reporter.md) · [A3/A4 fix underway](030-tell-the-reporter-a-fix-is-underway.md) · [A5 released → verify → close](031-tell-the-reporter-released-and-close-the-loop.md)

## User value (INVEST Valuable)

In order to fix the problems real users are actually hitting — not only the ones I happen to notice myself — as a maintainer, I want to capture a problem reported through an inbound channel (issue, discussion, or security advisory) and triage it into the backlog.

## Acceptance criteria (INVEST Testable) — core SHIPPED

- [x] Inbound channels exist — issue templates (`.github/ISSUE_TEMPLATE/config.yml` + `problem-report.yml`), the intake scaffold (ADR-036).
- [x] Inbound reports are risk-assessed + routed — `wr-risk-scorer:assess-inbound-report` + the `inbound-report` reviewer, per the ADR-062 pipeline.
- [~] A reported problem is triaged into a `docs/problems/` ticket with a persona + JTBD derived from the *reporter's* signals (maintainer-side via manage-problem, per JTBD-301); the derive/interview refinement is pending (P395/P401-adjacent).
- [ ] The ticket records its inbound origin + a link back to the channel so the update touchpoints (STORY-028–031) can reach the reporter.

## Driving problem trace (I6)

**P170** — the coordinated-fix journey must start from *externally-reported* problems too, not just internally-noticed ones. **ADR-062** — the inbound assessment pipeline. **JTBD-301** — the plugin-user reporter never pre-classifies; the maintainer triages from their signals.

## JTBD trace (I9)

**JTBD-008** — the fix journey, entered from an inbound report. **JTBD-301** — the plugin-user's report reaches a maintainer who acts on it.

## Related

- **STORY-MAP-002** A1 inbound-capture card. Sibling of [STORY-018](018-capture-the-problem-mid-flow.md) (the internal mid-flow capture). Implementation ripple tracked with the inbound thread (P404 / ADR-062 surfaces).
