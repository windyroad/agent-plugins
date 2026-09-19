---
name: plugin-user
description: Developer using an installed windyroad plugin who encountered a problem and wants to report it
human-oversight: unconfirmed
oversight-date: 2026-05-25
oversight-note: amended 2026-08-29 under P527 without a post-change confirmation; scope widened 2026-09-19 under P530 (see '## Pending re-ratification scope'); re-ratify via /wr-jtbd:confirm-jobs-and-personas
---

# Plugin User

## Who

Developer who has installed one or more `@windyroad/*` plugins into their own project and encountered a problem — a hook misfired, a skill failed to load, the installer errored, or behaviour contradicted the plugin's documented contract. They are a consumer of the suite, not a contributor (though they may become one). They may be solo, on a team, or running an adopter project (addressr, bbstats, or any future downstream).

## Context Constraints

- **Low context on repo internals**. Does not read the monorepo's source code, ADRs, or architecture; interacts with the plugins through their installed surface (Claude Code skills, hooks firing on their own edits, installer CLI output).
- **High context on their own failure mode**. Knows exactly what they were trying to do, what happened instead, which plugin they had installed, and their environment — because they were at the keyboard when it broke.
- **Multiple runtimes, one install**. May run the same installed plugin under Claude Code or under Codex. Does not know which conventions each host owns — component namespacing, display casing — and cannot be expected to reconcile a disagreement between them. Where two runtimes disagree, the plugin resolves it; the adopter reads one advertised name and types it.
- **Reporting is incidental, not their job**. Their primary goal is finishing their own work; the report is an interruption they are choosing to make so the problem gets fixed for them (and for others). Friction at the reporting surface has a high chance of abandoning the report entirely.
- **No Windy Road brand loyalty required**. They picked the plugin because it solved a problem; a broken plugin + bad intake experience reflects on the brand and on their willingness to stay.
- **No pre-existing taxonomy knowledge**. Does not know whether the issue they observed is a "bug", a "feature request", a "documentation gap", a "configuration issue", or an ITIL-shaped "problem". Asking them to pre-classify adds cognitive load and produces mis-classified intake.
- **Claude Code as the likely entry point**. Many plugin-users are themselves using AI agents and may file their report via an agent session; the intake must work equally well for human reporters and for agents describing what they observed on behalf of a user.

## Pain Points

- **Forced pre-classification** — bug-vs-feature-vs-question pickers demand a category decision the reporter shouldn't have to make, and triage has to re-bucket the result anyway.
- **Missing intake surfaces** — reaching a blank issue form (no template, no guidance) when the plugin repo hasn't shipped `.github/ISSUE_TEMPLATE/` or has shipped one that doesn't match what they observed.
- **No declared security-disclosure channel** — finding a possible security issue and not knowing whether to file publicly, email someone, or use GitHub Security Advisories.
- **Unacknowledged reports** — filing a report and not knowing whether it was received, categorised, or acted on. No audit trail back to them.
- **Duplicate rejection** — filing a report that turns out to be a duplicate of an existing ticket, with no way for the intake to have warned them beforehand.
- **Cross-plugin ambiguity** — observing a problem they can't confidently attribute to one plugin (hook from plugin A interacting with skill from plugin B) and being asked to pick one.

## Pending re-ratification scope

Recorded 2026-09-19 under P530. The maintainer confirmed anchoring that ticket to a new job (JTBD-304) **and** re-ratifying this persona in the same pass, because the new job shifts what this persona covers. This section states what the re-ratification has to decide; it does not decide it. This persona stays `human-oversight: unconfirmed` until `/wr-jtbd:confirm-jobs-and-personas` runs with a human present.

What the re-ratification must cover:

1. **The persona is no longer only a reporter.** Both the `description` and the `## Who` section frame this persona around having hit a problem and wanting to report it. JTBD-304 is about the adopter *running* an installed plugin's checks and skills day to day and reading their output — reporting is downstream of that, and most runs produce no report at all. Confirm whether this persona absorbs the runtime-consumer scope, or whether the runtime consumer is a separate persona and JTBD-304 re-anchors to it.
2. **"Reporting is incidental, not their job" needs re-reading under the wider scope.** The constraint is correct about reporting. Under the runtime-consumer reading, the incidental thing is the diagnostic output, and the primary thing is their own work — a related but distinct claim, and the one JTBD-304's outcomes actually rest on.
3. **Whether a trust cost belongs in `## Pain Points`.** The failure mode behind JTBD-304 is a check that fails open and keeps running while giving a wrong answer. Nothing in the current pain-point list covers a plugin that works but cannot be believed; every entry describes something being blocked, missing, or unanswered.
4. **Whether "low context on repo internals" should say what follows from it.** It already holds. What JTBD-304 adds is the consequence: the adopter cannot distinguish a genuine failure from a source-layout assumption, so any check whose correctness depends on a `packages/` tree is unanswerable in their context.

Confirming JTBD-304 without settling item 1 would leave the job anchored to a persona whose stated scope does not contain it.
