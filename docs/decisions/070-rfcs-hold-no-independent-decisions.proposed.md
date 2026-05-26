---
status: "proposed"
date: 2026-05-26
human-oversight: confirmed
oversight-date: 2026-05-26
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-08-26
amends: [060-problem-rfc-story-framework-with-mandatory-problem-trace-and-unified-problem-ontology]
problems: [P310]
---

# RFCs hold no independent decisions

## Context and Problem Statement

ADR-060 line 97 says *"an RFC's internal decomposition ... does NOT create ADRs by default; ADRs created during RFC execution capture decisions with scope outside the RFC's own boundary."* This permits RFCs to carry decision content that is not ADR-captured. Meanwhile ADR-066's unoversighted-decision detector greps **only `docs/decisions/`** — so any decision living in `docs/rfcs/` is structurally invisible to the human-oversight net designed to catch unratified decisions (P310).

The concrete drift: the atomic-fix carve-out reached `RFC-005` **accepted** status as decisions F2/F7/I13 with no human ratification, and the user disavowed it on 2026-05-26. It was exactly the kind of decision the oversight net exists to catch — invisible because it lived in an RFC, not an ADR.

This ADR decides where decisions live. (Its sibling **ADR-071** decides that every fix goes through an RFC; the two were ratified together but are independently transitionable.)

## Decision Drivers

- The oversight net (ADR-066 detector + `/wr-architect:review-decisions` drain + nudge) greps only `docs/decisions/` — decisions outside it are unguarded.
- A single decision ledger with one ratification gate is simpler and less drift-prone than two parallel gates.
- The decomposition-vs-decision boundary can reuse the existing "≥2 viable options" test (ADR-064 Needs-Direction / ADR-044 category-1), rather than inventing a new one.

## Considered Options

1. **RFCs hold no independent decisions; every choice among ≥2 viable options is an ADR.**
2. **Keep ADR-060 line 97 but add a parallel RFC-side ratification gate** — RFCs may still carry bounded-scope decisions, each with its own human-oversight marker + drain mirrored onto `docs/rfcs/`.
3. **Status quo (do nothing)** — leave line 97 as written.

## Decision Outcome

Chosen option: **"RFCs hold no independent decisions"**, because it is the only option that places every decision under the oversight + ratification machinery that already exists (ADR-064 confirm gate + ADR-066 born-confirmed marker), rather than building a second mechanism on a surface ADR-066's detector cannot see. Ratified by the user via AskUserQuestion on 2026-05-26.

Concretely:

- **RFCs hold no independent decisions.** Every choice among ≥2 viable options is recorded as an ADR and inherits the ADR-064 confirm gate + ADR-066 oversight marker. An RFC describes shippable scope, decomposition (story/slice/task breakdown, phase ordering, sequencing of *already-decided* work), and traces (problems, ADRs, story maps, stories).
- **ADR-060 line 97 is amended: delete the permissive half, keep the protective half.** Deleted: "RFC-internal decisions skip ADR capture / decisions with scope outside the RFC boundary become ADRs." Retained: "pure sequencing/breakdown of already-decided work is not an ADR." The boundary test is: *choice among ≥2 viable options → ADR; ordering of already-decided work → stays in the RFC.*
- **No "Considered Options / Alternatives Rejected" block in an RFC body.** Contested choices reference the governing ADR(s). The machine-detectable tell (for the enforcing behavioural test): an RFC body containing a rejected-alternatives block with no matching `adrs:` reference is a decision masquerading as scope.

This ADR records the decision. A separate RFC (tracing P310 + P251) scopes the implementation — the RFC-005 retrofit (F1–F7 decisions extract to ADRs), the template/skill changes, and the behavioural test.

## Consequences

### Good

- Every decision enters the existing ADR-064 confirm + ADR-066 born-confirmed oversight net — no new ratification mechanism to build, no second drift surface.
- Closes the RFC-decision blind spot that produced the unratified atomic-fix carve-out.
- One decision ledger (`docs/decisions/`); a crisp, reusable "what is an RFC" boundary.

### Neutral

- The decomposition-vs-decision boundary reuses the existing "≥2 viable options" test shared with ADR-064 and ADR-044 category-1 — no new concept.
- Sequencing/decomposition of already-decided work continues to live in the RFC (line 97's protective half is retained).

### Bad

- ADR count grows (ADR-sprawl) — bounded to genuine contested choices, which is the cheaper problem than invisible unratified drift. Pure sequencing never trips the trigger, so the sprawl denominator is "decisions that should always have been visible."
- One-time retrofit cost: RFC-005's F1–F7 decisions extract to ADR(s); the RFC template + capture-rfc/manage-rfc lose the "Considered Options" section.

## Confirmation

- ADR-060 line 97's permissive clause is deleted; its protective clause ("pure sequencing/breakdown of already-decided work is not an ADR") is retained.
- A behavioural test (per ADR-052) asserts no RFC body in `docs/rfcs/` contains a "Considered Options / Alternatives Rejected" block without a matching `adrs:` frontmatter reference.
- The RFC template + `/wr-itil:capture-rfc` + `/wr-itil:manage-rfc` carry no "Considered Options" section.
- RFC-005's F1–F7 decisions are extracted to ADR(s); RFC-005 is reduced to scope + decomposition + traces.

## Pros and Cons of the Options

### Option 1 — RFCs hold no independent decisions

- Good: every decision under the existing oversight net (ADR-064 + ADR-066); no parallel gate; closes the blind spot.
- Bad: ADR-sprawl (bounded to genuine decisions); one-time retrofit cost.

### Option 2 — Keep line 97 + parallel RFC-side ratification gate

- Good: avoids ADR-sprawl; keeps execution-local decisions near the RFC.
- Bad: builds a second ratification mechanism (two surfaces, two drift risks); ADR-066's detector still cannot see `docs/rfcs/`; the decomposition-vs-decision boundary remains fuzzy.

### Option 3 — Status quo

- Good: lowest churn.
- Bad: leaves the exact surface that produced the unratified carve-out drift; re-opens the same hole.

## Reassessment Criteria

Revisit if ADR-sprawl becomes a measured navigation cost (e.g. the `docs/decisions/` index becomes unusable), or if the "≥2 viable options" boundary test proves to over-fire into P132-style ADR-noise on pure-sequencing choices.

## Related

- **Sibling ADR-071** — Every fix goes through an RFC (the unconditional-RFC-first facet; ratified together, split per P017).
- **Amends ADR-060** (Problem-RFC-Story framework) — re-homes line 97; ADR-060 stays accepted, amended via the implementation RFC.
- **P310** — RFCs carry independent decisions invisible to the ADR-066 oversight net (driving problem).
- **P283 / P288** — lift-auto-decisions-to-human at the ADR / JTBD surfaces (sibling class).
- **ADR-064** — Architect Needs-Direction verdict + confirm-every-ADR gate (the ratification path inherited).
- **ADR-066** — human-oversight marker + review-decisions drain (the net that excludes `docs/rfcs/` today).
- **ADR-052** — behavioural-tests-default (the enforcement surface for the no-Considered-Options-in-RFC check).
- **ADR-069** — superseded ADR-051; precedent for the amend/supersede shape.
- **RFC-005** — carries the disavowed carve-out (F2/F7/I13); to be retrofitted under the implementation RFC.
