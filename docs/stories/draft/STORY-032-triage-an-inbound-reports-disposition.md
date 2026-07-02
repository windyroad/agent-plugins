---
status: draft
story-id: triage-an-inbound-reports-disposition
reported: 2026-07-02
decision-makers: [Tom Howard]
problems: [P170, P401]
jtbd: [JTBD-008, JTBD-301]
adrs: [ADR-062, ADR-068]
story-maps: [STORY-MAP-002]
estimated-effort: M
human-oversight: confirmed
oversight-confirmed-date: "2026-07-02 — ratified via AskUserQuestion (per-story pass; reworked to the internal-always-anchors vs external-scope-decision distinction)"
---

# STORY-032: Triage the report's disposition — accept, elicit a new job, or decline

**Story map:** [← STORY-MAP-002: Decompose a Fix Into Coordinated Changes](../../story-maps/draft/STORY-MAP-002-decompose-a-fix-into-coordinated-changes.html) · A1 (Release 1) — inbound touchpoint
**Backbone (inbound thread):** [A1 capture-inbound](027-capture-a-problem-from-an-inbound-channel.md) · [A1 acknowledge](028-acknowledge-the-inbound-report.md) · A1 triage-disposition · [A2 share workaround](029-share-the-workaround-with-the-reporter.md) · [A3/A4 fix underway](030-tell-the-reporter-a-fix-is-underway.md) · [A5 released → verify → close](031-tell-the-reporter-released-and-close-the-loop.md)

## User value (INVEST Valuable)

In order that the software's scope stays a deliberate choice — accepting a report that fits an existing job, or a new job I decide is worth supporting, and declining one I choose not to — as a maintainer triaging an *external* report, I want to settle its disposition after interviewing me: accept, create-a-new-job-and-accept, or decline (nicely).

## Acceptance criteria (INVEST Testable)

- [ ] **Matches an existing job** → accept and capture the ticket ([STORY-027](027-capture-a-problem-from-an-inbound-channel.md)).
- [ ] **No matching job** → interview the maintainer to understand the need, then **ask the maintainer: support this as a new job?** — **Yes** → create the JTBD/persona (ratified, ADR-068/P288) and accept; **No** → decline the problem, nicely (a deliberate scope decision).
- [ ] **Spam / not-a-problem / malicious** → decline via the ADR-062 request-risk path (`assess-inbound-report`).
- [ ] **P401 boundary:** a decline is only ever a *maintainer scope decision made after interview* — never the agent auto-rejecting because it couldn't anchor the report. Internal, maintainer-flagged problems always anchor to an existing-or-future job and are never declined (the P401 case); this story is the *external* path, where scope is genuinely the maintainer's call.

## Driving problem trace (I6)

**P170** — inbound triage needs a disposition step. **P401** — the no-discard rule applies to *anchoring uncertainty* (the agent can't figure out the job), NOT to a maintainer's deliberate scope decision: internal problems always anchor and are never rejected, but an external report the maintainer chooses not to support (after interview) may be declined. **ADR-062** — the request-risk decline path. **ADR-068** — new JTBDs/personas are human-ratified.

## JTBD trace (I9)

**JTBD-301** — the reporter's genuine need is heard (accepted or a new job created), and only true non-problems are declined. **JTBD-008** — the inbound entry's triage.

## Related

- **STORY-MAP-002** A1 inbound triage-disposition card. Partly leans on the shipped `assess-inbound-report` (ADR-062 request-risk) for the malicious-decline sub-case; the interview-and-create-new-job path is the gap. To build.
