---
status: proposed
job-id: restore-service-fast
persona: tech-lead
date-created: 2026-04-16
---

# JTBD-201: Restore Service Fast with an Audit Trail

## Job Statement

When production breaks, I want an evidence-first workflow that gets service restored quickly and hands the root-cause work to problem management, so I can separate "stop the bleeding" from "stop it happening again" without losing either.

## Desired Outcomes

- Incident lifecycle is explicit: investigating → mitigating → restored → closed
- Incidents use a separate `I###` namespace in `docs/incidents/` so they are not conflated with persistent problems in `docs/problems/`
- Hypotheses cite evidence (logs, repro, diff, metric) before any mitigation is attempted
- Reversible mitigations (rollback, feature flag, restart) are preferred over forward fixes
- Restoration triggers an explicit handoff to `wr-itil:manage-problem`, linking the incident to a new or existing `P###`
- Timeline, observations, mitigations, and verification signals are captured as an audit trail

## Persona Constraints

- Needs consistent incident-response standards across teams and client engagements
- Requires auditability of AI-assisted incident work for post-incident review
- Cross-links to solo-developer: workflow stays lightweight — low-severity incidents can skip the full template without breaking the lifecycle

## Current Solutions

Ad-hoc incident response in chat, post-mortems written from memory, root causes lost or merged into problem tickets by hand.
