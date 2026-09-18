# Governance Workflow

Cross-session learnings about ADRs, architect/JTBD reviews, risk scoring, and voice-tone.

## What You Need to Know

- **A ratified ADR's body is immutable — the only lawful change is a NEW decision that supersedes it (ADR-116, 2026-08-13).** Editing the body, adding an amendment section, adding an `amends:` claim, or clearing the marker to rewrite history are all barred. **Do not copy the amendment sections already in the corpus** — they predate ADR-116 and are migration debt (P483), not precedent. The live pattern is a new ADR with `supersedes: ["ADR-NNN (in part — <named scope>)"]`, the old body untouched and the old filename unchanged. That needs human ratification, so an AFK iter records the superseding decision and holds. (P466 2026-08-21; P463 2026-09-19.)
  <!-- signal-score: -3 | last-classified: 2026-09-19 | first-written: 2026-08-21 -->

> **Sibling brief**: promptfoo SKILL-eval authoring pitfalls (Tier-A regex, Nunjucks `{% raw %}`, negative-clause → Tier-B routing) live in [`promptfoo-eval-authoring.md`](./promptfoo-eval-authoring.md). Load when debugging `promptfooconfig.yaml` evals.

- **A supersede-in-part scope is a list of clauses, not a list of mechanisms — and an evidence arm the old ADR never recorded is NEW substance, not part of the scope.** Naming only the two grep predicates a decision retires under-states what it displaces: the old ADR's *chosen option* enumerated those predicates in its shape list, and its labelled fixture set (designated the regression suite under ADR-052) labels most of its cases by those predicates, so both go too. State each displaced clause individually, say what happens to the fixture labels, and say explicitly that the old ADR is **not** renamed to `.superseded.md` — partial supersession leaves it in force, and the compendium renders no back-link on a partially superseded entry, so its title keeps advertising the retired mechanisms. Separately: if the new decision *adds* an evidence arm the old ADR's closed literal-list never carried, do not widen the supersede scope to cover it — record it as the new decision's own substance composing with the old shape, with its own driver and bound. The architect raises `[Amendment To Ratified Decision]` on the widened form and `[Missing Supersession]` on the under-stated one; both are wording-level and both cost a full review round if you draft past them. (P463 → ADR-129, 2026-09-19.)
  <!-- signal-score: 0 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->

- **Older entries archived to [`governance-workflow-archive.md`](./governance-workflow-archive.md)** (last rotated 2026-08-21, Branch B split-by-date; the 2026-07-26 reconciler-section-bucketing entry moved there. Prior rotation 2026-07-26 — the post-draft-confirm rule for born-confirmed ADRs, the SKILL-prose-breaks-contract-bats trap, and the risk-appetite band reference moved there). Load the archive when full historical context is needed.

> **Sibling brief**: cross-session "what will surprise you" learnings — ADR mechanics, JTBD reviewer behaviour, the `git ls-tree` blob-SHA next-ID trap, README-refresh reconciliation, and smaller workflow gotchas — live in `governance-workflow-surprises.md` (split out 2026-05-03 per P145 MUST_SPLIT). Read alongside this file for the full governance-workflow surface.
