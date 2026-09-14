---
status: proposed
date: 2026-09-14
human-oversight: unconfirmed
decision-makers: Tom Howard
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-12-14
---

# Manifest-bound legacy projections for story-map migration

> Captured via /wr-architect:capture-adr. This decision remains unconfirmed until Tom ratifies or amends it.

## Context and Problem Statement

The story-map generator requires every ordinary card to link to a real story file. That rule protects delivery authority. It also keeps status, value, problems, and approval derived from their authoritative records. The renderer is the part of the generator that creates the visible map.

Some adopter maps predate that rule. They contain accepted historical cards without story files. The current generator cannot migrate those maps without deleting accepted context or creating retrospective stories with invented evidence.

The shared format's data rules (schema) need a narrow way to preserve historical context. They must not weaken the ordinary delivery model or create a second release-row system.

This decision adds a separate section for historical content. The existing story-map decisions listed in Related continue to govern ordinary map content.

This decision calls a map in the current shared format a canonical map. The exception is bound to a checked-in migration manifest: a file that lists each approved map and records fingerprints used to detect changes.

## Decision Drivers

- Preserve accepted historical context without inventing stories or evidence.
- Keep ordinary cards, release rows, approval, status, and queries unchanged.
- Make the exception explicit, reviewable, protected from unapproved changes, and invalid when required migration evidence is missing or incorrect.
- Keep one canonical map per journey.
- Render committed maps that remain readable without browser scripting.
- Give keyboard and assistive-technology users the same historical relationships shown visually.
- Support an in-place adopter migration without forcing future readers to reconstruct undocumented source history.

## Considered Options

1. **Add a manifest-bound `legacyProjection` section outside ordinary delivery data (chosen).** This preserves historical content while keeping ordinary release and task rules intact.
2. **Allow ordinary tasks without story identifiers.** This is smaller mechanically, but weakens the invariant for every new map and makes historical context indistinguishable from delivery authority.
3. **Require retrospective story files.** This keeps the current schema unchanged, but risks presenting reconstructed records as original evidence.
4. **Keep legacy maps beside canonical successors.** This avoids a schema change, but leaves two maintained maps for one journey and splits discovery.
5. **Remove unbacked historical cards.** This is simple, but deletes accepted journey substance.

## Decision Outcome

Chosen option: **"Add a manifest-bound `legacyProjection` section outside ordinary delivery data"**.

### Separate historical data

The map's embedded data may contain a top-level `legacyProjection` section. This restricted section is separate from `releases` and `tasks`. It contains:

- the legacy map's reported date;
- historical band identifiers, labels, and notes;
- historical cards with their activity and band placement, visible title, supporting text, and recorded status label; and
- no ordinary release or task objects.

A legacy projection contributes no delivery authority, request for comments (RFC) membership, release status, problem derivation, story approval, or `find-story` result. Its bands are not release rows. Labels such as `Live`, `Selected next`, `Research only`, `R1`, `R2`, and `R3` remain historical labels as of the map's reported date. They do not prove shipment dates, current production state, or delivery evidence.

Every ordinary card still requires a real story file and exactly one release row. An ordinary unbacked card remains invalid.

### Deterministic migration manifest

The renderer discovers one manifest at `docs/story-maps/legacy-projection-manifest.json`, relative to the repository root containing the map. A map with `legacyProjection` is invalid when the manifest is missing, malformed, lacks that exact map identifier and repository-relative path, or contains an unsupported schema version.

Each manifest entry records:

- `mapId` and `path`;
- `authorityAdr`, identifying the adopter architecture decision that ratifies the exact migration;
- the source commit and the 256-bit Secure Hash Algorithm (SHA-256) fingerprint of the exact pre-migration file bytes;
- the SHA-256 fingerprint of the projection's deterministic JavaScript Object Notation (JSON) representation; and
- the SHA-256 fingerprint of the first complete canonical file produced by the migration.

The deterministic projection representation recursively sorts object keys and preserves array order. It encodes the result as JSON without extra whitespace, using 8-bit Unicode Transformation Format (UTF-8). It computes the fingerprint from those exact bytes. The validator recomputes this fingerprint on every render and query. It rejects a missing entry, an ineligible path or identifier, malformed fields, a projection fingerprint mismatch, or ordinary `releases` or `tasks` nested inside the projection.

The first canonical-file fingerprint is a historical migration receipt. It is checked when the migration is created, but it does not gate later ordinary map evolution. Later release rows and ordinary cards therefore do not require a manifest change. The projection fingerprint remains an enforcement boundary: changing the projection or its manifest entry requires a new ratified decision.

### Approval boundary

The map's human-oversight fingerprint detects changes to ratified content. It includes `legacyProjection`, so migrating or changing a projection requires human ratification. Later presentation-only changes remain outside this fingerprint. Ordinary release rows and story cards retain their existing approval behavior under architecture decision record `ADR-103`.

### Committed accessible rendering

The renderer writes the historical projection into committed Hypertext Markup Language (HTML). It does not rely on browser scripting to make the content available. The projection uses a separate semantic table with:

- a caption naming the map's reported date and historical-context purpose;
- scoped activity-column and historical-band row headers;
- a named, keyboard-focusable horizontal scroll region with visible focus styling;
- explicit text for empty cells; and
- a visible and accessible “Historical context” label on unlinked cards.

Projection cards are not links unless they name a real historical source that the manifest explicitly preserves. Bare governance identifiers do not become link names without a descriptive title.

### Migration ownership

This decision changes the shared format, renderer, and migration surface. It does not ship a converter that reads arbitrary legacy HTML or infers journey activities, band meaning, card placement, evidence status, or traces.

The plugin ships a narrow `/wr-itil:migrate-story-map` skill that accepts a complete, adopter-ratified structured mapping. One invocation validates that mapping, writes the canonical embedded map data and manifest entry, renders the map, verifies the fingerprints, and commits the migration. Before writing, it resolves `authorityAdr`. The cited decision's metadata block at the top of its file (frontmatter) must contain `human-oversight: confirmed` and a `legacy-projections` mapping from each authorised map identifier to its projection fingerprint. The selected map identifier and fingerprint must match one exact entry. Duplicate map keys are invalid. A flag in the manifest cannot replace the cited ratified decision. The skill rejects a missing, unresolved, or unconfirmed decision. It also rejects incomplete, ambiguous, or mismatched authority data. It exits successfully without changing files when the selected map is already canonical or no eligible legacy map exists.

Each adopter remains authoritative for the mapping it supplies and ratifies. The shared migration skill owns only the deterministic rewrite, manifest, rendering, and verification mechanics. Git history preserves the replaced source file.

## Consequences

### Good

- Accepted historical context can move into the canonical format without fabricated stories.
- Ordinary story, release, RFC, status, approval, problem, and query rules remain strict.
- The manifest makes the exception reviewable and detects later projection changes.
- One maintained map replaces each legacy map.
- Historical relationships remain available to keyboard and assistive-technology users without browser scripting.

### Neutral

- A migrated map may contain both ordinary delivery rows and a visually separate historical projection.
- Adopters ratify the proposed content mapping because only they can authoritatively interpret their legacy maps.
- The first canonical-file fingerprint records the migration but does not freeze future ordinary map work.

### Bad

- The format gains an exceptional data section and a repository-level manifest.
- Migrated maps require another human ratification because historical projection substance joins the oversight fingerprint.
- The shared validator must inspect one additional file for maps that use the exception.

## Confirmation

- A map without `legacyProjection` keeps the same rendered output, query results, and fingerprint. Re-rendering produces a byte-identical file.
- An ordinary card without a real story still fails validation.
- Delivery rows retain existing RFC, status, problem, approval, and query behavior.
- A valid manifested projection renders into committed HTML with the required semantic table, caption, headers, focusable region, focus style, empty-cell text, and historical-context labels.
- Projection bands and cards contribute no RFC identity, release status, problem derivation, story approval, or `find-story` result.
- The map oversight fingerprint changes when projection substance changes and remains stable for presentation-only changes.
- Validation fails in each of these cases:
   - the manifest is missing, malformed, or uses an unsupported version;
   - the map is unlisted, or its path or identifier does not match;
   - the source fingerprint differs during migration;
   - the projection fingerprint differs;
   - the cited adopter decision is missing, unresolved, unconfirmed, or does not identify the same map and projection fingerprint;
   - the map is ineligible for a projection; or
   - ordinary `releases` or `tasks` are nested inside the projection.
- Changing the projection after migration fails until a newly ratified decision updates its manifest fingerprint.
- The first canonical-file fingerprint is verified when created, retained as a receipt, and ignored as a gate on later ordinary rows or cards.
- Existing story-map query and reverse-reference tests pass unchanged, and new behavioral tests cover every failure listed above.
- The migration skill accepts only a complete structured mapping whose cited adopter decision has confirmed human oversight and a `legacy-projections` entry matching the selected map and projection fingerprint. It then writes and verifies the canonical map and manifest in one invocation.
- The migration skill does not interpret legacy HTML. It rejects a missing, incomplete, or ambiguous mapping before writing, and exits successfully without changing files when the selected map is already canonical or no eligible legacy map exists.

Requested action: ratify Option 1 as written, propose amendments, or reject it.

## Pros and Cons of the Options

### Manifest-bound legacy projection

- Good, because it preserves history without weakening ordinary delivery data.
- Bad, because it adds a narrow exceptional schema and manifest.

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

- historical projections no longer need to be retained;
- every retained historical card gains a trustworthy original story record;
- manifest review or fingerprint-validation failures create recurring adopter friction; or
- the exception is used for newly authored work.

## Related

- [Problem 496: Story-map corpus encodings need migration](../problems/open/496-story-map-corpus-carries-three-incompatible-encodings-needing-migration.md).
- Architecture decision record `ADR-090` — Story maps and stories carry a drift-invalidated human-oversight marker.
- ADR-102 — Story maps render from JSON through a canonical template.
- ADR-103 — A release row is the RFC, and the map is the approval surface.
- ADR-104 — A story map card stores no value a story file already carries.
- ADR-105 — The grid ships in the file; a map is readable with no script engine.
- ADR-107 — A story map's RFC list is derived from its release rows.
- Jobs To Be Done record `JTBD-009` — Migrate adopter artefacts when a plugin layout evolves.
- Jobs To Be Done record `JTBD-101` — Extend the suite with new plugins.
