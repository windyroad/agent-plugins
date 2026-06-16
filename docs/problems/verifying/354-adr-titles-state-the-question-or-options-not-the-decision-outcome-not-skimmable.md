# Problem 354: ADR titles state the question / options being decided, not the decision outcome — not skimmable

**Status**: Verification Pending
**Reported**: 2026-06-03 (user direction with screenshot evidence — ADR-006 created as `006-npm-release-auth-stored-token-vs-oidc.proposed.md`)
**Released**: 2026-06-10 (`@windyroad/architect@0.16.0`, Phase 1 commit `b5e6ec1b`, changeset `4459d38`; published on npm — `npm view @windyroad/architect version` → 0.16.0; commit ancestor of HEAD; CHANGELOG 0.16.0 entry documents Step 2a convention + Step 5a retitle-after-decision + capture-adr Step 1 advisory). Phase 2 (structural lint + behavioural bats) deferred — future amendment, does not gate K→V per P184 conditional-deferral.
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

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Audit the existing ADR corpus for question-shaped titles (grep `docs/decisions/*-vs-*.md`, `*should*`, `*whether*`, `*-or-*`) — **corpus is currently clean** (zero hits across all four patterns as of 2026-06-08). The witnessed instance in the original capture (`006-npm-release-auth-stored-token-vs-oidc`) was hypothetical / from a different session; the actual on-disk ADR-006 is `006-connect-plugin` (outcome-shaped).
- [x] Amend create-adr + capture-adr SKILL prose: name the title-as-outcome convention + a "retitle after decision" step (if the title was drafted at the question stage). **Shipped 2026-06-08** — Phase 1 commit per ADR-014 amends both `packages/architect/skills/create-adr/SKILL.md` (new Step 2a convention prose with GOOD/BAD examples drawn from corpus + Step 5a mechanical retitle-after-decision check, ADR-044 category-4 silent-framework) and `packages/architect/skills/capture-adr/SKILL.md` (Step 1 convention prose + I2-isomorphic stderr advisory for question-shaped Titles).
- [ ] Decide: structural lint flagging question-shaped title patterns (optional) — **deferred** to Phase 2 along with bats coverage. Architect verdict (PASS-WITH-NOTES) Note 6 recommends three behavioural bats cases (`create-adr-outcome-shaped-retitle.bats`, `capture-adr-question-shape-advisory.bats`, `check-adr-title-shape.bats`); architect Note 7 recommends the optional structural lint at `packages/architect/scripts/check-adr-title-shape.sh`. Both deferred per user direction 2026-06-08 narrow-scope-this-iter constraint.
- [ ] Cadence-driven retitle of existing question-shaped ADRs (e.g. ADR-006 → outcome-shaped) — or a one-pass sweep — **N/A as of 2026-06-08** because the audit above found zero question-shaped titles in the current corpus. The convention guard (Step 5a mechanical retitle) prevents future drift; no historical sweep needed. Re-open this task if a future audit surfaces question-shaped titles that escaped the guard.

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

## Phase 1 Progress (2026-06-08)

**Shipped this iter (Open → Known Error transition):**

- `packages/architect/skills/create-adr/SKILL.md`:
  - Step 2 dispatch table Title row amended to point at Step 2a convention + Step 5a retitle check.
  - New Step 2a "Title-as-outcome convention (P354)" prose subsection — GOOD/BAD examples drawn from corpus; explicit anchor in MADR 4.0 + user direction 2026-06-03.
  - New Step 5a mechanical retitle-after-decision check — ADR-044 category-4 silent-framework (no AskUserQuestion fire per P132 inverse-P078 guard); ordered to preserve `architect-oversight-marker-discipline.sh` marker-discipline-hook semantics (marker-introducing Edit lands BEFORE `git mv`; subsequent H1 Edit allowed by hook's "old content already had marker" branch); emits I2-isomorphic stderr advisory.
- `packages/architect/skills/capture-adr/SKILL.md`:
  - Step 1 amended with "Title-as-outcome convention (P354)" prose + I2-isomorphic stderr advisory for question-shaped Titles supplied in `$ARGUMENTS`. Advisory-only at capture surface (the canonical-outcome short-name is the caller's to author, not the framework's to derive).

**Deferred (Phase 2 / future iters):**

- Structural lint at `packages/architect/scripts/check-adr-title-shape.sh` (advisory-only). Corpus currently has zero hits; lint would ship green.
- Three behavioural bats cases (architect Note 6) covering retitle-after-decision, capture-advisory, and lint-pattern-match.
- Bulk retitle of existing question-shaped ADRs — N/A as of 2026-06-08 (corpus clean).

**Confirmation criteria (Verifying transition):**

- Next ADR created via `/wr-architect:create-adr` against a question-shaped problem-statement is observed to retitle to outcome-shape after substance-confirm (mechanical, no user ask).
- Next ADR captured via `/wr-architect:capture-adr` with a question-shaped Title in `$ARGUMENTS` emits the stderr advisory.

## Related

- 2026-06-03 user direction (this capture's authoring context): *"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."*
- Witnessed instance: ADR-006 `006-npm-release-auth-stored-token-vs-oidc.proposed.md` — title names the option-pair (stored-token vs OIDC), not the chosen outcome.
- **P337** (Verifying) — compendium omits Decision Outcome body for 57% of ADRs; sibling skimmability concern at the BODY level (this ticket is the TITLE level). Both serve the "skim the decision without opening the file" goal.
- **ADR-077** — compendium token-cheap-load surface; inherits non-skimmable titles.
- create-adr + capture-adr SKILLs — the authoring surfaces that should name the title-as-outcome convention.
- MADR 4.0 — title-as-short-noun-phrase-of-decision convention this project follows.
