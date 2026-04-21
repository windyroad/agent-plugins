---
"@windyroad/itil": minor
---

P071 split slice 2: new `/wr-itil:review-problems` skill

`/wr-itil:manage-problem review` is deprecated; the review-problems user
intent now has its own skill so the `/` autocomplete surfaces it directly
(JTBD-001 + JTBD-101). This is phase 2 of the P071 phased-landing plan
(list-problems shipped as slice 1 in `@windyroad/itil@0.10.0`).

- `packages/itil/skills/review-problems/SKILL.md` — NEW skill carrying
  the full review stack: re-read `RISK-POLICY.md`, re-score every
  `.open.md` / `.known-error.md` ticket (Impact × Likelihood × Effort →
  WSJF), auto-transition Open → Known Error when root cause + workaround
  are documented, fire the Verification Queue prompt (`.verifying.md`
  per ADR-022 + P048 Candidate 4 `Likely verified?` heuristic), rewrite
  `docs/problems/README.md`, and commit per ADR-014 + ADR-015.
  `allowed-tools`: `Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion,
  Skill` — the tool surface the governance-scoped write path demands
  (contrast with `list-problems`'s read-only surface).
- `packages/itil/skills/review-problems/test/review-problems-contract.bats`
  — NEW 16 contract assertions (ADR-037 pattern; `@problem P071` +
  `@jtbd JTBD-001` + `@jtbd JTBD-101` traceability). Covers: frontmatter
  name, description intent language, allowed-tools surface (Write +
  Edit + Skill + AskUserQuestion required), glob scope (.open.md /
  .known-error.md / .verifying.md / .parked.md), README-refresh ownership
  boundary, Verification Queue prompt contract (ADR-022 fix-summary
  requirement), auto-transition path, ADR-014/015 commit-gate, P057
  staging-trap citation, RISK-POLICY.md reuse (no hardcoded scale),
  P071/ADR-010 citation, clean-split no-deprecated-arguments flag, and
  regression guard against word-argument subcommand branching.
- `packages/itil/skills/manage-problem/SKILL.md` — Step 1 `review`
  argument now routes to a thin-router forwarder that delegates to
  `/wr-itil:review-problems` via the Skill tool and emits the canonical
  deprecation notice verbatim per ADR-010's pinned template. Parser
  line updated from "run the review (step 9) only" to "delegate to
  `/wr-itil:review-problems`". Step 9's inline review logic stays in
  the file during the deprecation window (for historical reference +
  the inline `work` path that still flows through Step 9 pre-slice 3)
  but is no longer the primary entry point.
- `packages/itil/skills/manage-problem/test/manage-problem-review-forwarder.bats`
  — NEW 4 contract assertions for the review-forwarder contract:
  target-skill reference, canonical deprecation notice, delegate /
  Skill tool language (no re-implementation), and parser-line shape.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment.

Remaining phased-landing slices tracked on P071: `work-problem`
(singular; coexists with `/wr-itil:work-problems` AFK plural),
`transition-problem`, plus the `manage-incident` splits
(`list-incidents`, `mitigate-incident`, `restore-incident`,
`close-incident`, `link-incident`).
