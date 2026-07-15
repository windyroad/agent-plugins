# Governance Workflow

Cross-session learnings about ADRs, architect/JTBD reviews, risk scoring, and voice-tone.

## What You Need to Know

### Born-confirmed ADRs still need a POST-DRAFT confirm — picking the option pre-draft is not ratifying the draft (2026-07-07)

Surfacing the chosen option via `AskUserQuestion` BEFORE drafting an ADR (the P339 run-decision-before-drafting discipline) does NOT authorise `human-oversight: confirmed`. The pre-draft choice ratifies the DECISION, not that the DRAFT faithfully captured it. Sequence: draft born `unconfirmed` → brief the drafted content in plain prose → a SEPARATE `AskUserQuestion` confirm → only then write the marker. User correction 2026-07-07 (ADR-095): *"you CAN'T draft it confirmed. You need to draft it and then confirm, otherwise I can't catch if you have misunderstood."* This is P357 on the create-adr path; the ADR-095/096 pair went draft→brief→confirm→amend→re-confirm and the user caught a scope expansion (INVEST-at-capture) at the confirm.
  <!-- signal-score: 2 | last-classified: 2026-07-07 | first-written: 2026-07-07 -->

### Editing SKILL.md prose breaks contract bats that grep the old prose — grep the changed phrases across test .bats BEFORE pushing (2026-07-07)

Contract bats (`manage-story-contract.bats`, `itil-commit-trailer-transition-advisory.bats`) assert the PRESENCE of specific SKILL.md prose. Change that prose (e.g. removing a `draft → in-progress` auto-transition per an ADR amendment) and those greps go red — but only on CI's Quality Gates "Run hook tests", AFTER you push. Grep the changed phrases across `packages/*/skills/*/test/*.bats` + `packages/*/hooks/test/*.bats` BEFORE pushing a SKILL-prose change. Fresh evidence for P290/P324 (structural tests grep prose; behavioural-only wouldn't break on a wording change).
  <!-- signal-score: 2 | last-classified: 2026-07-07 | first-written: 2026-07-07 -->

### I13 fix-time RFC: the SKILL's Scope+Tasks directive is stale — the shape that PASSES is RFC + ≥1 story + thin ADR (updated 2026-07-05)

On an RFC-less Known Error, `wr-itil-check-fix-rfc-trace` emits `no-rfc-trace` and the I13 SKILL text directs `capture-rfc --fix-time` with authored `## Scope`+`## Tasks`. That prose-blob form is superseded (ADR-073 rewritten 2026-06-29: an RFC is stories in a story map per ADR-060/089/090; the P399 `--fix-time` mechanism is held) and a `stories: []` Scope+Tasks RFC gets architect-rejected (witnessed 2026-07-03, RFC-040/P357). **The reconciled path that WORKS — architect-APPROVED twice (RFC-043/P408 2026-07-04; RFC-044/P345 2026-07-05)**: author the fix-time RFC with `stories: [STORY-NNN]` (forward-reference ok) + Stories table load-bearing, capture the story via `/wr-itil:capture-story P<NNN> JTBD-<NNN> --rfc RFC-NNN <value-first description>`, and record the drain-ratified fix approach as a thin ADR (ADR-073 confirmation clause; ADR-091/092 precedent — born-unconfirmed in AFK per P348). Scope/Tasks may remain as supplementary prose only. <!-- signal-score: 3 | last-classified: 2026-07-05 | first-written: 2026-07-03 -->

> **Sibling brief**: promptfoo SKILL-eval authoring pitfalls (Tier-A regex, Nunjucks `{% raw %}`, negative-clause → Tier-B routing) live in [`promptfoo-eval-authoring.md`](./promptfoo-eval-authoring.md). Load when debugging `promptfooconfig.yaml` evals.


- **Risk appetite is Low (5)**. Changes scoring Medium (6+) need explicit acknowledgement (ADR-086 rebalanced the bands 2026-06-25: score 5 is now Low, default appetite 4→5). See `RISK-POLICY.md`, ADR-086. <!-- signal-score: 2 | last-classified: 2026-07-05 | first-written: 2026-06-11 -->
- **An amendment that changes an ADR's Decision Outcome MUST flip the frontmatter `human-oversight:` to `unconfirmed`** — ADR-066's amend rule ("the never-re-ask principle covers an unchanged decision, not a rewritten one"). A body-section-only "this amendment is pending ratification" annotation is INVISIBLE to the drain toolchain (`wr-architect-detect-unoversighted`, the SessionStart nudge, and `/wr-architect:review-decisions` grep frontmatter only) and violates ADR-087's self-firing-cadence contract. Keep the ratified-base explanation in body prose; flip the machine-readable scalar. Mechanism-only amendments keep `confirmed`. Caught by an independent architect pass 2 on the ADR-075 CI-cadence amendment (pass 1 had approved the body-annotation shape), P324 iter 2026-07-05. <!-- signal-score: 2 | last-classified: 2026-07-05 | first-written: 2026-07-05 -->
- **Older entries archived to [`governance-workflow-archive.md`](./governance-workflow-archive.md)** (last rotated 2026-07-15, Branch B). Load the archive when full historical context is needed.

> **Sibling brief**: cross-session "what will surprise you" learnings — ADR mechanics, JTBD reviewer behaviour, the `git ls-tree` blob-SHA next-ID trap, README-refresh reconciliation, and smaller workflow gotchas — live in `governance-workflow-surprises.md` (split out 2026-05-03 per P145 MUST_SPLIT). Read alongside this file for the full governance-workflow surface.
