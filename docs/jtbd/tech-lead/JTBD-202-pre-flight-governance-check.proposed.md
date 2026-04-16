---
status: proposed
job-id: pre-flight-governance-check
persona: tech-lead
date-created: 2026-04-16
---

# JTBD-202: Run Pre-Flight Governance Checks Before Release or Handover

## Job Statement

When I'm preparing a release or handing over work to a client, I want to run a full governance pre-flight (risk assessment, architecture compliance, JTBD alignment) on demand, so I can confirm the work meets our standards before it leaves my control.

## Desired Outcomes

- A single command gives me a release readiness score across commit, push, and release layers
- Architecture compliance against current ADRs is verifiable without staging a commit
- JTBD alignment shows whether the delivered features trace to documented persona needs
- Assessments produce a structured, auditable report — something I can attach to a release note or handover doc
- Pre-flight checks are available outside normal hook gate triggers — I choose when to run them

## Persona Constraints

- Needs consistent standards across multiple projects and team members
- Needs auditability — assessment results must be traceable (structured output, not prose)
- May run assessments before client reviews, retrospectives, or production deployments

## Current Solutions

Rely on hook-triggered assessments at commit/push time. No way to run a pre-flight assessment before deciding to commit. Manual delegation via the Task tool with knowledge of subagent_type strings.
