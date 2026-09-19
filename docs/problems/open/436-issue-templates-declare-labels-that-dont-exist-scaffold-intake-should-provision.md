# Problem 436: Issue templates declare labels ('problem', 'needs-triage') that don't exist; scaffold-intake should provision declared labels

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#170)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**WSJF**: 6 — (6 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-301 (Report a Problem Without Pre-Classifying It) — secondary: JTBD-101 (Extend the Suite with New Plugins)
**Persona**: plugin-user — `human-oversight: unconfirmed`; re-ratification queued, required scope recorded in `docs/jtbd/plugin-user/persona.md`
**Fix vehicle**: RFC-096 (release row on STORY-MAP-004) — STORY-092

## Description

`.github/ISSUE_TEMPLATE/problem-report.yml` declares labels (`problem`, `needs-triage`) that don't exist in the repo. The web form silently drops them, and `gh issue create --label problem` hard-fails. Two-part fix: create the labels in the repo, and have `/wr-itil:scaffold-intake` provision declared labels downstream.

## Symptoms

- A reporter using the issue template gets the label dropped (web) or a hard failure (`gh --label`). New adopters scaffolding intake inherit the same gap.

## Impact Assessment

- **Who is affected**: reporters + adopters using the scaffolded intake.
- **Frequency**: every template-driven issue in a repo without the labels.
- **Severity**: Medium — degrades triage; `gh --label` path fails outright.

## Root Cause Analysis

### Investigation Tasks

- [x] Create the declared labels in `windyroad/agent-plugins` (repo-admin; immediately actionable). Done 2026-09-19. `gh label list` beforehand returned only GitHub's nine stock labels — neither declared label existed, reproducing the report exactly. Created with pinned colour and description rather than gh-random: `problem` / `b60205` / "Structured problem report filed through the intake template", and `needs-triage` / `fbca04` / "Awaiting maintainer triage". Verified present. The `gh issue create --label problem` hard-fail and the web form's silent drop are both resolved for this repo.
- [ ] Have `/wr-itil:scaffold-intake` provision labels declared by the templates it writes downstream. **Queued on a decision — see Blocked on below.** Carried as STORY-092 on release row RFC-096 of STORY-MAP-004; the trace gate now reads P436 as traced.

## Blocked on — adopter-consent decision (queued for an interactive session)

The downstream half mutates the adopter's GitHub repository settings. The scaffold skill's
recorded scope is local file writes only: it records no network write, no third-party-service
mutation, and no external-binary dependency — and that same record explicitly rejected
auto-writing into a previously-empty `.github/` unattended as too aggressive for a persona who
does not trust an agent to make judgement calls. So this needs a new decision record
(supersede-in-part; the existing one is ratified and therefore immutable), and its substance
needs human confirmation before the story is implemented.

May `/wr-itil:scaffold-intake` mutate an adopter's remote GitHub state to make declared labels
real, and under what consent?

- **A** — provision automatically under the same consent as the file writes; one prompt covers both.
- **B** — separate opt-in, default off behind a dedicated flag; otherwise report the gap. Local
  scaffolding stays network-free by default.
- **C** — surface, never mutate: emit the exact `gh label create` commands plus the gap report.
  Removes the gh-absent and unauthenticated branches entirely.
- **D** — remove the cause: drop the label declaration from the template. Contradicts JTBD-301's
  ratified outcome, which names the two labels by name. Not viable on its own.

Reviewed lean is B or C.

Also queued: re-ratification of the `plugin-user` persona (`human-oversight: unconfirmed`).

## Pre-resolved implementation constraints

Settled by architecture and JTBD review on 2026-09-19, so the implementation pass does not
re-litigate them. All are carried as acceptance criteria on STORY-092.

- **Create-only, never `--force` bare.** `gh label create --force` updates an existing label,
  and with no colour supplied it re-randomises the adopter's colour on every run — a
  destructive re-run, not the no-op the skill's idempotency contract promises. Report an
  existing label as "already present — skipped" and leave it alone.
- **Pin colour and description** on the labels this project creates, using the values applied
  to `windyroad/agent-plugins` above as the reference.
- **Anchor the parse** to a column-0 `labels:` in the top-level mapping of each template's
  first YAML document. Multi-document files, commented-out blocks and nested `body:`
  occurrences must not bind; fail loudly naming the file on an ambiguous shape. Every parsed
  token becomes a label written into someone's repository.
- **A provisioning failure must not cost the adopter their intake files.** As a scaffold
  sub-step, report loudly, name the follow-up command verbatim, and let the marker step and
  the commit proceed. Label-write scope is routinely absent on forks and org-restricted repos.
  Only direct invocation hard-fails.
- **No source-repository identifiers** in the new published runtime prose. Structured `@adr` /
  `@problem` annotations in a script header are fine.
- **The prose verdict needs a promptfoo case**, not a bats one — bats cannot assert what the
  skill says when `gh` is absent.
- **Nothing may resolve from a monorepo-relative path**; an adopter runs this in their own
  checkout.

## Dependencies

- **Composes with**: P065 (scaffold-intake — the natural home for the downstream provisioning), P207 (removed `--label` from the report-upstream example — the workaround for this root cause, not a fix).

## Related

- Inbound issue #170.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-092 | STORY-092: Provision the labels the intake templates declare | draft |
