---
status: proposed
date: 2026-09-14
human-oversight: confirmed
oversight-date: 2026-09-14
decision-makers: Tom Howard
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: ["ADR-107 (in part - the closed preRfc set for manifested legacy-map migration only)"]
reassessment-date: 2026-12-14
---

# Manifest-bound historical rows from before request-for-comments identifiers

> Captured via /wr-architect:capture-adr. This decision remains unconfirmed until Tom ratifies or amends it.

## Context and Problem Statement

The story-map generator requires every ordinary card to link to a real story file. That rule protects delivery authority. It also keeps status, value, problems, and approval derived from their authoritative records. The renderer is the part of the generator that creates the visible map.

Some adopter maps predate that rule. They contain accepted historical cards without story files. The current generator cannot migrate those maps without deleting accepted context or creating retrospective stories with invented evidence.

This decision calls a map in the current shared format a canonical map. The shared format's data rules are its schema. A migration manifest is a checked-in file that lists approved maps and digital fingerprints used to detect changes.

Some story-map rows contain work delivered before rows carried request for comments (RFC) identities. Story maps mark those rows with `preRfc: true`. Architecture decision record `ADR-107` closed that set and treats every such row as delivered. Neither rule fits migrated legacy bands labelled `Selected next`, `Research only`, `R1`, `R2`, or `R3`.

This decision permits a separately validated historical pre-RFC row inside `releases`. It preserves the familiar row-shaped map without weakening ordinary delivery rows or claiming that every historical card was delivered.

## Decision Drivers

- Preserve accepted historical context without inventing stories or evidence.
- Keep ordinary cards, RFC rows, approval, status, and queries unchanged.
- Keep one canonical map per journey.
- Reuse the map's row structure instead of adding a separate top-level historical section.
- Protect the exception from unapproved changes and reject it when required migration evidence is missing or incorrect.
- Preserve source labels as dated history rather than translating them into current delivery claims.
- Render committed maps that remain readable without browser scripting.
- Give keyboard and assistive-technology users the same historical relationships shown visually.

## Considered Options

1. **Add manifest-bound historical pre-RFC rows inside `releases` (chosen).** This preserves the row-shaped map while separating historical cards from ordinary tasks and delivery meaning.
2. **Add a separate top-level historical projection.** This keeps history completely outside rows, but creates a second map structure for the same journey activities.
3. **Allow ordinary tasks without story identifiers.** This requires a smaller schema change, but makes historical context indistinguishable from delivery authority.
4. **Require retrospective story files.** This keeps the current schema unchanged, but risks presenting reconstructed records as original evidence.
5. **Keep legacy maps beside canonical successors.** This avoids a schema change, but leaves two maintained maps for one journey and splits discovery.
6. **Remove unbacked historical cards.** This is simple, but deletes accepted journey substance.

## Decision Outcome

Chosen option: **"Add manifest-bound historical pre-RFC rows inside `releases`"**.

### Historical pre-RFC row subtype

A migrated row contains `preRfc: true` and a `historicalProjection` object. Together, these fields define the historical pre-RFC subtype. The `historicalProjection` object is a preserved view of the legacy band and its cards. It contains:

- the legacy map's reported date;
- the source band's identifier, label, and note; and
- historical cards with their activity placement, visible title, supporting text, and recorded status label.

These cards are not ordinary `tasks` and do not require story files. The row contains no `rfc`, and its historical projection contains no ordinary release or task objects.

A historical pre-RFC row contributes no RFC identity, delivery status, problem derivation, story approval, or `find-story` result. Its source label remains visible as historical context as of the reported date. It does not prove shipment dates, current production state, or delivery evidence.

Existing story-backed rows that use bare `preRfc: true` keep their current delivered-history behavior. Every ordinary card still requires a real story file and exactly one ordinary release row. An ordinary unbacked card remains invalid. New work cannot use either pre-RFC form to avoid an RFC or story.

### Narrow supersession of ADR-107

This decision supersedes only architecture decision record `ADR-107`'s statement that no new row can join the `preRfc` set. A new row may join only as a manifest-bound historical pre-RFC subtype created from a retained legacy map under confirmed adopter authority.

ADR-107's RFC-list derivation remains unchanged. Bare `preRfc` rows retain their existing meaning. Unmarked rows without an RFC remain defects.

### Deterministic migration manifest

The renderer discovers one manifest at `docs/story-maps/legacy-projection-manifest.json`, relative to the repository root containing the map. A historical pre-RFC row is invalid when the manifest is missing, malformed, lacks the exact map identifier and repository-relative path, or contains an unsupported schema version.

Each manifest entry records:

- `mapId` and `path`;
- `authorityAdr`, identifying the adopter architecture decision that ratifies the exact migration;
- the source commit and the 256-bit Secure Hash Algorithm (SHA-256) fingerprint of the exact pre-migration file bytes;
- the SHA-256 fingerprint of every historical row and card, including its placement and text; and
- the SHA-256 fingerprint of the first complete canonical file produced by the migration.

The deterministic historical representation recursively sorts object keys and preserves array order. It encodes the result as JavaScript Object Notation (JSON) without extra whitespace, using 8-bit Unicode Transformation Format (UTF-8). It computes the fingerprint from those exact bytes. The validator recomputes this fingerprint on every render and query.

The first canonical-file fingerprint is a historical migration receipt. It is checked when the migration is created, but it does not gate later ordinary map evolution. Changing a historical row or its manifest entry requires newly ratified authority.

### Approval boundary

The map's human-oversight fingerprint detects changes to ratified content. It includes historical pre-RFC rows, so migrating or changing one requires human ratification. Later presentation-only changes remain outside this fingerprint. Ordinary release rows and story cards retain their existing approval behavior under architecture decision record `ADR-103`.

### Committed accessible rendering

The renderer writes historical pre-RFC rows into the map's committed Hypertext Markup Language (HTML) table. It does not rely on browser scripting. Each row has:

- a row header naming the source label, reported date, and historical-context purpose;
- the existing activity-column headers;
- a named, keyboard-focusable horizontal scroll region with visible focus styling;
- explicit text for empty cells; and
- a visible and accessible “Historical context” label on unlinked cards.

Historical cards are not links unless they name a real source that the manifest explicitly preserves. Bare governance identifiers do not become link names without a descriptive title.

### Migration ownership

The plugin ships a narrow `/wr-itil:migrate-story-map` skill that accepts a complete, adopter-ratified structured mapping. It does not read arbitrary legacy HTML or infer activities, bands, placement, evidence status, or traces.

One invocation validates the mapping, writes the canonical embedded map data and manifest entry, renders the map, verifies the fingerprints, and commits the migration. Before writing, it resolves `authorityAdr`. The cited decision's metadata block at the top of its file (frontmatter) must contain `human-oversight: confirmed` and a `legacy-projections` mapping from each authorised map identifier to its historical projection fingerprint. The selected map and fingerprint must match one exact entry. Duplicate map keys are invalid.

A flag in the manifest cannot replace the cited ratified decision. The skill rejects a missing, unresolved, or unconfirmed decision. It also rejects incomplete, ambiguous, or mismatched authority data. It exits successfully without changing files when the selected map is already canonical or no eligible legacy map exists.

Each adopter remains authoritative for the mapping it supplies and ratifies. The shared migration skill owns only the deterministic rewrite, manifest, rendering, and verification mechanics. Git history preserves the replaced source file.

### Scope boundary

This decision covers cards already present in a retained legacy source map. It does not author new historical claims or resolve Problem 509's separate question about adding already-working capability to a newly captured map.

## Consequences

### Good

- Accepted history stays in the same row-and-activity grid as the rest of the journey.
- Ordinary story, RFC, status, approval, problem, and query rules remain strict.
- Source labels remain visible without becoming present-day delivery claims.
- One maintained map replaces each legacy map.
- Historical relationships remain available to keyboard and assistive-technology users without browser scripting.

### Neutral

- `preRfc: true` now has two mechanically distinct forms: existing story-backed delivered rows and manifest-bound historical rows.
- Adopters ratify content mappings because only they can authoritatively interpret their legacy maps.
- The first canonical-file fingerprint records the migration but does not freeze future ordinary map work.

### Bad

- The release-row schema gains an exceptional historical subtype and repository-level manifest.
- The renderer must distinguish historical source labels from derived delivery status.
- Migrated maps require another human ratification because historical substance joins the oversight fingerprint.

## Confirmation

- A map without a manifest-bound historical pre-RFC row keeps the same rendered output, query results, and fingerprint. Re-rendering produces a byte-identical file.
- Existing story-backed rows with bare `preRfc: true` retain their current delivered-history behavior.
- An ordinary card without a real story still fails validation.
- Ordinary RFC rows retain existing RFC, status, problem, approval, and query behavior.
- A valid historical pre-RFC row renders in the committed map table with its source label, reported date, semantic headers, focusable region, focus style, empty-cell text, and historical-context labels.
- Historical rows and cards contribute no RFC identity, delivery status, problem derivation, story approval, or `find-story` result.
- Historical labels are shown as dated source labels and never translated into current delivery claims.
- Validation fails in each of these cases:
  - the manifest, map identifier, or path is missing, invalid, or mismatched;
  - the source or historical fingerprint differs;
  - the cited authority is missing, unconfirmed, or mismatched; or
  - the row subtype or card content is invalid or mismatched.
- Changing historical substance fails until a newly ratified decision authorises the new fingerprint.
- Existing story-map query and reverse-reference tests pass unchanged, and new behavioral tests cover every failure above.
- The migration skill accepts only a complete mapping whose cited adopter decision has confirmed human oversight and a matching `legacy-projections` entry. It writes and verifies the canonical map and manifest in one invocation.
- The migration skill rejects incomplete, ambiguous, or mismatched input before writing and makes no change when the selected map is already canonical or no eligible legacy map exists.
- No migration adds a historical card absent from the retained source file.

Requested action: ratify Option 1 as written, propose amendments, or reject it.

## Pros and Cons of the Options

### Manifest-bound historical pre-RFC rows

- Good, because they preserve the familiar map grid without weakening ordinary rows or tasks.
- Bad, because `preRfc` gains a second, exceptional subtype.

### Separate top-level historical projection

- Good, because it isolates history completely from releases.
- Bad, because it creates a second structure for the same activity relationships.

### Ordinary tasks without story identifiers

- Good, because it needs fewer schema concepts.
- Bad, because new unbacked work becomes indistinguishable from historical context.

### Retrospective story files

- Good, because the current renderer needs no change.
- Bad, because reconstructed stories can imply evidence that never existed.

### Legacy maps beside successors

- Good, because old files remain untouched.
- Bad, because journey ownership and discovery split across two maps.

### Remove historical cards

- Good, because migration is mechanically easy.
- Bad, because accepted context is lost.

## Reassessment Criteria

Reassess no later than 2026-12-14, or sooner if:

- historical pre-RFC rows are mistaken for current delivery state;
- every retained historical card gains a trustworthy original story record;
- manifest or fingerprint-validation failures create recurring adopter friction; or
- the exception is used for newly authored work.

## Related

- [Problem 496: Story-map corpus encodings need migration](../problems/open/496-story-map-corpus-carries-three-incompatible-encodings-needing-migration.md).
- [Problem 509: Story-map capture omits already-working capability](../problems/known-error/509-story-map-capture-produces-a-work-breakdown-not-the-personas-journey.md).
- Architecture decision record `ADR-090` — Story maps and stories carry a drift-invalidated human-oversight marker.
- Architecture decision record `ADR-102` — Story maps render from JSON through a canonical template.
- Architecture decision record `ADR-103` — A release row is the RFC, and the map is the approval surface.
- Architecture decision record `ADR-104` — A story map card stores no value a story file already carries.
- Architecture decision record `ADR-105` — The grid ships in the file; a map is readable with no script engine.
- Architecture decision record `ADR-107` — A story map's RFC list is derived from its release rows.
- Jobs To Be Done record `JTBD-009` — Migrate adopter artefacts when a plugin layout evolves.
- Jobs To Be Done record `JTBD-101` — Extend the suite with new plugins.
