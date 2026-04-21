---
"@windyroad/retrospective": minor
---

run-retro adds Step 2b Pipeline-instability scan (closes P074)

The retro reflection prompts were framed around product-code work and
under-reported **pipeline-level instability** — hook TTL expiries,
marker-vs-file deadlocks, skill-contract violations, release-path
failures, subagent DEFERRED/ISSUES FOUND outcomes, repeat workarounds,
and session-wrap silent drops. These recurred every session without
ticketing, so the WSJF queue never saw pipeline cost.

Step 2b is a dedicated evidence-scan step placed between Step 2
reflection and Step 4 ticket creation. Shape mirrors P068's Step 4a:
glob / evidence-scan / categorise / dedup / prompt. Six signal
categories enumerated. ADR-026 grounding required on each detection
(tool invocation + session position + observable outcome; no bare
counts). Interactive AskUserQuestion has four options per ADR-013
Rule 1 (Create new ticket / Append to P<NNN> / Record in retro report
only / Skip — false positive). AFK fallback populates a new Pipeline
Instability section in the retro summary and defers ticket creation to
the user, matching Step 4a's deferral pattern per
feedback_verify_from_own_observation.md.

Ownership boundary: run-retro surfaces detections;
`/wr-itil:manage-problem` creates or updates tickets and commits per
ADR-014. run-retro does not write problem files directly.

- New bats doc-lint: `run-retro-pipeline-instability-scan.bats` — 12
  assertions covering the step header, six-category enumeration,
  ADR-026 grounding, AskUserQuestion contract, AFK fallback,
  manage-problem delegation, dedup against existing tickets, ADR-027
  compat note, section placement, Step 5 summary integration, and
  P068 shape cross-reference.
