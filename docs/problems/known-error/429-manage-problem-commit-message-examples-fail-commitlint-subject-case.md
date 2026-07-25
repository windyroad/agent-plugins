# Problem 429: manage-problem commit-message examples fail @commitlint/config-conventional subject-case in adopter projects

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Origin**: inbound-reported (#137)
**Effort**: S. WSJF = (8 × 2.0) / 1 = 16.0.
**WSJF**: 16 — (8 × 2.0) / 1 (known-error multiplier applied 2026-07-26)
**JTBD**: JTBD-302 (Trust That the README Describes the Plugin I Just Installed) — secondary: JTBD-001 (Enforce Governance Without Slowing Down), JTBD-101 (Extend the Suite with New Plugins)
**Persona**: plugin-user — secondary: developer, plugin-developer

## Description

The `manage-problem` (and sibling) SKILL commit-message examples use a `P<NNN> <verb>` subject shape whose leading pascal-case token is rejected by `@commitlint/config-conventional`'s `subject-case` rule in adopter projects that run commitlint. The documented convention hard-fails on first use.

## Symptoms

- An adopter following the SKILL's commit-message example (`fix(itil): P<NNN> ...`) hits a commitlint `subject-case` failure. Every new adopter running commitlint trips on their first governance commit.

## Impact Assessment

- **Who is affected**: adopters with commitlint (a common conventional-commits setup).
- **Frequency**: first governance commit in any such repo.
- **Severity**: Medium — blocks the documented flow; easy workaround once diagnosed.

## Root Cause Analysis

**Root cause confirmed 2026-07-26.** `@commitlint/config-conventional` sets
`subject-case: [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']]`.
Commitlint's `sentence-case` predicate is `input === input.charAt(0).toUpperCase() + input.slice(1).toLowerCase()`.
A subject whose first token is an uppercase-leading artefact ID — `P429 known error — …`,
`I004 mitigated — …`, `RFC-050 accepted — …` — satisfies that predicate exactly (the ID's
leading letter is the only uppercase character, and digits/hyphens are case-neutral), so
`subject-case` rejects it. The documented example hard-fails on first use.

Verified empirically against the real linter (`@commitlint/lint` + `@commitlint/config-conventional`),
not inferred from the rule text:

| Subject | Verdict |
|---|---|
| `docs(problems): P429 known error — commitlint example` | FAIL `subject-case` |
| `docs(incidents): I004 mitigated — feature flag off` | FAIL `subject-case` |
| `docs(rfcs): RFC-050 accepted — flip example subjects` | FAIL `subject-case` |
| `docs(problems): mark P429 known error — commitlint example` | PASS |
| `docs(incidents): mitigate I004 — feature flag off` | PASS |
| `docs(rfcs): accept RFC-050 — flip example subjects` | PASS |
| `docs(problems): open P025 foo-bar-baz` (existing sibling row) | PASS |

**Corpus scope**: exactly 12 ID-leading example subjects across 8 shipped SKILL files
(`manage-problem`, `transition-problem`, `manage-incident`, `mitigate-incident`,
`restore-incident`, `manage-rfc`, `report-upstream`, `update-upstream`). Independently
confirmed by the architect and JTBD gate sweeps.

**Locus is wider than the SKILLs** (architect finding, 2026-07-26): the convention is
ADR-normative, not SKILL-local. ADR-014 § Commit Message Convention is the canonical
registry and pins three of the broken shapes verbatim (known-error, incident-mitigated,
incident-restored); ADR-024 Step 8 pins the reported-upstream shape in its Decision
Outcome. Flipping only the SKILLs would leave the registry contradicting the shipped prose,
and the next skill author would re-derive the broken shape from the ADR. The four shapes
that were SKILL-only (verification-pending, reported-upstream, upstream-lifecycle-update,
RFC-accept) are themselves evidence of the same gap — an incomplete registry let shapes be
invented skill-side.

**Why the verb-first shape**: it is not invented. The same convention tables already use
lowercase verb-first for their sibling rows (`open P<NNN>`, `close P<NNN>`, `open I<NNN>`,
`close I<NNN>`, `update RFC-<NNN>`, `close RFC-<NNN>`). The fix makes the transition rows
consistent with rows the adopter already reads in the same table, and matches
conventional-commits' own imperative-mood guidance.

### Workaround

Reorder the subject so a lowercase verb leads and the ID follows (`mark P429 known error — …`).
The ID stays in the subject, so no audit-trail tooling is affected.

### Investigation Tasks

- [x] Confirm the failing predicate empirically against `@commitlint/config-conventional`.
- [x] Sweep the corpus for every ID-leading example subject (12 sites / 8 files).
- [x] Confirm no consumer parses these subjects positionally.
- [ ] **Precondition (RFC-first, ADR-073 as rewritten 2026-06-29)** — mint a story map for the JTBD-302 adopter-shipped-contract-correctness class, capture ≥1 story on it, then capture RFC-050 with a **non-empty** `stories:` array. `stories: []` is not a conformant RFC shape once a fix is scoped (ADR-089 cardinality 1..N).
- [ ] **Precondition (ratification drain)** — ratify the ADR-014 + ADR-024 amendments (P357 post-change brief-and-ratify), ratify the story map + story (ADR-090), transition the story to `accepted` (ADR-096 — `in-progress` is reachable only from `accepted`), then transition RFC-050 to `accepted`.
- [ ] Flip the SKILL examples to verb-first so the subject starts lowercase — **held**: blocked on both preconditions above. The flips implement ADR-014's amended registry, so landing them before the amendment is ratified is the P315 build-on-unratified-decision failure (ADR-074 surface 3); and an implementation commit needs a `Refs: STORY-NNN` trailer naming an `accepted` story.
- [ ] Author the changeset naming `@windyroad/itil` (patch) — **held** with the flip. A changeset for a change that is not shipping is wrong metadata (ADR-099).
- [ ] Regression guard — blocked on a design decision, see below.

**Amended in this pass (2026-07-26)**: ADR-014 § Commit Message Convention (3 pinned rows
corrected + 4 previously-unregistered shapes added + rationale paragraph) and ADR-024
`## Amendments` (Step 8 subject shape deferred to ADR-014's registry). Both set to
`human-oversight: unconfirmed` pending the drain.

### Self-firing trigger for the held work (ADR-087 cadence annotation)

The held items are reachable by exactly two self-firing paths, and it is worth being precise
about which, because one plausible-looking path does **not** fire:

1. **This ticket's own WSJF rank.** It is a Tier-1 Known Error at WSJF 16, so
   `/wr-itil:work-problems` selects it on its own cadence. The held Investigation Tasks above
   are unchecked, so selection surfaces them.
2. **The AFK orchestrator's outstanding-questions drain.** The ratification question and the
   regression-guard design question are emitted in this iteration's `ITERATION_SUMMARY`
   and land in `.afk-run-state/outstanding-questions.jsonl` for batched surfacing at the next
   interactive drain.

**What does NOT fire (verified, 2026-07-26).** The `/wr-architect:review-decisions` drain and
its session-start nudge will **not** surface these amendments.
`packages/architect/scripts/detect-unoversighted.sh` extracts the **frontmatter block only**
(lines 41-47) and `continue`s on `^human-oversight:[[:space:]]*confirmed`. Both ADRs correctly
retain `human-oversight: confirmed` at frontmatter level — per ADR-066's rule that a mechanism
amendment does not clear the top-level marker, and per ADR-024's own four-entry precedent — so
the in-body "this amendment's substance is `human-oversight: unconfirmed`" marker is invisible
to the detector. Amendment-scoped unratified substance has no oversight-drain surface at all.
That gap is general, not specific to P429, and is captured separately; do not rely on the
oversight drain to bring these amendments back.

### Consumer-compatibility check (no positional parsing)

Verified that nothing anchors on a subject-leading ID, so the flip cannot break lifecycle
automation:

- `packages/itil/hooks/itil-fix-title-lifecycle-advisory.sh:51` — `grep -oE 'P[0-9]{3}'` over the whole subject (position-independent).
- `packages/itil/hooks/lib/changeset-detect.sh:186` — `grep -oiE '\b(P[0-9]+|RFC-[0-9]+|STORY-[0-9]+)\b'` (position-independent).
- `packages/itil/hooks/itil-rfc-trailer-advisory.sh:133` and `itil-commit-trailer-transition-advisory.sh:57` — read the `Refs:` trailer, not the subject.

Constraint the fix must hold (JTBD gate condition): every flipped example MUST retain its
`P<NNN>` / `I<NNN>` / `RFC-<NNN>` token. A flip that dropped the ID would satisfy commitlint
but break JTBD-001's change-set-level audit trail.

## Outstanding design question — regression-guard expression

The natural guard (a grep-as-lint over `packages/*/skills/*/SKILL.md`, modelled on the
sibling `packages/shared/test/no-repo-relative-script-paths-in-skills.bats`) is **not
permissible**: ADR-052's ratified amendment states that structural assertions on
prose-document content are "not permitted under any justification", and the sibling's
exemption rests on ADR-049 reassessment clause 3, which pre-authorises path-resolution
lints only — there is no equivalent clause for commit-subject shape. Per ADR-052 line 135,
a test not yet expressible behaviourally blocks on a harness-gap ticket rather than
shipping as structural.

Options surfaced by the architect gate (queued for the maintainer; ADR-044 category-1):

- **A** — extract every documented example subject from the SKILL corpus and pipe it through the *real* commitlint (`@commitlint/lint` + `@commitlint/config-conventional` as devDeps), asserting exit 0. Highest fidelity: the assertion subject becomes adopter-observable behaviour rather than our source text, so it satisfies ADR-052 on the merits instead of by exemption, and it catches future rule violations beyond `subject-case`. Costs one dev-only dependency plus CI wiring. Architect's advisory lean.
- **B** — same extraction, predicates re-implemented in bash. No dependency; drifts silently when the upstream rule set changes, and the predicate then needs its own tests.
- **C** — validate subject-case on *real* commits via an existing itil advisory hook. Cheap, but misses P429's actual failure mode (an adopter copying our documented prose).
- **D** — ship the grep-lint as a declared ADR-052 violation. Explicitly foreclosed by ADR-052's amendment.

Also worth deciding at the same time: whether the recurring class this belongs to —
*shipped SKILL prose must be valid in the **adopter's** toolchain, not only ours*
(P151 / P153 / P219 / P317 / P429) — deserves its own ADR, which would give future guards
of this shape the pre-authorising clause ADR-049 clause 3 gave the path lint.

## Dependencies

- **Composes with**: (distinct from P082/P360/P365 — those gate on commit-msg content; this is the SKILL example shape).
- **Composes with**: P151 / P153 / P219 / P317 — same recurring class (shipped SKILL prose must be valid in the adopter's toolchain, not just the source monorepo).

## Related

- Inbound issue #137.
- JTBD trace corrected 2026-07-26 from the AFK auto-capture default (`JTBD-101` / `plugin-developer`) to `JTBD-302` / `plugin-user` per the JTBD gate: `plugin-developer` "works in the monorepo with `--plugin-dir`" and never experiences this defect — the monorepo does not run commitlint. The harmed party is an adopter with the plugin installed in their own project. Same re-anchor precedent as P151.
