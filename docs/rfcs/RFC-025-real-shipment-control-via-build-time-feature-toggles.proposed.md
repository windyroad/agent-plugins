---
status: proposed
rfc-id: real-shipment-control-via-build-time-feature-toggles
reported: 2026-06-17
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P359]
adrs: [ADR-082]
jtbd: [JTBD-002, JTBD-006]
stories: []
---

# RFC-025: Real shipment control via build-time feature toggles

**Status**: proposed
**Reported**: 2026-06-17
**Problems**: P359
**ADRs**: ADR-082 (ratified option (b) at `/wr-architect:review-decisions` 2026-06-17)
**JTBD**: JTBD-002 (Ship AI-Assisted Code with Confidence), JTBD-006 (Progress the Backlog While I'm Away)

## Summary

Build the real shipment-control mechanism ADR-082 option (b) selected: when held above-appetite work is committed to main, the npm tarball must EXCLUDE the held content (not just exclude the CHANGELOG entry). The shipped tarball IS the build artifact, produced at publisher CI time from templated source. Adopters install pre-rendered tarballs and remain unaware of the templating layer. The mechanism must support testing BOTH the feature-enabled AND feature-disabled states of each held entry — otherwise the OFF state is untested and unsafe to ship.

## Driving problem trace

- **P359** — *Changeset holding does not withhold shipment*: ADR-042 Rule 7 documented holding as a shipment control, but moving the changeset file only withholds CHANGELOG entry + version attribution; `npm publish` packages the package directory verbatim, so any sibling-changeset release ships all committed code on main, held or not. The 2026-06-11 P220 witness confirmed the class-wide failure (all currently-held changesets whose code is committed on main have already shipped to adopters). User direction 2026-06-11: *"don't revert what's already shipped but going forward if we need to hold then we need a mechanism that's gonna work."* ADR-082 codifies that going-forward decision; this RFC builds it.

## Scope

The user-ratified shape (ADR-082 § Decision Outcome after 2026-06-17 drain): "feature-toggleable SKILL.md (and arbitrary shipped files) — produced programmatically from templated source — with paired test runs covering both ON and OFF states of each toggleable feature." Feature branches were considered and rejected (they go stale and don't compose permutations). Bespoke preprocessing was considered and rejected (corner cases will be more complex than expected; use a mature library).

### Slice 1 — Investigation (this RFC's first deliverable)

Produce a comparison matrix on candidate library / toolchain options for "markdown source → variant markdown output via conditional directives". Candidates to compare include at minimum:

- **`unified` / `remark` ecosystem with `remark-directive`** — JS native (matches existing npm toolchain); markdown-AST-level processing; lossless markdown→markdown round-trip is a design goal of `remark-stringify`; existing conditional-content remark plugins to validate (or write a small ~30-line plugin against the typed AST).
- **`pandoc` Lua filters** — single-binary distribution; mature; very wide format support; Lua filter API for conditional content; mature corner-case coverage.
- **`Sphinx` + `myst-parser` + `sphinx-markdown-builder`** — gold-standard `.. only:: tag` directive; HTML is the primary output but a markdown writer exists; round-trip fidelity on extended markdown constructs needs validation.
- **`MkDocs` + `mkdocs-macros-plugin`** — Jinja2-style conditionals in markdown; primary output is HTML site; usable for variant markdown but not its design centre.
- **`m4` / `cpp` / GPP general-purpose preprocessors** — decades-old, format-agnostic; cryptic syntax; markdown editor integration is the trade-off.

Comparison matrix axes:

1. **Corner-case coverage** — nested conditionals; feature interactions; dead-anchor detection; diff stability (small source change → predictable output diff); editor support for the source syntax.
2. **Dependency weight** — Python toolchain, Node-only, single-binary, runtime requirements at adopter publishers.
3. **Markdown round-trip fidelity** — does the tool preserve markdown constructs verbatim across the transformation? Tables, fenced code, frontmatter, link references, footnotes?
4. **Test-matrix integration ergonomics** — how easily does the tool support running the same tests against multiple feature permutations? bats parametrisation, CI matrix integration, build-output caching.
5. **Adopter-portability** — does the rendered tarball install + work identically to a hand-written equivalent at the adopter? Are there hidden runtime dependencies?

Deliverable: `docs/decisions/RFC-025-slice-1-tool-comparison.md` (or equivalent) with the matrix populated from actual investigation (not literature review). Includes a concrete recommendation with grounded rationale per ADR-026.

### Slice 2 — Build per recommended tool

After Slice 1's recommendation is ratified, build the per-skill (or per-package) feature-toggle mechanism:

- Per-skill `features.json` (or equivalent config) declaring feature names + held / active state.
- Render step (CI-side at publish time) that produces shipped artifacts from templated source.
- Test-matrix parametrisation covering at minimum: all-features-ON + all-held-features-OFF permutations. (Full 2^N matrix is budget-prohibitive; the matrix must cover both extrema and critical pairs per Slice 1's recommendation.)
- Tooling for graduating a held feature: config flip from `held: true` to `active: true`, rendered output regenerated, tests re-run against the new permutation, ship.

### Slice 3 — Retire holding-area as a shipment control

Once Slice 2 ships and dogfoods cleanly:

- Amend ADR-042 Rule 7 to remove the "shipment control" framing; reframe `docs/changesets-holding/` as attribution-only governance (the current de-facto behaviour) OR retire it entirely if the build-time toggle subsumes its role.
- Migrate currently-held changesets to the new mechanism (or graduate them all if Slice 2's permutation tests pass with their features active).

### Slice 4 — Reconcile K→V lifecycle semantics (ADR-082 option c)

Independently of Slices 1-3: stop keying problem-ticket K→V on changeset graduation when code is de-facto shipped on main (the P220 misclassification symptom). Likely lands as a small `manage-problem` Step 6 / `transition-problem` Step 5 patch.

## Tasks

- [ ] Slice 1: tooling comparison investigation (remark/unified, pandoc Lua, Sphinx+sphinx-markdown-builder, MkDocs+macros, generic preprocessor) — produce matrix + recommendation
- [ ] Slice 1: user ratifies the recommended tool at `/wr-architect:review-decisions` drain or equivalent
- [ ] Slice 2: per-skill `features.json` schema + render pipeline + test matrix wiring
- [ ] Slice 2: dogfood on one held changeset (smallest viable surface; likely an existing SKILL-prose hold)
- [ ] Slice 3: amend ADR-042 Rule 7 / retire holding-area as shipment control
- [ ] Slice 3: migrate or graduate the existing held cohort
- [ ] Slice 4: K→V lifecycle reconciliation (ADR-082 option c)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **ADR-082** — Changeset holding semantics: attribution-only vs shipment control. Option (b) ratified at the 2026-06-17 `/wr-architect:review-decisions` drain. This RFC is the build vehicle.
- **P359** — driving problem ticket.
- **P220** — empirical witness (Step 0d fix changeset held but full fix shipped in `@windyroad/itil@0.49.3`).
- **P228** — sibling K→V auto-transition fix; Slice 4 composes.
- **ADR-042 Rule 7** — current holding contract; Slice 3 amends or retires.
- **ADR-049 / ADR-080** — adopter-portable shim grammar (any build-step shim follows the existing `$PATH` resolution pattern).
- **JTBD-002** — agent cannot bypass governance; restoring the never-release-above-appetite invariant.
- **JTBD-006** — AFK loop needs a working above-appetite remediation it can rely on.
- **ADR-052** — behavioural tests default; the test-matrix Slice 2 builds is exactly this discipline at the shipment level.

(Captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation.)
