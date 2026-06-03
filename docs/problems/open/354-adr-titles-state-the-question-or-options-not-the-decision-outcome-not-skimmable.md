# Problem 354: ADR titles state the question / options being decided, not the decision outcome — not skimmable

**Status**: Open
**Reported**: 2026-06-03 (user direction with screenshot evidence — ADR-006 created as `006-npm-release-auth-stored-token-vs-oidc.proposed.md`)
**Priority**: 6 (Medium) — Impact: 3 (Moderate — every ADR reader scanning the compendium or `docs/decisions/` listing must open the file to learn what was actually decided; defeats the skimmability the title is supposed to provide; compounds with ADR-077 compendium token-cheap-load goal) × Likelihood: 3 (Possible — fires whenever an ADR is titled as a question/option-pair rather than an outcome; recurring authoring habit)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-001
**Effort**: M (create-adr + capture-adr SKILL prose amendment naming the title-as-outcome convention + possibly a structural lint + cadence-driven retitle of existing question-shaped ADRs)
**WSJF**: 3.0 (6 × 1.0 / 2)

## Description

User direction 2026-06-03 with screenshot evidence: ADR-006 was created as `006-npm-release-auth-stored-token-vs-oidc.proposed.md`. User direction: *"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."*

The title `npm-release-auth-stored-token-vs-oidc` states the **question** being decided (stored-token vs OIDC) — it names the two options but NOT which one was chosen. A reader scanning `docs/decisions/` or the ADR-077 compendium sees the option-pair and must open the file to learn the outcome. The title should be the **short version of what was decided** — e.g. `006-npm-release-auth-via-oidc` (if OIDC won) or `006-npm-release-auth-via-stored-token` (if stored-token won).

The MADR 4.0 convention this project uses names the title as a short noun phrase of the decision. The recurring authoring habit is to title ADRs as "X vs Y" (the question) or "should we do Z" (the deliberation) rather than "do Z" / "use Y" (the outcome).

## Symptoms

- ADR filenames / titles read as `<thing>-<optionA>-vs-<optionB>` or `should-<deliberation>` rather than `<outcome-noun-phrase>`.
- Reader scanning `docs/decisions/` listing or the compendium cannot tell what was decided without opening the file.
- ADR-077 compendium (token-cheap-load surface) inherits the non-skimmable titles, partially defeating its skim purpose.

## Workaround

Reader opens each question-shaped-title ADR to learn the outcome. Tedious; defeats the skimmability the title should provide.

## Impact Assessment

- **Who is affected**: every ADR reader — architect agent (routine compliance load), maintainer (compendium scan), any reader using `docs/decisions/` listing as a navigation entry-point. Persona: developer (governance). JTBD: JTBD-001 (enforce governance without slowing down — non-skimmable titles slow the read path).
- **Frequency**: every question-shaped-title ADR read. Authoring habit recurs on new ADRs without a convention guard.
- **Severity**: Moderate. Not a correctness bug; a skimmability / navigation-cost tax that compounds across the growing ADR corpus + the compendium surface.
- **Analytics**: count of question-shaped vs outcome-shaped titles in the current corpus would quantify the backlog.

## Root Cause Analysis

### Hypotheses

1. **create-adr / capture-adr SKILL prose doesn't name the title-as-outcome convention**: the skills prompt for a title but don't instruct "title the OUTCOME, not the question". Authors default to naming the deliberation.

2. **Title authored before the decision is made**: in create-adr, the title may be drafted at intake time (when the question is known but the outcome isn't yet decided). The title then never gets updated to the outcome after the decision is made.

3. **No structural lint**: no check flags ADR titles matching question-shaped patterns (`-vs-`, `should-`, `whether-`, `-or-`).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Audit the existing ADR corpus for question-shaped titles (grep `docs/decisions/*-vs-*.md`, `*should*`, `*whether*`, `*-or-*`).
- [ ] Amend create-adr + capture-adr SKILL prose: name the title-as-outcome convention + a "retitle after decision" step (if the title was drafted at the question stage).
- [ ] Decide: structural lint flagging question-shaped title patterns (optional).
- [ ] Cadence-driven retitle of existing question-shaped ADRs (e.g. ADR-006 → outcome-shaped) — or a one-pass sweep.

## Fix Strategy

**Kind**: improve (convention + authoring-prose) + audit (existing corpus)

**Shape**:

1. **create-adr + capture-adr SKILL prose amendment**: name the title-as-outcome convention explicitly. In create-adr, add a step after the Decision Outcome is chosen: "if the title was drafted as a question (X vs Y / should-Z), retitle the file + heading to the outcome noun-phrase now." MADR 4.0 title-as-short-noun-phrase-of-decision is the anchor.

2. **Structural lint (optional)**: a check flagging `docs/decisions/*.md` filenames matching question-shaped patterns (`-vs-`, `-or-`, `should-`, `whether-`). Advisory Phase 1.

3. **Corpus retitle (cadence or sweep)**: ADR-006 (the witnessed instance) + any siblings. Note: retitling an ADR file means a `git mv` + heading edit + compendium regen + cross-reference updates — non-trivial per ADR. Likely cadence-driven (retitle on next edit) rather than mass-sweep, unless user directs otherwise.

**Note on ADR-006 specifically**: the witnessed ADR is `006-npm-release-auth-stored-token-vs-oidc.proposed.md`. Its title should be retitled to the chosen outcome once its Decision Outcome is known (the screenshot shows it being created; the outcome may already be in the body). This ticket's first fix instance could be retitling ADR-006.

## Dependencies

- **Blocks**: skimmability of `docs/decisions/` + the ADR-077 compendium.
- **Blocked by**: (none).
- **Composes with**: ADR-077 (compendium token-cheap-load — non-skimmable titles partially defeat it), P337 (compendium Decision-Outcome extraction — sibling skimmability concern at the body level; this ticket is the title level), the create-adr + capture-adr authoring SKILLs, MADR 4.0 title convention.

## Related

- 2026-06-03 user direction (this capture's authoring context): *"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."*
- Witnessed instance: ADR-006 `006-npm-release-auth-stored-token-vs-oidc.proposed.md` — title names the option-pair (stored-token vs OIDC), not the chosen outcome.
- **P337** (Verifying) — compendium omits Decision Outcome body for 57% of ADRs; sibling skimmability concern at the BODY level (this ticket is the TITLE level). Both serve the "skim the decision without opening the file" goal.
- **ADR-077** — compendium token-cheap-load surface; inherits non-skimmable titles.
- create-adr + capture-adr SKILLs — the authoring surfaces that should name the title-as-outcome convention.
- MADR 4.0 — title-as-short-noun-phrase-of-decision convention this project follows.
