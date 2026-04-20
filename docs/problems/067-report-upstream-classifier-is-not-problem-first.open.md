# Problem 067: /wr-itil:report-upstream classifier is not problem-first — picks bug / feature / question and emits a bug-shaped default

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 9 (Medium) — Impact: Moderate (3) x Likelihood: Possible (3)
**Effort**: M — update `packages/itil/skills/report-upstream/SKILL.md` Step 3 (classification heuristic) and Step 5 (structured default body), plus the 9-assertion bats doc-lint test. Likely a sibling-ADR note or an update to ADR-024's Decision Outcome steps 3 and 5 to reflect the problem-first framing.
**WSJF**: 4.5 — (9 × 1.0) / 2 — Mid-priority; should ship after P066 (which establishes the problem-first shape) so the skill's new default matches the intake shape this repo ships.

## Description

`/wr-itil:report-upstream` (P055 Part B, shipped in `@windyroad/itil@0.8.0`, per ADR-024) currently follows a bug/feature/question mental model:

1. **Step 3 classification heuristic** (SKILL.md lines 80–91): maps local ticket title patterns to `bug`, `feature`, or `question`, then picks a matching upstream template (`bug-report.yml`, `feature-request.yml`, `question.yml`). There is no `problem` classification.
2. **Step 5 structured default** (SKILL.md lines 117–148): when the upstream has no matching template, the skill emits a bug-shaped body: `## Summary` → `## Steps to reproduce` → `## Expected behaviour` → `## Actual behaviour` → `## Environment`. This shape assumes the report is a bug — which contradicts ITIL problem management (the report is a problem; whether it's a bug is triage's call).

The intended behaviour (per user direction 2026-04-20): be problem-focused. Pick the most appropriate upstream template if one exists — including a `problem-report.yml` if the upstream has adopted the Windy Road pattern — otherwise emit a problem-shaped structured default whose sections mirror the local problem ticket: Description → Symptoms → Workaround → Impact → Environment.

Both concerns (the classifier and the default) live in the same skill file and must move together. Sibling ticket P066 fixes the intake templates in this repo so they become problem-first; this ticket fixes the outbound skill so its output aligns with the same discipline.

## Symptoms

- `packages/itil/skills/report-upstream/SKILL.md` Step 3 enumerates only `bug`, `feature`, `question` classifications (no `problem`).
- Step 3 template-matching preferences list `bug-report.yml`, `bug.yml`, `bug-report.md`, `bug.md` for "bug"; `feature-request.yml` etc. for "feature"; no preference list for a `problem-report.yml` / `problem.yml` target.
- Step 5 structured default emits a bug-shaped body (`Summary` / `Steps to reproduce` / `Expected behaviour` / `Actual behaviour` / `Environment`). When the local ticket is not a bug — e.g. a documentation gap, a cross-cutting observability request, an architectural concern — the output shape forces the content into a bug frame.
- Upstream issues filed via the skill on upstreams that lack templates carry the bug-shaped prose even when the local ticket itself was problem-shaped.
- The 9-assertion bats doc-lint test at `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` asserts the bug/feature/question classification language without asserting problem-first framing — so the current test passes despite the misalignment.
- ADR-024 Decision Outcome Step 3 enshrines the bug/feature/question classification. Until the ADR is updated or a sibling ADR reframes it, the SKILL.md aligns with its authoritative contract — which is itself misaligned with the project's ITIL framing.

## Workaround

Downstream agents invoking `/wr-itil:report-upstream` today get a bug-shaped default for any local ticket whose upstream has no templates. User has to manually re-shape the prose before the actual `gh issue create` lands — but the voice-tone-gate path (ADR-028) reviews prose only, not structure, so shape issues pass through.

## Impact Assessment

- **Who is affected**:
  - **Downstream agents calling `/wr-itil:report-upstream`** — every report lands with a bug-shaped default unless the upstream has a matching template. For problem-shaped local tickets (most of them), the frame is wrong.
  - **Upstream maintainers receiving reports** — receive bug-framed prose for reports that are really architectural or documentation problems; triage harder.
  - **Plugin-developer persona (JTBD-101)** — the "clear patterns" promise is that downstream behaviour mirrors this project's discipline. The skill's current output contradicts the discipline.
  - **Solo-developer persona (JTBD-001)** — user has to either rewrite the prose or accept the misalignment. "Enforce governance without slowing down" fails.
- **Frequency**: Every `/wr-itil:report-upstream` invocation whose target upstream has no matching template. Frequency scales with downstream adoption of the skill (P055 Part B, released 2026-04-20).
- **Severity**: Medium. Content-correct but structurally mis-framed. Not a data leak (P064 covers that) and not a tone issue (P038 / ADR-028 cover that) — a shape issue at the outbound surface.
- **Analytics**: N/A — no tracker metrics on structured-default vs template-matched outbound reports today.

## Root Cause Analysis

### Structural

ADR-024 was drafted 2026-04-20 alongside P055 Part B. The classification language inherited the npm-ecosystem bug/feature/question norm because upstreams overwhelmingly ship templates in that shape — the reasoning was "match what's there". The problem-first framing was not applied even though the skill's origin (the `/wr-itil:manage-problem` conventions) is explicitly problem-management. The default-body shape inherited the same assumption.

The structural fix:

- Classification becomes **problem-first with best-fit fallback**: look for an upstream `problem-report.yml` / `problem.yml` first; if absent, pick the best-fit of `bug-report` / `feature-request` / `question` based on the local ticket's shape (preserving backward compatibility with existing upstream conventions); if nothing matches, fall through to the problem-shaped structured default.
- Structured default becomes problem-shaped: `## Description` → `## Symptoms` → `## Workaround` → `## Impact` → `## Environment` → `## Cross-reference`.
- The bats test adds assertions for the problem-first preference list and the problem-shaped default body.
- ADR-024 updated (or extended by a sibling ADR) to document the new classification order and default shape.

### Candidate fix

Option 1 (recommended): **Problem-first with best-fit fallback**.

- Step 3 preference order: `problem-report.yml` / `problem.yml` / `problem-report.md` / `problem.md` → `bug-report.yml` / `bug.yml` etc → `feature-request.yml` etc → `question.yml` / Discussions routing → structured default.
- Step 5 default body:
  ```markdown
  ## Description

  <one-paragraph synthesis of the local ticket's Description>

  ## Symptoms

  <bullet list from local ticket's Symptoms>

  ## Workaround

  <from local ticket, or "None identified yet." if absent>

  ## Impact

  - Who is affected: <from local ticket's Impact Assessment>
  - Frequency: <from local ticket>

  ## Environment

  - Package / repo: <inferred from upstream repo name or local ticket>
  - Version: <detected via npm ls or local ticket's notes>
  - Claude Code version: <claude --version>
  - OS: <uname -srm>

  ## Cross-reference

  Reported from <downstream-repo-url>/<local-ticket-relative-path>

  This issue is tracked locally as P<NNN> in the downstream project's docs/problems/ directory.
  ```
- Step 3's classification heuristic widens: look for `problem`, `issue`, `concern`, `defect`, `gap` in the local ticket title and body; treat the shape as problem-first and let template-matching decide whether to coerce to bug/feature/question for backward compatibility.

Option 2 (rejected): **Keep bug/feature/question and ignore problem-report templates**. Preserves the ADR-024 language exactly but perpetuates the misalignment.

Option 3 (rejected): **Always use the problem-shape default, ignore upstream templates**. Simpler, but loses the "respect upstream maintainers' curated required-fields" benefit that ADR-024 Option 1 was chosen for.

### Investigation Tasks

- [ ] Update `packages/itil/skills/report-upstream/SKILL.md` Step 3 classification heuristic to be problem-first with best-fit fallback.
- [ ] Update Step 5 structured default body to the problem shape.
- [ ] Update Step 3's template preference list to look for `problem-report.yml` / `problem.yml` first.
- [ ] Update the 9-assertion bats doc-lint test — replace or supplement the bug/feature/question-only assertions with problem-first assertions (at least: "SKILL.md mentions problem-report template preference", "SKILL.md structured default uses Description / Symptoms / Workaround / Impact sections").
- [ ] Update ADR-024 Decision Outcome Step 3 + Step 5 (or draft a sibling ADR superseding the relevant steps) — the contract shift needs to be authoritative, not silent.
- [ ] Update ADR-024's "Considered Options" to note that the original option 3 ("Always use Windy-Road-structured default") has been partially reopened — we're now doing structured-default that matches OUR discipline, not the ecosystem norm, while still respecting upstream templates when they exist.
- [ ] Ensure P066 ships first (or in the same release batch) so the intake templates this repo ships match the outbound skill's preference order.
- [ ] Architect review on whether this is an ADR amendment or a new ADR. Precedent: ADR-022 replaced part of the problem lifecycle language from an earlier ADR — same pattern applies here for steps 3 and 5.
- [ ] Add a note to `packages/itil/skills/report-upstream/SKILL.md` references section pointing at P067 (and P066) as the problem-first reform.

## Related

- **P055** — parent; Part B shipped `/wr-itil:report-upstream` with the bug/feature/question shape.
- **P066** — sibling; this repo's intake templates adopt problem-first. Must ship first (or alongside) so the skill's preference order matches the shape this project ships.
- **P063** — manage-problem does not trigger report-upstream; related wiring gap.
- **P064** — no risk-scoring gate on external comms; neighbouring external-comms reform.
- **P065** — no scaffold-intake skill for downstream projects; downstream-side of the same intake-shape discipline.
- **ADR-024** — the contract currently enshrining bug/feature/question. Needs amendment or sibling ADR to document the problem-first shift.
- **ADR-022** — precedent for lifecycle-language amendment (the Verification Pending status replaced part of the earlier lifecycle description).
- `packages/itil/skills/report-upstream/SKILL.md` lines 80–91 (Step 3 classification) and lines 117–148 (Step 5 structured default) — the two edit surfaces.
- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — existing 9 assertions need updates for problem-first framing.
- **JTBD-004** (Connect Agents Across Repos to Collaborate) — the skill's primary JTBD; the outbound shape should match our problem-management discipline when we initiate cross-repo handoffs.
- **JTBD-101** (Extend the Suite with Clear Patterns) — problem-first is the "clear pattern".
- **JTBD-201** (Restore Service Fast with an Audit Trail) — problem-shaped outbound reports align with the bi-directional linkage discipline.
