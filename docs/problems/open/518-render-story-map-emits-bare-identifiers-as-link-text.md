# Problem 518: `render-story-map` emits bare identifiers as link text, so every reference link announces as "P033"

**Status**: Open
**Reported**: 2026-08-24
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at review from the report body. Impact 2: governance artefacts rendered for humans to read, no adopter runtime surface (same Impact basis as P466, whose Impact-3 rating was withdrawn on the false premise that this project's product line is accessibility tooling — do not re-borrow those stakes). Likelihood 4: the `link()` helper serves both reference call sites, so every map this toolchain renders carries the shape.
**Origin**: inbound-reported (#445)
**Effort**: S — one helper and two call sites in a single file; a slug-derived label needs no second lookup.
**WSJF**: 8 — (8 × 1.0) / 1
**JTBD**: JTBD-008
**Persona**: developer

## Description

`packages/itil/scripts/render-story-map.mjs` builds every artefact reference link with the identifier as its own link text:

```js
rel.problems.map((p) => link(hrefs, p, esc(p))).join(', ')   // line 718, row problems
ids.map((id) => link(hrefs, id, esc(id))).join(', ')          // line 792, traces footer
```

So a rendered map's links read `P033`, `JTBD-400`, `RFC-009`. A screen reader's link list presents links stripped of their surroundings, where those announce as six or eight characters between full sentences.

The reporter grades it: SC 2.4.4 (Link Purpose, In Context) is a marginal pass for the row-problem links, which sit inside a `th scope="row"` that supplies some context; the traces-footer links sit in a `p` and have less. SC 2.4.9 (Link Purpose, Link Only) fails for both.

This is the rendered-artefact instance of a principle this repo already holds internally. P350 established that `P-NNN` / `ADR-NNN` / `JTBD-NNN` IDs are audit-trail annotations and never carriers of meaning, and that the substance must be self-contained before the ID is named. The renderer violates the repo's own rule on its own approval surface.

`linkify()` (line 567) is a separate case and is **not** in scope: it replaces IDs found inside running prose, where the surrounding sentence is the context and substituting a title would corrupt the author's text.

## Symptoms

- Eight anchors on the map the reporter examined, all of the same shape.
- Link text is not authored by the adopter, so a fix applied to a rendered HTML file is overwritten on the next `render:story-maps` run — adopters cannot fix it locally.
- `link(hrefs, id, inner)` at line 561 is shared, so one change covers both call sites.

## Workaround

None available to an adopter. Reading the map visually still works — the IDs sit in context on the page; only the out-of-context link-list surface is degraded.

## Impact Assessment

- **Who is affected**: anyone navigating a rendered story map by link list rather than by reading the page — screen-reader users primarily, keyboard link-cycling secondarily.
- **Frequency**: every rendered map, every reference link.
- **Severity**: Medium (8).
- **Analytics**: 8 anchors on the single map inspected; the corpus is larger.

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide the label source. The reporter offers the filename slug (`033-source-inspection-tests-anti-pattern.md` → "Source inspection tests are an anti-pattern") at no extra I/O, versus reading the target file's H1, which is more faithful at one read per link. The slug is already lossy where a title was shortened into the filename; weigh that against the read cost.
- [ ] Confirm the composed shape keeps the identifier navigable — `P033: Source inspection tests are an anti-pattern` retains the ID for people who navigate by it, which is what P350 asks for (ID after substance, not instead of it).
- [ ] Confirm `linkify()` stays untouched and record why, so a later pass does not "fix" the prose path too.
- [ ] Behavioural coverage per ADR-052: render a fixture map and assert no anchor's text content matches `^(ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+$`.
- [ ] Check whether the `.ref-link` class carries any styling that assumed short text.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P466 (story-map template CSS defects — same rendered surface, same reporter, same day; that ticket is CSS-only and is in Verification Pending, this one is renderer output), P516 (`add-card` omits the `ref` back-link — the adjacent defect in what the Traces line *contains*, where this one is about how it *reads*).

## Related

- Discovered by `/wr-itil:review-problems` Step 4.5 inbound-discovery, 2026-08-24, from upstream issue #445 on `windyroad/agent-plugins`, filed from the adopter repo `mountain-pass/addressr`. Semantic-comparator found no matching local ticket.
- The reporter is the repo maintainer filing from an adopter tree, so this is an outbound filing rather than a third-party report; no JTBD-301 acknowledgement comment was posted, per the convention the 2026-08-21 discovery pass established for maintainer-authored issues.
- P350 — IDs are never carriers of meaning; brief the substance first. This ticket is that principle applied to rendered output.
- Sibling issue #444 (link underline relies on the UA default) matched P466 and needed no new ticket.
