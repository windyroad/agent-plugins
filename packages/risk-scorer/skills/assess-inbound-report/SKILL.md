---
name: wr-risk-scorer:assess-inbound-report
description: On-demand inbound-report risk review. Reviews a third-party submission against this repo's intake (problem-report issue body, Q&A discussion, security-advisory body) for Request-risk (info-extraction / backdoor request / malicious-code injection) and Fix-risk (privilege escalation / removal of load-bearing safety check / adopter-attack-surface expansion) per RISK-POLICY.md. Delegates to wr-risk-scorer:inbound-report and emits the structured verdict consumed by ADR-062's assessment-pipeline branch routing.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# Inbound-Report Risk Assessment Skill

Run a Request-risk + Fix-risk review on demand against a single inbound report — outside the `/wr-itil:review-problems` Step 8.5 assessment-pipeline trigger. Maintainer-facing pre-flight surface per JTBD-005 + JTBD-202; the assessment-pipeline itself invokes the same `wr-risk-scorer:inbound-report` subagent in-loop per ADR-062 § Decision Outcome step 3.

This skill is **read-only**. It does not commit, post comments upstream, or modify the inbound report. The marker (when the skill is invoked as a pre-satisfier for the pipeline's per-report gate) is written automatically by the `PostToolUse:Agent` hook (`risk-score-mark.sh`) after the subagent completes — the skill never writes to `${TMPDIR:-/tmp}/claude-risk-*` directly.

## When to use

- Before running `/wr-itil:review-problems` when a specific inbound report stands out as ambiguous (e.g. a discussion that mixes a legitimate feature request with a question that smells like info-extraction) — pre-flight the classification.
- After spotting a suspicious submission via `gh issue list` and wanting a second-pass review before the pipeline runs.
- During a retro on a misclassified prior report (Reassessment Criterion 1 in ADR-062 — false-positive rate exceeds ~10%) — replay the body through the subagent to surface why the prior verdict landed.
- As part of a P123 block-list eligibility review (a clear-malicious verdict here is the evidence chain the block-list scaffolding consumes when P123 lands).

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for any of:

- A report body verbatim (e.g. the user pastes the issue body).
- A `gh issue URL` or `<repo>#<issue-number>` reference — the skill fetches the body via `gh issue view --json body,author,labels`.
- A surface hint (`github-issues`, `github-discussions`, `github-security-advisories`).
- A submitter handle (`@user` or `user`).
- A JTBD-alignment hint from the assessment-pipeline (`aligned-with-existing-JTBD` / `aligned-with-new-JTBD-for-existing-persona` / `not-aligned`). Optional when invoked manually; required when invoked as a pipeline pre-satisfier.

If both body and surface are present, proceed to step 3. If either is missing, step 2.

### 2. Resolve missing context

If the body is missing AND a `gh issue URL` / `<repo>#<issue-number>` reference was supplied, fetch:

```bash
gh issue view "$ref" --json body,author,title,labels --jq '.'
```

Cache the JSON for downstream steps. Fail-soft on GH API errors — surface the error to the user and fall back to AskUserQuestion.

If the body is still missing, use `AskUserQuestion`:

> "What report do you want me to review? Paste the body verbatim, or give me a `gh issue URL`."

If the surface is missing AND cannot be inferred (from the URL pattern or context), use `AskUserQuestion`:

- header: "Inbound surface"
- options:
  1. `github-issues` (problem-report.yml or similar labelled issue)
  2. `github-discussions` (Q&A category)
  3. `github-security-advisories` (private vendor channel)

Do not ask if the surface is obvious from the URL / context.

### 3. Construct the review prompt

Build a self-contained prompt for the `wr-risk-scorer:inbound-report` subagent that includes:

- The **report body** verbatim (between explicit `<report>...</report>` markers so the agent's substring extraction is unambiguous).
- The **surface** (one of the canonical strings above).
- The **submitter handle** when known.
- The **JTBD-alignment hint** when known (composes with the agent's two-axis judgement).
- A reminder to compute `INBOUND_REPORT_KEY = sha256(body + '\n' + surface + '\n' + submitter)`.

### 4. Delegate to wr-risk-scorer:inbound-report

Invoke the subagent via the Skill / Agent tool with `subagent_type: wr-risk-scorer:inbound-report` and the constructed review prompt.

Wait for the subagent to complete. The subagent will output a structured verdict block (`INBOUND_REPORT_VERDICT: PASS|FAIL` + `INBOUND_REPORT_KEY: <sha>` + `INBOUND_REPORT_CLASS: <class>` + optional `INBOUND_REPORT_REASON: ...`). The `PostToolUse:Agent` hook (`risk-score-mark.sh`) reads that output and writes the per-report marker automatically.

**Do not write to `${TMPDIR:-/tmp}/claude-risk-*` yourself.** The hook is the only correct mechanism.

### 5. Present results

Present the full review report to the user. Highlight:

- The verdict (PASS / FAIL).
- The classification (`safe-low-fix-risk` / `safe-high-fix-risk` / `above-threshold-risk` / `clear-malicious-request`).
- The matched RISK-POLICY.md class + axis (Request-risk / Fix-risk) when FAIL.
- The exact substrings or metadata signals that triggered each finding when FAIL.
- The pipeline branch this report would route to under ADR-062 § Decision Outcome (pushback / clear-malicious-close-with-verdict / safe-and-valid-local-ticket-create).
- For `safe-high-fix-risk`: the fix-risk class the maintainer should weigh before accepting the local ticket (the pipeline creates the ticket but flags it for maintainer attention).

### 6. Above-appetite handling (ADR-013 Rule 6 + ADR-062 mechanical-stage carve-out)

The branch decision itself is **mechanical** per ADR-062 § Mechanical-stage carve-out (P132). When invoked as a pipeline pre-satisfier, this skill does NOT use `AskUserQuestion` to ask the maintainer "which branch?" — the verdict + class determine the branch deterministically. The maintainer's role is to accept or override the verdict via re-running with corrections, not to pick the branch.

When invoked manually as an on-demand pre-flight (NOT as a pipeline pre-satisfier), surface a single `AskUserQuestion` for what the maintainer wants to do next:

- header: "Next step"
- options:
  1. `Accept verdict + run pipeline` — the maintainer agrees with the classification; `/wr-itil:review-problems` will route accordingly on the next invocation.
  2. `Override + re-review with extra context` — the maintainer disagrees; pass extra context (e.g. "this submitter is a known good-faith contributor in `<other-repo>`") and re-invoke from step 3.
  3. `Block reporter (P123 scaffolding)` — surface the audit-log entry for P123 block-list enforcement when that ticket lands. Until then, this option appends to `docs/audits/inbound-discovery-log.md` only.
  4. `Cancel` — abandon the pre-flight; report intact for later review.

When invoked as a pipeline pre-satisfier (via the `/wr-itil:review-problems` Step 8.5 orchestrator), the skill is silent on this step per the mechanical-stage carve-out.

## Composition with the assessment-pipeline

This skill and the assessment-pipeline (ADR-062 § Decision Outcome) invoke the same `wr-risk-scorer:inbound-report` subagent. The skill is the maintainer-facing manual surface; the pipeline is the automated bulk-processing surface. Verdict shape is identical across both invocation paths (same `INBOUND_REPORT_VERDICT` + `INBOUND_REPORT_KEY` + `INBOUND_REPORT_CLASS` block); the consuming infrastructure (per-report marker, audit-log append, branch routing) is the same.

| Concern | This skill (on-demand) | `/wr-itil:review-problems` Step 8.5 (pipeline) |
|---------|------------------------|-----------------------------------------------|
| Invocation | Manual / pre-flight (JTBD-005, JTBD-202) | Automatic, in-loop with channel-config polling |
| Cardinality | One report per invocation | N reports per pass (channel-config drives N) |
| Branch decision | Per ADR-062 § Decision Outcome; mechanical | Same |
| Audit-log append | Yes (via PostToolUse hook) | Yes (via PostToolUse hook) |
| README rankings impact | None (skill is read-only) | Refreshes `## Inbound Upstream Reports` section in `docs/problems/README.md` Step 9e |
| AskUserQuestion authority | step 6 above (manual only) | None (mechanical-stage carve-out per P132) |

## ADR cross-references

- **ADR-062** (Inbound upstream-report discovery + assessment pipeline) — § Sibling subagent + § Mechanical-stage carve-out.
- **ADR-015** (On-demand assessment skills) — § Scope table extended with the `assess-inbound-report` row; § Naming Convention `assess-<artifact>` pattern; § Gate Marker Interaction (no skill-side marker writes).
- **ADR-009** (Gate marker lifecycle) — per-report marker TTL + drift discipline; same as the existing `external-comms-gate` marker.
- **ADR-013 Rule 1** + Rule 6 — `AskUserQuestion` only at maintainer-direction branches; mechanical-stage carve-out applies to pipeline invocations.
- **ADR-014** — assessment skills are read-only and exempt from commit obligation.
- **ADR-028** (External-comms gate, amended) — the pushback / clear-malicious-verdict comments the assessment-pipeline posts after this skill's FAIL verdict ride the P064 + P038 evaluator halves.
- **ADR-029** (Diagnose before implement) — verdict follows hypothesis / evidence / structured-verdict discipline.
- **ADR-044** — decision-delegation contract; mechanical-stage carve-out is the category-4 framework-resolution boundary.
- **P079** — parent ticket; this skill is Slice B per RFC-004.
- **P123** — blocked-user-list mechanism; composes with the `Block reporter` option in step 6.
- **JTBD-005** (Invoke Governance Assessments On Demand) — primary persona driver.
- **JTBD-202** (Pre-Flight Governance Checks) — secondary persona driver.
- **JTBD-001** (Enforce Governance Without Slowing Down) — mechanical-stage carve-out preserves "without slowing down".

$ARGUMENTS
